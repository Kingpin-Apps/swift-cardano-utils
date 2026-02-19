import Foundation
import SystemPackage

extension CardanoSigner {
    
    /// Implementation of sign commands
    public struct SignCommandImpl: CommandProtocol {
        var baseCLI: any BinaryInterfaceable
        
        var baseCommand: [String] {
            ["sign"]
        }
        
        init(baseCLI: any BinaryInterfaceable) {
            self.baseCLI = baseCLI
        }
        
        /// Sign a hex string, text, or file (basic signing mode)
        /// - Parameters:
        ///  - mode: CIP mode (.cip8, .cip30, .cip36, .cip88, .cip100)
        ///  - calidusPublicKey: Public key file or hex/bech key string for new calidus-key (CIP-88)
        ///  - dataHex: Data in hexadecimal format (mutually exclusive with other data inputs)
        ///  - dataText: Data as text string (mutually exclusive with other data inputs)
        ///  - dataFile: Path to file containing data (mutually exclusive with other data inputs)
        ///  - votePublicKeys: Array of vote public keys (CIP-36)
        ///  - voteWeights: Array of vote weights corresponding to votePublicKeys (CIP-36)
        ///  - secretKey: Path to signing key file or direct hex/bech key string
        ///  - authorName: Name of the signing author (e.g., "John Doe") (CIP-100)
        ///  - address: Address for verification (required for CIP-8/CIP-30, optional for CIP-100)
        ///  - paymentAddress: Payment address for catalyst registration (CIP-36)
        ///  - nonce: Optional nonce value (CIP-36, CIP-88)
        ///  - votePurpose: Vote purpose (default 0) (CIP-36)
        ///  - deregister: Create deregistration certificate instead of registration (CIP-36)
        ///  - noHashCheck: Don't perform check that public-key belongs to address/hash (CIP-8/CIP-30)
        ///  - hashed: Hash the payload given via the data parameters (CIP-8/CIP-30)
        ///  - noPayload: Exclude payload from COSE_Sign1 signature (CIP-8/CIP-30)
        ///  - testnetMagic: Testnet magic number for address check (CIP-8/CIP-30, CIP-36)
        ///  - includeMaps: Include COSE maps in JSON-extended output (CIP-8/CIP-30)
        ///  - includeSecret: Include secret/signing key in JSON-extended output (CIP-8/CIP-30, CIP-88)
        ///  - signatureOnly: Only output COSE_Sign1 without COSE_Key (CIP-8/CIP-30)
        ///  - replace: Replace authors entry with the same public-key (CIP-100)
        ///  - disableSafeMode: Disable safe-mode for JSON-LD canonization (CIP-100)
        ///  - outCBOR: Path to write binary metadata.cbor file (CIP-36, CIP-88)
        ///  - outputFormat: Output format (json, json-extended, or cborHex default for CIP-36/CIP-88)
        ///  - outFile: Path to output file
        public func callAsFunction(
            mode: CipSignMode,
            calidusPublicKey: String? = nil,
            dataHex: String? = nil,
            dataText: String? = nil,
            dataFile: FilePath? = nil,
            votePublicKeys: [String]? = nil,
            voteWeights: [UInt]? = nil,
            secretKey: String? = nil,
            authorName: String? = nil,
            address: String? = nil,
            paymentAddress: String? = nil,
            nonce: UInt? = nil,
            votePurpose: UInt = 0,
            deregister: Bool = false,
            noHashCheck: Bool = false,
            hashed: Bool = false,
            noPayload: Bool = false,
            testnetMagic: Int? = nil,
            includeMaps: Bool = false,
            includeSecret: Bool = false,
            signatureOnly: Bool = false,
            replace: Bool = false,
            disableSafeMode: Bool = false,
            outCBOR: String? = nil,
            outputFormat: SignOutputFormat = .hex,
            outFile: FilePath? = nil
        ) async throws -> String {
            switch mode {
                case .cip8:
                    return try await cip8(
                        dataHex: dataHex,
                        dataText: dataText,
                        dataFile: dataFile,
                        secretKey: secretKey!,
                        address: address!,
                        noHashCheck: noHashCheck,
                        hashed: hashed,
                        noPayload: noPayload,
                        testnetMagic: testnetMagic,
                        includeMaps: includeMaps,
                        includeSecret: includeSecret,
                        signatureOnly: signatureOnly,
                        outputFormat: outputFormat,
                        outFile: outFile
                    )
                case .cip30:
                    return try await cip30(
                        dataHex: dataHex,
                        dataText: dataText,
                        dataFile: dataFile,
                        secretKey: secretKey!,
                        address: address!,
                        noHashCheck: noHashCheck,
                        hashed: hashed,
                        noPayload: noPayload,
                        testnetMagic: testnetMagic,
                        includeMaps: includeMaps,
                        includeSecret: includeSecret,
                        signatureOnly: signatureOnly,
                        outputFormat: outputFormat,
                        outFile: outFile
                    )
                case .cip36:
                    return try await cip36(
                        votePublicKeys: votePublicKeys,
                        voteWeights: voteWeights,
                        secretKey: secretKey!,
                        paymentAddress: paymentAddress,
                        nonce: nonce,
                        votePurpose: votePurpose,
                        deregister: deregister,
                        testnetMagic: testnetMagic,
                        outputFormat: outputFormat,
                        outFile: outFile?.string,
                        outCbor: outCBOR
                    )
                case .cip88:
                    return try await cip88(
                        calidusPublicKey: calidusPublicKey!,
                        secretKey: secretKey!,
                        nonce: nonce,
                        includeSecret: includeSecret,
                        outputFormat: outputFormat,
                        outFile: outFile,
                        outCbor: outFile
                    )
                case .cip100:
                    return try await cip100(
                        data: dataText,
                        dataFile: dataFile,
                        secretKey: secretKey!,
                        authorName: authorName!,
                        address: address,
                        replace: replace,
                        disableSafeMode: disableSafeMode,
                        outFile: outFile
                    )
            }
        }
        
