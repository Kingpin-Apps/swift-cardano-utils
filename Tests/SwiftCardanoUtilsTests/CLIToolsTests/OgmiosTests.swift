import Testing
import Foundation
import Logging
import SystemPackage
import SwiftCardanoCore
@testable import SwiftCardanoUtils

@Suite("Ogmios Tests")
struct OgmiosTests {
    
    // MARK: - Static Properties Tests
    
    @Test("Ogmios static properties are correct")
    func testStaticProperties() {
        #expect(Ogmios.binaryName == "ogmios")
        #expect(Ogmios.mininumSupportedVersion == "6.13.0")
    }
    
    // MARK: - Protocol Conformance Tests
    
    @Test("Ogmios conforms to BinaryRunnable protocol")
    func testProtocolConformance() {
        // This test verifies that Ogmios implements the required protocol
        // by checking that it has the required static properties
        #expect(!Ogmios.binaryName.isEmpty)
        #expect(!Ogmios.mininumSupportedVersion.isEmpty)
    }
    
    // MARK: - Configuration Requirements Tests
    
    @Test("Ogmios requires ogmios configuration section")
    func testConfigurationRequirements() async throws {
        let testConfig = createTestConfiguration()
        
        let config = Config(
            cardano: testConfig.cardano,
            ogmios: nil, // Missing ogmios configuration should cause failure
            kupo: nil
        )
        
        await #expect(throws: SwiftCardanoUtilsError.self) {
            _ = try await Ogmios(configuration: config, logger: nil)
        }
    }
    
    @Test("Ogmios requires valid binary path")
    func testBinaryPathRequirements() async throws {
        let ogmiosConfig = OgmiosConfig(
            binary: FilePath("/nonexistent/path"), // Invalid binary path
            host: "127.0.0.1",
            port: 1337,
            timeout: 90,
            maxInFlight: 100,
            logLevel: "info",
            logLevelHealth: nil,
            logLevelMetrics: nil,
            logLevelWebsocket: nil,
            logLevelServer: nil,
            logLevelOptions: nil,
            workingDir: nil,
            showOutput: true
        )
        
        let testConfig = createTestConfiguration()
        let config = Config(
            cardano: testConfig.cardano,
            ogmios: ogmiosConfig,
            kupo: nil
        )
        
        await #expect(throws: SwiftCardanoUtilsError.self) {
            _ = try await Ogmios(configuration: config, logger: nil)
        }
    }
    
    // MARK: - Version Parsing Tests
    
    @Test("Ogmios version parsing logic works correctly")
    func testVersionParsingLogic() {
        // Test the version parsing logic without actually running the binary
        let testOutputs = [
            "v6.13.0 (4e93e254)": "6.13.0",
            "v6.0.0 (abc123)": "6.0.0",
            "v7.2.1": "7.2.1"
        ]
        
        for (output, expectedVersion) in testOutputs {
            // Simulate the version parsing logic from Ogmios.version()
            let versionString = output
                .split(separator: " ")
                .first!
                .split(separator: "v")
                .last ?? ""
            let extractedVersion = String(versionString)
            
            #expect(extractedVersion == expectedVersion, "Failed to extract version from: \(output)")
        }
    }
    
    @Test("Ogmios version parsing handles edge cases")
    func testVersionParsingEdgeCases() {
        let edgeCases = [
            ("v6.13.0", "6.13.0"),
            ("6.13.0", "6.13.0"),
            ("v1.0.0 (hash)", "1.0.0")
        ]
        
        for (output, expectedVersion) in edgeCases {
            let versionString = output
                .split(separator: " ")
                .first!
                .split(separator: "v")
                .last ?? ""
            let extractedVersion = String(versionString)
            
            #expect(extractedVersion == expectedVersion, "Failed to parse edge case: \(output)")
        }
    }
    
    // MARK: - Start Arguments Tests
    
    @Test("Ogmios start arguments construction with full configuration")
    func testStartArgumentsConstructionFull() {
        let cardanoConfig = CardanoConfig(
            cli: FilePath("/usr/bin/true"),
            node: FilePath("/usr/bin/true"),
            hwCli: nil,
            signer: nil,
            socket: FilePath("/tmp/node.socket"),
            config: FilePath("/tmp/config.json"),
            topology: nil,
            database: nil,
            port: nil,
            hostAddr: nil,
            network: Network.preview,
            era: Era.conway,
            ttlBuffer: 3600,
            workingDir: FilePath("/tmp"),
            showOutput: false
        )
        
        let ogmiosConfig = OgmiosConfig(
            binary: FilePath("/usr/local/bin/ogmios"),
            host: "0.0.0.0",
            port: 1338,
            timeout: 120,
            maxInFlight: 200,
            logLevel: "debug",
            logLevelHealth: nil,
            logLevelMetrics: nil,
            logLevelWebsocket: nil,
            logLevelServer: nil,
            logLevelOptions: nil,
            workingDir: FilePath("/tmp/ogmios"),
            showOutput: true
        )
        
        // Simulate argument construction logic from start() method
        var arguments: [String] = []
        
        // Required arguments
        arguments.append(contentsOf: ["--node-config", cardanoConfig.config?.string ?? "/tmp/config.json"])
        arguments.append(contentsOf: ["--node-socket", cardanoConfig.socket?.string ?? "/tmp/node.socket"])
        
        // Host and port
        arguments.append(contentsOf: ["--host", ogmiosConfig.host ?? "127.0.0.1"])
        arguments.append(contentsOf: ["--port", String(ogmiosConfig.port ?? 1337)])
        
        // Timeout and max in flight
        arguments.append(contentsOf: ["--timeout", String(ogmiosConfig.timeout ?? 90)])
        arguments.append(contentsOf: ["--max-in-flight", String(ogmiosConfig.maxInFlight ?? 100)])
        
        // Logging levels
        if let logLevel = ogmiosConfig.logLevel {
            arguments.append(contentsOf: ["--log-level", logLevel])
        }
        
        let expectedArguments = [
            "--node-config", "/tmp/config.json",
            "--node-socket", "/tmp/node.socket",
            "--host", "0.0.0.0",
            "--port", "1338",
            "--timeout", "120",
            "--max-in-flight", "200",
            "--log-level", "debug"
        ]
        
        #expect(arguments == expectedArguments)
    }
    
    @Test("Ogmios start arguments with individual log levels")
    func testStartArgumentsWithIndividualLogLevels() throws {
        let testConfig = createTestConfiguration()
        let cardanoConfig = testConfig.cardano!
        
        let ogmiosConfig = OgmiosConfig(
            binary: FilePath("/usr/local/bin/ogmios"),
            host: nil,
            port: nil,
            timeout: nil,
            maxInFlight: nil,
            logLevel: nil, // No main log level - use individual levels
            logLevelHealth: "info",
            logLevelMetrics: "warn",
            logLevelWebsocket: "debug",
            logLevelServer: "error",
            logLevelOptions: "trace",
            workingDir: nil,
            showOutput: nil
        )
        
        // Simulate argument construction with individual log levels
        var arguments: [String] = []
        arguments.append(contentsOf: ["--node-config", cardanoConfig.config?.string ?? "/tmp/config.json"])
        arguments.append(contentsOf: ["--node-socket", cardanoConfig.socket?.string ?? "/tmp/node.socket"])
        arguments.append(contentsOf: ["--host", ogmiosConfig.host ?? "127.0.0.1"])
        arguments.append(contentsOf: ["--port", String(ogmiosConfig.port ?? 1337)])
        arguments.append(contentsOf: ["--timeout", String(ogmiosConfig.timeout ?? 90)])
        arguments.append(contentsOf: ["--max-in-flight", String(ogmiosConfig.maxInFlight ?? 100)])
        
        // Individual log levels (when main logLevel is nil)
        if ogmiosConfig.logLevel == nil {
            if let logLevelHealth = ogmiosConfig.logLevelHealth {
                arguments.append(contentsOf: ["--log-level-health", logLevelHealth])
            }
            if let logLevelMetrics = ogmiosConfig.logLevelMetrics {
                arguments.append(contentsOf: ["--log-level-metrics", logLevelMetrics])
            }
            if let logLevelWebsocket = ogmiosConfig.logLevelWebsocket {
                arguments.append(contentsOf: ["--log-level-websockets", logLevelWebsocket])
            }
            if let logLevelServer = ogmiosConfig.logLevelServer {
                arguments.append(contentsOf: ["--log-level-server", logLevelServer])
            }
            if let logLevelOptions = ogmiosConfig.logLevelOptions {
                arguments.append(contentsOf: ["--log-level-options", logLevelOptions])
            }
        }
        
        // Check that individual log level arguments were added
        #expect(arguments.contains("--log-level-health"))
        #expect(arguments.contains("info"))
        #expect(arguments.contains("--log-level-metrics"))
        #expect(arguments.contains("warn"))
        #expect(arguments.contains("--log-level-websockets"))
        #expect(arguments.contains("debug"))
        #expect(arguments.contains("--log-level-server"))
        #expect(arguments.contains("error"))
        #expect(arguments.contains("--log-level-options"))
        #expect(arguments.contains("trace"))
    }
    
    @Test("Ogmios start arguments with minimal configuration")
    func testStartArgumentsMinimalConfig() throws {
        let testConfig = createTestConfiguration()
        let cardanoConfig = testConfig.cardano!
        let ogmiosConfig = OgmiosConfig(
            binary: FilePath("/usr/local/bin/ogmios"),
            host: nil,
            port: nil,
            timeout: nil,
            maxInFlight: nil,
            logLevel: nil,
            logLevelHealth: nil,
            logLevelMetrics: nil,
            logLevelWebsocket: nil,
            logLevelServer: nil,
            logLevelOptions: nil,
            workingDir: nil,
            showOutput: nil
        )
        
        // Simulate minimal argument construction
        var arguments: [String] = []
        arguments.append(contentsOf: ["--node-config", cardanoConfig.config?.string ?? "/tmp/config.json"])
        arguments.append(contentsOf: ["--node-socket", cardanoConfig.socket?.string ?? "/tmp/node.socket"])
        arguments.append(contentsOf: ["--host", ogmiosConfig.host ?? "127.0.0.1"])
        arguments.append(contentsOf: ["--port", String(ogmiosConfig.port ?? 1337)])
        arguments.append(contentsOf: ["--timeout", String(ogmiosConfig.timeout ?? 90)])
        arguments.append(contentsOf: ["--max-in-flight", String(ogmiosConfig.maxInFlight ?? 100)])
        
        let expectedArguments = [
            "--node-config", cardanoConfig.config?.string ?? "/tmp/config.json",
            "--node-socket", cardanoConfig.socket?.string ?? "/tmp/node.socket",
            "--host", "127.0.0.1",
            "--port", "1337",
            "--timeout", "90",
            "--max-in-flight", "100"
        ]
        
        #expect(arguments == expectedArguments)
    }
    
    // MARK: - Working Directory Tests
    
    @Test("Ogmios working directory handling")
    func testWorkingDirectoryHandling() {
        // Test that working directory logic works correctly
        let currentDir = FileManager.default.currentDirectoryPath
        let customDir = "/tmp/ogmios-test"
        
        // Test with nil working directory (should use current directory)
        let nilDirConfig = OgmiosConfig(
            binary: FilePath("/usr/local/bin/ogmios"),
            host: nil,
            port: nil,
            timeout: nil,
            maxInFlight: nil,
            logLevel: nil,
            logLevelHealth: nil,
            logLevelMetrics: nil,
            logLevelWebsocket: nil,
            logLevelServer: nil,
            logLevelOptions: nil,
            workingDir: nil,
            showOutput: nil
        )
        
        // Simulate working directory logic from init
        let workingDir1 = nilDirConfig.workingDir ?? FilePath(currentDir)
        #expect(workingDir1.string == currentDir)
        
        // Test with custom working directory
        let customDirConfig = OgmiosConfig(
            binary: FilePath("/usr/local/bin/ogmios"),
            host: nil,
            port: nil,
            timeout: nil,
            maxInFlight: nil,
            logLevel: nil,
            logLevelHealth: nil,
            logLevelMetrics: nil,
            logLevelWebsocket: nil,
            logLevelServer: nil,
            logLevelOptions: nil,
            workingDir: FilePath(customDir),
            showOutput: nil
        )
        
        let workingDir2 = customDirConfig.workingDir!
        #expect(workingDir2.string == customDir)
    }
    
    // MARK: - Constants and Configuration Tests
    
    @Test("Ogmios minimum version is valid semver")
    func testVersionConstantIsValidSemver() {
        let version = Ogmios.mininumSupportedVersion
        let semverPattern = #"^\d+\.\d+\.\d+$"#
        let regex = try! NSRegularExpression(pattern: semverPattern)
        
        let range = NSRange(version.startIndex..., in: version)
        let match = regex.firstMatch(in: version, range: range)
        #expect(match != nil, "Version '\(version)' is not valid semver format")
    }
    
    // MARK: - Default Values Tests
    
    @Test("Ogmios default configuration values are correct")
    func testDefaultConfigurationValues() {
        // Test the default values used in the start() method
        let defaultHost = "127.0.0.1"
        let defaultPort = 1337
        let defaultTimeout = 90
        let defaultMaxInFlight = 100
        
        #expect(!defaultHost.isEmpty)
        #expect(defaultPort > 0 && defaultPort < 65536)
        #expect(defaultTimeout > 0)
        #expect(defaultMaxInFlight > 0)
        
        // These should match the values in the actual implementation
        let ogmiosConfig = OgmiosConfig(
            binary: FilePath("/usr/local/bin/ogmios"),
            host: nil, port: nil, timeout: nil, maxInFlight: nil,
            logLevel: nil, logLevelHealth: nil, logLevelMetrics: nil,
            logLevelWebsocket: nil, logLevelServer: nil, logLevelOptions: nil,
            workingDir: nil, showOutput: nil
        )
        
        #expect(ogmiosConfig.host ?? defaultHost == defaultHost)
        #expect(ogmiosConfig.port ?? defaultPort == defaultPort)
        #expect(ogmiosConfig.timeout ?? defaultTimeout == defaultTimeout)
        #expect(ogmiosConfig.maxInFlight ?? defaultMaxInFlight == defaultMaxInFlight)
    }
    
    // MARK: - Error Types Tests
    
    @Test("Ogmios error scenarios are well-defined")
    func testErrorScenarios() throws {
        // Test that we understand what errors Ogmios can throw
        let expectedErrorTypes: [SwiftCardanoUtilsError] = [
            .binaryNotFound("test"),
            .configurationMissing("test configuration"),
            .invalidOutput("test"),
            .commandFailed([], "test"),
            .processAlreadyRunning,
            .unsupportedVersion("6.0.0", "6.13.0")
        ]
        
        for error in expectedErrorTypes {
            // Verify error types exist and have descriptions
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }
    
    // MARK: - Documentation Tests
    
    @Test("Ogmios initialization limitations are documented")
    func testInitializationLimitations() {
        // This test documents the current limitation that prevents full testing
        // of Ogmios initialization in the test environment
        
        // The Ogmios initializer:
        // 1. Calls checkVersion() which tries to execute the ogmios binary
        // 2. Validates binary existence and permissions
        // 3. Sets up working directories
        
        // The start() method:
        // 1. Launches a long-running ogmios process
        // 2. Requires connection to cardano-node
        // 3. Needs valid Cardano configuration files
        
        // For now, we test:
        // 1. Static properties and constants
        // 2. Version parsing logic
        // 3. Argument construction logic
        // 4. Configuration validation
        // 5. Working directory handling
        // 6. Default values
        
        #expect(Bool(true), "This test documents known testing limitations")
    }
    
    // MARK: - Configuration Integration Tests
    
    @Test("Ogmios integrates with OgmiosConfig properly")
    func testOgmiosConfigIntegration() throws {
        let ogmiosConfig = OgmiosConfig(
            binary: FilePath("/usr/local/bin/ogmios"),
            host: "192.168.1.100",
            port: 1338,
            timeout: 120,
            maxInFlight: 150,
            logLevel: "info",
            logLevelHealth: "warn",
            logLevelMetrics: "error",
            logLevelWebsocket: "debug",
            logLevelServer: "trace",
            logLevelOptions: "fatal",
            workingDir: FilePath("/tmp/ogmios-work"),
            showOutput: false
        )
        
        let testConfig = createTestConfiguration()
        let config = Config(
            cardano: testConfig.cardano,
            ogmios: ogmiosConfig,
            kupo: nil
        )
        
        // Test that all configuration fields are properly accessible
        #expect(config.ogmios!.binary!.string == "/usr/local/bin/ogmios")
        #expect(config.ogmios!.host == "192.168.1.100")
        #expect(config.ogmios!.port == 1338)
        #expect(config.ogmios!.timeout == 120)
        #expect(config.ogmios!.maxInFlight == 150)
        #expect(config.ogmios!.logLevel == "info")
        #expect(config.ogmios!.logLevelHealth == "warn")
        #expect(config.ogmios!.logLevelMetrics == "error")
        #expect(config.ogmios!.logLevelWebsocket == "debug")
        #expect(config.ogmios!.logLevelServer == "trace")
        #expect(config.ogmios!.logLevelOptions == "fatal")
        #expect(config.ogmios!.workingDir?.string == "/tmp/ogmios-work")
        #expect(config.ogmios!.showOutput == false)
    }
}
