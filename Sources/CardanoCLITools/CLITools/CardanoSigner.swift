import Foundation
import System
import Logging

// MARK: - Cardano Signer CLI

/// Wrapper struct for the cardano-signer tool
public struct CardanoSigner: BinaryInterfaceable {
    public let binaryPath: FilePath
    public let workingDirectory: FilePath
    public let configuration: Configuration
    public let logger: Logger
    public static let binaryName: String = "cardano-signer"
    public static let mininumSupportedVersion: String = "1.17.0"
    
    /// Initialize with optional configuration
    public init(configuration: Configuration, logger: Logger? = nil) async throws {
        // Assign all let properties directly
        self.configuration = configuration
        
        // Check for signer binary
        guard let signerPath = configuration.cardano.signer else {
            throw CardanoCLIToolsError.binaryNotFound("cardano-signer path not configured")
        }
        
        // Setup binary path
        self.binaryPath = signerPath
        try Self.checkBinary(binary: self.binaryPath)
        
        // Setup working directory
        self.workingDirectory = configuration.cardano.workingDir
        try Self.checkWorkingDirectory(workingDirectory: self.workingDirectory)
        
        // Setup logger
        self.logger = logger ?? Logger(label: "CardanoSigner")
        
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
            throw CardanoCLIToolsError.invalidOutput("Could not parse cardano-signer version from: \(output)")
        }
        
        return String(output[versionRange])
    }
}

// MARK: - Sign Operations

extension CardanoSigner {
    
    /// Sign a hex string, text, or file
    public func sign(
        dataHex: String? = nil,
        dataText: String? = nil,
        dataFile: String? = nil,
        secretKey: String,
        address: String? = nil,
        outputFormat: SignOutputFormat = .hex,
        outFile: String? = nil
    ) async throws -> String {
        var args = ["sign"]
        
        // Add data parameter - only one should be specified
        if let hex = dataHex {
            args.append(contentsOf: ["--data-hex", hex])
        } else if let text = dataText {
            args.append(contentsOf: ["--data", text])
        } else if let file = dataFile {
            args.append(contentsOf: ["--data-file", file])
        } else {
            throw CardanoCLIToolsError.invalidOutput("Must specify one of: dataHex, dataText, or dataFile")
        }
        
        // Add secret key
        args.append(contentsOf: ["--secret-key", secretKey])
        
        // Add optional address check
        if let addr = address {
            args.append(contentsOf: ["--address", addr])
        }
        
        // Add output format
        switch outputFormat {
        case .json:
            args.append("--json")
        case .jsonExtended:
            args.append("--json-extended")
        case .jcli:
            args.append("--jcli")
        case .bech:
            args.append("--bech")
        case .hex:
            break // Default format
        }
        
        // Add output file if specified
        if let file = outFile {
            args.append(contentsOf: ["--out-file", file])
        }
        
        return try await runCommand(args)
    }
    
    /// Sign payload in CIP-8 mode
    public func signCIP8(
        dataHex: String? = nil,
        dataText: String? = nil,
        dataFile: String? = nil,
        secretKey: String,
        address: String,
        noHashCheck: Bool = false,
        hashed: Bool = false,
        noPayload: Bool = false,
        testnetMagic: Int? = nil,
        outputFormat: SignOutputFormat = .hex,
        outFile: String? = nil
    ) async throws -> String {
        var args = ["sign", "--cip8"]
        
        // Add data parameter - only one should be specified
        if let hex = dataHex {
            args.append(contentsOf: ["--data-hex", hex])
        } else if let text = dataText {
            args.append(contentsOf: ["--data", text])
        } else if let file = dataFile {
            args.append(contentsOf: ["--data-file", file])
        } else {
            throw CardanoCLIToolsError.invalidOutput("Must specify one of: dataHex, dataText, or dataFile")
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
            break // Not applicable for CIP-8
        }
        
        // Add output file if specified
        if let file = outFile {
            args.append(contentsOf: ["--out-file", file])
        }
        
        return try await runCommand(args)
    }
    
