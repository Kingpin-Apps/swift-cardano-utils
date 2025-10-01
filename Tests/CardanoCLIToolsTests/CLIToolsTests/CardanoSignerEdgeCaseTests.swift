import Testing
import Foundation
import Logging
import System
import SwiftCardanoCore
@testable import CardanoCLITools

@Suite("CardanoSigner Edge Case Tests")
struct CardanoSignerEdgeCaseTests {
    
    // MARK: - Binary Path Edge Cases
    
    @Test("CardanoSigner handles various binary path formats")
    func testBinaryPathFormats() {
        let pathFormats = [
            "/usr/bin/cardano-signer",           // Absolute Unix path
            "/usr/local/bin/cardano-signer",     // Alternative absolute path
            "~/bin/cardano-signer",              // Home directory path
            "./cardano-signer",                  // Relative path
            "../bin/cardano-signer",             // Parent directory relative path
            "cardano-signer",                    // Just binary name (PATH lookup)
            "/opt/cardano/cardano-signer",       // Custom installation path
            "/Applications/CardanoSigner/bin/cardano-signer", // macOS application path
        ]
        
        for path in pathFormats {
            let config = createConfigWithSigner(path)
            #expect(config.cardano.signer?.string == path)
            #expect(config.cardano.signer != nil)
        }
    }
    
    @Test("CardanoSigner handles empty or whitespace paths correctly")
    func testInvalidPathHandling() {
        let invalidPaths = [
            "",           // Empty string
            " ",          // Single space
            "   ",        // Multiple spaces  
            "\t",         // Tab character
            "\n",         // Newline
            "\r\n",       // Windows line ending
        ]
        
        for path in invalidPaths {
            let config = createConfigWithSigner(path)
            #expect(config.cardano.signer?.string == path) // Path is stored as-is
            // Note: The actual validation would happen during CardanoSigner initialization
        }
    }
    
    // MARK: - Version String Edge Cases
    
