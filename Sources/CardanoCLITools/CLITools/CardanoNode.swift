import Foundation
import System
import Logging


/// Cardano Node binary runner
public struct CardanoNode: BinaryRunnable {
    let binaryPath: FilePath
    let workingDirectory: FilePath
    let configuration: Configuration
    let logger: Logging.Logger
    static let binaryName: String = "cardano-node"
    static let mininumSupportedVersion: String = "8.0.0"
    
    let showOutput: Bool
    let cardanoConfig: CardanoConfig
    var process: Process?

    init(configuration: Configuration, logger: Logging.Logger?) async throws {
        // Assign all let properties directly
        self.configuration = configuration
        self.cardanoConfig = configuration.cardano
        self.showOutput = configuration.cardano.showOutput ?? true
        
        // Setup binary path
        self.binaryPath = configuration.cardano.node
        try Self.checkBinary(binary: self.binaryPath)
        
        // Setup working directory
        self.workingDirectory = configuration.cardano.workingDir
        try Self.checkWorkingDirectory(workingDirectory: self.workingDirectory)
        
        // Setup logger
        self.logger = logger ?? Logger(label: Self.binaryName)
        
        // Setup node socket environment variable
        Environment.set(.cardanoSocketPath, value: cardanoConfig.socket.string)
        
        // Check the version compatibility on initialization
        try await checkVersion()
    }
    
    /// Start the cardano-node process
    public mutating func start() throws {
        var arguments: [String] = ["run"]
        
        // Add required arguments
        arguments.append(contentsOf: ["--config", cardanoConfig.config.string])
        arguments.append(contentsOf: ["--socket-path", cardanoConfig.socket.string])
        
        // Add optional arguments
        if let topology = cardanoConfig.topology {
            arguments.append(contentsOf: ["--topology", topology.string])
        }
        
        if let database = cardanoConfig.database {
            arguments.append(contentsOf: ["--database-path", database.string])
        }
        
        if let port = cardanoConfig.port {
            arguments.append(contentsOf: ["--port", String(port)])
        }
        
        if let hostAddr = cardanoConfig.hostAddr {
            arguments.append(contentsOf: ["--host-addr", hostAddr])
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