    /// Sign payload in CIP-30 mode
    public func signCIP30(
        dataHex: String? = nil,
        dataText: String? = nil,
        dataFile: String? = nil,
        secretKey: String,
        address: String,
        noHashCheck: Bool = false,
        hashed: Bool = false,
        noPayload: Bool = false,
        testnetMagic: Int? = nil,
        outputFormat: SignOutputFormat = .hex,
        outFile: String? = nil
    ) async throws -> String {
        var args = ["sign", "--cip30"]
        
        // Add data parameter - only one should be specified
        if let hex = dataHex {
            args.append(contentsOf: ["--data-hex", hex])
        } else if let text = dataText {
            args.append(contentsOf: ["--data", text])
        } else if let file = dataFile {
            args.append(contentsOf: ["--data-file", file])
        } else {
            throw CardanoCLIToolsError.invalidOutput("Must specify one of: dataHex, dataText, or dataFile")
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
            break // Not applicable for CIP-30
        }
        
        // Add output file if specified
        if let file = outFile {
            args.append(contentsOf: ["--out-file", file])
        }
        
        return try await runCommand(args)
    }
    
    /// Sign catalyst registration/delegation in CIP-36 mode
    public func signCIP36(
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
        var args = ["sign", "--cip36"]
        
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
                throw CardanoCLIToolsError.invalidOutput("Payment address is required for CIP-36 registration")
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
        
        return try await runCommand(args)
    }
}

// MARK: - Verify Operations

extension CardanoSigner {
    
    /// Verify a hex string, text, or file via signature + public key
    public func verify(
        dataHex: String? = nil,
        dataText: String? = nil,
        dataFile: String? = nil,
        signature: String,
        publicKey: String,
        address: String? = nil,
        outputFormat: SignOutputFormat = .hex,
        outFile: String? = nil
    ) async throws -> Bool {
        var args = ["verify"]
        
        // Add data parameter - only one should be specified
        if let hex = dataHex {
            args.append(contentsOf: ["--data-hex", hex])
        } else if let text = dataText {
            args.append(contentsOf: ["--data", text])
        } else if let file = dataFile {
            args.append(contentsOf: ["--data-file", file])
        } else {
            throw CardanoCLIToolsError.invalidOutput("Must specify one of: dataHex, dataText, or dataFile")
        }
        
        // Add signature and public key
        args.append(contentsOf: ["--signature", signature])
        args.append(contentsOf: ["--public-key", publicKey])
        
        // Add optional address check
        if let addr = address {
            args.append(contentsOf: ["--address", addr])
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
            args.append(contentsOf: ["--out-file", file])
        }
        
        do {
            let output = try await runCommand(args)
            return output.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "true"
        } catch {
            return false
        }
    }
    
    /// Verify CIP-8 payload
    public func verifyCIP8(
        coseSign1: String,
        coseKey: String,
        dataHex: String? = nil,
        dataText: String? = nil,
        dataFile: String? = nil,
        address: String? = nil,
        noHashCheck: Bool = false,
        hashed: Bool = false,
        outputFormat: SignOutputFormat = .hex,
        outFile: String? = nil
    ) async throws -> Bool {
        var args = ["verify", "--cip8"]
        
        // Add COSE parameters
        args.append(contentsOf: ["--cose-sign1", coseSign1])
        args.append(contentsOf: ["--cose-key", coseKey])
        
        // Add optional data parameter
        if let hex = dataHex {
            args.append(contentsOf: ["--data-hex", hex])
        } else if let text = dataText {
            args.append(contentsOf: ["--data", text])
        } else if let file = dataFile {
            args.append(contentsOf: ["--data-file", file])
        }
        
        // Add optional address
        if let addr = address {
            args.append(contentsOf: ["--address", addr])
        }
        
        // Add optional flags
        if noHashCheck {
            args.append("--nohashcheck")
        }
        
        if hashed {
            args.append("--hashed")
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
            args.append(contentsOf: ["--out-file", file])
        }
        
        do {
            let output = try await runCommand(args)
            return output.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "true"
        } catch {
            return false
        }
    }
    