        /// Sign payload in CIP-8/CIP-30 mode (COSE_Sign1)
        /// - Parameters:
        ///   - dataHex: Data in hexadecimal format (mutually exclusive with other data inputs)
        ///   - dataText: Data as text string (mutually exclusive with other data inputs)
        ///   - dataFile: Path to file containing data (mutually exclusive with other data inputs)
        ///   - secretKey: Path to signing key file or direct hex/bech key string
        ///   - address: Address for verification (required for CIP-8/CIP-30)
        ///   - noHashCheck: Don't perform check that public-key belongs to address/hash
        ///   - hashed: Hash the payload given via the data parameters
        ///   - noPayload: Exclude payload from COSE_Sign1 signature
        ///   - testnetMagic: Testnet magic number for address check
        ///   - includeMaps: Include COSE maps in JSON-extended output
        ///   - includeSecret: Include secret/signing key in JSON-extended output
        ///   - signatureOnly: Only output COSE_Sign1 without COSE_Key
        ///   - outputFormat: Output format (json, json-extended)
        ///   - outFile: Path to output file
        /// - Returns: COSE_Sign1 + COSE_Key or JSON format
        public func cip8(
            dataHex: String? = nil,
            dataText: String? = nil,
            dataFile: FilePath? = nil,
            secretKey: String,
            address: String,
            noHashCheck: Bool = false,
            hashed: Bool = false,
            noPayload: Bool = false,
            testnetMagic: Int? = nil,
            includeMaps: Bool = false,
            includeSecret: Bool = false,
            signatureOnly: Bool = false,
            outputFormat: SignOutputFormat = .hex,
            outFile: FilePath? = nil
        ) async throws -> String {
            return try await cipSign(
                mode: .cip8,
                dataHex: dataHex,
                dataText: dataText,
                dataFile: dataFile,
                secretKey: secretKey,
                address: address,
                noHashCheck: noHashCheck,
                hashed: hashed,
                noPayload: noPayload,
                testnetMagic: testnetMagic,
                includeMaps: includeMaps,
                includeSecret: includeSecret,
                signatureOnly: signatureOnly,
                outputFormat: outputFormat,
                outFile: outFile
            )
        }
        
        /// Sign payload in CIP-30 mode
        public func cip30(
            dataHex: String? = nil,
            dataText: String? = nil,
            dataFile: FilePath? = nil,
            secretKey: String,
            address: String,
            noHashCheck: Bool = false,
            hashed: Bool = false,
            noPayload: Bool = false,
            testnetMagic: Int? = nil,
            includeMaps: Bool = false,
            includeSecret: Bool = false,
            signatureOnly: Bool = false,
            outputFormat: SignOutputFormat = .hex,
            outFile: FilePath? = nil
        ) async throws -> String {
            return try await cipSign(
                mode: .cip30,
                dataHex: dataHex,
                dataText: dataText,
                dataFile: dataFile,
                secretKey: secretKey,
                address: address,
                noHashCheck: noHashCheck,
                hashed: hashed,
                noPayload: noPayload,
                testnetMagic: testnetMagic,
                includeMaps: includeMaps,
                includeSecret: includeSecret,
                signatureOnly: signatureOnly,
                outputFormat: outputFormat,
                outFile: outFile
            )
        }
        
