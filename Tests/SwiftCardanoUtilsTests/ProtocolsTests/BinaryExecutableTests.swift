import Testing
import Foundation
import Logging
import SystemPackage
import SwiftCardanoCore
import Mockable
import Command
@testable import SwiftCardanoUtils

@Suite("BinaryExecutable Protocol Tests")
struct BinaryExecutableTests {
    
    // MARK: - Test Helper Structure
    
    /// Mock implementation of BinaryExecutable for testing
    struct MockBinaryExecutable: BinaryExecutable {
        let configuration: Config
        let logger: Logger
        static let binaryName: String = "test-binary"
        static let mininumSupportedVersion: String = "1.0.0"
        var commandRunner: any CommandRunning
        
        private let mockVersion: String
        
        init(configuration: Config, logger: Logger, mockVersion: String = "1.0.0") {
            self.configuration = configuration
            self.logger = logger
            self.mockVersion = mockVersion
            
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
    
    // MARK: - Working Directory Tests
    
    @Test("checkWorkingDirectory creates directory when it doesn't exist")
    func testCheckWorkingDirectoryCreatesDirectory() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("BinaryExecutableTests-\(UUID().uuidString)")
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Ensure directory doesn't exist
        #expect(!FileManager.default.fileExists(atPath: tempDir.path))
        
        // Call checkWorkingDirectory
        try MockBinaryExecutable.checkWorkingDirectory(workingDirectory: FilePath(tempDir.path))
        
        // Verify directory was created
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: tempDir.path, isDirectory: &isDirectory)
        #expect(exists)
        #expect(isDirectory.boolValue)
    }
    
    @Test("checkWorkingDirectory succeeds when directory exists")
    func testCheckWorkingDirectoryWithExistingDirectory() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("BinaryExecutableTests-existing-\(UUID().uuidString)")
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Pre-create directory
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        #expect(FileManager.default.fileExists(atPath: tempDir.path))
        
        // Call checkWorkingDirectory - should not throw
        try MockBinaryExecutable.checkWorkingDirectory(workingDirectory: FilePath(tempDir.path))
        
