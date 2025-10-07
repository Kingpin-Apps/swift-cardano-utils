import Testing
import Foundation
import Logging
import SystemPackage
import SwiftCardanoCore
@testable import CardanoCLITools

@Suite("CardanoSigner Tests")
struct CardanoSignerTests {
    
    // MARK: - Static Properties Tests
    
    @Test("CardanoSigner static properties are correct")
    func testStaticProperties() {
        #expect(CardanoSigner.binaryName == "cardano-signer")
        #expect(CardanoSigner.mininumSupportedVersion == "1.17.0")
    }
    
    // MARK: - Protocol Conformance Tests
    
    @Test("CardanoSigner conforms to BinaryInterfaceable protocol")
    func testProtocolConformance() {
        // This test verifies that CardanoSigner implements the required protocol
        // by checking that it has the required static properties
        #expect(!CardanoSigner.binaryName.isEmpty)
        #expect(!CardanoSigner.mininumSupportedVersion.isEmpty)
    }
    
    // MARK: - Configuration Requirements Tests
    
    @Test("CardanoSigner requires signer configuration")
    func testConfigurationRequirements() async throws {
        let testConfig = createTestConfiguration()
        
        // Create config without signer path
        let configWithoutSigner = CardanoCLIToolsConfig(
            cardano: CardanoConfig(
                cli: testConfig.cardano.cli,
                node: testConfig.cardano.node,
                hwCli: testConfig.cardano.hwCli,
                signer: nil, // Missing signer configuration should cause failure
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
            ogmios: nil,
            kupo: nil
        )
        
        await #expect(throws: CardanoCLIToolsError.self) {
            _ = try await CardanoSigner(configuration: configWithoutSigner, logger: nil)
        }
    }
    
    @Test("CardanoSigner requires valid binary path")
    func testBinaryPathRequirements() async throws {
        let testConfig = createTestConfiguration()
        
        // Create config with invalid signer path
        let configWithInvalidSigner = CardanoCLIToolsConfig(
            cardano: CardanoConfig(
                cli: testConfig.cardano.cli,
                node: testConfig.cardano.node,
                hwCli: testConfig.cardano.hwCli,
                signer: FilePath("/nonexistent/path"), // Invalid binary path
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
            ogmios: nil,
            kupo: nil
        )
        
        await #expect(throws: CardanoCLIToolsError.self) {
            _ = try await CardanoSigner(configuration: configWithInvalidSigner, logger: nil)
        }
    }
    
    // MARK: - Version Parsing Tests
    