        /// Sign catalyst registration/delegation in CIP-36 mode
        public func cip36(
            votePublicKeys: [String]? = nil,
            voteWeights: [UInt]? = nil,
            secretKey: String,
            paymentAddress: String? = nil,
            nonce: UInt? = nil,
            votePurpose: UInt = 0,
            deregister: Bool = false,
            testnetMagic: Int? = nil,
            outputFormat: SignOutputFormat = .hex,
            outFile: String? = nil,
            outCbor: String? = nil
        ) async throws -> String {
            var args = ["--cip36"]
            
            // Add vote public keys and weights if not deregistering
            if !deregister {
                if let keys = votePublicKeys {
                    for key in keys {
                        args.append(contentsOf: ["--vote-public-key", key])
                    }
                }
                
                if let weights = voteWeights {
                    for weight in weights {
                        args.append(contentsOf: ["--vote-weight", String(weight)])
                    }
                }
                
                // Payment address is required for registration
                if let address = paymentAddress {
                    args.append(contentsOf: ["--payment-address", address])
                } else {
                    throw SwiftCardanoUtilsError.invalidOutput("Payment address is required for CIP-36 registration")
                }
            }
            
            // Add secret key
            args.append(contentsOf: ["--secret-key", secretKey])
            
            // Add optional nonce
            if let n = nonce {
                args.append(contentsOf: ["--nonce", String(n)])
            }
            
            // Add vote purpose
            if votePurpose != 0 {
                args.append(contentsOf: ["--vote-purpose", String(votePurpose)])
            }
            
            // Add deregister flag
            if deregister {
                args.append("--deregister")
            }
            
            // Add testnet magic if specified
            if let magic = testnetMagic {
                args.append(contentsOf: ["--testnet-magic", String(magic)])
            }
            
            // Add output format
            switch outputFormat {
                case .json:
                    args.append("--json")
                case .jsonExtended:
                    args.append("--json-extended")
                case .hex, .jcli, .bech:
                    break // Default is cborHex for CIP-36
            }
            
            // Add output files if specified
            if let file = outFile {
                args.append(contentsOf: ["--out-file", file])
            }
            
            if let cbor = outCbor {
                args.append(contentsOf: ["--out-cbor", cbor])
            }
            
            return try await executeCommand("sign", arguments: args)
        }
        
        /// Sign and generate Calidus-Pool-PublicKey registration with Pool-Cold-Key (CIP-88v2)
        /// - Parameters:
        ///   - calidusPublicKey: Public key file or hex/bech key string for new calidus-key
        ///   - secretKey: Signing key file or direct hex/bech key string of the stakepool
        ///   - nonce: Optional nonce value (uses mainnet slot height if not provided)
        ///   - includeSecret: Include secret/signing key in JSON-extended output
        ///   - outputFormat: Output format (json, json-extended, or cborHex default)
        ///   - outFile: Path to output file
        ///   - outCbor: Path to write binary metadata.cbor file
        /// - Returns: Registration-Metadata in JSON, cborHex, or cborBinary format
        public func cip88(
            calidusPublicKey: String,
            secretKey: String,
            nonce: UInt? = nil,
            includeSecret: Bool = false,
            outputFormat: SignOutputFormat = .hex,
            outFile: FilePath? = nil,
            outCbor: FilePath? = nil
        ) async throws -> String {
            var args = ["--cip88"]
            
            // Add calidus public key and secret key
            args.append(contentsOf: ["--calidus-public-key", calidusPublicKey])
            args.append(contentsOf: ["--secret-key", secretKey])
            
            // Add optional nonce
            if let n = nonce {
                args.append(contentsOf: ["--nonce", String(n)])
            }
            
            // Add optional flags
            if includeSecret {
                args.append("--include-secret")
            }
            
            // Add output format
            switch outputFormat {
            case .json:
                args.append("--json")
            case .jsonExtended:
                args.append("--json-extended")
            case .hex, .jcli, .bech:
                break // Default is cborHex for CIP-88
            }
            
            // Add output files if specified
            if let file = outFile {
                args.append(contentsOf: ["--out-file", file.string])
            }
            
            if let cbor = outCbor {
                args.append(contentsOf: ["--out-cbor", cbor.string])
            }
            
            return try await executeCommand("sign", arguments: args)
        }
        
