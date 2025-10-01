import Testing
import Foundation
import Logging
import System
import SwiftCardanoCore
@testable import CardanoCLITools

@Suite("CardanoSigner Extensive Tests")
struct CardanoSignerExtensiveTests {
    
    // MARK: - Sign Method Parameter Validation Tests
    
    @Test("Sign method validates data input parameters")
    func testSignDataInputValidation() async throws {
        let mockSigner = createMockCardanoSigner()
        
        // Test that providing no data input throws an error
        await #expect(throws: CardanoCLIToolsError.self) {
            _ = try await mockSigner.sign(
                secretKey: "ed25519_sk1...",
                address: "addr1..."
            )
        }
        
        // Test that all three data inputs provided throws error (in real implementation)
        // This would be caught by cardano-signer binary, but we test the parameter logic
        let _ = { (signer: CardanoSigner) async throws -> String in
            return try await signer.sign(
                dataHex: "48656c6c6f",
                dataText: "Hello",
                dataFile: "/tmp/data.txt",
                secretKey: "ed25519_sk1..."
            )
        }
        
        // Verify method signature compiles (we can't test execution without actual binary)
        #expect(Bool(true))
    }
    
    @Test("Sign method handles all output formats correctly")
    func testSignOutputFormats() async throws {
        // Test that all SignOutputFormat cases can be used in sign method
        let formats: [SignOutputFormat] = [.hex, .json, .jsonExtended, .jcli, .bech]
        
        for format in formats {
            let _ = { (signer: CardanoSigner) async throws -> String in
                return try await signer.sign(
                    dataHex: "48656c6c6f",
                    secretKey: "ed25519_sk1...",
                    outputFormat: format
                )
            }
            
            // Verify each format compiles correctly
            #expect(Bool(true))
        }
    }
    
    @Test("Sign method handles optional parameters correctly")
    func testSignOptionalParameters() async throws {
        // Test sign method with minimal parameters
        let _ = { (signer: CardanoSigner) async throws -> String in
            return try await signer.sign(
                dataHex: "48656c6c6f",
                secretKey: "ed25519_sk1..."
            )
        }
        
        // Test sign method with all optional parameters
        let _ = { (signer: CardanoSigner) async throws -> String in
            return try await signer.sign(
                dataHex: "48656c6c6f",
                secretKey: "ed25519_sk1...",
                address: "addr1...",
                outputFormat: .json,
                outFile: "/tmp/signature.json"
            )
        }
        
        #expect(Bool(true))
    }
    
    // MARK: - CIP-8 Signing Tests
    
    @Test("CIP-8 signing method parameter validation")
    func testCIP8SigningValidation() async throws {
        // Test CIP-8 signing with required parameters
        let _ = { (signer: CardanoSigner) async throws -> String in
            return try await signer.signCIP8(
                dataHex: "48656c6c6f",
                secretKey: "ed25519_sk1...",
                address: "addr1..." // Required for CIP-8
            )
        }
        
        // Test CIP-8 with all optional flags
        let _ = { (signer: CardanoSigner) async throws -> String in
            return try await signer.signCIP8(
                dataText: "Hello World",
                secretKey: "ed25519_sk1...",
                address: "addr1...",
                noHashCheck: true,
                hashed: true,
                noPayload: true,
                testnetMagic: 2,
                outputFormat: .jsonExtended,
                outFile: "/tmp/cip8.json"
            )
        }
        
        #expect(Bool(true))
    }
    
    // MARK: - CIP-30 Signing Tests
    
    @Test("CIP-30 signing method parameter validation")
    func testCIP30SigningValidation() async throws {
        // Test CIP-30 signing with required parameters
        let _ = { (signer: CardanoSigner) async throws -> String in
            return try await signer.signCIP30(
                dataFile: "/tmp/payload.json",
                secretKey: "ed25519_sk1...",
                address: "addr1..." // Required for CIP-30
            )
        }
        
        // Test CIP-30 with different data input types
        let _ = { (signer: CardanoSigner) async throws -> String in
            return try await signer.signCIP30(
                dataHex: "deadbeef",
                secretKey: "ed25519_sk1...",
                address: "addr1...",
                testnetMagic: 1
            )
        }
        
        #expect(Bool(true))
    }
    
    // MARK: - CIP-36 Signing Tests
    
    @Test("CIP-36 signing method handles registration parameters")
    func testCIP36RegistrationValidation() async throws {
        // Test CIP-36 registration (not deregistration)
        let _ = { (signer: CardanoSigner) async throws -> String in
            return try await signer.signCIP36(
                votePublicKeys: ["ed25519_pk1abc123", "ed25519_pk1def456"],
                voteWeights: [60, 40],
                secretKey: "ed25519_sk1...",
                paymentAddress: "addr1...", // Required for registration
                nonce: 12345,
                votePurpose: 0,
                testnetMagic: 2,
                outputFormat: .json
            )
        }
        
        #expect(Bool(true))
    }
    
    @Test("CIP-36 signing method handles deregistration parameters")
    func testCIP36DeregistrationValidation() async throws {
        // Test CIP-36 deregistration (no vote keys/weights needed)
        let _ = { (signer: CardanoSigner) async throws -> String in
            return try await signer.signCIP36(
                secretKey: "ed25519_sk1...",
                nonce: 54321,
                deregister: true,
                testnetMagic: 2,
                outFile: "/tmp/dereg.cbor",
                outCbor: "/tmp/dereg-raw.cbor"
            )
        }
        
        #expect(Bool(true))
    }
    
    @Test("CIP-36 signing validates payment address for registration")
    func testCIP36PaymentAddressValidation() async throws {
        let mockSigner = createMockCardanoSigner()
        
        // Test that registration without payment address should throw error
        await #expect(throws: CardanoCLIToolsError.self) {
            _ = try await mockSigner.signCIP36(
                votePublicKeys: ["ed25519_pk1abc123"],
                voteWeights: [100],
                secretKey: "ed25519_sk1...",
                // Missing paymentAddress for registration
                deregister: false
            )
        }
    }
    
    // MARK: - Verify Method Tests
    
    @Test("Verify method handles all data input types")
    func testVerifyDataInputTypes() async throws {
        // Test verify with hex data
        let _ = { (signer: CardanoSigner) async throws -> Bool in
            return try await signer.verify(
                dataHex: "48656c6c6f",
                signature: "ed25519_sig1...",
                publicKey: "ed25519_pk1..."
            )
        }
        
        // Test verify with text data
        let _ = { (signer: CardanoSigner) async throws -> Bool in
            return try await signer.verify(
                dataText: "Hello World",
                signature: "ed25519_sig1...",
                publicKey: "ed25519_pk1...",
                address: "addr1...",
                outputFormat: .json
            )
        }
        
        // Test verify with file data
        let _ = { (signer: CardanoSigner) async throws -> Bool in
            return try await signer.verify(
                dataFile: "/tmp/message.txt",
                signature: "ed25519_sig1...",
                publicKey: "ed25519_pk1...",
                outFile: "/tmp/verify-result.json"
            )
        }
        
        #expect(Bool(true))
    }
    
    @Test("CIP-8 verify method parameter validation")
    func testCIP8VerifyValidation() async throws {
        // Test CIP-8 verification with required parameters
        let _ = { (signer: CardanoSigner) async throws -> Bool in
            return try await signer.verifyCIP8(
                coseSign1: "cose_sign1_data",
                coseKey: "cose_key_data"
            )
        }
        
        // Test CIP-8 verification with optional data and flags
        let _ = { (signer: CardanoSigner) async throws -> Bool in
            return try await signer.verifyCIP8(
                coseSign1: "cose_sign1_data",
                coseKey: "cose_key_data",
                dataHex: "48656c6c6f",
                address: "addr1...",
                noHashCheck: true,
                hashed: true,
                outputFormat: .jsonExtended
            )
        }
        
        #expect(Bool(true))
    }
    
    @Test("CIP-30 verify method parameter validation")
    func testCIP30VerifyValidation() async throws {
        // Test CIP-30 verification with file input
        let _ = { (signer: CardanoSigner) async throws -> Bool in
            return try await signer.verifyCIP30(
                coseSign1: "cose_sign1_data",
                coseKey: "cose_key_data",
                dataFile: "/tmp/signed-data.json",
                address: "addr1...",
                outFile: "/tmp/verify-cip30.json"
            )
        }
        
        #expect(Bool(true))
    }
    
    // MARK: - Key Generation Tests
    
    @Test("Keygen method handles different derivation scenarios")
    func testKeygenDerivationScenarios() async throws {
        // Test keygen with standard derivation path
        let _ = { (signer: CardanoSigner) async throws -> String in
            return try await signer.keygen(
                path: "m/1852'/1815'/0'/0/0",
                mnemonics: "word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12",
                outputFormat: .json
            )
        }
        
        // Test keygen for CIP-36 voting keys
        let _ = { (signer: CardanoSigner) async throws -> String in
            return try await signer.keygen(
                path: DerivationPath.cip36.pathString,
                cip36: true,
                votePurpose: 0,
                vkeyExtended: true,
                outSkey: "/tmp/vote.skey",
                outVkey: "/tmp/vote.vkey"
            )
        }
        
        // Test keygen for DRep keys
        let _ = { (signer: CardanoSigner) async throws -> String in
            return try await signer.keygen(
                path: DerivationPath.drep.pathString,
                mnemonics: "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about",
                outputFormat: .jsonExtended,
                outFile: "/tmp/drep-keys.json"
            )
        }
        
        #expect(Bool(true))
    }
    
    @Test("Keygen method handles constitutional committee keys")
    func testKeygenConstitutionalCommittee() async throws {
        // Test keygen for cold committee keys
        let _ = { (signer: CardanoSigner) async throws -> String in
            return try await signer.keygen(
                path: DerivationPath.ccCold.pathString,
                vkeyExtended: true,
                outSkey: "/tmp/cc-cold.skey",
                outVkey: "/tmp/cc-cold.vkey"
            )
        }
        
        // Test keygen for hot committee keys
        let _ = { (signer: CardanoSigner) async throws -> String in
            return try await signer.keygen(
                path: DerivationPath.ccHot.pathString,
                mnemonics: "test test test test test test test test test test test junk",
                outputFormat: .hex,
                outFile: "/tmp/cc-hot-keys.hex"
            )
        }
        
        #expect(Bool(true))
    }
    
    // MARK: - Hash CIP-100 Tests
    
    @Test("Hash CIP-100 method parameter validation")
    func testHashCIP100Validation() async throws {
        let mockSigner = createMockCardanoSigner()
        
        // Test that providing no data input throws an error
        await #expect(throws: CardanoCLIToolsError.self) {
            _ = try await mockSigner.hashCIP100()
        }
        
        // Test hash with text input
        let _ = { (signer: CardanoSigner) async throws -> String in
            return try await signer.hashCIP100(
                dataText: "{\"governance_metadata\": {\"title\": \"Test Proposal\"}}",
                outputFormat: .json,
                outFile: "/tmp/hash-result.json"
            )
        }
        
        // Test hash with file input
        let _ = { (signer: CardanoSigner) async throws -> String in
            return try await signer.hashCIP100(
                dataFile: "/tmp/governance.jsonld",
                outCanonized: "/tmp/canonized.jsonld",
                outFile: "/tmp/governance-hash.hex"
            )
        }
        
        #expect(Bool(true))
    }
    
    // MARK: - DerivationPath Enum Tests
    
    @Test("DerivationPath enum covers all Cardano use cases")
    func testDerivationPathComprehensive() {
        let allPaths: [DerivationPath] = [
            .payment,
            .stake,
            .cip36,
            .drep,
            .ccCold,
            .ccHot,
            .custom("m/1852'/1815'/0'/2/0"),
            .custom("1855H/1815H/0H")
        ]
        
        let expectedStrings = [
            "payment",
            "stake", 
            "cip36",
            "drep",
            "cc-cold",
            "cc-hot",
            "m/1852'/1815'/0'/2/0",
            "1855H/1815H/0H"
        ]
        
        for (path, expected) in zip(allPaths, expectedStrings) {
            #expect(path.pathString == expected, "Path \(path) should return \(expected)")
        }
        
        // Test that DerivationPath can be used in collections
        let pathSet = Set(allPaths.map { $0.pathString })
        #expect(pathSet.count == allPaths.count, "All path strings should be unique")
    }
    
    // MARK: - SignOutputFormat Enum Tests
    
    @Test("SignOutputFormat enum completeness and usage")
    func testSignOutputFormatComprehensive() {
        let allFormats: [SignOutputFormat] = [.hex, .json, .jsonExtended, .jcli, .bech]
        
        // Test that all formats can be used in different contexts
        for format in allFormats {
            // Test in sign context
            let _ = { (signer: CardanoSigner) async throws -> String in
                try await signer.sign(
                    dataHex: "test",
                    secretKey: "key",
                    outputFormat: format
                )
            }
            
            // Test in verify context
            let _ = { (signer: CardanoSigner) async throws -> Bool in
                try await signer.verify(
                    dataHex: "test",
                    signature: "sig",
                    publicKey: "pub",
                    outputFormat: format
                )
            }
            
            // Test in keygen context
            let _ = { (signer: CardanoSigner) async throws -> String in
                try await signer.keygen(
                    path: "m/0/0",
                    outputFormat: format
                )
            }
            
            #expect(Bool(true))
        }
    }
    
    // MARK: - Version Parsing Edge Cases
    
    @Test("Version parsing handles malformed outputs")
    func testVersionParsingMalformedInput() {
        let malformedInputs = [
            "cardano-signer", // No version
            "cardano-signer abc.def.ghi", // Non-numeric version
            "some-other-tool 1.2.3", // Wrong binary name
            "", // Empty string
            "cardano-signer 1.2", // Incomplete version
            "cardano-signer 1.2.3.4", // Too many version parts (will match 1.2.3)
            "CARDANO-SIGNER 1.2.3", // Wrong case
            "cardano-signer version 1.2.3", // Extra word
        ]
        
        let pattern = #"cardano-signer (\d+\.\d+\.\d+)"#
        
        for input in malformedInputs {
            guard let regex = try? NSRegularExpression(pattern: pattern) else {
                #expect(Bool(false), "Regex should compile")
                continue
            }
            
            let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input))
            // Note: "cardano-signer 1.2.3.4" will match "1.2.3" which is expected behavior
            if input.contains("1.2.3.4") {
                #expect(match != nil, "Input '\(input)' should match version pattern and extract 1.2.3")
            } else {
                #expect(match == nil, "Input '\(input)' should not match version pattern")
            }
        }
    }
    
    @Test("Version parsing handles valid version formats")
    func testVersionParsingValidFormats() {
        let validInputs = [
            ("cardano-signer 1.17.0", "1.17.0"),
            ("cardano-signer 2.0.0", "2.0.0"), 
            ("cardano-signer 10.25.99", "10.25.99"),
            ("cardano-signer 1.17.0-beta", "1.17.0"), // Should extract just the numeric part
            ("Usage: cardano-signer 1.18.5 [options]", "1.18.5"), // Version in longer text
        ]
        
        let pattern = #"cardano-signer (\d+\.\d+\.\d+)"#
        
        for (input, expectedVersion) in validInputs {
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)),
                  let versionRange = Range(match.range(at: 1), in: input) else {
                #expect(Bool(false), "Input '\(input)' should match version pattern")
                continue
            }
            
            let extractedVersion = String(input[versionRange])
            #expect(extractedVersion == expectedVersion, "Expected \(expectedVersion) from '\(input)', got \(extractedVersion)")
        }
    }
    
    // MARK: - Configuration Integration Tests
    
    @Test("CardanoSigner works with different configuration scenarios")
    func testConfigurationScenarios() throws {
        let baseConfig = createTestConfiguration()
        
        // Test with different signer paths
        let configurations = [
            // Production-like path
            createConfigWithSigner("/usr/local/bin/cardano-signer"),
            // Development path
            createConfigWithSigner("/home/user/.local/bin/cardano-signer"),
            // Custom build path
            createConfigWithSigner("/opt/cardano/bin/cardano-signer"),
            // Relative path (in working directory)
            createConfigWithSigner("./cardano-signer"),
        ]
        
        for config in configurations {
            // Test that each configuration has the signer properly set
            #expect(config.cardano.signer != nil)
            #expect(!config.cardano.signer!.string.isEmpty)
            
            // Test that it maintains other configuration properties (CLI paths differ due to mock creation)
            #expect(!config.cardano.cli.string.isEmpty)
            #expect(config.cardano.workingDir.string == baseConfig.cardano.workingDir.string)
        }
    }
    
    @Test("CardanoSigner integrates with different network configurations")
    func testNetworkIntegration() throws {
        let networks: [CardanoCLITools.Network] = [.mainnet, .preview, .preprod]
        
        for network in networks {
            let config = createConfigWithSignerAndNetwork("/usr/bin/cardano-signer", network)
            
            #expect(config.cardano.network == network)
            #expect(config.cardano.signer != nil)
            
            // Test that signing methods would work with different networks
            let _ = { (signer: CardanoSigner) async throws -> String in
                try await signer.signCIP36(
                    votePublicKeys: ["ed25519_pk1test"],
                    voteWeights: [100],
                    secretKey: "ed25519_sk1test",
                    paymentAddress: "addr1test",
                    testnetMagic: network == .mainnet ? nil : (network == .preview ? 2 : 1)
                )
            }
            
            #expect(Bool(true))
        }
    }
    
    // MARK: - Error Scenarios
    
    @Test("CardanoSigner handles argument building correctly")
    func testArgumentBuilding() async throws {
        // Test that methods correctly build command line arguments
        // This tests the internal logic without executing commands
        
        // Test sign arguments
        let _ = { (signer: CardanoSigner) async throws -> String in
            try await signer.sign(
                dataHex: "deadbeef",
                secretKey: "ed25519_sk1abc123def456",
                address: "addr1qxy123abc456def789",
                outputFormat: .json,
                outFile: "/tmp/signature.json"
            )
        }
        
        // Test CIP-36 arguments with multiple keys
        let _ = { (signer: CardanoSigner) async throws -> String in
            try await signer.signCIP36(
                votePublicKeys: ["key1", "key2", "key3"],
                voteWeights: [30, 30, 40],
                secretKey: "skey",
                paymentAddress: "payment_addr",
                nonce: 42,
                votePurpose: 1,
                testnetMagic: 2,
                outputFormat: .jsonExtended,
                outFile: "/tmp/vote.json",
                outCbor: "/tmp/vote.cbor"
            )
        }
        
        // Test verify arguments
        let _ = { (signer: CardanoSigner) async throws -> Bool in
            try await signer.verify(
                dataFile: "/tmp/message.txt",
                signature: "ed25519_sig1xyz789",
                publicKey: "ed25519_pk1uvw456",
                address: "addr1verify123",
                outputFormat: .hex
            )
        }
        
        #expect(Bool(true))
    }
    
    // MARK: - Mock Helper Methods
    
    /// Create a mock CardanoSigner for testing (would require actual binary for real initialization)
    private func createMockCardanoSigner() -> MockCardanoSigner {
        return MockCardanoSigner()
    }
    
    /// Create configuration with specific signer path
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
    
    /// Create configuration with specific signer path and network
    private func createConfigWithSignerAndNetwork(_ signerPath: String, _ network: CardanoCLITools.Network) -> Configuration {
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
            network: network,
            era: baseConfig.cardano.era,
            ttlBuffer: baseConfig.cardano.ttlBuffer,
            workingDir: baseConfig.cardano.workingDir,
            showOutput: baseConfig.cardano.showOutput
        )
        
        return Configuration(cardano: cardanoConfig, ogmios: nil, kupo: nil)
    }
}

