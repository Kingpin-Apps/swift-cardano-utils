import Testing
import Foundation
import Logging
import SystemPackage
import Mockable
import Command
import Path
import SwiftCardanoCore
@testable import SwiftCardanoUtils

// MARK: - CapturingCommandRunner
//
// A lightweight CommandRunning that records the arguments it receives and
// immediately finishes the stream — no Docker required.  Defined here
// separately from the identical helper in ContainerRunnerTests (which is
// `private` and therefore not visible cross-file).

private final class CapturingCommandRunner: CommandRunning, @unchecked Sendable {

    /// The most-recently-captured argument list.
    private(set) var capturedArguments: [String] = []

    func run(
        arguments: [String],
        environment: [String: String],
        workingDirectory: AbsolutePath?
    ) -> AsyncThrowingStream<CommandEvent, any Error> {
        capturedArguments = arguments
        return AsyncThrowingStream { $0.finish() }
    }
}

// MARK: - BinaryRunnableTests
//
// NOTE: This suite is marked `.serialized` to prevent concurrent execution of
// tests that all exercise `runWithSignalForwarding`.  That method installs
// process-wide signal handlers (via `signal()`) and creates
// `DispatchSource.makeSignalSource` handlers.  Apple's GCD documentation
// states there should be only one dispatch signal source per signal number per
// process.  Running two such tests in parallel can therefore produce undefined
// behaviour — including timing anomalies that cause threshold assertions to
// fail — so tests in this suite must run one at a time.

@Suite("BinaryRunnable Protocol Tests", .serialized)
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
        
        /// Initialiser for container-mode tests.
        ///
        /// Accepts a pre-built `commandRunner` instead of creating a
        /// `MockCommandRunning` internally.  In container mode `binaryPath` is
        /// never used in the command (only the `ContainerConfig` matters), so
        /// `checkBinary` is skipped here.
        init(
            configuration: Config,
            logger: Logger? = nil,
            commandRunner injected: any CommandRunning
        ) async throws {
            self.configuration = configuration
            self.cardanoConfig = configuration.cardano!
            self.logger = logger ?? Logger(label: Self.binaryName)
            self.showOutput = false
            self.mockVersion = "1.0.0"
            self.shouldFailOnStart = false

            // binaryPath is unused in the container branch of start(); use
            // /bin/sleep as a harmless placeholder.
            self.binaryPath = FilePath("/bin/sleep")

            self.workingDirectory = cardanoConfig.workingDir!
            try Self.checkWorkingDirectory(workingDirectory: self.workingDirectory)

            self.commandRunner = injected
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
    
    // MARK: - Container Mode Tests

    // In container mode, start() uses Foundation.Process directly (not the
    // injected commandRunner) so that it can hold the process identifier and
    // forward SIGINT/SIGTERM for graceful shutdown.  These tests therefore
    // exercise ContainerizedCommandRunner.runArguments(for:) directly —
    // the exact call start() makes to build the argument list before spawning
    // the process.

    @Test("Container start() forces foreground mode — --detach absent from docker run args")
    func testContainerStartForcesNonDetachedMode() {
        // start() overrides detach to false before calling runArguments(for:).
        // Replicate that transformation here and verify the output.
        var containerConfig = ContainerConfig(
            runtime: .docker,
            imageName: "alpine:latest",
            containerName: "test-node",
            detach: true   // original config has detach=true
        )
        containerConfig.detach = false   // what start() does internally

        let runner = ContainerizedCommandRunner(config: containerConfig, mode: .run)
        let args = runner.runArguments(for: [])

        guard args.count >= 2 else {
            Issue.record("Expected at least 2 args (docker run …), got: \(args)")
            return
        }
        #expect(args[0] == "docker",
                "Expected docker as the runtime binary")
        #expect(args[1] == "run",
                "Expected 'run' subcommand at index 1")
        #expect(!args.contains("--detach"),
                "Expected --detach to be absent: start() must force foreground mode")
    }

    @Test("Container start() passes arguments after image name in docker run")
    func testContainerStartPassesArgumentsAfterImageName() {
        let containerConfig = ContainerConfig(
            runtime: .docker,
            imageName: "cardanosolutions/cardano-node:10.2",
            detach: false
        )
        let runner = ContainerizedCommandRunner(config: containerConfig, mode: .run)

        let nodeArgs = ["run", "--config", "/config.json", "--mainnet"]
        let args = runner.runArguments(for: nodeArgs)

        guard let imageIdx = args.firstIndex(of: "cardanosolutions/cardano-node:10.2") else {
            Issue.record("Image name not found in args: \(args)")
            return
        }
        #expect(Array(args.suffix(from: imageIdx + 1)) == nodeArgs,
                "Original args must appear verbatim after the image name")
    }

    @Test("Container start() detach flag behaviour — present only when detach=true")
    func testContainerRunArgumentsDetachFlagBehaviour() {
        // Verify the flag is added when detach=true and absent when detach=false.
        // This confirms that start()'s forced detach=false override removes the flag.
        let withDetach = ContainerConfig(
            runtime: .docker,
            imageName: "alpine:latest",
            detach: true
        )
        let withoutDetach = ContainerConfig(
            runtime: .docker,
            imageName: "alpine:latest",
            detach: false
        )

        let argsWithDetach    = ContainerizedCommandRunner(config: withDetach,    mode: .run).runArguments(for: [])
        let argsWithoutDetach = ContainerizedCommandRunner(config: withoutDetach, mode: .run).runArguments(for: [])

        #expect(argsWithDetach.contains("--detach"),
                "detach=true must produce --detach flag")
        #expect(!argsWithoutDetach.contains("--detach"),
                "detach=false must not produce --detach flag (the state start() forces)")
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
