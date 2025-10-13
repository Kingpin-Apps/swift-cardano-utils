import Foundation
import SystemPackage

extension CardanoSigner {
    
    /// Implementation of verify commands
    public struct VerifyCommandImpl: CommandProtocol {
        var baseCLI: any BinaryInterfaceable
        
        var baseCommand: [String] {
            ["verify"]
        }
        
        init(baseCLI: any BinaryInterfaceable) {
            self.baseCLI = baseCLI
        }
        
        /// Verify a hex string, text, or file via signature + public key (basic verification mode)
        /// - Parameters:
        ///  - mode: Verification mode (CIP-8, CIP-30, CIP-88, CIP-100)
        ///  - coseSign1: COSE_Sign1 signature in cbor-hex-format (for CIP-8/CIP-30)
        ///  - coseKey: COSE_Key containing the public-key in cbor-hex-format (for CIP-8/CIP-30)
        ///  - dataHex: Optional data in hex format if not present in COSE_Sign1 (for CIP-8/CIP-30)
        ///  - data: Optional data as text if not present in COSE_Sign1 (for CIP-8/CIP-30)
        ///  - dataFile: Optional data file if not present in COSE_Sign1 (for CIP-8/CIP-30)
        ///  - address: Optional signing address for verification (for CIP-8/CIP-30)
        ///  - noHashCheck: Don't check that public-key belongs to address/hash (for CIP-8/CIP-30)
        ///  - includeMaps: Include COSE maps in JSON-extended output (for CIP-8/CIP-30/CIP-88)
        ///  - disableSafeMode: Disable safe-mode for JSON-LD canonization (for CIP-100)
        ///  - outputFormat: Output format (json, json-extended)
        ///  - outFile: Path to output file
        ///  - Returns: true/false verification result
        ///  - Throws: SwiftCardanoUtilsError
        ///  - Note: For CIP-8 and CIP-30, either dataHex, data, or dataFile can be provided if the data is not embedded in the COSE_Sign1 structure. For CIP-88, exactly one of dataHex, data, or dataFile must be provided. For CIP-100, either data or dataFile must be provided.
        public func callAsFunction(
            mode: CipSignMode,
            coseSign1: String,
            coseKey: String,
            dataHex: String? = nil,
            data: String? = nil,
            dataFile: FilePath? = nil,
            address: String? = nil,
            noHashCheck: Bool = false,
            includeMaps: Bool = false,
            disableSafeMode: Bool = false,
            outputFormat: SignOutputFormat = .hex,
            outFile: FilePath? = nil
        ) async throws -> Bool {
            switch mode {
                case .cip8:
                    return try await cip8(
                        coseSign1: coseSign1,
                        coseKey: coseKey,
                        dataHex: dataHex,
                        dataText: data,
                        dataFile: dataFile,
                        address: address,
                        noHashCheck: noHashCheck,
                        includeMaps: includeMaps,
                        outputFormat: outputFormat,
                        outFile: outFile
                    )
                case .cip30:
                    return try await cip30(
                        coseSign1: coseSign1,
                        coseKey: coseKey,
                        dataHex: dataHex,
                        dataText: data,
                        dataFile: dataFile,
                        address: address,
                        noHashCheck: noHashCheck,
                        includeMaps: includeMaps,
                        outputFormat: outputFormat,
                        outFile: outFile
                    )
                case .cip88:
                    return try await cip88(
                        data: data,
                        dataFile: dataFile,
                        dataHex: dataHex,
                        includeMaps: includeMaps,
                        outputFormat: outputFormat,
                        outFile: outFile
                    )
                case .cip100:
                    return try await cip100(
                        data: data,
                        dataFile: dataFile,
                        disableSafeMode: disableSafeMode,
                        outputFormat: outputFormat,
                        outFile: outFile
                    )
                default:
                    throw SwiftCardanoUtilsError.invalidParameters("Unsupported verify mode \(mode.rawValue)")
            }
        }
        
        /// Verify CIP-8 payload (COSE_Sign1)
        /// - Parameters:
        ///   - coseSign1: COSE_Sign1 signature in cbor-hex-format
        ///   - coseKey: COSE_Key containing the public-key in cbor-hex-format
        ///   - dataHex: Optional data in hex format if not present in COSE_Sign1
        ///   - dataText: Optional data as text if not present in COSE_Sign1
        ///   - dataFile: Optional data file if not present in COSE_Sign1
        ///   - address: Optional signing address for verification
        ///   - noHashCheck: Don't check that public-key belongs to address/hash
        ///   - includeMaps: Include COSE maps in JSON-extended output
        ///   - outputFormat: Output format (json, json-extended)
        ///   - outFile: Path to output file
        /// - Returns: true/false verification result
        public func cip8(
            coseSign1: String,
            coseKey: String,
            dataHex: String? = nil,
            dataText: String? = nil,
            dataFile: FilePath? = nil,
            address: String? = nil,
            noHashCheck: Bool = false,
            includeMaps: Bool = false,
            outputFormat: SignOutputFormat = .hex,
            outFile: FilePath? = nil
        ) async throws -> Bool {
            return try await cipVerify(
                mode: .cip8,
                coseSign1: coseSign1,
                coseKey: coseKey,
                dataHex: dataHex,
                dataText: dataText,
                dataFile: dataFile,
                address: address,
                noHashCheck: noHashCheck,
                includeMaps: includeMaps,
                outputFormat: outputFormat,
                outFile: outFile
            )
        }
        