        // Verify directory still exists
        #expect(FileManager.default.fileExists(atPath: tempDir.path))
    }
    
    @Test("checkWorkingDirectory creates nested directories")
    func testCheckWorkingDirectoryCreatesNestedDirectories() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("BinaryExecutableTests-nested-\(UUID().uuidString)")
            .appendingPathComponent("deep")
            .appendingPathComponent("nested")
        
        defer {
            try? FileManager.default.removeItem(at: tempDir.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent())
        }
        
        // Ensure nested directory doesn't exist
        #expect(!FileManager.default.fileExists(atPath: tempDir.path))
        
        // Call checkWorkingDirectory
        try MockBinaryExecutable.checkWorkingDirectory(workingDirectory: FilePath(tempDir.path))
        
        // Verify nested directory was created
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: tempDir.path, isDirectory: &isDirectory)
        #expect(exists)
        #expect(isDirectory.boolValue)
    }
    
    // MARK: - Binary Validation Tests
    
    @Test("checkBinary succeeds with valid executable")
    func testCheckBinaryWithValidExecutable() async throws {
        // Use /bin/echo as a known executable
        let binaryURL = URL(fileURLWithPath: "/bin/echo")
        
        // Should not throw
        try MockBinaryExecutable.checkBinary(binary: FilePath(binaryURL.path))
    }
    
    @Test("checkBinary throws error for non-existent binary")
    func testCheckBinaryWithNonExistentBinary() async throws {
        let nonExistentBinary = URL(fileURLWithPath: "/path/to/nonexistent/binary")
        
        #expect(throws: SwiftCardanoUtilsError.self) {
            try MockBinaryExecutable.checkBinary(binary: FilePath(nonExistentBinary.path))
        }
    }
    
    @Test("checkBinary throws error for directory instead of file")
    func testCheckBinaryWithDirectory() async throws {
        let directoryPath = URL(fileURLWithPath: "/tmp")
        
        #expect(throws: SwiftCardanoUtilsError.self) {
            try MockBinaryExecutable.checkBinary(binary: FilePath(directoryPath.path))
        }
    }
    
    @Test("checkBinary throws error for non-executable file")
    func testCheckBinaryWithNonExecutableFile() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let nonExecutableFile = tempDir.appendingPathComponent("non-executable-\(UUID().uuidString)")
        
        defer {
            try? FileManager.default.removeItem(at: nonExecutableFile)
        }
        
        // Create a non-executable file
        try "test content".write(to: nonExecutableFile, atomically: true, encoding: .utf8)
        
        // Remove execute permissions
        var attributes = try FileManager.default.attributesOfItem(atPath: nonExecutableFile.path)
        if let permissions = attributes[.posixPermissions] as? NSNumber {
            let newPermissions = NSNumber(value: permissions.uint16Value & ~0o111) // Remove execute bits
            attributes[.posixPermissions] = newPermissions
            try FileManager.default.setAttributes(attributes, ofItemAtPath: nonExecutableFile.path)
        }
        
        #expect(throws: SwiftCardanoUtilsError.self) {
            try MockBinaryExecutable.checkBinary(binary: FilePath(nonExecutableFile.path))
        }
    }
    
    // MARK: - Version Checking Tests
    
    @Test("checkVersion passes with supported version")
    func testCheckVersionWithSupportedVersion() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "test")
        
        let mockBinary = MockBinaryExecutable(
            configuration: config,
            logger: logger,
            mockVersion: "2.0.0" // Higher than minimum 1.0.0
        )
        
        // Should not throw
        try await mockBinary.checkVersion()
    }
    
    @Test("checkVersion passes with exact minimum version")
    func testCheckVersionWithExactMinimumVersion() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "test")
        
        let mockBinary = MockBinaryExecutable(
            configuration: config,
            logger: logger,
            mockVersion: "1.0.0" // Exactly minimum version
        )
        
        // Should not throw
        try await mockBinary.checkVersion()
    }
    
    @Test("checkVersion throws error with unsupported version")
    func testCheckVersionWithUnsupportedVersion() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "test")
        
        let mockBinary = MockBinaryExecutable(
            configuration: config,
            logger: logger,
            mockVersion: "0.9.0" // Lower than minimum 1.0.0
        )
        
        await #expect(throws: SwiftCardanoUtilsError.self) {
            try await mockBinary.checkVersion()
        }
    }
    
    @Test("checkVersion handles semantic versioning correctly", arguments: [
        ("0.9.9", false),     // Lower
        ("1.0.0", true),      // Exact match
        ("1.0.1", true),      // Patch higher
        ("1.1.0", true),      // Minor higher
        ("2.0.0", true),      // Major higher
        ("10.0.0", true),     // Much higher
        ("0.10.0", false),    // Higher minor but lower major
    ])
    func testCheckVersionWithSemanticVersioning(_ testCase: (version: String, shouldPass: Bool)) async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "test")
        
        let mockBinary = MockBinaryExecutable(
            configuration: config,
            logger: logger,
            mockVersion: testCase.version
        )
        
        if testCase.shouldPass {
            // Should not throw
            try await mockBinary.checkVersion()
        } else {
            await #expect(throws: SwiftCardanoUtilsError.self) {
                try await mockBinary.checkVersion()
            }
        }
    }
    
    // MARK: - Protocol Properties Tests
    
    @Test("BinaryExecutable protocol requires necessary static properties")
    func testBinaryExecutableProtocolProperties() async throws {
        // Test that our mock implementation has the required static properties
        #expect(MockBinaryExecutable.binaryName == "test-binary")
        #expect(MockBinaryExecutable.mininumSupportedVersion == "1.0.0")
    }
    
    @Test("BinaryExecutable protocol requires necessary instance properties")
    func testIntegrationWithRealConfiguration() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "test")
        
        let mockBinary = MockBinaryExecutable(configuration: config, logger: logger)
        
        // Test that instance properties are accessible
        #expect(mockBinary.configuration.cardano.network == Network.preview)
        #expect(mockBinary.logger.label == "test")
        
        // Test that version method is callable
        let version = try await mockBinary.version()
        #expect(version == "1.0.0")
    }
    
    // MARK: - Error Handling Tests
    
    @Test("BinaryExecutable methods throw appropriate errors")
    func testBinaryExecutableErrorTypes() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let nonExecutableFile = tempDir.appendingPathComponent("test-binary-\(UUID().uuidString)")
        
        defer {
            try? FileManager.default.removeItem(at: nonExecutableFile)
        }
        
        // Create a non-executable file
        try "test".write(to: nonExecutableFile, atomically: true, encoding: .utf8)
        
        // Test that specific error types are thrown
        do {
            try MockBinaryExecutable.checkBinary(binary: FilePath(nonExecutableFile.path))
            Issue.record("Expected CLIError.binaryNotFound to be thrown")
        } catch let error as SwiftCardanoUtilsError {
            switch error {
            case .binaryNotFound(let message):
                #expect(message.contains("test-binary"))
                #expect(message.contains("not executable"))
            default:
                Issue.record("Expected CLIError.binaryNotFound, got \(error)")
            }
        }
    }
    
    @Test("checkVersion throws specific unsupportedVersion error")
    func testCheckVersionThrowsSpecificError() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "test")
        
        let mockBinary = MockBinaryExecutable(
            configuration: config,
            logger: logger,
            mockVersion: "0.5.0"
        )
        
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
    
    // MARK: - Integration Tests
    
    @Test("BinaryExecutable works with real Configuration objects")
    func testBinaryExecutableWithRealConfiguration() async throws {
        let config = createTestConfiguration()
        let logger = Logger(label: "integration-test")
        
        let mockBinary = MockBinaryExecutable(
            configuration: config,
            logger: logger,
            mockVersion: "2.1.0"
        )
        
        // Test that all protocol methods work together
        try await mockBinary.checkVersion()
        
        let version = try await mockBinary.version()
        #expect(version == "2.1.0")
        
        // Test configuration access
        #expect(mockBinary.configuration.cardano.era == Era.conway)
    }
    
    // MARK: - Edge Cases Tests
    
    @Test("checkWorkingDirectory handles permission issues gracefully")
    func testCheckWorkingDirectoryPermissionIssues() async throws {
        // Test with /dev/null which can't be used as directory
        let invalidPath = URL(fileURLWithPath: "/dev/null/cannot-create")
        
        #expect(throws: Error.self) {
            try MockBinaryExecutable.checkWorkingDirectory(workingDirectory: FilePath(invalidPath.path))
        }
    }
}

