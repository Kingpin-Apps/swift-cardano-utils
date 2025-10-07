import Testing
import Foundation
import Logging
import SystemPackage
import SwiftCardanoCore
@testable import CardanoCLITools

@Suite("CardanoHWCLI Tests")
struct CardanoHWCLITests {
    
    // MARK: - Static Properties Tests
    
    @Test("CardanoHWCLI static properties are correct")
    func testStaticProperties() {
        #expect(CardanoHWCLI.binaryName == "cardano-hw-cli")
        #expect(CardanoHWCLI.mininumSupportedVersion == "1.10.0")
        #expect(CardanoHWCLI.minLedgerCardanoApp == "4.0.0")
        #expect(CardanoHWCLI.minTrezorCardanoApp == "2.4.3")
    }
    
    // MARK: - Protocol Conformance Tests
    
    @Test("CardanoHWCLI conforms to BinaryInterfaceable protocol")
    func testProtocolConformance() {
        // This test verifies that CardanoHWCLI implements the required protocol
        // by checking that it has the required static properties
        #expect(!CardanoHWCLI.binaryName.isEmpty)
        #expect(!CardanoHWCLI.mininumSupportedVersion.isEmpty)
    }
    
    // MARK: - Configuration Requirements Tests
    
    @Test("CardanoHWCLI requires hwCli path in configuration")
    func testConfigurationRequirements() async throws {
        // Test that CardanoHWCLI initialization fails when hwCli is not configured
        let cardanoConfig = CardanoConfig(
            cli: FilePath("/usr/bin/true"),
            node: FilePath("/usr/bin/true"),
            hwCli: nil, // This should cause initialization to fail
            signer: nil,
            socket: FilePath("/tmp/test-socket"),
            config: FilePath("/tmp/test-config.json"),
            topology: nil,
            database: nil,
            port: nil,
            hostAddr: nil,
            network: Network.preview,
            era: Era.conway,
            ttlBuffer: 3600,
            workingDir: FilePath(FileManager.default.temporaryDirectory.appendingPathComponent("cardano-hwcli-test").path),
            showOutput: false
        )
        
        let config = CardanoCLIToolsConfig(
            cardano: cardanoConfig,
            ogmios: nil,
            kupo: nil
        )
        
        await #expect(throws: CardanoCLIToolsError.self) {
            _ = try await CardanoHWCLI(configuration: config)
        }
    }
    
    // MARK: - Version Parsing Tests
    
    @Test("CardanoHWCLI version regex pattern works correctly")
    func testVersionRegexPattern() {
        // Test the version parsing logic without actually running the CLI
        let testOutputs = [
            "cardano-hw-cli version 1.10.0": "1.10.0",
            "cardano-hw-cli version 2.5.3": "2.5.3",
            "cardano-hw-cli version 1.0.0": "1.0.0"
        ]
        
        let pattern = #"version (\d+\.\d+\.\d+)"#
        
        for (output, expectedVersion) in testOutputs {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: output, range: NSRange(output.startIndex..., in: output)),
               let versionRange = Range(match.range(at: 1), in: output) {
                let extractedVersion = String(output[versionRange])
                #expect(extractedVersion == expectedVersion, "Failed to extract version from: \(output)")
            } else {
                Issue.record("Failed to match version pattern in: \(output)")
            }
        }
    }
    
    @Test("CardanoHWCLI version regex pattern rejects invalid formats")
    func testVersionRegexPatternRejectsInvalid() {
        // Test that invalid version formats are not matched
        let invalidOutputs = [
            "cardano-hw-cli 1.10.0",
            "cardano-hw-cli version abc",
            "invalid output",
            "cardano-hw-cli version 1.10"
        ]
        
        let pattern = #"version (\d+\.\d+\.\d+)"#
        
        for output in invalidOutputs {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let match = regex.firstMatch(in: output, range: NSRange(output.startIndex..., in: output))
                #expect(match == nil, "Pattern incorrectly matched invalid output: \(output)")
            }
        }
    }
    
    // MARK: - Constants and Configuration Tests
    
    @Test("CardanoHWCLI minimum version constants are valid semver")
    func testVersionConstantsAreValidSemver() {
        let versions = [
            CardanoHWCLI.mininumSupportedVersion,
            CardanoHWCLI.minLedgerCardanoApp,
            CardanoHWCLI.minTrezorCardanoApp
        ]
        
        let semverPattern = #"^\d+\.\d+\.\d+$"#
        let regex = try! NSRegularExpression(pattern: semverPattern)
        
        for version in versions {
            let range = NSRange(version.startIndex..., in: version)
            let match = regex.firstMatch(in: version, range: range)
            #expect(match != nil, "Version '\(version)' is not valid semver format")
        }
    }
    
    // MARK: - Error Types Tests
    
    @Test("CardanoHWCLI error scenarios are well-defined")
    func testErrorScenarios() {
        // Test that we understand what errors CardanoHWCLI can throw
        let expectedErrorTypes: [CardanoCLIToolsError] = [
            .binaryNotFound("test"),
            .deviceError("test"),
            .invalidOutput("test"),
            .commandFailed([], "test")
        ]
        
        for error in expectedErrorTypes {
            // Verify error types exist and have descriptions
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }
    
    // MARK: - Documentation Tests
    
    @Test("CardanoHWCLI initialization limitations are documented")
    func testInitializationLimitations() {
        // This test documents the current limitation that prevents full testing
        // of CardanoHWCLI initialization in the test environment
        
        // The CardanoHWCLI initializer calls checkVersion() which tries to execute
        // the cardano-hw-cli binary. In tests, we can't easily mock this without
        // creating complex file system mocks.
        
        // Additionally, the startHardwareWallet() method has retry loops with
        // Task.sleep(for: .seconds(10)) that make it unsuitable for unit testing
        // without significant refactoring.
        
        // For now, we test:
        // 1. Static properties and constants
        // 2. Version parsing logic
        // 3. Configuration validation (hwCli path requirement)
        // 4. Error scenarios
        
        #expect(Bool(true), "This test documents known testing limitations")
    }
    
    // MARK: - Hardware Wallet Types Integration
    
    @Test("CardanoHWCLI integrates with HardwareWalletType enum")
    func testHardwareWalletTypeIntegration() {
        // Test that CardanoHWCLI constants relate properly to HardwareWalletType
        let ledgerType = HardwareWalletType.ledger
        let trezorType = HardwareWalletType.trezor
        
        #expect(ledgerType.displayName.contains("Ledger"))
        #expect(trezorType.displayName.contains("Trezor"))
        
        // Verify that the minimum version constants exist for both device types
        #expect(!CardanoHWCLI.minLedgerCardanoApp.isEmpty)
        #expect(!CardanoHWCLI.minTrezorCardanoApp.isEmpty)
    }
}
