import Foundation
import SystemPackage
import Logging
import Command

// MARK: - Cardano Hardware Wallet CLI

/// Wrapper struct for the cardano-hw-cli tool
public struct CardanoHWCLI: BinaryInterfaceable {
    public let binaryPath: FilePath
    public let workingDirectory: FilePath
    public let configuration: Config
    public let cardanoConfig: CardanoConfig
    public let logger: Logger
    
    public static let binaryName: String = "cardano-hw-cli"
    public static let mininumSupportedVersion: String = "1.10.0"
    public static let minLedgerCardanoApp: String = "4.0.0"
    public static let minTrezorCardanoApp: String = "2.4.3"
    
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
        
        guard let hwCliPath = cardanoConfig.hwCli else {
            throw SwiftCardanoUtilsError.binaryNotFound("cardano-hw-cli path not configured")
        }
        
        // Assign all let properties directly
        self.configuration = configuration
        self.cardanoConfig = cardanoConfig
        
        // Setup binary path
        self.binaryPath = hwCliPath
        try Self.checkBinary(binary: self.binaryPath)
        
        // Setup working directory
        self.workingDirectory = cardanoConfig.workingDir ?? FilePath(
            FileManager.default.currentDirectoryPath
        )
        try Self.checkWorkingDirectory(workingDirectory: self.workingDirectory)
        
        // Setup logger
        self.logger = logger ?? Logger(label: "CardanoHWCLI")
        
        // Setup command runner
        self.commandRunner = commandRunner ?? CommandRunner(logger: self.logger)
        
        try await checkVersion()
    }
    
    /// Get the version of cardano-hw-cli
    public func version() async throws -> String {
        let output = try await runCommand(["version"])
        
        // Extract version using regex pattern
        let pattern = #"version (\d+\.\d+\.\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: output, range: NSRange(output.startIndex..., in: output)),
              let versionRange = Range(match.range(at: 1), in: output) else {
            throw SwiftCardanoUtilsError.invalidOutput("Could not parse cardano-hw-cli version from: \(output)")
        }
        
        return String(output[versionRange])
    }
    
    /// Start hardware wallet interaction process
    public func startHardwareWallet(onlyForType: HardwareWalletType? = nil) async throws -> HardwareWalletType {
        logger.info("Preparing hardware wallet...")
        
        // In a real implementation, this would prompt the user
        logger.info("Please connect & unlock your Hardware Wallet, open the Cardano App on Ledger devices")
        logger.info("Press any key to continue (abort with CTRL+C)")
        
        var deviceLocked = true
        var deviceInfo = ""
        var attempts = 0
        let maxAttempts = 10
        
        while deviceLocked && attempts < maxAttempts {
            do {
                deviceInfo = try await device.version()
                if deviceInfo.contains("app version") || deviceInfo.contains("undefined") {
                    deviceLocked = false
                }
            } catch {
                logger.warning("Device check failed: \(error). Retrying in 10 seconds...")
                attempts += 1
                try await Task.sleep(for: .seconds(10))
            }
        }
        
        guard !deviceLocked else {
            throw SwiftCardanoUtilsError.deviceError("Hardware wallet could not be accessed after \(maxAttempts) attempts")
        }
        
        // Determine device type
        let deviceType: HardwareWalletType
        if deviceInfo.contains("Ledger") {
            deviceType = .ledger
            try await validateLedgerVersion(from: deviceInfo)
        } else if deviceInfo.contains("Trezor") {
            deviceType = .trezor
            try await validateTrezorVersion(from: deviceInfo)
        } else {
            throw SwiftCardanoUtilsError.deviceError("Only Ledger and Trezor Hardware Wallets are supported")
        }
        
        // Check device type compatibility
        if let requiredType = onlyForType, deviceType != requiredType {
            throw SwiftCardanoUtilsError.deviceError("This function is NOT available on \(deviceType.displayName), only available on \(requiredType.displayName)")
        }
        
        logger.info("Hardware wallet (\(deviceType.displayName)) ready. Please approve actions on your device.")
        
        return deviceType
    }
    
    /// Validate Ledger device version
    private func validateLedgerVersion(from deviceInfo: String) async throws {
        // Extract version from device info
        let components = deviceInfo.split(separator: " ")
        guard let versionString = components.last else {
            throw SwiftCardanoUtilsError.deviceError("Could not extract Ledger app version from device info")
        }
        
        logger
            .info(
                "Ledger Cardano app version: \(versionString), minimum required: \(Self.minLedgerCardanoApp)"
            )
    }
    
    /// Validate Trezor device version
    private func validateTrezorVersion(from deviceInfo: String) async throws {
        // Extract version from device info
        let components = deviceInfo.split(separator: " ")
        guard let versionString = components.last else {
            throw SwiftCardanoUtilsError.deviceError("Could not extract Trezor firmware version from device info")
        }
        
        logger
            .info(
                "Trezor firmware version: \(versionString), minimum required: \(Self.minTrezorCardanoApp)"
            )
    }
    
    /// Autocorrect transaction body file for hardware wallet compatibility
    public func autocorrectTxBodyFile(txBodyFile: String) async throws {
        let outputFile = txBodyFile + "-corrected"
        
        // Transform transaction to canonical order for hardware wallets
        let args = [
            "transaction", "transform",
            "--tx-file", txBodyFile,
            "--out-file", outputFile
        ]
        
        _ = try await runCommand(args)
        
        // Replace original file with corrected version
        try FileManager.default.removeItem(atPath: txBodyFile)
        try FileManager.default.moveItem(atPath: outputFile, toPath: txBodyFile)
        
        logger.info("Transaction body file autocorrected for hardware wallet compatibility")
    }
}

// MARK: - Address Commands

/// Address command namespace for CardanoHWCLI
extension CardanoHWCLI {
    // MARK: - Command Accessors
    
    /// Access to address commands
    public var address: AddressCommandImpl {
        return AddressCommandImpl(baseCLI: self)
    }
    
    /// Access to address commands
    public var device: DeviceCommandImpl {
        return DeviceCommandImpl(baseCLI: self)
    }
    
    /// Access to key commands
    public var key: KeyCommandImpl {
        return KeyCommandImpl(baseCLI: self)
    }
    
    /// Access to transaction commands
    public var transaction: TransactionCommandImpl {
        return TransactionCommandImpl(baseCLI: self)
    }
    
    /// Access to node commands
    public var node: NodeCommandImpl {
        return NodeCommandImpl(baseCLI: self)
    }
    
    /// Access to vote commands
    public var vote: VoteCommandImpl {
        return VoteCommandImpl(baseCLI: self)
    }
}
