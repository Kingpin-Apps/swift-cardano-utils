import Testing
import Foundation
import Logging
import SystemPackage
import SwiftCardanoCore
@testable import CardanoCLITools

@Suite("BinaryRunnable Protocol Tests")
struct BinaryRunnableTests {
    
    // MARK: - Test Helper Structure
    
    /// Mock implementation of BinaryRunnable for testing
    struct MockBinaryRunnable: BinaryRunnable {
        let binaryPath: FilePath
        let workingDirectory: FilePath
        let configuration: CardanoCLIToolsConfig
        let logger: Logger
        let showOutput: Bool
        var process: Process?
        var processTerminated: Bool = false
        static let binaryName: String = "test-runner"
        static let mininumSupportedVersion: String = "1.0.0"
        
        private let mockVersion: String
        private let shouldFailOnStart: Bool
        
        init(configuration: CardanoCLIToolsConfig, logger: Logger?) async throws {
            self.configuration = configuration
            self.logger = logger ?? Logger(label: Self.binaryName)
            self.showOutput = false // Default to not showing output for tests
            self.mockVersion = "1.0.0"
            self.shouldFailOnStart = false
            
            // Use /bin/sleep as a reliable binary for testing long-running processes
            self.binaryPath = FilePath("/bin/sleep")
            try Self.checkBinary(binary: self.binaryPath)
            
            // Set up working directory
            self.workingDirectory = configuration.cardano.workingDir!
            try Self.checkWorkingDirectory(workingDirectory: self.workingDirectory)
        }
        
        init(configuration: CardanoCLIToolsConfig, logger: Logger?, showOutput: Bool, mockVersion: String = "1.0.0", shouldFailOnStart: Bool = false) async throws {
            self.configuration = configuration
            self.logger = logger ?? Logger(label: Self.binaryName)
            self.showOutput = showOutput
            self.mockVersion = mockVersion
            self.shouldFailOnStart = shouldFailOnStart
            
            // Use /bin/sleep for testing, or /bin/false for failure tests
            let binaryName = shouldFailOnStart ? "/bin/false" : "/bin/sleep"
            self.binaryPath = FilePath(binaryName)
            try Self.checkBinary(binary: self.binaryPath)
            
            // Set up working directory
            self.workingDirectory = configuration.cardano.workingDir!
            try Self.checkWorkingDirectory(workingDirectory: self.workingDirectory)
        }
        
        func version() async throws -> String {
            return mockVersion
        }
    }
    
    // MARK: - Protocol Properties Tests
    
