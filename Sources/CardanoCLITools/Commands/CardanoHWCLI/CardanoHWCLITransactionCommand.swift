import Foundation
import SystemPackage

// MARK: - Cardano HW CLI Transaction Command Implementation

extension CardanoHWCLI {
    
    /// Implementation of transaction utility commands
    public struct TransactionCommandImpl: CommandProtocol {
        var baseCLI: any BinaryInterfaceable
        
        var baseCommand: [String] {
            ["transaction"]
        }
        
        init(baseCLI: any BinaryInterfaceable) {
            self.baseCLI = baseCLI
        }
        
        /// Generate policy ID from a native script with hardware wallet
        /// - Parameters:
        ///   - scriptFile: File path to the native script
        ///   - hwSigningFile: Optional hardware wallet signing file
        ///   - derivationType: Optional derivation type
        /// - Returns: The generated policy ID as a String
        /// - Throws: CardanoCLIToolsError if command execution fails
        public func policyId(
            scriptFile: FilePath,
            hwSigningFile: FilePath? = nil,
            derivationType: DerivationType? = nil
        ) async throws -> String {
            var args: [String] = []
            
            // Add required script file
            args.append(contentsOf: ["--script-file", scriptFile.string])
            
            // Add optional hardware signing file
            if let hwSigningFile = hwSigningFile {
                args.append(contentsOf: ["--hw-signing-file", hwSigningFile.string])
            }
            
            // Add optional derivation type
            if let derivationType = derivationType {
                args.append(contentsOf: ["--derivation-type", derivationType.rawValue])
            }
            
            return try await executeCommand("policyid", arguments: args)
        }
        
        /// Transform a transaction file to canonical format for hardware wallets
        /// - Parameters:
        ///   - txFile: File path to the input transaction file
        ///   - outFile: File path for the transformed output file
        /// - Returns: Command output as a String
        /// - Throws: CardanoCLIToolsError if command execution fails
        public func transform(
            txFile: FilePath,
            outFile: FilePath
        ) async throws -> String {
            let args = [
                "--tx-file", txFile.string,
                "--out-file", outFile.string
            ]
            return try await executeCommand("transform", arguments: args)
        }
        
        /// Validate a transaction file
        /// - Parameters:
        ///   - txFile: File path to the transaction file to validate
        /// - Returns: Validation result as a String
        /// - Throws: CardanoCLIToolsError if command execution fails
        public func validate(
            txFile: FilePath
        ) async throws -> String {
            let args = ["--tx-file", txFile.string]
            return try await executeCommand("validate", arguments: args)
        }
        
        /// Generate witness for a transaction using hardware wallet
        /// - Parameters:
        ///   - txFile: File path to the transaction body file
        ///   - hwSigningFile: Hardware wallet signing file
        ///   - outFile: Output file path for the witness
        ///   - changeOutputKeyFile: Optional change output key file
        ///   - derivationType: Optional derivation type
        ///   - network: Network specification (mainnet/testnet)
        /// - Returns: Command output as a String
        /// - Throws: CardanoCLIToolsError if command execution fails
        public func witness(
            txFile: FilePath,
            hwSigningFile: FilePath,
            outFile: FilePath,
            changeOutputKeyFile: FilePath? = nil,
            derivationType: DerivationType? = nil,
            network: Network? = nil
        ) async throws -> String {
            var args: [String] = []
            
            // Add network arguments if specified, otherwise use default from config
            if let network = network {
                args.append(contentsOf: network.arguments)
            } else {
                args.append(contentsOf: networkArgs)
            }
            
            // Add required arguments
            args.append(contentsOf: ["--tx-file", txFile.string])
            args.append(contentsOf: ["--hw-signing-file", hwSigningFile.string])
            args.append(contentsOf: ["--out-file", outFile.string])
            
            // Add optional change output key file
            if let changeOutputKeyFile = changeOutputKeyFile {
                args.append(contentsOf: ["--change-output-key-file", changeOutputKeyFile.string])
            }
            
            // Add optional derivation type
            if let derivationType = derivationType {
                args.append(contentsOf: ["--derivation-type", derivationType.rawValue])
            }
            
            return try await executeCommand("witness", arguments: args)
        }
    }
}
