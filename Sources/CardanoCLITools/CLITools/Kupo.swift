import Foundation
import SystemPackage
import Logging

/// Kupo binary runner
public struct Kupo: BinaryRunnable {
    public let binaryPath: FilePath
    public let workingDirectory: FilePath
    public let configuration: CardanoCLIToolsConfig
    public let logger: Logging.Logger
    public static let binaryName: String = "kupo"
    public static let mininumSupportedVersion: String = "2.3.4"
    
    public let showOutput: Bool
    public let cardanoConfig: CardanoConfig
    public let kupoConfig: KupoConfig
    public var process: Process?
    public var processTerminated: Bool = false

    public init(configuration: CardanoCLIToolsConfig, logger: Logging.Logger? = nil) async throws {
        // Assign all let properties directly
        self.configuration = configuration
        self.cardanoConfig = configuration.cardano
        self.showOutput = configuration.kupo?.showOutput ?? true
        
        guard let kupoConfig = configuration.kupo else {
            throw CardanoCLIToolsError.configurationMissing(configuration)
        }
        self.kupoConfig = kupoConfig
        
        // Setup binary path
        guard let binaryPath = kupoConfig.binary else {
            throw CardanoCLIToolsError.valueError("Kupo binary path is required")
        }
        self.binaryPath = binaryPath
        try Self.checkBinary(binary: self.binaryPath)
        
        // Setup working directory
        if kupoConfig.workingDir == nil {
            self.workingDirectory = .init(FileManager.default.currentDirectoryPath)
        } else {
            self.workingDirectory = kupoConfig.workingDir!
            try Self.checkWorkingDirectory(workingDirectory: self.workingDirectory)
        }
        
        // Setup logger
        self.logger = logger ?? Logger(label: Self.binaryName)
        
        // Check the version compatibility on initialization
        try await checkVersion()
    }
    
    /// Start the kupo process
    public mutating func start() throws {
        var arguments: [String] = []
        
        // Connection arguments - prefer Ogmios if available, otherwise use direct node connection
        if let ogmiosConfig = configuration.ogmios {
            // Use Ogmios connection
            let ogmiosHost = ogmiosConfig.host ?? "127.0.0.1"
            let ogmiosPort = ogmiosConfig.port ?? 1337
            arguments.append(contentsOf: ["--ogmios-host", ogmiosHost])
            arguments.append(contentsOf: ["--ogmios-port", String(ogmiosPort)])
        } else {
            // Use direct node connection
            guard let socket = cardanoConfig.socket else {
                throw CardanoCLIToolsError.valueError("Cardano node socket path is required for kupo when Ogmios is not configured")
            }
            guard let config = cardanoConfig.config else {
                throw CardanoCLIToolsError.valueError("Cardano node config path is required for kupo when Ogmios is not configured")
            }
            arguments.append(contentsOf: ["--node-socket", socket.string])
            arguments.append(contentsOf: ["--node-config", config.string])
        }
        
        // In-memory mode or work directory
        if let inMemory = kupoConfig.inMemory, inMemory {
            arguments.append("--in-memory")
        } else if let workDir = kupoConfig.workingDir {
            arguments.append(contentsOf: ["--workdir", workDir.string])
        }
        
        // Host and port
        arguments.append(contentsOf: ["--host", kupoConfig.host ?? "127.0.0.1"])
        arguments.append(contentsOf: ["--port", String(kupoConfig.port ?? 1442)])
        
        // Since parameter (start from specific point)
        if let since = kupoConfig.since {
            arguments.append(contentsOf: ["--since", since])
        }
        
        // Match patterns (can be provided multiple times)
        if let matches = kupoConfig.matches {
            for pattern in matches {
                arguments.append(contentsOf: ["--match", pattern])
            }
        }
        
        // Boolean flags
        if let deferDbIndexes = kupoConfig.deferDbIndexes, deferDbIndexes {
            arguments.append("--defer-db-indexes")
        }
        
        if let pruneUTxO = kupoConfig.pruneUTxO, pruneUTxO {
            arguments.append("--prune-utxo")
        }
        
        // Numeric options
        if let gcInterval = kupoConfig.gcInterval {
            arguments.append(contentsOf: ["--gc-interval", String(gcInterval)])
        }
        
        if let maxConcurrency = kupoConfig.maxConcurrency {
            arguments.append(contentsOf: ["--max-concurrency", String(maxConcurrency)])
        }
        
        // Log level options - use global log level if provided, otherwise use specific ones
        if let logLevel = kupoConfig.logLevel {
            arguments.append(contentsOf: ["--log-level", logLevel])
        } else {
            // Individual log levels (only if global log level is not set)
            if let logLevelHttpServer = kupoConfig.logLevelHttpServer {
                arguments.append(contentsOf: ["--log-level-http-server", logLevelHttpServer])
            }
            
            if let logLevelDatabase = kupoConfig.logLevelDatabase {
                arguments.append(contentsOf: ["--log-level-database", logLevelDatabase])
            }
            
            if let logLevelConsumer = kupoConfig.logLevelConsumer {
                arguments.append(contentsOf: ["--log-level-consumer", logLevelConsumer])
            }
            
            if let logLevelGarbageCollector = kupoConfig.logLevelGarbageCollector {
                arguments.append(contentsOf: ["--log-level-garbage-collector", logLevelGarbageCollector])
            }
            
            if let logLevelConfiguration = kupoConfig.logLevelConfiguration {
                arguments.append(contentsOf: ["--log-level-configuration", logLevelConfiguration])
            }
        }
        
        try self.start(arguments)
    }
    
    public func version() async throws -> String {
        let output = try await runCommand(["--version"])
        // Handle output like v2.3.4
        let versionString = output.split(separator: "v").last ?? ""
        return String(versionString)
    }
}