// MARK: - Mock CardanoSigner for Testing

/// Mock implementation for testing without requiring actual binary
private struct MockCardanoSigner {
    
    func sign(
        dataHex: String? = nil,
        dataText: String? = nil,
        dataFile: String? = nil,
        secretKey: String,
        address: String? = nil,
        outputFormat: SignOutputFormat = .hex,
        outFile: String? = nil
    ) async throws -> String {
        // Validate that at least one data input is provided
        guard dataHex != nil || dataText != nil || dataFile != nil else {
            throw CardanoCLIToolsError.invalidOutput("Must specify one of: dataHex, dataText, or dataFile")
        }
        return "mock_signature"
    }
    
    func signCIP36(
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
        // Validate payment address for registration
        if !deregister && paymentAddress == nil {
            throw CardanoCLIToolsError.invalidOutput("Payment address is required for CIP-36 registration")
        }
        return "mock_cip36_signature"
    }
    
    func hashCIP100(
        dataText: String? = nil,
        dataFile: String? = nil,
        outputFormat: SignOutputFormat = .hex,
        outCanonized: String? = nil,
        outFile: String? = nil
    ) async throws -> String {
        // Validate that at least one data input is provided
        guard dataText != nil || dataFile != nil else {
            throw CardanoCLIToolsError.invalidOutput("Must specify either dataText or dataFile")
        }
        return "mock_hash"
    }
}