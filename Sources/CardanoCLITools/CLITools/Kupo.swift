import Foundation
import System
import Logging

/// Kupo binary runner
public struct Kupo: BinaryRunnable {
    let binaryPath: FilePath
    let workingDirectory: FilePath
    let configuration: Configuration
    let logger: Logging.Logger
    static let binaryName: String = "kupo"
    static let mininumSupportedVersion: String = "2.3.4"
    
    let showOutput: Bool
    let cardanoConfig: CardanoConfig
    let kupoConfig: KupoConfig
    var process: Process?

    init(configuration: Configuration, logger: Logging.Logger?) async throws {
        // Assign all let properties directly
        self.configuration = configuration
        self.cardanoConfig = configuration.cardano
        self.showOutput = configuration.kupo?.showOutput ?? true
        
        guard let kupoConfig = configuration.kupo else {
            throw CardanoCLIToolsError.configurationMissing(configuration)
        }
        self.kupoConfig = kupoConfig
        
        // Setup binary path
        self.binaryPath = kupoConfig.binary
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
        
        // Required arguments
        arguments.append(contentsOf: ["--node-socket", cardanoConfig.socket.string])
        arguments.append(contentsOf: ["--node-config", cardanoConfig.config.string])
        
        // Host and port
        arguments.append(contentsOf: ["--host", kupoConfig.host ?? "127.0.0.1"])
        arguments.append(contentsOf: ["--port", String(kupoConfig.port ?? 1442)])
        
        // Since parameter (start from specific point)
        if let since = kupoConfig.since {
            arguments.append(contentsOf: ["--since", since])
        }
        
        // Work directory
        if let workDir = kupoConfig.workingDir {
            arguments.append(contentsOf: ["--workdir", workDir.string])
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
