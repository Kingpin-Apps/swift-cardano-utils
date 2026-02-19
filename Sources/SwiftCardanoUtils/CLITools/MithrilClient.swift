import Foundation
import SystemPackage
import SwiftCardanoCore
import Logging
import PotentCodables
import PotentCBOR
import Command


// MARK: - Main MithrilClient Interface

/// Main interface for interacting with Mithril client CLI tools
/// 
/// The Mithril client is used to download and verify certified Cardano blockchain snapshots.
/// It supports downloading the Cardano database, stake distributions, and transaction data.
public struct MithrilClient: BinaryInterfaceable {
    public let binaryPath: FilePath
    public let workingDirectory: FilePath
    public let configuration: Config
    public let cardanoConfig: CardanoConfig
    public let logger: Logging.Logger
    
    public static let binaryName: String = "mithril-client"
    public static let mininumSupportedVersion: String = "0.12.38"
    
    public let commandRunner: any CommandRunning
    
    public let mithrilConfig: MithrilConfig
    
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
        guard let mithrilConfig = configuration.mithril else {
            throw SwiftCardanoUtilsError.configurationMissing(
                "Mithril configuration missing: \(configuration)"
            )
        }
        
        self.configuration = configuration
        self.cardanoConfig = cardanoConfig
        self.mithrilConfig = mithrilConfig
        
        // Setup binary path
        guard let mithrilPath = mithrilConfig.binary else {
            throw SwiftCardanoUtilsError.binaryNotFound("mithril-client path not configured")
        }
        self.binaryPath = mithrilPath
        try Self.checkBinary(binary: self.binaryPath)
        
        // Setup working directory
        self.workingDirectory = mithrilConfig.workingDir ?? cardanoConfig.workingDir ?? FilePath(
            FileManager.default.currentDirectoryPath
        )
        try Self.checkWorkingDirectory(workingDirectory: self.workingDirectory)
        
        // Setup logger
        self.logger = logger ?? Logger(label: Self.binaryName)
        
        // Setup command runner
        self.commandRunner = commandRunner ?? CommandRunner(logger: self.logger)
        
        // Check the CLI version compatibility on initialization
        try await checkVersion()
    }
    
    // MARK: - Version and Help

    public func version() async throws -> String {
        let output = try await runCommand(["--version"])
        let components = output.components(separatedBy: " ")
        
        guard components.count >= 2 else {
            throw SwiftCardanoUtilsError.invalidOutput("Could not parse version from: \(output)")
        }
        
        let versionString = components[1].components(separatedBy: "+")
        
        return versionString[0]
    }
    
    /// Get the help text
    public func help() async throws -> String {
        return try await runCommand(["help"])
    }
    
    // MARK: - High-Level Utility Methods
    
    /// Download the latest Cardano database snapshot with full verification
    /// - Parameters:
    ///   - downloadDir: Optional directory to download the snapshot to (defaults to configured download directory or current working directory)
    ///   - includeAncillary: Whether to include ancillary files for fast bootstrap (defaults to true)
    /// - Returns: The command output
    public func downloadLatestSnapshot(
        downloadDir: String? = nil,
        includeAncillary: Bool = true
    ) async throws -> String {
        let dir = downloadDir ?? mithrilConfig.downloadDir?.string ?? cardanoConfig.database?.string
        let ancillaryKey = mithrilConfig.ancillaryVerificationKey
        
        return try await cardanoDb.download(
            digest: "latest",
            downloadDir: dir,
            includeAncillary: includeAncillary,
            ancillaryVerificationKey: ancillaryKey
        )
    }
    
    /// Download the latest snapshot without ancillary files (faster download, but slower node startup)
    /// - Parameter downloadDir: Optional directory to download the snapshot to
    /// - Returns: The command output
    public func downloadLatestSnapshotFast(downloadDir: String? = nil) async throws -> String {
        let dir = downloadDir ?? mithrilConfig.downloadDir?.string ?? cardanoConfig.database?.string
        
        return try await cardanoDb.downloadSkipAncillary(
            digest: "latest",
            downloadDir: dir
        )
    }
    
    /// List available Cardano database snapshots
    /// - Returns: JSON string containing available snapshots
    public func listSnapshots() async throws -> String {
        return try await cardanoDb.snapshotList(arguments: ["--json"])
    }
    
    /// Certify that a transaction is included in the certified Cardano transactions set
    /// - Parameter transactionHash: The transaction hash to certify
    /// - Returns: The certification result
    public func certifyTransaction(transactionHash: String) async throws -> String {
        return try await cardanoTransaction.certify(transactionHashes: [transactionHash])
    }
}

// MARK: - Command Accessors

extension MithrilClient {
    
    /// Access to cardano-db commands (alias: cdb)
    public var cardanoDb: CardanoDbCommandImpl {
        return CardanoDbCommandImpl(
            baseCLI: self,
            mithrilConfig: self.mithrilConfig
        )
    }
    
    /// Access to mithril-stake-distribution commands (alias: msd)
    public var mithrilStakeDistribution: MithrilStakeDistributionCommandImpl {
        return MithrilStakeDistributionCommandImpl(
            baseCLI: self,
            mithrilConfig: self.mithrilConfig
        )
    }
    
    /// Access to cardano-transaction commands (alias: ctx)
    public var cardanoTransaction: CardanoTransactionCommandImpl {
        return CardanoTransactionCommandImpl(
            baseCLI: self,
            mithrilConfig: self.mithrilConfig
        )
    }
    
    /// Access to cardano-stake-distribution commands (alias: csd)
    public var cardanoStakeDistribution: CardanoStakeDistributionCommandImpl {
        return CardanoStakeDistributionCommandImpl(
            baseCLI: self,
            mithrilConfig: self.mithrilConfig
        )
    }
    
    /// Access to tools commands
    public var tools: ToolsCommandImpl {
        return ToolsCommandImpl(
            baseCLI: self,
            mithrilConfig: self.mithrilConfig
        )
    }
}
