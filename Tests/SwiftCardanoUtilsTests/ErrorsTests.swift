import Testing
import Foundation
import Logging
import SystemPackage
import SwiftCardanoCore
@testable import SwiftCardanoUtils

@Suite("SwiftCardanoUtilsError Tests")
struct SwiftCardanoUtilsErrorTests {
    
    // MARK: - binaryNotFound Error Tests
    
    @Test("binaryNotFound error case")
    func testBinaryNotFoundError() {
        let binaryPath = "/usr/bin/nonexistent-binary"
        let error = SwiftCardanoUtilsError.binaryNotFound(binaryPath)
        
        #expect(error.errorDescription == "Binary not found at: \(binaryPath)")
    }
    
    @Test("binaryNotFound error with different paths")
    func testBinaryNotFoundErrorWithDifferentPaths() {
        let testPaths = [
            "/usr/local/bin/cardano-cli",
            "/path/to/missing/binary",
            "/System/Applications/NonExistent.app",
            "",
            " ",
            "relative/path/binary"
        ]
        
        for path in testPaths {
            let error = SwiftCardanoUtilsError.binaryNotFound(path)
            let expectedMessage = "Binary not found at: \(path)"
            #expect(error.errorDescription == expectedMessage, "Failed for path: \(path)")
        }
    }
    
    // MARK: - commandFailed Error Tests
    
    @Test("commandFailed error case")
    func testCommandFailedError() {
        let command = ["cardano-cli", "query", "tip"]
        let errorMessage = "Network connection failed"
        let error = SwiftCardanoUtilsError.commandFailed(command, errorMessage)
        
        let expectedDescription = "Command failed: cardano-cli query tip. Error: Network connection failed"
        #expect(error.errorDescription == expectedDescription)
    }
    
    @Test("commandFailed error with empty command")
    func testCommandFailedErrorWithEmptyCommand() {
        let command: [String] = []
        let errorMessage = "Unknown error"
        let error = SwiftCardanoUtilsError.commandFailed(command, errorMessage)
        
        let expectedDescription = "Command failed: . Error: Unknown error"
        #expect(error.errorDescription == expectedDescription)
    }
    
    @Test("commandFailed error with single command")
    func testCommandFailedErrorWithSingleCommand() {
        let command = ["cardano-cli"]
        let errorMessage = "Invalid arguments"
        let error = SwiftCardanoUtilsError.commandFailed(command, errorMessage)
        
        let expectedDescription = "Command failed: cardano-cli. Error: Invalid arguments"
        #expect(error.errorDescription == expectedDescription)
    }
    
    @Test("commandFailed error with complex command and arguments")
    func testCommandFailedErrorWithComplexCommand() {
        let command = ["cardano-cli", "transaction", "build", "--tx-in", "abc123#0", "--tx-out", "addr_test...+1000000"]
        let errorMessage = "Insufficient funds: available 500000, required 1000000"
        let error = SwiftCardanoUtilsError.commandFailed(command, errorMessage)
        
        let expectedCommand = "cardano-cli transaction build --tx-in abc123#0 --tx-out addr_test...+1000000"
        let expectedDescription = "Command failed: \(expectedCommand). Error: \(errorMessage)"
        #expect(error.errorDescription == expectedDescription)
    }
    
    @Test("commandFailed error with special characters in command")
    func testCommandFailedErrorWithSpecialCharacters() {
        let command = ["cardano-cli", "address", "build", "--payment-verification-key", "key with spaces", "--out-file", "file@special#chars.addr"]
        let errorMessage = "File path contains invalid characters: @#"
        let error = SwiftCardanoUtilsError.commandFailed(command, errorMessage)
        
        let expectedCommand = "cardano-cli address build --payment-verification-key key with spaces --out-file file@special#chars.addr"
        let expectedDescription = "Command failed: \(expectedCommand). Error: \(errorMessage)"
        #expect(error.errorDescription == expectedDescription)
    }
    