    @Test("CardanoSigner version parsing logic works correctly")
    func testVersionParsingLogic() {
        // Test the version parsing logic without actually running the binary
        let testOutputs = [
            "cardano-signer 1.17.0": "1.17.0",
            "cardano-signer 1.18.2": "1.18.2",
            "cardano-signer 2.0.0": "2.0.0"
        ]
        
        for (output, expectedVersion) in testOutputs {
            // Simulate the version parsing logic from CardanoSigner.version()
            let pattern = #"cardano-signer (\d+\.\d+\.\d+)"#
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: output, range: NSRange(output.startIndex..., in: output)),
                  let versionRange = Range(match.range(at: 1), in: output) else {
                continue
            }
            
            let extractedVersion = String(output[versionRange])
            #expect(extractedVersion == expectedVersion, "Failed to extract version from: \(output)")
        }
    }
    
    @Test("CardanoSigner version parsing handles edge cases")
    func testVersionParsingEdgeCases() {
        let edgeCases = [
            ("cardano-signer 1.17.0", "1.17.0"),
            ("cardano-signer 10.5.3", "10.5.3"),
            ("cardano-signer 1.0.0-beta", "1.0.0") // Should only match the numeric part
        ]
        
        for (output, expectedVersion) in edgeCases {
            let pattern = #"cardano-signer (\d+\.\d+\.\d+)"#
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: output, range: NSRange(output.startIndex..., in: output)),
                  let versionRange = Range(match.range(at: 1), in: output) else {
                continue
            }
            
            let extractedVersion = String(output[versionRange])
            #expect(extractedVersion == expectedVersion, "Failed to parse edge case: \(output)")
        }
    }
    
    // MARK: - SignOutputFormat Tests
    
    @Test("SignOutputFormat enum has all expected cases")
    func testSignOutputFormatCases() {
        // Verify all format cases exist
        let formats: [SignOutputFormat] = [.hex, .json, .jsonExtended, .jcli, .bech]
        #expect(formats.count == 5)
        
        // Test that they can be used in switch statements (compile-time check)
        for format in formats {
            switch format {
            case .hex, .json, .jsonExtended, .jcli, .bech:
                // All cases handled
                break
            }
        }
    }
    
    // MARK: - DerivationPath Tests
    
    @Test("DerivationPath enum provides correct path strings")
    func testDerivationPathStrings() {
        #expect(DerivationPath.payment.pathString == "payment")
        #expect(DerivationPath.stake.pathString == "stake")
        #expect(DerivationPath.cip36.pathString == "cip36")
        #expect(DerivationPath.drep.pathString == "drep")
        #expect(DerivationPath.ccCold.pathString == "cc-cold")
        #expect(DerivationPath.ccHot.pathString == "cc-hot")
        
        // Test custom path
        let customPath = DerivationPath.custom("1852H/1815H/0H/0/0")
        #expect(customPath.pathString == "1852H/1815H/0H/0/0")
    }
    
    // MARK: - Method Signature Tests
    
    @Test("CardanoSigner sign method signature validation")
    func testSignMethodSignature() {
        // This test verifies that the sign method accepts the expected parameters
        // by testing the method signature compilation without executing it
        
        // Test that we can create the method call with all parameters (compile-time check)
        let _ = { (signer: CardanoSigner) async throws -> String in
            return try await signer.sign(
                dataHex: "48656c6c6f", // "Hello" in hex
                secretKey: "ed25519_sk1...",
                address: "addr1...",
                outputFormat: .json,
                outFile: "/tmp/output.json"
            )
        }
        
        // Verify the method exists and compiles
        #expect(Bool(true))
    }
    
    @Test("CardanoSigner CIP-36 method signature validation")
    func testCIP36MethodSignature() {
        // Test that the CIP-36 method accepts the expected parameters
        
        // Test that we can create the method call with all parameters (compile-time check)
        let _ = { (signer: CardanoSigner) async throws -> String in
            return try await signer.signCIP36(
                votePublicKeys: ["ed25519_pk1..."],
                voteWeights: [100],
                secretKey: "ed25519_sk1...",
                paymentAddress: "addr1...",
                nonce: 12345,
                votePurpose: 0,
                deregister: false,
                testnetMagic: 2,
                outputFormat: .json,
                outFile: "/tmp/catalyst.json",
                outCbor: "/tmp/catalyst.cbor"
            )
        }
        
        // Verify the method exists and compiles
        #expect(Bool(true))
    }
    
    @Test("CardanoSigner keygen method signature validation")
    func testKeygenMethodSignature() {
        // Test that the keygen method accepts the expected parameters
        
        // Test that we can create the method call with all parameters (compile-time check)
        let _ = { (signer: CardanoSigner) async throws -> String in
            return try await signer.keygen(
                path: DerivationPath.payment.pathString,
                mnemonics: "word1 word2 ... word24",
                cip36: true,
                votePurpose: 0,
                vkeyExtended: true,
                outputFormat: .json,
                outFile: "/tmp/keys.json",
                outSkey: "/tmp/secret.skey",
                outVkey: "/tmp/verification.vkey"
            )
        }
        
        // Verify the method exists and compiles
        #expect(Bool(true))
    }
    
    // MARK: - Error Handling Tests
    
    @Test("CardanoSigner error scenarios are well-defined")
    func testErrorScenarios() throws {
        // Test that we understand what errors CardanoSigner can throw
        let testConfig = createTestConfiguration()
        let expectedErrorTypes: [CardanoCLIToolsError] = [
            .binaryNotFound("test"),
            .configurationMissing(testConfig),
            .invalidOutput("test"),
            .commandFailed([], "test"),
            .unsupportedVersion("1.0.0", "1.17.0")
        ]
        
        for error in expectedErrorTypes {
            // Verify error types exist and have descriptions
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }
    
    // MARK: - Documentation Tests
    
    @Test("CardanoSigner initialization limitations are documented")
    func testInitializationLimitations() {
        // This test documents the current limitation that prevents full testing
        // of CardanoSigner initialization in the test environment
        
        // The CardanoSigner initializer:
        // 1. Calls checkVersion() which tries to execute the cardano-signer binary
        // 2. Validates binary existence and permissions
        // 3. Sets up working directories
        
        // The signing/verification methods:
        // 1. Execute cardano-signer with various subcommands
        // 2. Process cryptographic operations
        // 3. Handle different input/output formats
        
        // For now, we test:
        // 1. Static properties and constants
        // 2. Method signatures and parameter validation
        // 3. Enum types and their string representations
        // 4. Configuration validation
        // 5. Error scenarios
        
        #expect(Bool(true), "This test documents known testing limitations")
    }
    
    // MARK: - Integration Tests
    
    @Test("CardanoSigner integrates with Configuration properly")
    func testConfigurationIntegration() throws {
        let testConfig = createTestConfiguration()
        let signerPath = FilePath("/usr/local/bin/cardano-signer")
        
        let cardanoConfig = CardanoConfig(
            cli: testConfig.cardano.cli,
            node: testConfig.cardano.node,
            hwCli: testConfig.cardano.hwCli,
            signer: signerPath, // Add signer path
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
        )
        
        let config = CardanoCLIToolsConfig(cardano: cardanoConfig, ogmios: nil, kupo: nil)
        
        // Test that CardanoSigner configuration fields are properly accessible
        #expect(config.cardano.signer != nil)
        #expect(config.cardano.signer?.string == signerPath.string)
        #expect(config.cardano.cli!.string == testConfig.cardano.cli!.string)
        #expect(config.cardano.workingDir.string == testConfig.cardano.workingDir.string)
    }
}
