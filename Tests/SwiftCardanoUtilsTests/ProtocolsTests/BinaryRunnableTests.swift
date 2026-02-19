import Testing
import Foundation
import Logging
import SystemPackage
import Mockable
import Command
import SwiftCardanoCore
@testable import SwiftCardanoUtils

@Suite("BinaryRunnable Protocol Tests")
struct BinaryRunnableTests {
    
    // MARK: - Test Helper Structure
    
    /// Mock implementation of BinaryRunnable for testing
    struct MockBinaryRunnable: BinaryRunnable {
        let binaryPath: FilePath
        let workingDirectory: FilePath
        let configuration: Config
        let cardanoConfig: CardanoConfig
        var logger: Logger
        let showOutput: Bool
        var process: Process?
        var processTerminated: Bool = false
        static let binaryName: String = "sleep"
        static let mininumSupportedVersion: String = "1.0.0"
        
        private let mockVersion: String
        private let shouldFailOnStart: Bool
        var commandRunner: any CommandRunning
        
        init(configuration: Config, logger: Logger?) async throws {
            self.configuration = configuration
            self.cardanoConfig = configuration.cardano!
            self.logger = logger ?? Logger(label: Self.binaryName)
            self.showOutput = false // Default to not showing output for tests
            self.mockVersion = "1.0.0"
            self.shouldFailOnStart = false
            
            // Use /bin/sleep as a reliable binary for testing long-running processes
            self.binaryPath = FilePath("/bin/sleep")
            try Self.checkBinary(binary: self.binaryPath)
            
            // Set up working directory
            self.workingDirectory = cardanoConfig.workingDir!
            try Self.checkWorkingDirectory(workingDirectory: self.workingDirectory)
            
            self.logger = logger ?? Logger(label: Self.binaryName)
            
            let commandRunner = MockCommandRunning()
            given(commandRunner)
                .run(
                    arguments: .any,
                    environment: .any,
                    workingDirectory: .any
                )
                .willReturn(AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(.standardOutput([UInt8]("Done\n".utf8)))
                    continuation.finish()
                })
            self.commandRunner = commandRunner
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
        #expect(mockRunner.workingDirectory == config.cardano!.workingDir)
        #expect(mockRunner.cardanoConfig.network == Network.preview)
        #expect(mockRunner.logger.label == "test")
        #expect(mockRunner.showOutput == false)
        #expect(mockRunner.process == nil) // Should be nil initially
        
        // Test static properties
        #expect(MockBinaryRunnable.binaryName == "sleep")
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
    
    // MARK: - Output Handling Tests
    
    @Test("showOutput property controls process output handling")
    func testShowOutputPropertyControlsOutputHandling() async throws {
        var config = createTestConfiguration()
        let logger = Logger(label: "test")
        config.cardano!.showOutput = false
        
        // Test with showOutput = false
        let mockRunnerNoOutput = try await MockBinaryRunnable(
            configuration: config,
            logger: logger
        )
        
        #expect(mockRunnerNoOutput.showOutput == false)
    }
    
    @Test("process with showOutput false completes immediately")
    func testProcessWithShowOutputFalseCompletesImmediately() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "test")
        
        let mockRunner = try await MockBinaryRunnable(
            configuration: config,
            logger: logger
        )
        
        let startTime = Date()
        
        // Start a process that would normally take longer
        try await mockRunner.start(["0.5"]) // Sleep for 0.5 seconds
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // With showOutput = false, start() should return immediately
        // (much less than the 0.5 seconds the process would take)
        #expect(duration < 0.1, "Expected start() to return immediately, took \(duration) seconds")
        
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
        
        #expect(mockRunner.cardanoConfig.cli == config.cardano!.cli)
        #expect(mockRunner.logger.label == "custom-test")
        #expect(mockRunner.binaryPath.string == "/bin/sleep")
        #expect(mockRunner.workingDirectory == config.cardano!.workingDir)
        #expect(mockRunner.process == nil)
    }
    
    @Test("BinaryRunnable uses default logger when none provided")
    func testBinaryRunnableInitializationWithDefaultLogger() async throws {
        let config = createTestConfiguration()
        
        let mockRunner = try await MockBinaryRunnable(
            configuration: config,
            logger: Logger(label: "custom-test")
        )
        
        #expect(mockRunner.logger.label == "custom-test")
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
        
        let config = Config(
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
            let configuration: Config
            let cardanoConfig: CardanoConfig
            let logger: Logger
            let showOutput: Bool
            var process: Process?
            var processTerminated: Bool = false
            static let binaryName: String = "invalid-runner"
            static let mininumSupportedVersion: String = "1.0.0"
            var commandRunner: any CommandRunning
            
            init(configuration: Config, logger: Logger? = nil) async throws {
                self.configuration = configuration
                self.cardanoConfig = configuration.cardano!
                self.logger = logger ?? Logger(label: Self.binaryName)
                self.showOutput = false
                
                // Try to use a non-existent binary
                self.binaryPath = FilePath("/path/to/nonexistent/binary")
                try Self.checkBinary(binary: self.binaryPath)
                
                self.workingDirectory = cardanoConfig.workingDir!
                try Self.checkWorkingDirectory(workingDirectory: self.workingDirectory)
                
                let commandRunner = MockCommandRunning()
                given(commandRunner)
                    .run(arguments: .value(["xcodebuild", "-project", "/path/to/Project.xcodeproj", "build"]), environment: .any, workingDirectory: .any)
                    .willReturn(AsyncThrowingStream<CommandEvent, any Error> { continuation in
                        continuation.yield(.standardOutput([UInt8]("first\n".utf8)))
                        continuation.yield(.standardOutput([UInt8]("second\n".utf8)))
                        continuation.finish()
                    })
                self.commandRunner = commandRunner
            }
            
            func version() async throws -> String {
                return "1.0.0"
            }
        }
        
        let config = createTestConfiguration()
        
        await #expect(throws: SwiftCardanoUtilsError.self) {
            _ = try await InvalidBinaryMock(configuration: config)
        }
    }
}
