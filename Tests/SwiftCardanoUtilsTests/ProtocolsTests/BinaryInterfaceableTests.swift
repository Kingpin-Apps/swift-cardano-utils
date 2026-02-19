import Testing
import Foundation
import Logging
import SystemPackage
import Mockable
import Command
import SwiftCardanoCore
@testable import SwiftCardanoUtils

@Suite("BinaryInterfaceable Protocol Tests")
struct BinaryInterfaceableTests {
    
    // MARK: - Test Helper Structure
    
    /// Mock implementation of BinaryInterfaceable for testing
    struct MockBinaryInterfaceable: BinaryInterfaceable {
        let binaryPath: FilePath
        let workingDirectory: FilePath
        let configuration: Config
        let cardanoConfig: CardanoConfig
        let logger: Logger
        static let binaryName: String = "echo"
        static let mininumSupportedVersion: String = "1.0.0"
        
        private let mockVersion: String
        private let shouldFailCommands: Bool
        var commandRunner: any CommandRunning
        
        init(configuration: Config, logger: Logger?) async throws {
            self.configuration = configuration
            self.cardanoConfig = configuration.cardano!
            self.logger = logger ?? Logger(label: Self.binaryName)
            self.mockVersion = "1.0.0"
            
            self.shouldFailCommands = false
            
            // Use /bin/echo as a reliable binary for testing
            self.binaryPath = FilePath("/bin/echo")
            try Self.checkBinary(binary: self.binaryPath)
            
            // Set up working directory
            self.workingDirectory = cardanoConfig.workingDir!
            try Self.checkWorkingDirectory(workingDirectory: self.workingDirectory)
            
            let commandRunner = MockCommandRunning()
            given(commandRunner)
                .run(
                    arguments: .value(["/bin/echo", "Hello", "World", "Test"]),
                    environment: .any,
                    workingDirectory: .any
                )
                .willReturn(AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(.standardOutput([UInt8]("Hello World Test\n".utf8)))
                    continuation.finish()
                })
            self.commandRunner = commandRunner
        }
        
        func version() async throws -> String {
            return mockVersion
        }
    }
    
    // MARK: - getBinaryPath Static Method Tests
    
    @Test("getBinaryPath finds existing binary")
    func testGetBinaryPathWithExistingBinary() async throws {
        // Test with a binary that should exist on most systems
        let echoPath = try MockBinaryInterfaceable.getBinaryPath()
        
        #expect(echoPath.string.contains("echo"))
        
        // Verify the returned path is actually executable
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: echoPath.string, isDirectory: &isDirectory)
        #expect(exists)
        #expect(!isDirectory.boolValue)
    }
    
    @Test("getBinaryPath throws error for non-existent binary")
    func testGetBinaryPathWithNonExistentBinary() async throws {
        // Create a mock class with a non-existent binary name
        struct NonExistentBinaryMock: BinaryInterfaceable {
            let binaryPath: FilePath
            let workingDirectory: FilePath
            let configuration: Config
            let cardanoConfig: CardanoConfig
            let logger: Logger
            static let binaryName: String = "nonexistent-binary-xyz123"
            static let mininumSupportedVersion: String = "1.0.0"
            var commandRunner: any CommandRunning
            
            init(configuration: Config, logger: Logger?) async throws {
                self.configuration = configuration
                self.cardanoConfig = configuration.cardano!
                self.logger = logger ?? Logger(label: Self.binaryName)
                self.binaryPath = try Self.getBinaryPath()
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
        
        #expect(throws: SwiftCardanoUtilsError.self) {
            _ = try NonExistentBinaryMock.getBinaryPath()
        }
    }
    
    @Test("getBinaryPath handles empty binary name")
    func testGetBinaryPathWithEmptyBinaryName() async throws {
        // Create a mock class with an empty binary name
        struct EmptyBinaryNameMock: BinaryInterfaceable {
            let binaryPath: FilePath
            let workingDirectory: FilePath
            let configuration: Config
            let cardanoConfig: CardanoConfig
            let logger: Logger
            static let binaryName: String = ""
            static let mininumSupportedVersion: String = "1.0.0"
            var commandRunner: any CommandRunning
            
            init(configuration: Config, logger: Logger?) async throws {
                self.configuration = configuration
                self.cardanoConfig = configuration.cardano!
                self.logger = logger ?? Logger(label: "empty-binary")
                self.binaryPath = try Self.getBinaryPath()
                self.workingDirectory = cardanoConfig.workingDir!
                try Self.checkWorkingDirectory(workingDirectory: self.workingDirectory)
                
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
                return "1.0.0"
            }
        }
        
        #expect(throws: SwiftCardanoUtilsError.self) {
            _ = try EmptyBinaryNameMock.getBinaryPath()
        }
    }
    
    // MARK: - runCommand Method Tests
    
    @Test("runCommand executes successful command")
    func testRunCommandWithSuccessfulCommand() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "test")
        
        let mockBinary = try await MockBinaryInterfaceable(
            configuration: config,
            logger: logger,
        )
        
        let result = try await mockBinary.runCommand(["Hello", "World", "Test"])
        #expect(result == "Hello World Test\n")
    }
    
    // MARK: - Initialization Tests
    
    @Test("BinaryInterfaceable initializes with valid configuration")
    func testBinaryInterfaceableInitializationWithValidConfiguration() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "custom-test")
        
        let mockBinary = try await MockBinaryInterfaceable(
            configuration: config,
            logger: logger
        )
        
        #expect(mockBinary.cardanoConfig.cli == config.cardano!.cli)
        #expect(mockBinary.logger.label == "custom-test")
        #expect(mockBinary.binaryPath.string == "/bin/echo")
        #expect(mockBinary.workingDirectory == config.cardano!.workingDir)
    }
    
    @Test("BinaryInterfaceable uses default logger when none provided")
    func testBinaryInterfaceableInitializationWithDefaultLogger() async throws {
        let config = createTestConfiguration()
        
        let mockBinary = try await MockBinaryInterfaceable(
            configuration: config,
            logger: nil
        )
        
        #expect(mockBinary.logger.label == "echo")
    }
    
    @Test("BinaryInterfaceable creates working directory if needed")
    func testBinaryInterfaceableCreatesWorkingDirectory() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("BinaryInterfaceableTests-\(UUID().uuidString)")
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        let cardanoConfig = CardanoConfig(
            cli: FilePath("/bin/echo"),
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
        
        let mockBinary = try await MockBinaryInterfaceable(configuration: config, logger: nil)
        
        // Verify directory was created
        #expect(FileManager.default.fileExists(atPath: tempDir.path))
        #expect(mockBinary.workingDirectory.string == tempDir.path)
    }
    
    @Test("BinaryInterfaceable throws error for invalid binary path")
    func testBinaryInterfaceableInitializationWithInvalidBinary() async throws {
        // Create a mock implementation that tries to use a non-existent binary
        struct InvalidBinaryMock: BinaryInterfaceable {
            let binaryPath: FilePath
            let workingDirectory: FilePath
            let configuration: Config
            let cardanoConfig: CardanoConfig
            let logger: Logger
            static let binaryName: String = "invalid-binary"
            static let mininumSupportedVersion: String = "1.0.0"
            var commandRunner: any CommandRunning
            
            init(configuration: Config, logger: Logger? = nil) async throws {
                self.configuration = configuration
                self.cardanoConfig = configuration.cardano!
                self.logger = logger ?? Logger(label: Self.binaryName)
                
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