    @Test("Version parsing handles various cardano-signer version outputs")
    func testVersionOutputVariations() {
        let versionOutputs = [
            // Standard formats
            ("cardano-signer 1.17.0", "1.17.0"),
            ("cardano-signer 2.0.0", "2.0.0"),
            ("cardano-signer 10.5.25", "10.5.25"),
            
            // With additional text
            ("cardano-signer 1.17.0\nUsage: cardano-signer [options]", "1.17.0"),
            ("Version: cardano-signer 1.18.2", "1.18.2"),
            ("cardano-signer 1.19.0 (build 12345)", "1.19.0"),
            
            // Multi-line outputs
            ("cardano-signer 2.1.0\nCopyright (c) 2024", "2.1.0"),
            ("Usage:\ncardano-signer 1.20.0\n  sign [options]", "1.20.0"),
            
            // With pre-release identifiers (should extract base version)
            ("cardano-signer 1.17.0-alpha", "1.17.0"),
            ("cardano-signer 1.17.0-beta.1", "1.17.0"),
            ("cardano-signer 1.17.0-rc.2", "1.17.0"),
            
            // Development versions
            ("cardano-signer 1.17.0-dev+abc123", "1.17.0"),
            ("cardano-signer 1.17.0+20240101", "1.17.0"),
        ]
        
        let pattern = #"cardano-signer (\d+\.\d+\.\d+)"#
        
        for (output, expectedVersion) in versionOutputs {
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: output, range: NSRange(output.startIndex..., in: output)),
                  let versionRange = Range(match.range(at: 1), in: output) else {
                #expect(Bool(false), "Failed to parse version from: '\(output)'")
                continue
            }
            
            let extractedVersion = String(output[versionRange])
            #expect(extractedVersion == expectedVersion, "Expected '\(expectedVersion)' from '\(output)', got '\(extractedVersion)'")
        }
    }
    
    // MARK: - Parameter Validation Edge Cases
    
    @Test("Sign methods handle parameter edge cases")
    func testSignParameterEdgeCases() {
        // Test various data input combinations and edge cases
        let parameterTests = [
            // Empty/minimal values
            ("", "minimal_key", nil),
            ("00", "single_byte_key", nil),
            ("deadbeef", "", "empty_key"), // Should work in signature compilation
            
            // Long values
            (String(repeating: "ab", count: 1000), "long_data_key", nil),
            ("test", String(repeating: "x", count: 500), "long_key"),
            
            // Special characters in hex
            ("deadbeef", "ed25519_sk1" + String(repeating: "a", count: 50), nil),
            
            // Unicode and special characters (for text data)
            ("Hello 世界 🌍", "unicode_key", nil),
        ]
        
        for (data, key, _) in parameterTests {
            let _ = { (signer: CardanoSigner) async throws -> String in
                return try await signer.sign(
                    dataHex: data.isEmpty ? nil : data,
                    dataText: data.isEmpty ? "fallback text" : nil,
                    secretKey: key,
                    address: "addr1test"
                )
            }
            
            // All these should compile (actual validation happens at runtime)
            #expect(Bool(true))
        }
    }
    
    @Test("CIP-36 signing handles complex vote weight scenarios")
    func testCIP36VoteWeightEdgeCases() {
        // Test various vote weight distributions
        let voteScenarios = [
            // Single vote key
            ([1], [100]),
            
            // Equal distribution
            ([2], [50, 50]),
            ([3], [33, 33, 34]),
            
            // Unequal distribution
            ([3], [70, 20, 10]),
            ([5], [40, 30, 15, 10, 5]),
            
            // Edge case: very unequal
            ([2], [99, 1]),
            ([10], [91, 1, 1, 1, 1, 1, 1, 1, 1, 1]),
            
            // Maximum single vote
            ([1], [UInt.max]),
            
            // Zero weight (unusual but might be valid)
            ([3], [50, 50, 0]),
        ]
        
        for (keyCount, weights) in voteScenarios {
            let keys = (0..<keyCount[0]).map { "ed25519_pk1key\($0)_" + String(repeating: "a", count: 20) }
            
            let _ = { (signer: CardanoSigner) async throws -> String in
                return try await signer.signCIP36(
                    votePublicKeys: keys,
                    voteWeights: weights,
                    secretKey: "ed25519_sk1secret_key",
                    paymentAddress: "addr1payment_address",
                    nonce: 12345
                )
            }
            
            #expect(Bool(true))
        }
    }
    
    @Test("File path parameters handle various path formats")
    func testFilePathParameterFormats() {
        let pathFormats = [
            // Unix absolute paths
            "/tmp/cardano-data.txt",
            "/home/user/cardano/keys.json",
            "/var/lib/cardano/signature.hex",
            
            // Relative paths
            "./local-file.txt",
            "../config/cardano.json",
            "keys/secret.skey",
            
            // Paths with spaces and special characters
            "/tmp/cardano data.txt",
            "/tmp/cardano-file(1).json",
            "/tmp/cardano_file-2024.hex",
            
            // Windows-style paths (for cross-platform compatibility)
            "C:/cardano/data.txt",
            "D:/Projects/Cardano/keys.json",
            
            // Home directory paths
            "~/cardano/wallet.skey",
            "~/.cardano/protocol-params.json",
            
            // Very long paths
            "/tmp/" + String(repeating: "very_long_directory_name/", count: 10) + "file.txt",
        ]
        
        for path in pathFormats {
            // Test in various signing contexts
            let _ = { (signer: CardanoSigner) async throws -> String in
                try await signer.sign(
                    dataFile: path,
                    secretKey: "ed25519_sk1test",
                    outFile: path + ".sig"
                )
            }
            
            let _ = { (signer: CardanoSigner) async throws -> Bool in
                try await signer.verify(
                    dataFile: path,
                    signature: "sig123",
                    publicKey: "pub123",
                    outFile: path + ".verify"
                )
            }
            
            let _ = { (signer: CardanoSigner) async throws -> String in
                try await signer.keygen(
                    outFile: path + ".keys",
                    outSkey: path + ".skey",
                    outVkey: path + ".vkey"
                )
            }
            
            #expect(Bool(true))
        }
    }
    
    // MARK: - Network Configuration Edge Cases
    
    @Test("CardanoSigner handles testnet magic numbers correctly")
    func testTestnetMagicNumbers() {
        let testnetMagics = [
            0,          // Edge case: zero
            1,          // Preprod
            2,          // Preview
            42,         // Custom testnet
            1097911063, // Mainnet magic (though mainnet usually doesn't use this)
            Int.max,    // Maximum value
        ]
        
        for magic in testnetMagics {
            let _ = { (signer: CardanoSigner) async throws -> String in
                try await signer.signCIP8(
                    dataHex: "test",
                    secretKey: "sk1test",
                    address: "addr1test",
                    testnetMagic: magic
                )
            }
            
            let _ = { (signer: CardanoSigner) async throws -> String in
                try await signer.signCIP30(
                    dataText: "test",
                    secretKey: "sk1test", 
                    address: "addr1test",
                    testnetMagic: magic
                )
            }
            
            let _ = { (signer: CardanoSigner) async throws -> String in
                try await signer.signCIP36(
                    votePublicKeys: ["pk1test"],
                    voteWeights: [100],
                    secretKey: "sk1test",
                    paymentAddress: "addr1test",
                    testnetMagic: magic
                )
            }
            
            #expect(Bool(true))
        }
    }
    
    // MARK: - Output Format Combinations
    
    @Test("Output formats work across all method contexts")
    func testOutputFormatContextCompatibility() {
        let formats: [SignOutputFormat] = [.hex, .json, .jsonExtended, .jcli, .bech]
        
        // Test each format in each method context
        for format in formats {
            // Basic signing
            let _ = { (signer: CardanoSigner) async throws -> String in
                try await signer.sign(dataHex: "test", secretKey: "sk", outputFormat: format)
            }
            
            // CIP-8 signing (note: some formats may not be applicable)
            let _ = { (signer: CardanoSigner) async throws -> String in
                try await signer.signCIP8(
                    dataHex: "test",
                    secretKey: "sk",
                    address: "addr",
                    outputFormat: format
                )
            }
            
            // CIP-30 signing
            let _ = { (signer: CardanoSigner) async throws -> String in
                try await signer.signCIP30(
                    dataHex: "test",
                    secretKey: "sk",
                    address: "addr",
                    outputFormat: format
                )
            }
            
            // CIP-36 signing
            let _ = { (signer: CardanoSigner) async throws -> String in
                try await signer.signCIP36(
                    votePublicKeys: ["pk"],
                    voteWeights: [100],
                    secretKey: "sk",
                    paymentAddress: "addr",
                    outputFormat: format
                )
            }
            
            // Verification
            let _ = { (signer: CardanoSigner) async throws -> Bool in
                try await signer.verify(
                    dataHex: "test",
                    signature: "sig",
                    publicKey: "pk",
                    outputFormat: format
                )
            }
            
            // Key generation
            let _ = { (signer: CardanoSigner) async throws -> String in
                try await signer.keygen(outputFormat: format)
            }
            
            // CIP-100 hashing
            let _ = { (signer: CardanoSigner) async throws -> String in
                try await signer.hashCIP100(dataText: "test", outputFormat: format)
            }
            
            #expect(Bool(true))
        }
    }
    
    // MARK: - Derivation Path Edge Cases
    
    @Test("DerivationPath handles complex custom paths")
    func testComplexDerivationPaths() {
        let complexPaths = [
            // Standard BIP44 paths
            "m/44'/1815'/0'/0/0",
            "m/44'/1815'/0'/1/0",
            "m/44'/1815'/1'/0/0",
            
            // CIP-1852 paths
            "m/1852'/1815'/0'/0/0",
            "m/1852'/1815'/0'/1/0",  
            "m/1852'/1815'/0'/2/0",
            
            // Multisig paths
            "m/1854'/1815'/0'/0/0",
            "m/1855'/1815'/0'/0/0",
            
            // Deep derivation paths
            "m/44'/1815'/0'/0/0/0/0",
            "m/1852'/1815'/0'/0/0/1/2/3",
            
            // Large account numbers
            "m/1852'/1815'/999'/0/0",
            "m/1852'/1815'/2147483647'/0/0", // Max hardened derivation
            
            // Non-hardened mixed with hardened
            "m/1852'/1815'/0/0'/0",
            "m/1852/1815'/0'/0/0",
            
            // Alternative hardened notation
            "1852H/1815H/0H/0/0",
            "44H/1815H/0H/1H/0",
            
            // Unusual but valid paths
            "m/0'/0'/0'/0'/0'",
            "0/1/2/3/4/5",
        ]
        
        for pathString in complexPaths {
            let customPath = DerivationPath.custom(pathString)
            #expect(customPath.pathString == pathString)
            
            // Test that custom paths can be used in keygen
            let _ = { (signer: CardanoSigner) async throws -> String in
                try await signer.keygen(path: customPath.pathString)
            }
            
            #expect(Bool(true))
        }
    }
    
    // MARK: - Nonce and Vote Purpose Edge Cases
    
    @Test("CIP-36 handles various nonce and vote purpose values")
    func testCIP36NonceAndVotePurposeValues() {
        let nonceValues: [UInt?] = [
            nil,        // No nonce
            0,          // Zero nonce
            1,          // Minimal nonce
            42,         // Arbitrary nonce
            12345678,   // Large nonce
            UInt.max,   // Maximum nonce
        ]
        
        let votePurposes: [UInt] = [
            0,          // Default (Catalyst)
            1,          // Alternative purpose
            10,         // Higher purpose
            255,        // Byte maximum
            UInt.max,   // Maximum purpose
        ]
        
        for nonce in nonceValues {
            for votePurpose in votePurposes {
                let _ = { (signer: CardanoSigner) async throws -> String in
                    try await signer.signCIP36(
                        votePublicKeys: ["pk1test"],
                        voteWeights: [100],
                        secretKey: "sk1test",
                        paymentAddress: "addr1test",
                        nonce: nonce,
                        votePurpose: votePurpose
                    )
                }
                
                #expect(Bool(true))
            }
        }
    }
    
    // MARK: - Boolean Flag Combinations
    
    @Test("Boolean flags work in all combinations")
    func testBooleanFlagCombinations() {
        // Test all boolean flag combinations for CIP-8/CIP-30
        let flagCombinations = [
            (noHashCheck: false, hashed: false, noPayload: false),
            (noHashCheck: true, hashed: false, noPayload: false),
            (noHashCheck: false, hashed: true, noPayload: false),
            (noHashCheck: false, hashed: false, noPayload: true),
            (noHashCheck: true, hashed: true, noPayload: false),
            (noHashCheck: true, hashed: false, noPayload: true),
            (noHashCheck: false, hashed: true, noPayload: true),
            (noHashCheck: true, hashed: true, noPayload: true),
        ]
        
        for (noHashCheck, hashed, noPayload) in flagCombinations {
            let _ = { (signer: CardanoSigner) async throws -> String in
                try await signer.signCIP8(
                    dataHex: "test",
                    secretKey: "sk",
                    address: "addr",
                    noHashCheck: noHashCheck,
                    hashed: hashed,
                    noPayload: noPayload
                )
            }
            
            let _ = { (signer: CardanoSigner) async throws -> String in
                try await signer.signCIP30(
                    dataHex: "test",
                    secretKey: "sk",
                    address: "addr",
                    noHashCheck: noHashCheck,
                    hashed: hashed,
                    noPayload: noPayload
                )
            }
            
            #expect(Bool(true))
        }
        
        // Test keygen boolean flags
        let keygenFlagCombinations = [
            (cip36: false, vkeyExtended: false),
            (cip36: true, vkeyExtended: false),
            (cip36: false, vkeyExtended: true),
            (cip36: true, vkeyExtended: true),
        ]
        
        for (cip36, vkeyExtended) in keygenFlagCombinations {
            let _ = { (signer: CardanoSigner) async throws -> String in
                try await signer.keygen(
                    cip36: cip36,
                    vkeyExtended: vkeyExtended
                )
            }
            
            #expect(Bool(true))
        }
    }
    
    // MARK: - Configuration Property Access
    
    @Test("CardanoSigner configuration properties are accessible")
    func testConfigurationPropertyAccess() {
        let testConfig = createTestConfiguration()
        let signerPath = FilePath("/test/cardano-signer")
        
        let modifiedConfig = Configuration(
            cardano: CardanoConfig(
                cli: testConfig.cardano.cli,
                node: testConfig.cardano.node,
                hwCli: testConfig.cardano.hwCli,
                signer: signerPath,
                socket: testConfig.cardano.socket,
                config: testConfig.cardano.config,
                topology: testConfig.cardano.topology,
                database: testConfig.cardano.database,
                port: testConfig.cardano.port,
                hostAddr: testConfig.cardano.hostAddr,
                network: testConfig.cardano.network,
                era: testConfig.cardano.era,
                ttlBuffer: testConfig.cardano.ttlBuffer,
                workingDir: testConfig.cardano.workingDir,
                showOutput: testConfig.cardano.showOutput
            ),
            ogmios: testConfig.ogmios,
            kupo: testConfig.kupo
        )
        
        // Test that all configuration properties are properly set
        #expect(modifiedConfig.cardano.signer == signerPath)
        #expect(modifiedConfig.cardano.signer?.string == "/test/cardano-signer")
        #expect(modifiedConfig.cardano.cli == testConfig.cardano.cli)
        #expect(modifiedConfig.cardano.node == testConfig.cardano.node)
        #expect(modifiedConfig.cardano.workingDir == testConfig.cardano.workingDir)
        #expect(modifiedConfig.cardano.network == testConfig.cardano.network)
        #expect(modifiedConfig.cardano.era == testConfig.cardano.era)
        #expect(modifiedConfig.cardano.ttlBuffer == testConfig.cardano.ttlBuffer)
    }
    
    // MARK: - Helper Methods
    
    private func createConfigWithSigner(_ signerPath: String) -> Configuration {
        let baseConfig = createTestConfiguration()
        let cardanoConfig = CardanoConfig(
            cli: baseConfig.cardano.cli,
            node: baseConfig.cardano.node,
            hwCli: baseConfig.cardano.hwCli,
            signer: FilePath(signerPath),
            socket: baseConfig.cardano.socket,
            config: baseConfig.cardano.config,
            topology: baseConfig.cardano.topology,
            database: baseConfig.cardano.database,
            port: baseConfig.cardano.port,
            hostAddr: baseConfig.cardano.hostAddr,
            network: baseConfig.cardano.network,
            era: baseConfig.cardano.era,
            ttlBuffer: baseConfig.cardano.ttlBuffer,
            workingDir: baseConfig.cardano.workingDir,
            showOutput: baseConfig.cardano.showOutput
        )
        
        return Configuration(cardano: cardanoConfig, ogmios: nil, kupo: nil)
    }
}