    // MARK: - processAlreadyRunning Error Tests
    
    @Test("processAlreadyRunning error case")
    func testProcessAlreadyRunningError() {
        let error = SwiftCardanoUtilsError.processAlreadyRunning
        
        #expect(error.errorDescription == "Process is already running")
    }
    
    // MARK: - configurationMissing Error Tests
    
    @Test("configurationMissing error case")
    func testConfigurationMissingError() {
        let config = createTestConfiguration()
        let error = SwiftCardanoUtilsError.configurationMissing(config)
        
        let expectedDescription = "Configuration is missing or invalid: \(config)"
        #expect(error.errorDescription == expectedDescription)
    }
    
    @Test("configurationMissing error with different configurations")
    func testConfigurationMissingErrorWithDifferentConfigurations() {
        // Test with minimal configuration
        let minimalCardanoConfig = CardanoConfig(
            cli: FilePath("/usr/bin/cardano-cli"),
            node: FilePath("/usr/bin/cardano-node"),
            hwCli: nil,
            signer: nil,
            socket: FilePath("/tmp/cardano-node.socket"),
            config: FilePath("/tmp/config.json"),
            topology: nil,
            database: nil,
            port: nil,
            hostAddr: nil,
            network: Network.mainnet,
            era: Era.conway,
            ttlBuffer: 3600,
            workingDir: FilePath("/tmp"),
            showOutput: false
        )
        
        let configuration = Config(
            cardano: minimalCardanoConfig,
            ogmios: nil,
            kupo: nil
        )
        
        let error = SwiftCardanoUtilsError.configurationMissing(configuration)
        let expectedDescription = "Configuration is missing or invalid: \(configuration)"
        #expect(error.errorDescription == expectedDescription)
    }
    
    // MARK: - deviceError Error Tests
    
    @Test("deviceError error case")
    func testDeviceErrorError() {
        let deviceMessage = "Ledger device not found"
        let error = SwiftCardanoUtilsError.deviceError(deviceMessage)
        
        let expectedDescription = "Hardware wallet device error: \(deviceMessage)"
        #expect(error.errorDescription == expectedDescription)
    }
    
    @Test("deviceError error with various messages")
    func testDeviceErrorWithVariousMessages() {
        let testMessages = [
            "Ledger device not found",
            "Trezor connection timeout",
            "Hardware wallet locked",
            "Invalid PIN attempt",
            "Device firmware outdated",
            "USB connection error",
            "",
            "Device error: 0x6985"
        ]
        
        for message in testMessages {
            let error = SwiftCardanoUtilsError.deviceError(message)
            let expectedDescription = "Hardware wallet device error: \(message)"
            #expect(error.errorDescription == expectedDescription, "Failed for message: \(message)")
        }
    }
    
    // MARK: - invalidOutput Error Tests
    
    @Test("invalidOutput error case")
    func testInvalidOutputError() {
        let outputMessage = "Expected JSON, got plain text"
        let error = SwiftCardanoUtilsError.invalidOutput(outputMessage)
        
        let expectedDescription = "Invalid CLI output: \(outputMessage)"
        #expect(error.errorDescription == expectedDescription)
    }
    
    @Test("invalidOutput error with JSON parsing scenarios")
    func testInvalidOutputErrorWithJSONScenarios() {
        let jsonErrorMessages = [
            "Expected JSON, got plain text",
            "Missing required field 'syncProgress'",
            "Invalid JSON format: unexpected end of input",
            "Could not decode response as UTF-8",
            "Empty response from command",
            "Malformed JSON: missing closing brace",
            "Field 'epoch' expected Number, got String"
        ]
        
        for message in jsonErrorMessages {
            let error = SwiftCardanoUtilsError.invalidOutput(message)
            let expectedDescription = "Invalid CLI output: \(message)"
            #expect(error.errorDescription == expectedDescription, "Failed for message: \(message)")
        }
    }
    