        /// Verify CIP-30 payload (COSE_Sign1)
        public func cip30(
            coseSign1: String,
            coseKey: String,
            dataHex: String? = nil,
            dataText: String? = nil,
            dataFile: FilePath? = nil,
            address: String? = nil,
            noHashCheck: Bool = false,
            includeMaps: Bool = false,
            outputFormat: SignOutputFormat = .hex,
            outFile: FilePath? = nil
        ) async throws -> Bool {
            return try await cipVerify(
                mode: .cip30,
                coseSign1: coseSign1,
                coseKey: coseKey,
                dataHex: dataHex,
                dataText: dataText,
                dataFile: dataFile,
                address: address,
                noHashCheck: noHashCheck,
                includeMaps: includeMaps,
                outputFormat: outputFormat,
                outFile: outFile
            )
        }
        
        /// Verify CIP-88v2 Calidus-Pool-PublicKey registration data
        /// - Parameters:
        ///   - data: JSON metadata as text (mutually exclusive with other data inputs)
        ///   - dataFile: Path to file containing JSON data (mutually exclusive with other data inputs)
        ///   - dataHex: Data in cbor-hex-format (mutually exclusive with other data inputs)
        ///   - includeMaps: Include COSE maps in JSON-extended output
        ///   - outputFormat: Output format (json, json-extended)
        ///   - outFile: Path to output file
        /// - Returns: true/false verification result
        public func cip88(
            data: String? = nil,
            dataFile: FilePath? = nil,
            dataHex: String? = nil,
            includeMaps: Bool = false,
            outputFormat: SignOutputFormat = .hex,
            outFile: FilePath? = nil
        ) async throws -> Bool {
            // Validate that exactly one data input is provided
            let hasData = data != nil
            let hasDataFile = dataFile != nil
            let hasDataHex = dataHex != nil
            let dataInputCount = [hasData, hasDataFile, hasDataHex].filter { $0 }.count
            
            guard dataInputCount == 1 else {
                throw SwiftCardanoUtilsError.invalidParameters("Exactly one of data, dataFile, or dataHex must be specified")
            }
            
            var args = ["--cip88"]
            
            // Add data parameter
            if let jsonData = data {
                args.append(contentsOf: ["--data", jsonData])
            } else if let file = dataFile {
                args.append(contentsOf: ["--data-file", file.string])
            } else if let hex = dataHex {
                args.append(contentsOf: ["--data-hex", hex])
            }
            
            // Add optional flags
            if includeMaps {
                args.append("--include-maps")
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
            
            // Add output file if specified
            if let file = outFile {
                args.append(contentsOf: ["--out-file", file.string])
            }
            
            do {
                let output = try await executeCommand("verify", arguments: args)
                return output.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "true"
            } catch {
                return false
            }
        }
        
        /// Verify signatures in CIP-100/108/119/136 governance JSON-LD metadata
        /// - Parameters:
        ///   - data: JSON-LD data as text (mutually exclusive with dataFile)
        ///   - dataFile: Path to JSON-LD file (mutually exclusive with data)
        ///   - disableSafeMode: Disable safe-mode for JSON-LD canonization
        ///   - outputFormat: Output format (json, json-extended)
        ///   - outFile: Path to output file
        /// - Returns: true/false verification result
        public func cip100(
            data: String? = nil,
            dataFile: FilePath? = nil,
            disableSafeMode: Bool = false,
            outputFormat: SignOutputFormat = .hex,
            outFile: FilePath? = nil
        ) async throws -> Bool {
            // Validate that exactly one data input is provided
            let hasData = data != nil
            let hasDataFile = dataFile != nil
            
            guard hasData != hasDataFile else {
                throw SwiftCardanoUtilsError.invalidParameters("Either data OR dataFile must be specified, but not both")
            }
            
            var args = ["--cip100"]
            
            // Add data parameter
            if let jsonldData = data {
                args.append(contentsOf: ["--data", jsonldData])
            } else if let file = dataFile {
                args.append(contentsOf: ["--data-file", file.string])
            }
            
            // Add optional flags
            if disableSafeMode {
                args.append("--disable-safemode")
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
            
            // Add output file if specified
            if let file = outFile {
                args.append(contentsOf: ["--out-file", file.string])
            }
            
            do {
                let output = try await executeCommand("verify", arguments: args)
                return output.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "true"
            } catch {
                return false
            }
        }
        
        // MARK: - Helper Methods
        
        /// Helper method for CIP-8/CIP-30 verification with common parameters
        private func cipVerify(
            mode: CipSignMode,
            coseSign1: String,
            coseKey: String,
            dataHex: String? = nil,
            dataText: String? = nil,
            dataFile: FilePath? = nil,
            address: String? = nil,
            noHashCheck: Bool = false,
            includeMaps: Bool = false,
            outputFormat: SignOutputFormat = .hex,
            outFile: FilePath? = nil
        ) async throws -> Bool {
            var args = [mode.rawValue]
            
            // Add COSE parameters
            args.append(contentsOf: ["--cose-sign1", coseSign1])
            args.append(contentsOf: ["--cose-key", coseKey])
            
            // Add optional data parameter (all are optional for CIP verify)
            if let hex = dataHex {
                args.append(contentsOf: ["--data-hex", hex])
            } else if let text = dataText {
                args.append(contentsOf: ["--data", text])
            } else if let file = dataFile {
                args.append(contentsOf: ["--data-file", file.string])
            }
            
            // Add optional address
            if let addr = address {
                args.append(contentsOf: ["--address", addr])
            }
            
            // Add optional flags
            if noHashCheck {
                args.append("--nohashcheck")
            }
            
            if includeMaps {
                args.append("--include-maps")
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
            
            // Add output file if specified
            if let file = outFile {
                args.append(contentsOf: ["--out-file", file.string])
            }
            
            do {
                let output = try await executeCommand("verify", arguments: args)
                return output.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "true"
            } catch {
                return false
            }
        }
    }
}