        /// Sign governance JSON-LD metadata file with Secret-Key (CIP-100)
        /// - Parameters:
        ///   - data: JSON-LD data as text (mutually exclusive with dataFile)
        ///   - dataFile: Path to JSON-LD file (mutually exclusive with data)
        ///   - secretKey: Path to signing key file or direct hex/bech key string
        ///   - authorName: Name of the signing author (e.g., "John Doe")
        ///   - address: Optional address/ID for CIP-8 algorithm signing
        ///   - replace: Replace authors entry with the same public-key
        ///   - disableSafeMode: Disable safe-mode for JSON-LD canonization
        ///   - outFile: Path to output file
        /// - Returns: Signed JSON-LD Content or JSON-HashInfo if outFile is used
        public func cip100(
            data: String? = nil,
            dataFile: FilePath? = nil,
            secretKey: String,
            authorName: String,
            address: String? = nil,
            replace: Bool = false,
            disableSafeMode: Bool = false,
            outFile: FilePath? = nil
        ) async throws -> String {
            // Validate that exactly one data input is provided
            let hasData = data != nil
            let hasDataFile = dataFile != nil
            
            guard hasData != hasDataFile else {
                throw SwiftCardanoUtilsError.invalidParameters("Either data OR dataFile must be specified, but not both")
            }
            
            var args = ["--cip100"]
            
            // Add data parameter
            if let text = data {
                args.append(contentsOf: ["--data", text])
            } else if let file = dataFile {
                args.append(contentsOf: ["--data-file", file.string])
            }
            
            // Add required parameters
            args.append(contentsOf: ["--secret-key", secretKey])
            args.append(contentsOf: ["--author-name", authorName])
            
            // Add optional address
            if let addr = address {
                args.append(contentsOf: ["--address", addr])
            }
            
            // Add optional flags
            if replace {
                args.append("--replace")
            }
            
            if disableSafeMode {
                args.append("--disable-safemode")
            }
            
            // Add output file if specified
            if let file = outFile {
                args.append(contentsOf: ["--out-file", file.string])
            }
            
            return try await executeCommand("sign", arguments: args)
        }
        
        // MARK: - Helper Methods
        
        /// Helper method for CIP-8/CIP-30 signing with common parameters
        private func cipSign(
            mode: CipSignMode,
            dataHex: String? = nil,
            dataText: String? = nil,
            dataFile: FilePath? = nil,
            secretKey: String,
            address: String,
            noHashCheck: Bool = false,
            hashed: Bool = false,
            noPayload: Bool = false,
            testnetMagic: Int? = nil,
            includeMaps: Bool = false,
            includeSecret: Bool = false,
            signatureOnly: Bool = false,
            outputFormat: SignOutputFormat = .hex,
            outFile: FilePath? = nil
        ) async throws -> String {
            // Validate that exactly one data input is provided
            let hasDataHex = dataHex != nil
            let hasDataText = dataText != nil
            let hasDataFile = dataFile != nil
            let dataInputCount = [hasDataHex, hasDataText, hasDataFile].filter { $0 }.count
            
            guard dataInputCount == 1 else {
                throw SwiftCardanoUtilsError.invalidParameters("Exactly one of dataHex, dataText, or dataFile must be specified")
            }
            
            var args = [mode.rawValue]
            
            // Add data parameter
            if let hex = dataHex {
                args.append(contentsOf: ["--data-hex", hex])
            } else if let text = dataText {
                args.append(contentsOf: ["--data", text])
            } else if let file = dataFile {
                args.append(contentsOf: ["--data-file", file.string])
            }
            
            // Add secret key and address
            args.append(contentsOf: ["--secret-key", secretKey])
            args.append(contentsOf: ["--address", address])
            
            // Add optional flags
            if noHashCheck {
                args.append("--nohashcheck")
            }
            
            if hashed {
                args.append("--hashed")
            }
            
            if noPayload {
                args.append("--nopayload")
            }
            
            if includeMaps {
                args.append("--include-maps")
            }
            
            if includeSecret {
                args.append("--include-secret")
            }
            
            if signatureOnly {
                args.append("--signature-only")
            }
            
            // Add testnet magic if specified
            if let magic = testnetMagic {
                args.append(contentsOf: ["--testnet-magic", String(magic)])
            }
            
            // Add output format
            switch outputFormat {
            case .json:
                args.append("--json")
            case .jsonExtended:
                args.append("--json-extended")
            case .hex, .jcli, .bech:
                break // Not applicable for CIP modes
            }
            
            // Add output file if specified
            if let file = outFile {
                args.append(contentsOf: ["--out-file", file.string])
            }
            
            return try await executeCommand("sign", arguments: args)
        }
    }
}