    /// Verify CIP-30 payload
    public func verifyCIP30(
        coseSign1: String,
        coseKey: String,
        dataHex: String? = nil,
        dataText: String? = nil,
        dataFile: String? = nil,
        address: String? = nil,
        noHashCheck: Bool = false,
        hashed: Bool = false,
        outputFormat: SignOutputFormat = .hex,
        outFile: String? = nil
    ) async throws -> Bool {
        var args = ["verify", "--cip30"]
        
        // Add COSE parameters
        args.append(contentsOf: ["--cose-sign1", coseSign1])
        args.append(contentsOf: ["--cose-key", coseKey])
        
        // Add optional data parameter
        if let hex = dataHex {
            args.append(contentsOf: ["--data-hex", hex])
        } else if let text = dataText {
            args.append(contentsOf: ["--data", text])
        } else if let file = dataFile {
            args.append(contentsOf: ["--data-file", file])
        }
        
        // Add optional address
        if let addr = address {
            args.append(contentsOf: ["--address", addr])
        }
        
        // Add optional flags
        if noHashCheck {
            args.append("--nohashcheck")
        }
        
        if hashed {
            args.append("--hashed")
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
            args.append(contentsOf: ["--out-file", file])
        }
        
        do {
            let output = try await runCommand(args)
            return output.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "true"
        } catch {
            return false
        }
    }
}

// MARK: - Key Generation

extension CardanoSigner {
    
    /// Generate Cardano ed25519/ed25519-extended keys
    public func keygen(
        path: String? = nil,
        mnemonics: String? = nil,
        cip36: Bool = false,
        votePurpose: UInt? = nil,
        vkeyExtended: Bool = false,
        outputFormat: SignOutputFormat = .hex,
        outFile: String? = nil,
        outSkey: String? = nil,
        outVkey: String? = nil
    ) async throws -> String {
        var args = ["keygen"]
        
        // Add optional derivation path
        if let derivationPath = path {
            args.append(contentsOf: ["--path", derivationPath])
        }
        
        // Add optional mnemonics
        if let words = mnemonics {
            args.append(contentsOf: ["--mnemonics", words])
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
            args.append(contentsOf: ["--out-file", file])
        }
        
        if let skey = outSkey {
            args.append(contentsOf: ["--out-skey", skey])
        }
        
        if let vkey = outVkey {
            args.append(contentsOf: ["--out-vkey", vkey])
        }
        
        return try await runCommand(args)
    }
}

// MARK: - Hash Operations

extension CardanoSigner {
    
    /// Hash/Canonize governance JSON-LD body metadata (CIP-100)
    public func hashCIP100(
        dataText: String? = nil,
        dataFile: String? = nil,
        outputFormat: SignOutputFormat = .hex,
        outCanonized: String? = nil,
        outFile: String? = nil
    ) async throws -> String {
        var args = ["hash", "--cip100"]
        
        // Add data parameter - only one should be specified
        if let text = dataText {
            args.append(contentsOf: ["--data", text])
        } else if let file = dataFile {
            args.append(contentsOf: ["--data-file", file])
        } else {
            throw CardanoCLIToolsError.invalidOutput("Must specify either dataText or dataFile")
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
        if let canonized = outCanonized {
            args.append(contentsOf: ["--out-canonized", canonized])
        }
        
        if let file = outFile {
            args.append(contentsOf: ["--out-file", file])
        }
        
        return try await runCommand(args)
    }
}

// MARK: - Supporting Types

/// Output format options for CardanoSigner
public enum SignOutputFormat {
    case hex
    case json
    case jsonExtended
    case jcli
    case bech
}

/// Predefined derivation paths for key generation
public enum DerivationPath {
    case payment
    case stake
    case cip36
    case drep
    case ccCold
    case ccHot
    case custom(String)
    
    public var pathString: String {
        switch self {
        case .payment:
            return "payment"
        case .stake:
            return "stake"
        case .cip36:
            return "cip36"
        case .drep:
            return "drep"
        case .ccCold:
            return "cc-cold"
        case .ccHot:
            return "cc-hot"
        case .custom(let path):
            return path
        }
    }
}
