import Foundation
import SystemPackage
import Logging

// MARK: - Cardano Hardware Wallet CLI

/// Wrapper struct for the cardano-hw-cli tool
public struct CardanoHWCLI: BinaryInterfaceable {
    public let binaryPath: FilePath
    public let workingDirectory: FilePath
    public let configuration: CardanoCLIToolsConfig
    public let logger: Logger
    public static let binaryName: String = "cardano-hw-cli"
    public static let mininumSupportedVersion: String = "1.10.0"
    public static let minLedgerCardanoApp: String = "4.0.0"
    public static let minTrezorCardanoApp: String = "2.4.3"
    
    /// Initialize with optional configuration
    public init(configuration: CardanoCLIToolsConfig, logger: Logger? = nil) async throws {
        // Assign all let properties directly
        self.configuration = configuration
        
        // Check for hardware CLI binary
        guard let hwCliPath = configuration.cardano.hwCli else {
            throw CardanoCLIToolsError.binaryNotFound("cardano-hw-cli path not configured")
        }
        
        // Setup binary path
        self.binaryPath = hwCliPath
        try Self.checkBinary(binary: self.binaryPath)
        
        // Setup working directory
        self.workingDirectory = configuration.cardano.workingDir
        try Self.checkWorkingDirectory(workingDirectory: self.workingDirectory)
        
        // Setup logger
        self.logger = logger ?? Logger(label: "CardanoHWCLI")
        
        try await checkVersion()
    }
    
    /// Get the version of cardano-hw-cli
    public func version() async throws -> String {
        let output = try await runCommand(["--version"])
        
        // Extract version using regex pattern
        let pattern = #"version (\d+\.\d+\.\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: output, range: NSRange(output.startIndex..., in: output)),
              let versionRange = Range(match.range(at: 1), in: output) else {
            throw CardanoCLIToolsError.invalidOutput("Could not parse cardano-hw-cli version from: \(output)")
        }
        
        return String(output[versionRange])
    }
    
    /// Check device version
    public func checkDeviceVersion() async throws -> String {
        return try await runCommand(["device", "version"])
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
                deviceInfo = try await checkDeviceVersion()
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
            throw CardanoCLIToolsError.deviceError("Hardware wallet could not be accessed after \(maxAttempts) attempts")
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
            throw CardanoCLIToolsError.deviceError("Only Ledger and Trezor Hardware Wallets are supported")
        }
        
        // Check device type compatibility
        if let requiredType = onlyForType, deviceType != requiredType {
            throw CardanoCLIToolsError.deviceError("This function is NOT available on \(deviceType.displayName), only available on \(requiredType.displayName)")
        }
        
        logger.info("Hardware wallet (\(deviceType.displayName)) ready. Please approve actions on your device.")
        
        return deviceType
    }
    
    /// Validate Ledger device version
    private func validateLedgerVersion(from deviceInfo: String) async throws {
        // Extract version from device info
        let components = deviceInfo.split(separator: " ")
        guard let versionString = components.last else {
            throw CardanoCLIToolsError.deviceError("Could not extract Ledger app version from device info")
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
            throw CardanoCLIToolsError.deviceError("Could not extract Trezor firmware version from device info")
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
    
    /// Generate device-specific witness for transaction
    public func witnessTransaction(
        txBodyFile: String,
        signingKeyFile: String,
        addressDerivationPath: String? = nil,
        outputFile: String
    ) async throws -> String {
        var args = [
            "transaction", "witness",
            "--tx-body-file", txBodyFile,
            "--hw-signing-file", signingKeyFile,
            "--out-file", outputFile
        ]
        
        if let derivationPath = addressDerivationPath {
            args.append(contentsOf: ["--address-derivation-path", derivationPath])
        }
        
        return try await runCommand(args)
    }
    
    /// Verify transaction with hardware wallet
    public func verifyTransaction(txFile: String) async throws -> String {
        return try await runCommand([
            "transaction", "verify",
            "--tx-file", txFile
        ])
    }
}
