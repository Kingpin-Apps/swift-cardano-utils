import Foundation
import SystemPackage

extension CardanoSigner {
    
    /// Implementation of keygen commands
    public struct KeyGenCommandImpl: CommandProtocol {
        var baseCLI: any BinaryInterfaceable
        
        var baseCommand: [String] {
            ["keygen"]
        }
        
        init(baseCLI: any BinaryInterfaceable) {
            self.baseCLI = baseCLI
        }
        
        /// Generate Cardano ed25519/ed25519-extended keys with comprehensive parameter support
        /// - Parameters:
        ///   - path: Derivation path string or predefined path type
        ///   - mnemonics: Mnemonic words or file path containing mnemonics  
        ///   - passphrase: Optional passphrase for hardware wallet derivation
        ///   - derivationMethod: Derivation method (ledger, trezor, byron, yoroi, exodus, etc.)
        ///   - address: Optional Byron address for auto-derivation-path discovery in Byron mode
        ///   - cip36: Generate CIP36 conform vote keys
        ///   - votePurpose: Vote purpose when using CIP36
        ///   - vkeyExtended: Generate 64byte publicKey with chain code
        ///   - withChainCode: Generate 96byte privateKey with chain code
        ///   - outputFormat: Output format (hex, json, json-extended)
        ///   - outFile: Path to general output file
        ///   - outSkey: Path to output skey file
        ///   - outVkey: Path to output vkey file
        ///   - outId: Path to output id file (for pool, drep, calidus IDs)
        ///   - outMnemonics: Path to output mnemonics file
        ///   - outAddr: Path to output address file
        /// - Returns: Generated key output
        public func callAsFunction(
            path: String? = nil,
            mnemonics: MnemonicInput? = nil,
            passphrase: String? = nil,
            derivationMethod: CardanoSignerDerivationMethod? = nil,
            address: String? = nil,
            cip36: Bool = false,
            votePurpose: UInt? = nil,
            vkeyExtended: Bool = false,
            withChainCode: Bool = false,
            outputFormat: SignOutputFormat = .hex,
            outFile: FilePath? = nil,
            outSkey: FilePath? = nil,
            outVkey: FilePath? = nil,
            outId: FilePath? = nil,
            outMnemonics: FilePath? = nil,
            outAddr: FilePath? = nil
        ) async throws -> String {
            var args: [String] = []
            
            // Add optional derivation path
            if let keyPath = path {
                args.append(contentsOf: ["--path", keyPath])
            }
            
            // Add optional mnemonics
            if let mnemonicInput = mnemonics {
                switch mnemonicInput {
                    case .words(let words):
                        args.append(contentsOf: ["--mnemonics", words])
                    case .file(let filePath):
                        args.append(contentsOf: ["--mnemonics", filePath.string])
                }
            }
            
            // Add optional passphrase
            if let phrase = passphrase {
                args.append(contentsOf: ["--passphrase", phrase])
            }
            
            // Add derivation method flags
            if let method = derivationMethod {
                switch method {
                    case .ledger:
                        args.append("--ledger")
                    case .trezor:
                        args.append("--trezor")
                    case .byron:
                        args.append("--byron")
                    case .yoroi:
                        args.append("--yoroi")
                    case .exodus:
                        args.append("--exodus")
                    case .exodusStake:
                        args.append("--exodus-stake")
                }
            }
            
            // Add optional Byron address for auto-discovery
            if let byronAddr = address {
                args.append(contentsOf: ["--address", byronAddr])
            }
            
            // Add CIP-36 flag
            if cip36 {
                args.append("--cip36")
                
                // Add vote purpose if specified
                if let purpose = votePurpose {
                    args.append(contentsOf: ["--vote-purpose", String(purpose)])
                }
            }
            
            // Add extended vkey flag
            if vkeyExtended {
                args.append("--vkey-extended")
            }
            
            // Add with chain code flag
            if withChainCode {
                args.append("--with-chain-code")
            }
            
            // Add output format
            switch outputFormat {
                case .json:
                    args.append("--json")
                case .jsonExtended:
                    args.append("--json-extended")
                case .hex, .jcli, .bech:
                    break // Default format
            }
            
            // Add output files if specified
            if let file = outFile {
                args.append(contentsOf: ["--out-file", file.string])
            }
            
            if let skey = outSkey {
                args.append(contentsOf: ["--out-skey", skey.string])
            }
            
            if let vkey = outVkey {
                args.append(contentsOf: ["--out-vkey", vkey.string])
            }
            
            if let id = outId {
                args.append(contentsOf: ["--out-id", id.string])
            }
            
            if let mnemonicsFile = outMnemonics {
                args.append(contentsOf: ["--out-mnemonics", mnemonicsFile.string])
            }
            
            if let addr = outAddr {
                args.append(contentsOf: ["--out-addr", addr.string])
            }
            
            return try await executeCommand("keygen", arguments: args)
        }
        
    
    }
}