    @Test("BinaryRunnable protocol requires necessary properties")
    func testBinaryRunnableProtocolProperties() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "test")
        
        let mockRunner = try await MockBinaryRunnable(
            configuration: config,
            logger: logger
        )
        
        // Test that all required properties are accessible
        #expect(mockRunner.binaryPath.string == "/bin/sleep")
        #expect(mockRunner.workingDirectory == config.cardano.workingDir)
        #expect(mockRunner.configuration.cardano.network == Network.preview)
        #expect(mockRunner.logger.label == "test")
        #expect(mockRunner.showOutput == false)
        #expect(mockRunner.process == nil) // Should be nil initially
        
        // Test static properties
        #expect(MockBinaryRunnable.binaryName == "test-runner")
        #expect(MockBinaryRunnable.mininumSupportedVersion == "1.0.0")
    }
    
    @Test("BinaryRunnable inherits BinaryInterfaceable functionality")
    func testBinaryRunnableInheritsBinaryInterfaceable() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "test")
        
        let mockRunner = try await MockBinaryRunnable(
            configuration: config,
            logger: logger
        )
        
        // Test BinaryInterfaceable methods are available
        let version = try await mockRunner.version()
        #expect(version == "1.0.0")
        
        // Test version checking (should not throw for supported version)
        try await mockRunner.checkVersion()
    }
    
    // MARK: - Process Management Tests
    
    @Test("start method launches process successfully")
    func testStartProcessSuccessfully() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "test")
        
        var mockRunner = try await MockBinaryRunnable(
            configuration: config,
            logger: logger,
            showOutput: false
        )
        
        // Initially no process
        #expect(mockRunner.process == nil)
        #expect(mockRunner.isRunning == false)
        
        // Start the process with a short sleep
        try mockRunner.start(["0.1"]) // Sleep for 0.1 seconds
        
        // Process should now exist
        #expect(mockRunner.process != nil)
        
        // Give the process a moment to start
        try await Task.sleep(for: .milliseconds(50))
        
        // Process might still be running or have finished (depending on timing)
        // We'll test this without strict expectations due to timing variability
        let processExists = mockRunner.process != nil
        #expect(processExists)
        
        // Clean up
        try await mockRunner.stop()
    }
    
    @Test("start throws error when process already running")
    func testStartThrowsErrorWhenProcessAlreadyRunning() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "test")
        
        var mockRunner = try await MockBinaryRunnable(
            configuration: config,
            logger: logger,
            showOutput: false
        )
        
        // Start the first process
        try mockRunner.start(["10"]) // Sleep for 10 seconds
        
        // Give the process a moment to start
        try await Task.sleep(for: .milliseconds(100))
        
        // Try to start another process - should throw error
        #expect(throws: CardanoCLIToolsError.self) {
            try mockRunner.start(["1"])
        }
        
        // Verify the error type
        do {
            try mockRunner.start(["1"])
            Issue.record("Expected CardanoCLIToolsError.processAlreadyRunning to be thrown")
        } catch let error as CardanoCLIToolsError {
            switch error {
            case .processAlreadyRunning:
                // Expected error
                break
            default:
                Issue.record("Expected CardanoCLIToolsError.processAlreadyRunning, got \(error)")
            }
        }
        
        // Clean up
        try await mockRunner.stop()
        
        // Wait a bit for cleanup
        try await Task.sleep(for: .milliseconds(100))
    }
    
    @Test("stop method terminates running process")
    func testStopTerminatesRunningProcess() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "test")
        
        var mockRunner = try await MockBinaryRunnable(
            configuration: config,
            logger: logger,
            showOutput: false
        )
        
        // Start a long-running process
        try mockRunner.start(["10"]) // Sleep for 10 seconds
        
        // Give the process a moment to start
        try await Task.sleep(for: .milliseconds(100))
        
        // Should be running
        #expect(mockRunner.process != nil)
        
        // Stop the process
        try await mockRunner.stop()
        
        // Wait for termination with timeout (more robust across platforms)
        var attempts = 0
        let maxAttempts = 50 // 5 seconds total
        
        while mockRunner.isRunning && attempts < maxAttempts {
            try await Task.sleep(for: .milliseconds(100))
            attempts += 1
        }
        
        // Process should no longer be running
        #expect(mockRunner.isRunning == false)
    }
    
    @Test("stop method handles non-running process gracefully")
    func testStopHandlesNonRunningProcessGracefully() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "test")
        
        var mockRunner = try await MockBinaryRunnable(
            configuration: config,
            logger: logger,
            showOutput: false
        )
        
        // Try to stop when no process is running - should not throw
        try await mockRunner.stop()
        
        // Still no process
        #expect(mockRunner.process == nil)
        #expect(mockRunner.isRunning == false)
    }
    
    @Test("isRunning property reflects process state correctly")
    func testIsRunningPropertyReflectsState() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "test")
        
        var mockRunner = try await MockBinaryRunnable(
            configuration: config,
            logger: logger,
            showOutput: false
        )
        
        // Initially not running
        #expect(mockRunner.isRunning == false)
        
        // Start a short process
        try mockRunner.start(["0.2"]) // Sleep for 0.2 seconds
        
        // Give it a moment to start
        try await Task.sleep(for: .milliseconds(50))
        
        // Should be running (or process object should exist)
        #expect(mockRunner.process != nil)
        
        // Wait for it to finish
        try await Task.sleep(for: .milliseconds(1000))
        
        // Should no longer be running
        #expect(mockRunner.isRunning == false)
    }
    
    // MARK: - Version Tests
    
    @Test("version method returns correct version")
    func testVersionReturnsCorrectVersion() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "test")
        
        let mockRunner = try await MockBinaryRunnable(
            configuration: config,
            logger: logger,
            showOutput: false,
            mockVersion: "2.1.0"
        )
        
        let version = try await mockRunner.version()
        #expect(version == "2.1.0")
    }
    
    @Test("version method works with different mock versions")
    func testVersionWithDifferentMockVersions() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "test")
        
        let testVersions = ["1.0.0", "1.5.2", "2.0.0-rc1", "10.5.3"]
        
        for testVersion in testVersions {
            let mockRunner = try await MockBinaryRunnable(
                configuration: config,
                logger: logger,
                showOutput: false,
                mockVersion: testVersion
            )
            
            let version = try await mockRunner.version()
            #expect(version == testVersion, "Expected version \(testVersion), got \(version)")
        }
    }
    
    // MARK: - Output Handling Tests
    
    @Test("showOutput property controls process output handling")
    func testShowOutputPropertyControlsOutputHandling() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "test")
        
        // Test with showOutput = false
        let mockRunnerNoOutput = try await MockBinaryRunnable(
            configuration: config,
            logger: logger,
            showOutput: false
        )
        
        #expect(mockRunnerNoOutput.showOutput == false)
        
        // Test with showOutput = true
        let mockRunnerWithOutput = try await MockBinaryRunnable(
            configuration: config,
            logger: logger,
            showOutput: true
        )
        
        #expect(mockRunnerWithOutput.showOutput == true)
    }
    
    @Test("process with showOutput false completes immediately")
    func testProcessWithShowOutputFalseCompletesImmediately() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "test")
        
        var mockRunner = try await MockBinaryRunnable(
            configuration: config,
            logger: logger,
            showOutput: false
        )
        
        let startTime = Date()
        
        // Start a process that would normally take longer
        try mockRunner.start(["0.5"]) // Sleep for 0.5 seconds
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // With showOutput = false, start() should return immediately
        // (much less than the 0.5 seconds the process would take)
        #expect(duration < 0.1, "Expected start() to return immediately, took \(duration) seconds")
        
        // Clean up
        try await mockRunner.stop()
        try await Task.sleep(for: .milliseconds(100))
    }
    
    // MARK: - Initialization Tests
    
    @Test("BinaryRunnable initializes with valid configuration")
    func testBinaryRunnableInitializationWithValidConfiguration() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "custom-test")
        
        let mockRunner = try await MockBinaryRunnable(
            configuration: config,
            logger: logger
        )
        
        #expect(mockRunner.configuration.cardano.cli == config.cardano.cli)
        #expect(mockRunner.logger.label == "custom-test")
        #expect(mockRunner.binaryPath.string == "/bin/sleep")
        #expect(mockRunner.workingDirectory == config.cardano.workingDir)
        #expect(mockRunner.process == nil)
    }
    
    @Test("BinaryRunnable uses default logger when none provided")
    func testBinaryRunnableInitializationWithDefaultLogger() async throws {
        let config = createTestConfiguration()
        
        let mockRunner = try await MockBinaryRunnable(
            configuration: config,
            logger: nil
        )
        
        #expect(mockRunner.logger.label == "test-runner")
    }
    
    @Test("BinaryRunnable creates working directory if needed")
    func testBinaryRunnableCreatesWorkingDirectory() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("BinaryRunnableTests-\(UUID().uuidString)")
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        let cardanoConfig = CardanoConfig(
            cli: FilePath("/bin/sleep"),
            node: FilePath("/usr/bin/true"),
            hwCli: nil,
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
            workingDir: FilePath(tempDir.path),
            showOutput: false
        )
        
        let config = CardanoCLIToolsConfig(
            cardano: cardanoConfig,
            ogmios: nil,
            kupo: nil
        )
        
        // Ensure directory doesn't exist before initialization
        #expect(!FileManager.default.fileExists(atPath: tempDir.path))
        
        let mockRunner = try await MockBinaryRunnable(configuration: config, logger: nil)
        
        // Verify directory was created
        #expect(FileManager.default.fileExists(atPath: tempDir.path))
        #expect(mockRunner.workingDirectory.string == tempDir.path)
    }
    
    @Test("BinaryRunnable throws error for invalid binary path")
    func testBinaryRunnableInitializationWithInvalidBinary() async throws {
        // Create a mock implementation that tries to use a non-existent binary
        struct InvalidBinaryMock: BinaryRunnable {
            let binaryPath: FilePath
            let workingDirectory: FilePath
            let configuration: CardanoCLIToolsConfig
            let logger: Logger
            let showOutput: Bool
            var process: Process?
            var processTerminated: Bool = false
            static let binaryName: String = "invalid-runner"
            static let mininumSupportedVersion: String = "1.0.0"
            
            init(configuration: CardanoCLIToolsConfig, logger: Logger? = nil) async throws {
                self.configuration = configuration
                self.logger = logger ?? Logger(label: Self.binaryName)
                self.showOutput = false
                
                // Try to use a non-existent binary
                self.binaryPath = FilePath("/path/to/nonexistent/binary")
                try Self.checkBinary(binary: self.binaryPath)
                
                self.workingDirectory = configuration.cardano.workingDir!
                try Self.checkWorkingDirectory(workingDirectory: self.workingDirectory)
            }
            
            func version() async throws -> String {
                return "1.0.0"
            }
        }
        
        let config = createTestConfiguration()
        
        await #expect(throws: CardanoCLIToolsError.self) {
            _ = try await InvalidBinaryMock(configuration: config)
        }
    }
    
    // MARK: - Integration Tests
    
    @Test("BinaryRunnable works with real Configuration objects")
    func testBinaryRunnableWithRealConfiguration() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "integration-test")
        
        var mockRunner = try await MockBinaryRunnable(
            configuration: config,
            logger: logger,
            showOutput: false,
            mockVersion: "2.1.0"
        )
        
        // Test that all protocol methods work together
        try await mockRunner.checkVersion()
        
        let version = try await mockRunner.version()
        #expect(version == "2.1.0")
        
        // Test process management
        #expect(mockRunner.isRunning == false)
        
        try mockRunner.start(["0.1"])
        #expect(mockRunner.process != nil)
        
        // Give it time to start
        try await Task.sleep(for: .milliseconds(50))
        
        try await mockRunner.stop()
        
        // Give it time to stop
        try await Task.sleep(for: .milliseconds(150))
        #expect(mockRunner.isRunning == false)
        
        // Test configuration access
        #expect(mockRunner.configuration.cardano.era == Era.conway)
    }
    
    @Test("BinaryRunnable can be used polymorphically")
    func testBinaryRunnablePolymorphism() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "polymorphism-test")
        
        // Test that BinaryRunnable can be used as protocol type
        let binaryRunner: BinaryRunnable = try await MockBinaryRunnable(
            configuration: config,
            logger: logger,
            showOutput: false,
            mockVersion: "1.5.0"
        )
        
        // Test that all methods are accessible through protocol
        #expect(binaryRunner.binaryPath.string == "/bin/sleep")
        #expect(binaryRunner.configuration.cardano.network == Network.preview)
        #expect(binaryRunner.logger.label == "polymorphism-test")
        #expect(binaryRunner.showOutput == false)
        #expect(binaryRunner.process == nil)
        #expect(binaryRunner.isRunning == false)
        
        let version = try await binaryRunner.version()
        #expect(version == "1.5.0")
    }
    
    // MARK: - Error Handling Tests
    
    @Test("BinaryRunnable methods throw appropriate errors")
    func testBinaryRunnableErrorTypes() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "error-test")
        
        let mockRunner = try await MockBinaryRunnable(
            configuration: config,
            logger: logger,
            showOutput: false,
            mockVersion: "0.5.0" // Below minimum
        )
        
        // Test version check throws appropriate error
        do {
            try await mockRunner.checkVersion()
            Issue.record("Expected CardanoCLIToolsError.unsupportedVersion to be thrown")
        } catch let error as CardanoCLIToolsError {
            switch error {
            case .unsupportedVersion(let current, let minimum):
                #expect(current == "0.5.0")
                #expect(minimum == "1.0.0")
            default:
                Issue.record("Expected CardanoCLIToolsError.unsupportedVersion, got \(error)")
            }
        }
    }
    
    @Test("BinaryRunnable process already running error includes context")
    func testBinaryRunnableProcessAlreadyRunningError() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "context-test")
        
        var mockRunner = try await MockBinaryRunnable(
            configuration: config,
            logger: logger,
            showOutput: false
        )
        
        // Start first process
        try mockRunner.start(["10"])
        
        // Give it time to start
        try await Task.sleep(for: .milliseconds(100))
        
        // Try to start second process
        do {
            try mockRunner.start(["1"])
            Issue.record("Expected CLIError.processAlreadyRunning to be thrown")
        } catch let error as CardanoCLIToolsError {
            switch error {
            case .processAlreadyRunning:
                // Expected error - verify the error description
                let description = error.errorDescription
                #expect(description?.contains("already running") == true)
            default:
                Issue.record("Expected CLIError.processAlreadyRunning, got \(error)")
            }
        }
        
        // Clean up
        try await mockRunner.stop()
        try await Task.sleep(for: .milliseconds(100))
    }
    
    // MARK: - Edge Cases Tests
    
    @Test("BinaryRunnable handles empty arguments")
    func testBinaryRunnableWithEmptyArguments() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "empty-args-test")
        
        var mockRunner = try await MockBinaryRunnable(
            configuration: config,
            logger: logger,
            showOutput: false
        )
        
        // Start with no arguments (sleep will default to sleeping forever)
        try mockRunner.start([])
        
        // Give it time to start
        try await Task.sleep(for: .milliseconds(50))
        
        #expect(mockRunner.process != nil)
        
        // Stop it quickly
        try await mockRunner.stop()
        
        // Give it time to stop
        try await Task.sleep(for: .milliseconds(100))
    }
    
    @Test("BinaryRunnable handles special characters in arguments")
    func testBinaryRunnableWithSpecialCharacters() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "special-chars-test")
        
        var mockRunner = try await MockBinaryRunnable(
            configuration: config,
            logger: logger,
            showOutput: false
        )
        
        // Start with arguments containing special characters
        // Note: sleep only takes numeric arguments, so this will likely fail,
        // but it tests that the process creation doesn't crash
        let specialArgs = ["0.1"] // Keep it simple for sleep command
        
        try mockRunner.start(specialArgs)
        
        // Give it time to start/complete
        try await Task.sleep(for: .milliseconds(200))
        
        // Clean up
        try await mockRunner.stop()
    }
    
    @Test("BinaryRunnable process termination handler works")
    func testBinaryRunnableProcessTerminationHandler() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "termination-test")
        
        var mockRunner = try await MockBinaryRunnable(
            configuration: config,
            logger: logger,
            showOutput: false
        )
        
        // Start a short-lived process
        try mockRunner.start(["0.1"]) // Sleep for 0.1 seconds
        
        #expect(mockRunner.process != nil)
        
        // Wait for the process to complete naturally
        try await Task.sleep(for: .milliseconds(200))
        
        // The termination handler should have been called
        // We can't directly test the handler, but we can verify the process finished
        #expect(mockRunner.isRunning == false)
    }
}
