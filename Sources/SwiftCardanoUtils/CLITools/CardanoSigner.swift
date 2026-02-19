import Foundation
import SystemPackage
import Logging
import Command

// MARK: - Cardano Signer CLI

/// Wrapper struct for the cardano-signer tool
public struct CardanoSigner: BinaryInterfaceable {
    public let binaryPath: FilePath
    public let workingDirectory: FilePath
    public let configuration: Config
    public let cardanoConfig: CardanoConfig
    public let logger: Logger
    
    public static let binaryName: String = "cardano-signer"
    public static let mininumSupportedVersion: String = "1.17.0"
    
    public let commandRunner: any CommandRunning
    
    /// Initialize with optional configuration
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
        
        guard let signerPath = cardanoConfig.signer else {
            throw SwiftCardanoUtilsError.binaryNotFound("cardano-signer path not configured")
        }
        
        self.configuration = configuration
        self.cardanoConfig = cardanoConfig
        
        // Setup binary path
        self.binaryPath = signerPath
        try Self.checkBinary(binary: self.binaryPath)
        
        // Setup working directory
        self.workingDirectory = cardanoConfig.workingDir ?? FilePath(
            FileManager.default.currentDirectoryPath
        )
        try Self.checkWorkingDirectory(workingDirectory: self.workingDirectory)
        
        // Setup logger
        self.logger = logger ?? Logger(label: "CardanoSigner")
        
        // Setup command runner
        self.commandRunner = commandRunner ?? CommandRunner(logger: self.logger)
        
        try await checkVersion()
    }
    
    /// Get the version of cardano-signer
    public func version() async throws -> String {
        let output = try await runCommand(["help"])
        
        // Extract version using regex pattern
        let pattern = #"cardano-signer (\d+\.\d+\.\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: output, range: NSRange(output.startIndex..., in: output)),
              let versionRange = Range(match.range(at: 1), in: output) else {
            throw SwiftCardanoUtilsError.invalidOutput("Could not parse cardano-signer version from: \(output)")
        }
        
        return String(output[versionRange])
    }
}

extension CardanoSigner {
    // MARK: - Command Accessors
    
    /// Access to canonize commands
    public var canonize: CanonizeCommandImpl {
        return CanonizeCommandImpl(baseCLI: self)
    }
    
    /// Access to keygen commands
    public var keygen: KeyGenCommandImpl {
        return KeyGenCommandImpl(baseCLI: self)
    }
    
    /// Access to sign commands
    public var sign: SignCommandImpl {
        return SignCommandImpl(baseCLI: self)
    }
    
    /// Access to verify commands
    public var verify: VerifyCommandImpl {
        return VerifyCommandImpl(baseCLI: self)
    }
}
