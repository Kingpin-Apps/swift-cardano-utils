import Foundation
import SystemPackage

// MARK: - Cardano HW CLI Address Command Implementation

extension CardanoHWCLI {
    
    /// Implementation of address utility commands
    public struct AddressCommandImpl: CommandProtocol {
        var baseCLI: any BinaryInterfaceable
        
        var baseCommand: [String] {
            ["address"]
        }
        
        init(baseCLI: any BinaryInterfaceable) {
            self.baseCLI = baseCLI
        }
        
        /// Generate hardware wallet signing files and verification keys from derivation paths
        /// - Parameters:
        ///   - paths: Array of derivation paths (e.g., ["1852'/1815'/0'/0/0"])
        ///   - hwFiles: Array of output file paths for hardware signing files
        ///   - vkeyFiles: Array of output file paths for verification key files
        ///   - derivationType: Optional derivation type (defaults to ICARUS_TREZOR)
        /// - Throws: CardanoCLIToolsError if validation fails or command execution fails
        @discardableResult
        public func keyGen(
            path: String,
            hwFile: FilePath,
            vkeyFile: FilePath,
            derivationType: DerivationType? = nil
        ) async throws -> String {
            var args: [String] = []
            
            args.append(contentsOf: ["--path", path])
            args.append(contentsOf: ["--hw-signing-file", hwFile.string])
            args.append(contentsOf: ["--verification-key-file", vkeyFile.string])
            
            // Add derivation type if specified
            if let derivationType = derivationType {
                args.append(contentsOf: ["--derivation-type", derivationType.rawValue])
            }
            
            return try await executeCommand("key-gen", arguments: args)
        }
        
        /// Show/display address from hardware wallet using derivation paths or script hashes
        /// - Parameters:
        ///   - paymentPath: Payment derivation path (mutually exclusive with paymentScriptHash)
        ///   - paymentScriptHash: Payment script hash in hex format (mutually exclusive with paymentPath)
        ///   - stakingPath: Staking derivation path (mutually exclusive with stakingScriptHash)
        ///   - stakingScriptHash: Staking script hash in hex format (mutually exclusive with stakingPath)
        ///   - addressFile: Output file path for the address
        ///   - derivationType: Optional derivation type (defaults to ICARUS_TREZOR)
        /// - Returns: The generated address as a String
        /// - Throws: CardanoCLIToolsError if validation fails or command execution fails
        public func show(
            paymentPath: String? = nil,
            paymentScriptHash: String? = nil,
            stakingPath: String? = nil,
            stakingScriptHash: String? = nil,
            addressFile: FilePath,
            derivationType: DerivationType? = nil
        ) async throws -> String {
            // Validate payment parameters (exactly one must be provided)
            let hasPaymentPath = paymentPath != nil
            let hasPaymentScriptHash = paymentScriptHash != nil
            guard hasPaymentPath != hasPaymentScriptHash else {
                throw CardanoCLIToolsError.invalidParameters("Either paymentPath OR paymentScriptHash must be specified, but not both")
            }
            
            // Validate staking parameters (exactly one must be provided)
            let hasStakingPath = stakingPath != nil
            let hasStakingScriptHash = stakingScriptHash != nil
            guard hasStakingPath != hasStakingScriptHash else {
                throw CardanoCLIToolsError.invalidParameters("Either stakingPath OR stakingScriptHash must be specified, but not both")
            }
            
            // Build CLI arguments
            var args: [String] = []
            
            // Add payment parameters
            if let paymentPath = paymentPath {
                args.append(contentsOf: ["--payment-path", paymentPath])
            } else if let paymentScriptHash = paymentScriptHash {
                args.append(contentsOf: ["--payment-script-hash", paymentScriptHash])
            }
            
            // Add staking parameters
            if let stakingPath = stakingPath {
                args.append(contentsOf: ["--staking-path", stakingPath])
            } else if let stakingScriptHash = stakingScriptHash {
                args.append(contentsOf: ["--staking-script-hash", stakingScriptHash])
            }
            
            // Add address file
            args.append(contentsOf: ["--address-file", addressFile.string])
            
            // Add derivation type if specified
            if let derivationType = derivationType {
                args.append(contentsOf: ["--derivation-type", derivationType.rawValue])
            }
            
            return try await executeCommand("key-gen", arguments: args)
        }
    }
    
}
