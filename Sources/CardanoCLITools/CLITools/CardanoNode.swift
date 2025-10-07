import Foundation
import SystemPackage
import Logging


/// Cardano Node binary runner
public struct CardanoNode: BinaryRunnable {
    let binaryPath: FilePath
    let workingDirectory: FilePath
    let configuration: CardanoCLIToolsConfig
    let logger: Logging.Logger
    static let binaryName: String = "cardano-node"
    static let mininumSupportedVersion: String = "8.0.0"
    
    let showOutput: Bool
    let cardanoConfig: CardanoConfig
    var process: Process?
    var processTerminated: Bool = false

    init(configuration: CardanoCLIToolsConfig, logger: Logging.Logger?) async throws {
        // Assign all let properties directly
        self.configuration = configuration
        self.cardanoConfig = configuration.cardano
        self.showOutput = configuration.cardano.showOutput ?? true
        
        // Setup binary path
        guard let nodePath = configuration.cardano.node else {
            throw CardanoCLIToolsError.binaryNotFound("cardano-node path not configured")
        }
        self.binaryPath = nodePath
        try Self.checkBinary(binary: self.binaryPath)
        
        // Setup working directory
        self.workingDirectory = configuration.cardano.workingDir
        try Self.checkWorkingDirectory(workingDirectory: self.workingDirectory)
        
        // Setup logger
        self.logger = logger ?? Logger(label: Self.binaryName)
        
        // Setup node socket environment variable
        guard let socket = cardanoConfig.socket else {
            throw CardanoCLIToolsError.configurationMissing(configuration)
        }
        Environment.set(.cardanoSocketPath, value: socket.string)
        
        // Check the version compatibility on initialization
        try await checkVersion()
    }
    
    /// Start the cardano-node process
    public mutating func start() throws {
        var arguments: [String] = ["run"]
        
        // Add required arguments
        guard let nodeConfig = cardanoConfig.config else {
            throw CardanoCLIToolsError.valueError("Cardano node config path is required for cardano-node run")
        }
        guard let nodeSocket = cardanoConfig.socket else {
            throw CardanoCLIToolsError.valueError("Cardano node socket path is required for cardano-node run")
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
        
        try self.start(arguments)
    }
    
    public func version() async throws -> String {
        let output = try await runCommand(["--version"])
        let components = output.components(separatedBy: " ")
        guard components.count >= 2 else {
            throw CardanoCLIToolsError.invalidOutput("Could not parse version from: \(output)")
        }
        return components[1]
    }
}
