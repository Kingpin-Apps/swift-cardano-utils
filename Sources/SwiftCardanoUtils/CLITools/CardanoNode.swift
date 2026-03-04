import Foundation
import SystemPackage
import Logging
import Command
import Path


/// Cardano Node binary runner
public struct CardanoNode: BinaryRunnable {
    public let binaryPath: FilePath
    public let workingDirectory: FilePath
    public let configuration: Config
    public let cardanoConfig: CardanoConfig
    public let logger: Logging.Logger
    
    public static let binaryName: String = "cardano-node"
    public static let mininumSupportedVersion: String = "8.0.0"
    
    public let showOutput: Bool
    
    public let commandRunner: any CommandRunning

    public init(
        configuration: Config,
        logger: Logging.Logger? = nil,
        commandRunner: (any CommandRunning)? = nil
    ) async throws {
        guard let cardanoConfig = configuration.cardano else {
            throw SwiftCardanoUtilsError.configurationMissing(
                "Cardano configuration missing: \(configuration)"
            )
        }
        
        // Assign all let properties directly
        self.configuration = configuration
        self.cardanoConfig = cardanoConfig
        self.showOutput = cardanoConfig.showOutput ?? true

        // Setup binary path and validate
        if let container = cardanoConfig.container {
            // Container mode: the official IntersectMBO entrypoint script routes on $1:
            //   $1 == "run" → /usr/local/bin/run-node "$@" → cardano-node run <flags>
            // We set binaryPath to "run" so the CMD sent to the container is
            //   ["run", "--config", ...] and NOT ["cardano-node", "run", ...]
            // which would fall through to the entrypoint's error branch.
            self.binaryPath = FilePath("run")
            try ContainerChecks.checkImage(config: container)
        } else {
            guard let nodePath = cardanoConfig.node else {
                throw SwiftCardanoUtilsError.binaryNotFound("cardano-node path not configured")
            }
            self.binaryPath = nodePath
            try Self.checkBinary(binary: self.binaryPath)
        }

        // Setup working directory
        self.workingDirectory = cardanoConfig.workingDir ?? FilePath(
            FileManager.default.currentDirectoryPath
        )
        try Self.checkWorkingDirectory(workingDirectory: self.workingDirectory)

        // Setup logger
        self.logger = logger ?? Logger(label: Self.binaryName)

        // Setup command runner — inject ContainerizedCommandRunner when container is configured
        self.commandRunner = ContainerizedCommandRunner.resolve(
            injected: commandRunner,
            container: cardanoConfig.container,
            mode: .run,
            logger: self.logger
        )

        // Setup node socket environment variable
        if let socket = cardanoConfig.socket {
            Environment.set(.cardanoSocketPath, value: socket.string)
        }

        // Version check is skipped in container run-mode because the container
        // has not been launched yet — call start() first.
        if cardanoConfig.container == nil {
            guard cardanoConfig.socket != nil else {
                throw SwiftCardanoUtilsError.configurationMissing(
                    "Cardano node socket path is required for cardano-node run: \(cardanoConfig)"
                )
            }
            try await checkVersion()
        } else {
            self.logger.info("\(Self.binaryName): skipping version check in container run-mode")
        }
    }
    
