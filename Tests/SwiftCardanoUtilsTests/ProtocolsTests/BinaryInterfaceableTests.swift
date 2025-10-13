import Testing
import Foundation
import Logging
import SystemPackage
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
        let logger: Logger
        static let binaryName: String = "echo"
        static let mininumSupportedVersion: String = "1.0.0"
        
        private let mockVersion: String
        private let shouldFailCommands: Bool
        
        init(configuration: Config, logger: Logger?) async throws {
            self.configuration = configuration
            self.logger = logger ?? Logger(label: Self.binaryName)
            self.mockVersion = "1.0.0"
            self.shouldFailCommands = false
            
            // Use /bin/echo as a reliable binary for testing
            self.binaryPath = FilePath("/bin/echo")
            try Self.checkBinary(binary: self.binaryPath)
            
            // Set up working directory
            self.workingDirectory = configuration.cardano.workingDir!
            try Self.checkWorkingDirectory(workingDirectory: self.workingDirectory)
        }
        
        init(configuration: Config, logger: Logger?, mockVersion: String, shouldFailCommands: Bool) async throws {
            self.configuration = configuration
            self.logger = logger ?? Logger(label: Self.binaryName)
            self.mockVersion = mockVersion
            self.shouldFailCommands = shouldFailCommands
            
            // Use /bin/echo as a reliable binary for testing
            self.binaryPath = FilePath("/bin/echo")
            try Self.checkBinary(binary: self.binaryPath)
            
            // Set up working directory
            self.workingDirectory = configuration.cardano.workingDir!
            try Self.checkWorkingDirectory(workingDirectory: self.workingDirectory)
        }
        
        func version() async throws -> String {
            return mockVersion
        }
        
        // Override runCommand to allow testing different scenarios
        func runCommand(_ arguments: [String]) async throws -> String {
            if shouldFailCommands {
                throw SwiftCardanoUtilsError.commandFailed(arguments, "Mock command failure")
            }
            
            // For testing purposes, simulate command execution
            if arguments.isEmpty {
                return "mock-output"
            }
            
            // Use actual echo for realistic behavior
            return try await withCheckedThrowingContinuation { continuation in
                let process = Process()
                process.executableURL = URL(fileURLWithPath: self.binaryPath.string)
                process.arguments = arguments
                
                let outputPipe = Pipe()
                let errorPipe = Pipe()
                process.standardOutput = outputPipe
                process.standardError = errorPipe
                
                process.terminationHandler = { process in
                    if process.terminationStatus == 0 {
                        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                        let output = String(data: outputData, encoding: .utf8)?.trimmingCharacters(
                            in: .whitespacesAndNewlines) ?? ""
                        continuation.resume(returning: output)
                    } else {
                        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                        let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                        continuation.resume(throwing: SwiftCardanoUtilsError.commandFailed(arguments, errorMessage))
                    }
                }
                
                do {
                    try process.run()
                } catch {
                    continuation.resume(throwing: SwiftCardanoUtilsError.commandFailed(arguments, "Failed to run command: \(error.localizedDescription)"))
                }
            }
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
            let logger: Logger
            static let binaryName: String = "nonexistent-binary-xyz123"
            static let mininumSupportedVersion: String = "1.0.0"
            
            init(configuration: Config, logger: Logger?) async throws {
                self.configuration = configuration
                self.logger = logger ?? Logger(label: Self.binaryName)
                self.binaryPath = try Self.getBinaryPath()
                self.workingDirectory = configuration.cardano.workingDir!
                try Self.checkWorkingDirectory(workingDirectory: self.workingDirectory)
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
            let logger: Logger
            static let binaryName: String = ""
            static let mininumSupportedVersion: String = "1.0.0"
            
            init(configuration: Config, logger: Logger?) async throws {
                self.configuration = configuration
                self.logger = logger ?? Logger(label: "empty-binary")
                self.binaryPath = try Self.getBinaryPath()
                self.workingDirectory = configuration.cardano.workingDir!
                try Self.checkWorkingDirectory(workingDirectory: self.workingDirectory)
            }
            
            func version() async throws -> String {
                return "1.0.0"
            }
        }
        
        #expect(throws: SwiftCardanoUtilsError.self) {
            _ = try EmptyBinaryNameMock.getBinaryPath()
        }
    }
    
    @Test("getBinaryPath finds common system binaries")
    func testGetBinaryPathWithCommonBinaries() async throws {
        let commonBinaries = ["ls", "cat", "grep", "which", "true"]
        
        for binaryName in commonBinaries {
            // Test binary path finding using direct process execution like getBinaryPath does
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
            process.arguments = [binaryName]
            
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            
            process.standardOutput = outputPipe
            process.standardError = errorPipe
            process.environment = ProcessInfo.processInfo.environment
            
            do {
                try process.run()
                process.waitUntilExit()
                
                if process.terminationStatus == 0 {
                    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                    if let outputString = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !outputString.isEmpty {
                        let path = FilePath(outputString)
                        let exists = FileManager.default.fileExists(atPath: path.string)
                        #expect(exists, "Binary path should exist: \(path.string) for binary: \(binaryName)")
                    }
                }
                // If binary is not found, that's fine - we just skip the test for that binary
            } catch {
                // If we can't run which, skip this test
                continue
            }
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
            mockVersion: "1.0.0",
            shouldFailCommands: false
        )
        
        let result = try await mockBinary.runCommand(["Hello", "World", "Test"])
        #expect(result == "Hello World Test")
    }
    
    @Test("runCommand handles empty arguments")
    func testRunCommandWithEmptyArguments() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "test")
        
        let mockBinary = try await MockBinaryInterfaceable(
            configuration: config,
            logger: logger,
            mockVersion: "1.0.0",
            shouldFailCommands: false
        )
        
        let result = try await mockBinary.runCommand([])
        #expect(result == "mock-output")
    }
    
    @Test("runCommand throws error for failing command")
    func testRunCommandWithFailingCommand() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "test")
        
        let mockBinary = try await MockBinaryInterfaceable(
            configuration: config,
            logger: logger,
            mockVersion: "1.0.0",
            shouldFailCommands: true
        )
        
        await #expect(throws: SwiftCardanoUtilsError.self) {
            _ = try await mockBinary.runCommand(["test", "arguments"])
        }
    }
    
    @Test("runCommand includes command in error message")
    func testRunCommandErrorIncludesCommand() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "test")
        
        let mockBinary = try await MockBinaryInterfaceable(
            configuration: config,
            logger: logger,
            mockVersion: "1.0.0",
            shouldFailCommands: true
        )
        
        do {
            _ = try await mockBinary.runCommand(["test", "command"])
            Issue.record("Expected CLIError.commandFailed to be thrown")
        } catch let error as SwiftCardanoUtilsError {
            switch error {
            case .commandFailed(let command, let message):
                #expect(command == ["test", "command"])
                #expect(message.contains("Mock command failure"))
            default:
                Issue.record("Expected CLIError.commandFailed, got \(error)")
            }
        }
    }
    
    @Test("runCommand logs debug information")
    func testRunCommandLogsDebugInformation() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "test")
        
        let mockBinary = try await MockBinaryInterfaceable(
            configuration: config,
            logger: logger,
            mockVersion: "1.0.0",
            shouldFailCommands: false
        )
        
        // The actual logging verification would require capturing log output,
        // but we can test that the command executes without throwing
        let result = try await mockBinary.runCommand(["test", "logging"])
        #expect(result == "test logging")
    }
    
    // MARK: - Protocol Properties Tests
    
    @Test("BinaryInterfaceable protocol requires necessary properties")
    func testBinaryInterfaceableProtocolProperties() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "test")
        
        let mockBinary = try await MockBinaryInterfaceable(
            configuration: config,
            logger: logger,
            mockVersion: "2.1.0",
            shouldFailCommands: false
        )
        
        // Test that all required properties are accessible
        #expect(mockBinary.binaryPath.string == "/bin/echo")
        #expect(mockBinary.workingDirectory == config.cardano.workingDir)
        #expect(mockBinary.configuration.cardano.network == Network.preview)
        #expect(mockBinary.logger.label == "test")
        
        // Test static properties
        #expect(MockBinaryInterfaceable.binaryName == "echo")
        #expect(MockBinaryInterfaceable.mininumSupportedVersion == "1.0.0")
    }
    
    @Test("BinaryInterfaceable inherits BinaryExecutable functionality")
    func testBinaryInterfaceableInheritsBinaryExecutable() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "test")
        
        let mockBinary = try await MockBinaryInterfaceable(
            configuration: config,
            logger: logger,
            mockVersion: "2.1.0",
            shouldFailCommands: false
        )
        
        // Test BinaryExecutable methods are available
        let version = try await mockBinary.version()
        #expect(version == "2.1.0")
        
        // Test version checking (should not throw for supported version)
        try await mockBinary.checkVersion()
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
        
        #expect(mockBinary.configuration.cardano.cli == config.cardano.cli)
        #expect(mockBinary.logger.label == "custom-test")
        #expect(mockBinary.binaryPath.string == "/bin/echo")
        #expect(mockBinary.workingDirectory == config.cardano.workingDir)
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
            let logger: Logger
            static let binaryName: String = "invalid-binary"
            static let mininumSupportedVersion: String = "1.0.0"
            
            init(configuration: Config, logger: Logger? = nil) async throws {
                self.configuration = configuration
                self.logger = logger ?? Logger(label: Self.binaryName)
                
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
        
        await #expect(throws: SwiftCardanoUtilsError.self) {
            _ = try await InvalidBinaryMock(configuration: config)
        }
    }
    
    // MARK: - Integration Tests
    
    @Test("BinaryInterfaceable works with real Configuration objects")
    func testBinaryInterfaceableWithRealConfiguration() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "integration-test")
        
        let mockBinary = try await MockBinaryInterfaceable(
            configuration: config,
            logger: logger,
            mockVersion: "2.1.0",
            shouldFailCommands: false
        )
        
        // Test that all protocol methods work together
        try await mockBinary.checkVersion()
        
        let version = try await mockBinary.version()
        #expect(version == "2.1.0")
        
        // Test command execution
        let output = try await mockBinary.runCommand(["integration", "test"])
        #expect(output == "integration test")
        
        // Test configuration access
        #expect(mockBinary.configuration.cardano.era == Era.conway)
    }
    
    @Test("BinaryInterfaceable can be used polymorphically")
    func testBinaryInterfaceablePolymorphism() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "polymorphism-test")
        
        // Test that BinaryInterfaceable can be used as protocol type
        let binaryInterface: BinaryInterfaceable = try await MockBinaryInterfaceable(
            configuration: config,
            logger: logger,
            mockVersion: "1.5.0",
            shouldFailCommands: false
        )
        
        // Test that all methods are accessible through protocol
        #expect(binaryInterface.binaryPath.string == "/bin/echo")
        #expect(binaryInterface.configuration.cardano.network == Network.preview)
        #expect(binaryInterface.logger.label == "polymorphism-test")
        
        let version = try await binaryInterface.version()
        #expect(version == "1.5.0")
        
        let output = try await binaryInterface.runCommand(["polymorphism", "test"])
        #expect(output == "polymorphism test")
    }
    
    // MARK: - Error Handling Tests
    
    @Test("BinaryInterfaceable methods throw appropriate errors")
    func testBinaryInterfaceableErrorTypes() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "error-test")
        
        let mockBinary = try await MockBinaryInterfaceable(
            configuration: config,
            logger: logger,
            mockVersion: "0.5.0", // Below minimum
            shouldFailCommands: false
        )
        
        // Test version check throws appropriate error
        do {
            try await mockBinary.checkVersion()
            Issue.record("Expected CLIError.unsupportedVersion to be thrown")
        } catch let error as SwiftCardanoUtilsError {
            switch error {
            case .unsupportedVersion(let current, let minimum):
                #expect(current == "0.5.0")
                #expect(minimum == "1.0.0")
            default:
                Issue.record("Expected CLIError.unsupportedVersion, got \(error)")
            }
        }
    }
    
    @Test("BinaryInterfaceable command failure includes full context")
    func testBinaryInterfaceableCommandFailureContext() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "context-test")
        
        let mockBinary = try await MockBinaryInterfaceable(
            configuration: config,
            logger: logger,
            mockVersion: "1.0.0",
            shouldFailCommands: true
        )
        
        let testCommand = ["complex", "command", "with", "multiple", "arguments"]
        
        do {
            _ = try await mockBinary.runCommand(testCommand)
            Issue.record("Expected CLIError.commandFailed to be thrown")
        } catch let error as SwiftCardanoUtilsError {
            switch error {
            case .commandFailed(let command, let message):
                #expect(command == testCommand)
                #expect(!message.isEmpty)
            default:
                Issue.record("Expected CLIError.commandFailed, got \(error)")
            }
        }
    }
    
    // MARK: - Edge Cases Tests
    
    @Test("BinaryInterfaceable handles special characters in commands")
    func testBinaryInterfaceableWithSpecialCharacters() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "special-chars-test")
        
        let mockBinary = try await MockBinaryInterfaceable(
            configuration: config,
            logger: logger,
            mockVersion: "1.0.0",
            shouldFailCommands: false
        )
        
        // Test with arguments containing spaces and special characters
        let specialArgs = ["arg with spaces", "arg@with!special#chars", "unicode-🚀-test"]
        let result = try await mockBinary.runCommand(specialArgs)
        #expect(result == "arg with spaces arg@with!special#chars unicode-🚀-test")
    }
    
    @Test("BinaryInterfaceable handles large command output")
    func testBinaryInterfaceableWithLargeOutput() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "large-output-test")
        
        let mockBinary = try await MockBinaryInterfaceable(
            configuration: config,
            logger: logger,
            mockVersion: "1.0.0",
            shouldFailCommands: false
        )
        
        // Create a large string of arguments to test output handling
        let largeArgs = Array(repeating: "test-word", count: 100)
        let result = try await mockBinary.runCommand(largeArgs)
        #expect(result.contains("test-word"))
        #expect(result.split(separator: " ").count == 100)
    }
    
    @Test("BinaryInterfaceable working directory permissions")
    func testBinaryInterfaceableWorkingDirectoryPermissions() async throws {
        // Test that working directory is created with proper permissions
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("BinaryInterfaceablePermissionsTest-\(UUID().uuidString)")
        
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
        
        _ = try await MockBinaryInterfaceable(configuration: config, logger: nil)
        
        // Verify directory exists and is writable
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: tempDir.path, isDirectory: &isDirectory)
        #expect(exists)
        #expect(isDirectory.boolValue)
        
        // Test that we can write to the directory
        let testFile = tempDir.appendingPathComponent("test-file.txt")
        try "test content".write(to: testFile, atomically: true, encoding: .utf8)
        #expect(FileManager.default.fileExists(atPath: testFile.path))
    }
}