    // MARK: - nodeNotSynced Error Tests
    
    @Test("nodeNotSynced error case")
    func testNodeNotSyncedError() {
        let syncProgress = 78.5
        let error = SwiftCardanoUtilsError.nodeNotSynced(syncProgress)
        
        let expectedDescription = "Node is not fully synced. Current sync progress: \(syncProgress)%"
        #expect(error.errorDescription == expectedDescription)
    }
    
    @Test("nodeNotSynced error with different sync progress values")
    func testNodeNotSyncedErrorWithDifferentProgress() {
        let progressValues: [Double] = [
            0.0,
            25.5,
            50.0,
            75.75,
            99.9,
            99.99,
            0.01,
            100.0  // Edge case: technically synced but might still trigger this error
        ]
        
        for progress in progressValues {
            let error = SwiftCardanoUtilsError.nodeNotSynced(progress)
            let expectedDescription = "Node is not fully synced. Current sync progress: \(progress)%"
            #expect(error.errorDescription == expectedDescription, "Failed for progress: \(progress)")
        }
    }
    
    // MARK: - unsupportedVersion Error Tests
    
    @Test("unsupportedVersion error case")
    func testUnsupportedVersionError() {
        let currentVersion = "7.5.2"
        let minimumVersion = "8.0.0"
        let error = SwiftCardanoUtilsError.unsupportedVersion(currentVersion, minimumVersion)
        
        let expectedDescription = "Unsupported version: \(currentVersion). Minimum required: \(minimumVersion)"
        #expect(error.errorDescription == expectedDescription)
    }
    