    /// Start the cardano-node process
    public func start(useDefaultEntrypoint: Bool = false) async throws -> Void {
        
        // In non-container (binary) mode the first positional argument to
         // cardano-node is "run".  In container mode "run" is already captured
        // in binaryPath (the entrypoint routing word), so we must NOT repeat
        // it here — that would produce ["run", "run", "--config", ...].
        var arguments: [String] = cardanoConfig.container == nil ? ["run"] : []
        
        // Add required arguments
        guard let nodeConfig = cardanoConfig.config else {
            throw SwiftCardanoUtilsError.valueError("Cardano node config path is required for cardano-node run")
        }
        guard let nodeSocket = cardanoConfig.socket else {
            throw SwiftCardanoUtilsError.valueError("Cardano node socket path is required for cardano-node run")
        }
        arguments.append(contentsOf: ["--config", nodeConfig.string])
        arguments.append(contentsOf: ["--socket-path", nodeSocket.string])
        
        // Add optional arguments
        if let topology = cardanoConfig.topology {
            arguments.append(contentsOf: ["--topology", topology.string])
        }
        
        // Database options (use specific immutable/volatile paths if provided, otherwise fallback to database)
        if let immutableDatabase = cardanoConfig.immutableDatabase {
            arguments.append(contentsOf: ["--immutable-database-path", immutableDatabase.string])
        }
        if let volatileDatabase = cardanoConfig.volatileDatabase {
            arguments.append(contentsOf: ["--volatile-database-path", volatileDatabase.string])
        }
        // Only use --database-path if immutable/volatile paths are not specified
        if cardanoConfig.immutableDatabase == nil && cardanoConfig.volatileDatabase == nil,
           let database = cardanoConfig.database {
            arguments.append(contentsOf: ["--database-path", database.string])
        }
        
        // Validation
        if let validateDb = cardanoConfig.validateDb, validateDb {
            arguments.append("--validate-db")
        }
        
        // Tracer options
        if let tracerAccept = cardanoConfig.tracerSocketPathAccept {
            arguments.append(contentsOf: ["--tracer-socket-path-accept", tracerAccept.string])
        }
        if let tracerConnect = cardanoConfig.tracerSocketPathConnect {
            arguments.append(contentsOf: ["--tracer-socket-path-connect", tracerConnect.string])
        }
        
        // Key and certificate paths
        if let byronDelegationCert = cardanoConfig.byronDelegationCertificate {
            arguments.append(contentsOf: ["--byron-delegation-certificate", byronDelegationCert.string])
        }
        if let byronSigningKey = cardanoConfig.byronSigningKey {
            arguments.append(contentsOf: ["--byron-signing-key", byronSigningKey.string])
        }
        if let shelleyKesKey = cardanoConfig.shelleyKesKey {
            arguments.append(contentsOf: ["--shelley-kes-key", shelleyKesKey.string])
        }
        if let shelleyVrfKey = cardanoConfig.shelleyVrfKey {
            arguments.append(contentsOf: ["--shelley-vrf-key", shelleyVrfKey.string])
        }
        if let shelleyOpCert = cardanoConfig.shelleyOperationalCertificate {
            arguments.append(contentsOf: ["--shelley-operational-certificate", shelleyOpCert.string])
        }
        if let bulkCredentials = cardanoConfig.bulkCredentialsFile {
            arguments.append(contentsOf: ["--bulk-credentials-file", bulkCredentials.string])
        }
        
        // Node behavior
        if let nonProducingNode = cardanoConfig.nonProducingNode, nonProducingNode {
            arguments.append("--non-producing-node")
        }
        
        // Network settings
        if let port = cardanoConfig.port {
            arguments.append(contentsOf: ["--port", String(port)])
        }
        if let hostAddr = cardanoConfig.hostAddr {
            arguments.append(contentsOf: ["--host-addr", hostAddr])
        }
        if let hostIPv6Addr = cardanoConfig.hostIPv6Addr {
            arguments.append(contentsOf: ["--host-ipv6-addr", hostIPv6Addr])
        }
        
        // Shutdown options
        if let shutdownIpc = cardanoConfig.shutdownIpc {
            arguments.append(contentsOf: ["--shutdown-ipc", String(shutdownIpc)])
        }
        if let shutdownOnSlot = cardanoConfig.shutdownOnSlotSynced {
            arguments.append(contentsOf: ["--shutdown-on-slot-synced", String(shutdownOnSlot)])
        }
        if let shutdownOnBlock = cardanoConfig.shutdownOnBlockSynced {
            arguments.append(contentsOf: ["--shutdown-on-block-synced", shutdownOnBlock])
        }
        
        // Mempool options
        if let mempoolCapacity = cardanoConfig.mempoolCapacityOverride {
            arguments.append(contentsOf: ["--mempool-capacity-override", String(mempoolCapacity)])
        }
        if let noMempoolOverride = cardanoConfig.noMempoolCapacityOverride, noMempoolOverride {
            arguments.append("--no-mempool-capacity-override")
        }
        
        
        if cardanoConfig.container != nil {
            return try await self.start(useDefaultEntrypoint ? [] : arguments)
        } else {
            return try await self.start(arguments)
        }
    }
    
    public func version() async throws -> String {
        let output = try await runCommand(["--version"])
        let components = output.components(separatedBy: " ")
        guard components.count >= 2 else {
            throw SwiftCardanoUtilsError.invalidOutput("Could not parse version from: \(output)")
        }
        return components[1]
    }
}
