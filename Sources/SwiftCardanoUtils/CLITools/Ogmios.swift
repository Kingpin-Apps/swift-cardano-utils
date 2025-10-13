import Foundation
import SystemPackage
import Logging

/// Ogmios binary runner
public struct Ogmios: BinaryRunnable {
    public let binaryPath: FilePath
    public let workingDirectory: FilePath
    public let configuration: Config
    public let logger: Logging.Logger
    public static let binaryName: String = "ogmios"
    public static let mininumSupportedVersion: String = "6.13.0"
    
    public let showOutput: Bool
    public let cardanoConfig: CardanoConfig
    public let ogmiosConfig: OgmiosConfig
    public var process: Process?
    public var processTerminated: Bool = false
    
    public init(configuration: Config, logger: Logging.Logger? = nil) async throws {
        // Assign all let properties directly
        self.configuration = configuration
        self.cardanoConfig = configuration.cardano
        self.showOutput = configuration.ogmios?.showOutput ?? true
        
        guard let ogmiosConfig = configuration.ogmios else {
            throw SwiftCardanoUtilsError.configurationMissing(configuration)
        }
        self.ogmiosConfig = ogmiosConfig
        
        // Setup binary path
        guard let binaryPath = ogmiosConfig.binary else {
            throw SwiftCardanoUtilsError.valueError("Ogmios binary path is required")
        }
        self.binaryPath = binaryPath
        try Self.checkBinary(binary: self.binaryPath)
        
        // Setup working directory
        if ogmiosConfig.workingDir == nil {
            self.workingDirectory = .init(FileManager.default.currentDirectoryPath)
        } else {
            self.workingDirectory = ogmiosConfig.workingDir!
            try Self.checkWorkingDirectory(workingDirectory: self.workingDirectory)
        }
        
        // Setup logger
        self.logger = logger ?? Logger(label: Self.binaryName)
        
        // Check the version compatibility on initialization
        try await checkVersion()
    }
    
    /// Start the ogmios process
    public mutating func start() throws {
        var arguments: [String] = []
        
        // Required arguments
        guard let nodeConfig = cardanoConfig.config else {
            throw SwiftCardanoUtilsError.valueError("Cardano node config path is required for Ogmios")
        }
        guard let nodeSocket = cardanoConfig.socket else {
            throw SwiftCardanoUtilsError.valueError("Cardano node socket path is required for Ogmios")
        }
        arguments.append(contentsOf: ["--node-config", nodeConfig.string])
        arguments.append(contentsOf: ["--node-socket", nodeSocket.string])
        
        // Host and port
        arguments.append(contentsOf: ["--host", ogmiosConfig.host ?? "127.0.0.1"])
        arguments.append(contentsOf: ["--port", String(ogmiosConfig.port ?? 1337)])
        
        // Timeout and max in flight
        if let timeout = ogmiosConfig.timeout { arguments.append(contentsOf: ["--timeout", String(timeout)]) }
        if let maxInFlight = ogmiosConfig.maxInFlight { arguments.append(contentsOf: ["--max-in-flight", String(maxInFlight)]) }
        
        // Logging levels
        if let logLevel = ogmiosConfig.logLevel {
            arguments.append(contentsOf: ["--log-level", logLevel])
        } else {
            if let logLevelHealth = ogmiosConfig.logLevelHealth {
                arguments.append(contentsOf: ["--log-level-health", logLevelHealth])
            }
            if let logLevelMetrics = ogmiosConfig.logLevelMetrics {
                arguments.append(contentsOf: ["--log-level-metrics", logLevelMetrics])
            }
            if let logLevelWebsocket = ogmiosConfig.logLevelWebsocket {
                arguments.append(contentsOf: ["--log-level-websocket", logLevelWebsocket])
            }
            if let logLevelServer = ogmiosConfig.logLevelServer {
                arguments.append(contentsOf: ["--log-level-server", logLevelServer])
            }
            if let logLevelOptions = ogmiosConfig.logLevelOptions {
                arguments.append(contentsOf: ["--log-level-options", logLevelOptions])
            }
        }
        
        try self.start(arguments)
    }
    
    public func version() async throws -> String {
        let output = try await runCommand(["--version"])
        // Handle output like v6.13.0 (4e93e254)
        let versionString = output
            .split(separator: " ")
            .first!
            .split(separator: "v")
            .last ?? ""
        return String(versionString)
    }
}


