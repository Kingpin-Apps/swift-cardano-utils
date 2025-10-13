import Foundation
import SystemPackage

// MARK: - Cardano HW CLI Vote Command Implementation

extension CardanoHWCLI {
    
    /// Implementation of vote utility commands
    public struct VoteCommandImpl: CommandProtocol {
        var baseCLI: any BinaryInterfaceable
        
        var baseCommand: [String] {
            ["vote"]
        }
        
        init(baseCLI: any BinaryInterfaceable) {
            self.baseCLI = baseCLI
        }
        
        /// Generate voting registration metadata
        /// - Parameters:
        ///   - votePublicKeys: Array of vote public key inputs (can be files, strings, etc.)
        ///   - voteWeights: Array of vote weights corresponding to each public key
        ///   - stakeSigningKeyHwsFile: Hardware wallet stake signing file path
        ///   - paymentAddress: Address to receive voting rewards
        ///   - nonce: Current slot number
        ///   - metadataCborOutFile: Output file path for metadata CBOR
        ///   - network: Network type (mainnet or testnet)
        ///   - votingPurpose: Optional voting purpose
        ///   - paymentAddressSigningKeyHwsFile: Optional payment address hardware wallet signing file
        ///   - derivationType: Optional derivation type (defaults to ICARUS_TREZOR)
        /// - Returns: Output from the command execution
        /// - Throws: SwiftCardanoUtilsError if validation fails or command execution fails
        @discardableResult
        public func registrationMetadata(
            votePublicKeys: [VotePublicKeyInput],
            voteWeights: [UInt64],
            stakeSigningKeyHwsFile: FilePath,
            paymentAddress: String,
            nonce: UInt64,
            metadataCborOutFile: FilePath,
            network: Network = .mainnet,
            votingPurpose: String? = nil,
            paymentAddressSigningKeyHwsFile: FilePath? = nil,
            derivationType: DerivationType? = nil
        ) async throws -> String {
            // Validate that vote public keys and weights arrays have the same length
            guard votePublicKeys.count == voteWeights.count else {
                throw SwiftCardanoUtilsError.invalidParameters("Number of vote public keys (\(votePublicKeys.count)) must match number of vote weights (\(voteWeights.count))")
            }
            
            guard !votePublicKeys.isEmpty else {
                throw SwiftCardanoUtilsError.invalidParameters("At least one vote public key must be provided")
            }
            
            var args: [String] = []
            
            // Add network parameters
            args.append(contentsOf: network.arguments)
            
            // Add vote public keys and weights
            for (index, votePublicKey) in votePublicKeys.enumerated() {
                switch votePublicKey {
                    case .jcli(let filePath):
                        args.append(contentsOf: ["--vote-public-key-jcli", filePath.string])
                    case .string(let publicKeyString):
                        args.append(contentsOf: ["--vote-public-key-string", publicKeyString])
                    case .hwsFile(let filePath):
                        args.append(contentsOf: ["--vote-public-key-hwsfile", filePath.string])
                    case .file(let filePath):
                        args.append(contentsOf: ["--vote-public-key-file", filePath.string])
                }
                
                // Add corresponding vote weight
                args.append(contentsOf: ["--vote-weight", String(voteWeights[index])])
            }
            
            // Add required parameters
            args.append(contentsOf: ["--stake-signing-key-hwsfile", stakeSigningKeyHwsFile.string])
            args.append(contentsOf: ["--payment-address", paymentAddress])
            args.append(contentsOf: ["--nonce", String(nonce)])
            args.append(contentsOf: ["--metadata-cbor-out-file", metadataCborOutFile.string])
            
            // Add optional parameters
            if let votingPurpose = votingPurpose {
                args.append(contentsOf: ["--voting-purpose", votingPurpose])
            }
            
            if let paymentAddressSigningKeyHwsFile = paymentAddressSigningKeyHwsFile {
                args.append(contentsOf: ["--payment-address-signing-key-hwsfile", paymentAddressSigningKeyHwsFile.string])
            }
            
            if let derivationType = derivationType {
                args.append(contentsOf: ["--derivation-type", derivationType.rawValue])
            }
            
            return try await executeCommand("registration-metadata", arguments: args)
        }
    }
}