    @Test("unsupportedVersion error with semantic versioning scenarios")
    func testUnsupportedVersionErrorWithSemanticVersioning() {
        let versionScenarios: [(current: String, minimum: String)] = [
            ("1.0.0", "2.0.0"),
            ("1.9.9", "2.0.0"),
            ("2.0.0-beta", "2.0.0"),
            ("2.0.0-rc1", "2.0.0"),
            ("8.15.2", "8.20.0"),
            ("0.9.0", "1.0.0"),
            ("", "1.0.0"),
            ("invalid.version", "1.0.0"),
            ("1.0.0", "")
        ]
        
        for scenario in versionScenarios {
            let error = SwiftCardanoUtilsError.unsupportedVersion(scenario.current, scenario.minimum)
            let expectedDescription = "Unsupported version: \(scenario.current). Minimum required: \(scenario.minimum)"
            #expect(error.errorDescription == expectedDescription, 
                   "Failed for current: \(scenario.current), minimum: \(scenario.minimum)")
        }
    }
    
    // MARK: - invalidMultiSigConfig Error Tests
    
    @Test("invalidMultiSigConfig error case")
    func testInvalidMultiSigConfigError() {
        let configMessage = "Required signatures exceeds total signers"
        let error = SwiftCardanoUtilsError.invalidMultiSigConfig(configMessage)
        
        let expectedDescription = "Invalid multi-signature configuration: \(configMessage)"
        #expect(error.errorDescription == expectedDescription)
    }
    
    @Test("invalidMultiSigConfig error with various configuration issues")
    func testInvalidMultiSigConfigErrorWithVariousIssues() {
        let configIssues = [
            "Required signatures exceeds total signers",
            "Minimum required signatures cannot be zero",
            "Empty signer list not allowed",
            "Duplicate signer keys detected",
            "Invalid signature threshold: -1",
            "Script type 'invalidType' not supported",
            "Nested script depth exceeds maximum allowed",
            "Missing required field 'type' in script"
        ]
        
        for issue in configIssues {
            let error = SwiftCardanoUtilsError.invalidMultiSigConfig(issue)
            let expectedDescription = "Invalid multi-signature configuration: \(issue)"
            #expect(error.errorDescription == expectedDescription, "Failed for issue: \(issue)")
        }
    }
    
    // MARK: - fileNotFound Error Tests
    
    @Test("fileNotFound error case")
    func testFileNotFoundError() {
        let filePath = "/path/to/missing/file.json"
        let error = SwiftCardanoUtilsError.fileNotFound(filePath)
        
        let expectedDescription = "File not found: \(filePath)"
        #expect(error.errorDescription == expectedDescription)
    }
    
    @Test("fileNotFound error with different file paths")
    func testFileNotFoundErrorWithDifferentPaths() {
        let filePaths = [
            "/usr/local/etc/cardano/mainnet-config.json",
            "./protocol-parameters.json",
            "~/Documents/wallet.json",
            "/tmp/transaction.signed",
            "",
            "file with spaces.key",
            "/path/to/file@with#special$chars.vkey",
            "../relative/path/genesis.json"
        ]
        
        for path in filePaths {
            let error = SwiftCardanoUtilsError.fileNotFound(path)
            let expectedDescription = "File not found: \(path)"
            #expect(error.errorDescription == expectedDescription, "Failed for path: \(path)")
        }
    }
    
    // MARK: - versionMismatch Error Tests
    
    @Test("versionMismatch error case")
    func testVersionMismatchError() {
        let versionMessage = "Expected cardano-cli version 8.20.3, found 8.15.2"
        let error = SwiftCardanoUtilsError.versionMismatch(versionMessage)
        
        let expectedDescription = "Version mismatch for binary at path: \(versionMessage)"
        #expect(error.errorDescription == expectedDescription)
    }
    
    @Test("versionMismatch error with various mismatch scenarios")
    func testVersionMismatchErrorWithVariousScenarios() {
        let mismatchMessages = [
            "Expected cardano-cli version 8.20.3, found 8.15.2",
            "Binary version 1.0.0 incompatible with required 2.0.0",
            "cardano-node version mismatch: expected 8.9.0, got 8.7.3",
            "Hardware wallet CLI version too old: 1.2.3 < 1.3.0",
            "Version string could not be parsed: 'invalid-version'",
            "Binary reported version '', expected valid semver",
            "/usr/bin/cardano-cli --version failed with exit code 1"
        ]
        
        for message in mismatchMessages {
            let error = SwiftCardanoUtilsError.versionMismatch(message)
            let expectedDescription = "Version mismatch for binary at path: \(message)"
            #expect(error.errorDescription == expectedDescription, "Failed for message: \(message)")
        }
    }
    
    // MARK: - Error Protocol Conformance Tests
    
    @Test("SwiftCardanoUtilsError conforms to Error protocol")
    func testErrorProtocolConformance() {
        let error = SwiftCardanoUtilsError.binaryNotFound("/test/path")
        
        // Test that it can be thrown and caught
        do {
            throw error
        } catch {
            #expect(error is SwiftCardanoUtilsError)
            
            if let cliError = error as? SwiftCardanoUtilsError {
                switch cliError {
                case .binaryNotFound(let path):
                    #expect(path == "/test/path")
                default:
                    Issue.record("Expected binaryNotFound case")
                }
            }
        }
    }
    
    @Test("SwiftCardanoUtilsError conforms to LocalizedError protocol")
    func testLocalizedErrorProtocolConformance() {
        let testCases: [SwiftCardanoUtilsError] = [
            .binaryNotFound("/test/binary"),
            .commandFailed(["test", "command"], "test error"),
            .processAlreadyRunning,
            .configurationMissing(createTestConfiguration()),
            .deviceError("test device error"),
            .invalidOutput("test invalid output"),
            .invalidParameters("test invalid parameters"),
            .nodeNotSynced(75.0),
            .unsupportedVersion("1.0.0", "2.0.0"),
            .invalidMultiSigConfig("test config error"),
            .fileNotFound("/test/file.json"),
            .fileAlreadyExists("/test/existing-file.json"),
            .versionMismatch("test version mismatch")
        ]
        
        for error in testCases {
            // Test that errorDescription is not nil and not empty
            #expect(error.errorDescription != nil, "Error description should not be nil for case: \(error)")
            #expect(!(error.errorDescription?.isEmpty ?? true), "Error description should not be empty for case: \(error)")
        }
    }
    
    // MARK: - Error Equality Tests
    
    @Test("SwiftCardanoUtilsError equality comparison")
    func testErrorEqualityComparison() {
        // Test same error cases
        let error1 = SwiftCardanoUtilsError.binaryNotFound("/test/path")
        let error2 = SwiftCardanoUtilsError.binaryNotFound("/test/path")
        
        // Note: Swift enums with associated values don't automatically conform to Equatable
        // We test that they have the same case and values by comparing their descriptions
        #expect(error1.errorDescription == error2.errorDescription)
        
        // Test different error cases
        let error3 = SwiftCardanoUtilsError.binaryNotFound("/different/path")
        #expect(error1.errorDescription != error3.errorDescription)
        
        let error4 = SwiftCardanoUtilsError.processAlreadyRunning
        #expect(error1.errorDescription != error4.errorDescription)
    }
    
    // MARK: - Error Pattern Matching Tests
    
    @Test("SwiftCardanoUtilsError pattern matching")
    func testErrorPatternMatching() {
        let errors: [SwiftCardanoUtilsError] = [
            .binaryNotFound("/test/binary"),
            .commandFailed(["test"], "error"),
            .processAlreadyRunning,
            .configurationMissing(createTestConfiguration()),
            .deviceError("test"),
            .invalidOutput("test"),
            .invalidParameters("test"),
            .nodeNotSynced(50.0),
            .unsupportedVersion("1.0", "2.0"),
            .invalidMultiSigConfig("test"),
            .fileNotFound("/test/file"),
            .fileAlreadyExists("/test/existing-file"),
            .valueError("test"),
            .versionMismatch("test")
        ]
        
        var patternMatchCount = 0
        
        for error in errors {
            switch error {
            case .binaryNotFound:
                patternMatchCount += 1
            case .commandFailed:
                patternMatchCount += 1
            case .processAlreadyRunning:
                patternMatchCount += 1
            case .configurationMissing:
                patternMatchCount += 1
            case .deviceError:
                patternMatchCount += 1
            case .invalidOutput:
                patternMatchCount += 1
            case .invalidParameters:
                patternMatchCount += 1
            case .nodeNotSynced:
                patternMatchCount += 1
            case .unsupportedVersion:
                patternMatchCount += 1
            case .invalidMultiSigConfig:
                patternMatchCount += 1
            case .fileNotFound:
                patternMatchCount += 1
            case .fileAlreadyExists:
                patternMatchCount += 1
            case .versionMismatch:
                patternMatchCount += 1
            case .valueError:
                patternMatchCount += 1
            }
        }
        
        #expect(patternMatchCount == errors.count, "All error cases should be pattern matched")
    }
    
    // MARK: - Error Context Preservation Tests
    
    @Test("SwiftCardanoUtilsError preserves context information")
    func testErrorContextPreservation() {
        // Test that associated values are preserved correctly
        let binaryPath = "/usr/local/bin/cardano-cli"
        let binaryError = SwiftCardanoUtilsError.binaryNotFound(binaryPath)
        
        switch binaryError {
        case .binaryNotFound(let path):
            #expect(path == binaryPath)
        default:
            Issue.record("Expected binaryNotFound case")
        }
        
        let command = ["cardano-cli", "query", "tip", "--testnet-magic", "1"]
        let errorMsg = "Connection refused"
        let commandError = SwiftCardanoUtilsError.commandFailed(command, errorMsg)
        
        switch commandError {
        case .commandFailed(let cmd, let msg):
            #expect(cmd == command)
            #expect(msg == errorMsg)
        default:
            Issue.record("Expected commandFailed case")
        }
        
        let syncProgress = 87.5
        let syncError = SwiftCardanoUtilsError.nodeNotSynced(syncProgress)
        
        switch syncError {
        case .nodeNotSynced(let progress):
            #expect(progress == syncProgress)
        default:
            Issue.record("Expected nodeNotSynced case")
        }
    }
    
    // MARK: - Error Message Formatting Tests
    
    @Test("SwiftCardanoUtilsError message formatting consistency")
    func testErrorMessageFormattingConsistency() {
        // Test that all error messages follow consistent formatting patterns
        let testCases: [(error: SwiftCardanoUtilsError, expectedPrefix: String)] = [
            (.binaryNotFound("test"), "Binary not found at:"),
            (.commandFailed(["test"], "error"), "Command failed:"),
            (.processAlreadyRunning, "Process is already running"),
            (.configurationMissing(createTestConfiguration()), "Configuration is missing or invalid:"),
            (.deviceError("test"), "Hardware wallet device error:"),
            (.invalidOutput("test"), "Invalid CLI output:"),
            (.invalidParameters("test"), "Invalid parameters:"),
            (.nodeNotSynced(50.0), "Node is not fully synced."),
            (.unsupportedVersion("1.0", "2.0"), "Unsupported version:"),
            (.invalidMultiSigConfig("test"), "Invalid multi-signature configuration:"),
            (.fileNotFound("test"), "File not found:"),
            (.fileAlreadyExists("test"), "File already exists:"),
            (.valueError("test"), "Value error:"),
            (.versionMismatch("test"), "Version mismatch for binary at path:")
        ]
        
        for (error, expectedPrefix) in testCases {
            guard let description = error.errorDescription else {
                Issue.record("Error description should not be nil for: \(error)")
                continue
            }
            
            #expect(description.hasPrefix(expectedPrefix), 
                   "Error description '\(description)' should start with '\(expectedPrefix)'")
            #expect(!description.isEmpty, "Error description should not be empty")
        }
    }
    
    // MARK: - Integration with Throwing Functions Tests
    
    @Test("SwiftCardanoUtilsError integration with throwing functions")
    func testErrorIntegrationWithThrowingFunctions() async throws {
        // Test that SwiftCardanoUtilsError can be thrown and caught properly
        func mockBinaryCheck(_ path: String) async throws {
            if path.isEmpty {
                throw SwiftCardanoUtilsError.binaryNotFound(path)
            }
        }
        
        func mockCommandExecution(_ command: [String]) throws -> String {
            if command.isEmpty {
                throw SwiftCardanoUtilsError.commandFailed(command, "Empty command not allowed")
            }
            return "success"
        }
        
        func mockVersionCheck(_ current: String, _ minimum: String) async throws {
            if current < minimum {
                throw SwiftCardanoUtilsError.unsupportedVersion(current, minimum)
            }
        }
        
        // Test successful execution
        let result = try mockCommandExecution(["cardano-cli", "--version"])
        #expect(result == "success")
        
        // Test error throwing and catching
        await #expect(throws: SwiftCardanoUtilsError.self) {
            try await mockBinaryCheck("")
        }
        
        #expect(throws: SwiftCardanoUtilsError.self) {
            try mockCommandExecution([])
        }
        
        await #expect(throws: SwiftCardanoUtilsError.self) {
            try await mockVersionCheck("1.0.0", "2.0.0")
        }
        
        // Test error type checking in catch blocks
        do {
            try await mockVersionCheck("7.0.0", "8.0.0")
        } catch let error as SwiftCardanoUtilsError {
            switch error {
            case .unsupportedVersion(let current, let minimum):
                #expect(current == "7.0.0")
                #expect(minimum == "8.0.0")
            default:
                Issue.record("Expected unsupportedVersion error case")
            }
        } catch {
            Issue.record("Expected SwiftCardanoUtilsError, got: \(type(of: error))")
        }
    }
}
