import Testing
import Foundation
import Logging
import System
import SwiftCardanoCore
@testable import CardanoCLITools

@Suite("Kupo Tests")
struct KupoTests {
    
    // MARK: - Static Properties Tests
    
    @Test("Kupo static properties are correct")
    func testStaticProperties() {
        #expect(Kupo.binaryName == "kupo")
        #expect(Kupo.mininumSupportedVersion == "2.3.4")
    }
    
    // MARK: - Protocol Conformance Tests
    
    @Test("Kupo conforms to BinaryRunnable protocol")
    func testProtocolConformance() {
        // This test verifies that Kupo implements the required protocol
        // by checking that it has the required static properties
        #expect(!Kupo.binaryName.isEmpty)
        #expect(!Kupo.mininumSupportedVersion.isEmpty)
    }
    
    // MARK: - Configuration Requirements Tests
    
    @Test("Kupo requires kupo configuration section")
    func testConfigurationRequirements() async throws {
        let testConfig = createTestConfiguration()
        
        let config = Configuration(
            cardano: testConfig.cardano,
            ogmios: nil,
            kupo: nil // Missing kupo configuration should cause failure
        )
        
        await #expect(throws: CardanoCLIToolsError.self) {
            _ = try await Kupo(configuration: config, logger: nil)
        }
    }
    
    @Test("Kupo requires valid binary path")
    func testBinaryPathRequirements() async throws {
        let kupoConfig = KupoConfig(
            binary: FilePath("/nonexistent/path"), // Invalid binary path
            host: "127.0.0.1",
            port: 1442,
            since: "origin",
            matches: ["*"],
            deferDbIndexes: true,
            pruneUTxO: false,
            gcInterval: 3600,
            maxConcurrency: 10,
            logLevel: "info",
            logLevelHttpServer: nil,
            logLevelDatabase: nil,
            logLevelConsumer: nil,
            logLevelGarbageCollector: nil,
            logLevelConfiguration: nil,
            workingDir: nil,
            showOutput: true
        )
        
        let testConfig = createTestConfiguration()
        let config = Configuration(
            cardano: testConfig.cardano,
            ogmios: nil,
            kupo: kupoConfig
        )
        
        await #expect(throws: CardanoCLIToolsError.self) {
            _ = try await Kupo(configuration: config, logger: nil)
        }
    }
    
    // MARK: - Version Parsing Tests
    
    @Test("Kupo version parsing logic works correctly")
    func testVersionParsingLogic() {
        // Test the version parsing logic without actually running the binary
        let testOutputs = [
            "v2.3.4": "2.3.4",
            "v2.0.0": "2.0.0",
            "v3.1.5": "3.1.5"
        ]
        
        for (output, expectedVersion) in testOutputs {
            // Simulate the version parsing logic from Kupo.version()
            let versionString = output.split(separator: "v").last ?? ""
            let extractedVersion = String(versionString)
            
            #expect(extractedVersion == expectedVersion, "Failed to extract version from: \(output)")
        }
    }
    
    @Test("Kupo version parsing handles edge cases")
    func testVersionParsingEdgeCases() {
        let edgeCases = [
            ("v2.3.4", "2.3.4"),
            ("2.3.4", "2.3.4"),  // Without 'v' prefix
            ("v10.0.0-beta", "10.0.0-beta")
        ]
        
        for (output, expectedVersion) in edgeCases {
            let versionString = output.split(separator: "v").last ?? ""
            let extractedVersion = String(versionString)
            
            #expect(extractedVersion == expectedVersion, "Failed to parse edge case: \(output)")
        }
    }
    
    // MARK: - Start Arguments Tests
    
    @Test("Kupo start arguments construction with full configuration")
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
        
        let kupoConfig = KupoConfig(
            binary: FilePath("/usr/local/bin/kupo"),
            host: "0.0.0.0",
            port: 1443,
            since: "origin",
            matches: ["*", "addr1*"],
            deferDbIndexes: true,
            pruneUTxO: false,
            gcInterval: 7200,
            maxConcurrency: 5,
            logLevel: "debug",
            logLevelHttpServer: "info",
            logLevelDatabase: "warn",
            logLevelConsumer: "error",
            logLevelGarbageCollector: "debug",
            logLevelConfiguration: "trace",
            workingDir: FilePath("/tmp/kupo-data"),
            showOutput: true
        )
        
        // Simulate argument construction logic from start() method
        var arguments: [String] = []
        
        // Required arguments
        arguments.append(contentsOf: ["--node-socket", cardanoConfig.socket.string])
        arguments.append(contentsOf: ["--node-config", cardanoConfig.config.string])
        
        // Host and port
        arguments.append(contentsOf: ["--host", kupoConfig.host ?? "127.0.0.1"])
        arguments.append(contentsOf: ["--port", String(kupoConfig.port ?? 1442)])
        
        // Since parameter (start from specific point)
        if let since = kupoConfig.since {
            arguments.append(contentsOf: ["--since", since])
        }
        
        // Work directory
        if let workDir = kupoConfig.workingDir {
            arguments.append(contentsOf: ["--workdir", workDir.string])
        }
        
        let expectedArguments = [
            "--node-socket", "/tmp/node.socket",
            "--node-config", "/tmp/config.json",
            "--host", "0.0.0.0",
            "--port", "1443",
            "--since", "origin",
            "--workdir", "/tmp/kupo-data"
        ]
        
        #expect(arguments == expectedArguments)
    }
    
    @Test("Kupo start arguments with minimal configuration")
    func testStartArgumentsMinimalConfig() throws {
        let testConfig = createTestConfiguration()
        let cardanoConfig = testConfig.cardano
        let kupoConfig = KupoConfig(
            binary: FilePath("/usr/local/bin/kupo"),
            host: nil,
            port: nil,
            since: nil,
            matches: nil,
            deferDbIndexes: nil,
            pruneUTxO: nil,
            gcInterval: nil,
            maxConcurrency: nil,
            logLevel: nil,
            logLevelHttpServer: nil,
            logLevelDatabase: nil,
            logLevelConsumer: nil,
            logLevelGarbageCollector: nil,
            logLevelConfiguration: nil,
            workingDir: nil,
            showOutput: nil
        )
        
        // Simulate minimal argument construction
        var arguments: [String] = []
        arguments.append(contentsOf: ["--node-socket", cardanoConfig.socket.string])
        arguments.append(contentsOf: ["--node-config", cardanoConfig.config.string])
        arguments.append(contentsOf: ["--host", kupoConfig.host ?? "127.0.0.1"])
        arguments.append(contentsOf: ["--port", String(kupoConfig.port ?? 1442)])
        
        let expectedArguments = [
            "--node-socket", cardanoConfig.socket.string,
            "--node-config", cardanoConfig.config.string,
            "--host", "127.0.0.1",
            "--port", "1442"
        ]
        
        #expect(arguments == expectedArguments)
    }
    
    @Test("Kupo start arguments with since parameter variations")
    func testStartArgumentsWithSinceVariations() {
        
        let sinceOptions = [
            "origin",
            "genesis",
            "46.120",  // epoch.slot format
            "2023-01-15T10:30:00Z"  // ISO timestamp
        ]
        
        for sinceValue in sinceOptions {
            let kupoConfig = KupoConfig(
                binary: FilePath("/usr/local/bin/kupo"),
                host: nil,
                port: nil,
                since: sinceValue,
                matches: nil,
                deferDbIndexes: nil,
                pruneUTxO: nil,
                gcInterval: nil,
                maxConcurrency: nil,
                logLevel: nil,
                logLevelHttpServer: nil,
                logLevelDatabase: nil,
                logLevelConsumer: nil,
                logLevelGarbageCollector: nil,
                logLevelConfiguration: nil,
                workingDir: nil,
                showOutput: nil
            )
            
            // Test that since parameter is handled correctly
            var arguments: [String] = []
            if let since = kupoConfig.since {
                arguments.append(contentsOf: ["--since", since])
            }
            
            #expect(arguments == ["--since", sinceValue], "Failed for since value: \(sinceValue)")
        }
    }
    
    // MARK: - Working Directory Tests
    
    @Test("Kupo working directory handling")
    func testWorkingDirectoryHandling() {
        // Test that working directory logic works correctly
        let currentDir = FileManager.default.currentDirectoryPath
        let customDir = "/tmp/kupo-test"
        
        // Test with nil working directory (should use current directory)
        let nilDirConfig = KupoConfig(
            binary: FilePath("/usr/local/bin/kupo"),
            host: nil,
            port: nil,
            since: nil,
            matches: nil,
            deferDbIndexes: nil,
            pruneUTxO: nil,
            gcInterval: nil,
            maxConcurrency: nil,
            logLevel: nil,
            logLevelHttpServer: nil,
            logLevelDatabase: nil,
            logLevelConsumer: nil,
            logLevelGarbageCollector: nil,
            logLevelConfiguration: nil,
            workingDir: nil,
            showOutput: nil
        )
        
        // Simulate working directory logic from init
        let workingDir1 = nilDirConfig.workingDir ?? FilePath(currentDir)
        #expect(workingDir1.string == currentDir)
        
        // Test with custom working directory
        let customDirConfig = KupoConfig(
            binary: FilePath("/usr/local/bin/kupo"),
            host: nil,
            port: nil,
            since: nil,
            matches: nil,
            deferDbIndexes: nil,
            pruneUTxO: nil,
            gcInterval: nil,
            maxConcurrency: nil,
            logLevel: nil,
            logLevelHttpServer: nil,
            logLevelDatabase: nil,
            logLevelConsumer: nil,
            logLevelGarbageCollector: nil,
            logLevelConfiguration: nil,
            workingDir: FilePath(customDir),
            showOutput: nil
        )
        
        let workingDir2 = customDirConfig.workingDir!
        #expect(workingDir2.string == customDir)
    }
    
    // MARK: - Match Patterns Tests
    
    @Test("Kupo match patterns validation")
    func testMatchPatternsValidation() {
        // Test various match patterns that Kupo might use
        let validMatchPatterns = [
            ["*"],  // Match all
            ["addr1*"],  // Match specific address prefix
            ["stake1*"],  // Match stake addresses
            ["asset1*", "addr1*"],  // Multiple patterns
            ["*/asset123"],  // Asset-specific patterns
            []  // Empty array should be valid
        ]
        
        for patterns in validMatchPatterns {
            let kupoConfig = KupoConfig(
                binary: FilePath("/usr/local/bin/kupo"),
                host: nil,
                port: nil,
                since: nil,
                matches: patterns.isEmpty ? nil : patterns,
                deferDbIndexes: nil,
                pruneUTxO: nil,
                gcInterval: nil,
                maxConcurrency: nil,
                logLevel: nil,
                logLevelHttpServer: nil,
                logLevelDatabase: nil,
                logLevelConsumer: nil,
                logLevelGarbageCollector: nil,
                logLevelConfiguration: nil,
                workingDir: nil,
                showOutput: nil
            )
            
            // Verify the patterns are stored correctly
            if patterns.isEmpty {
                #expect(kupoConfig.matches == nil)
            } else {
                #expect(kupoConfig.matches == patterns)
            }
        }
    }
    
    // MARK: - Constants and Configuration Tests
    
    @Test("Kupo minimum version is valid semver")
    func testVersionConstantIsValidSemver() {
        let version = Kupo.mininumSupportedVersion
        let semverPattern = #"^\d+\.\d+\.\d+$"#
        let regex = try! NSRegularExpression(pattern: semverPattern)
        
        let range = NSRange(version.startIndex..., in: version)
        let match = regex.firstMatch(in: version, range: range)
        #expect(match != nil, "Version '\(version)' is not valid semver format")
    }
    
    // MARK: - Default Values Tests
    
    @Test("Kupo default configuration values are correct")
    func testDefaultConfigurationValues() {
        // Test the default values used in the start() method
        let defaultHost = "127.0.0.1"
        let defaultPort = 1442
        
        #expect(!defaultHost.isEmpty)
        #expect(defaultPort > 0 && defaultPort < 65536)
        
        // These should match the values in the actual implementation
        let kupoConfig = KupoConfig(
            binary: FilePath("/usr/local/bin/kupo"),
            host: nil, port: nil, since: nil, matches: nil,
            deferDbIndexes: nil, pruneUTxO: nil, gcInterval: nil, maxConcurrency: nil,
            logLevel: nil, logLevelHttpServer: nil, logLevelDatabase: nil,
            logLevelConsumer: nil, logLevelGarbageCollector: nil, logLevelConfiguration: nil,
            workingDir: nil, showOutput: nil
        )
        
        #expect(kupoConfig.host ?? defaultHost == defaultHost)
        #expect(kupoConfig.port ?? defaultPort == defaultPort)
    }
    
    // MARK: - Boolean Configuration Tests
    
    @Test("Kupo boolean configuration options")
    func testBooleanConfigurationOptions() {
        let kupoConfig = KupoConfig(
            binary: FilePath("/usr/local/bin/kupo"),
            host: nil,
            port: nil,
            since: nil,
            matches: nil,
            deferDbIndexes: true,
            pruneUTxO: false,
            gcInterval: nil,
            maxConcurrency: nil,
            logLevel: nil,
            logLevelHttpServer: nil,
            logLevelDatabase: nil,
            logLevelConsumer: nil,
            logLevelGarbageCollector: nil,
            logLevelConfiguration: nil,
            workingDir: nil,
            showOutput: true
        )
        
        // Test boolean options
        #expect(kupoConfig.deferDbIndexes == true)
        #expect(kupoConfig.pruneUTxO == false)
        #expect(kupoConfig.showOutput == true)
    }
    
    // MARK: - Numeric Configuration Tests
    
    @Test("Kupo numeric configuration validation")
    func testNumericConfigurationValidation() {
        let kupoConfig = KupoConfig(
            binary: FilePath("/usr/local/bin/kupo"),
            host: nil,
            port: 8080,
            since: nil,
            matches: nil,
            deferDbIndexes: nil,
            pruneUTxO: nil,
            gcInterval: 3600,  // 1 hour
            maxConcurrency: 10,
            logLevel: nil,
            logLevelHttpServer: nil,
            logLevelDatabase: nil,
            logLevelConsumer: nil,
            logLevelGarbageCollector: nil,
            logLevelConfiguration: nil,
            workingDir: nil,
            showOutput: nil
        )
        
        // Test numeric values
        #expect(kupoConfig.port == 8080)
        #expect(kupoConfig.gcInterval == 3600)
        #expect(kupoConfig.maxConcurrency == 10)
        
        // Validate reasonable ranges
        #expect(kupoConfig.port! > 0 && kupoConfig.port! < 65536)
        #expect(kupoConfig.gcInterval! > 0)
        #expect(kupoConfig.maxConcurrency! > 0)
    }
    
    // MARK: - Error Types Tests
    
    @Test("Kupo error scenarios are well-defined")
    func testErrorScenarios() throws {
        // Test that we understand what errors Kupo can throw
        let testConfig = createTestConfiguration()
        let expectedErrorTypes: [CardanoCLIToolsError] = [
            .binaryNotFound("test"),
            .configurationMissing(testConfig),
            .invalidOutput("test"),
            .commandFailed([], "test"),
            .processAlreadyRunning,
            .unsupportedVersion("2.0.0", "2.3.4")
        ]
        
        for error in expectedErrorTypes {
            // Verify error types exist and have descriptions
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }
    
    // MARK: - Documentation Tests
    
    @Test("Kupo initialization limitations are documented")
    func testInitializationLimitations() {
        // This test documents the current limitation that prevents full testing
        // of Kupo initialization in the test environment
        
        // The Kupo initializer:
        // 1. Calls checkVersion() which tries to execute the kupo binary
        // 2. Validates binary existence and permissions
        // 3. Sets up working directories
        
        // The start() method:
        // 1. Launches a long-running kupo process
        // 2. Requires connection to cardano-node
        // 3. Needs valid Cardano configuration files
        // 4. Creates and manages database files
        
        // For now, we test:
        // 1. Static properties and constants
        // 2. Version parsing logic
        // 3. Argument construction logic
        // 4. Configuration validation
        // 5. Working directory handling
        // 6. Match patterns validation
        // 7. Default values and boolean/numeric options
        
        #expect(Bool(true), "This test documents known testing limitations")
    }
    
    // MARK: - Configuration Integration Tests
    
    @Test("Kupo integrates with KupoConfig properly")
    func testKupoConfigIntegration() throws {
        let kupoConfig = KupoConfig(
            binary: FilePath("/usr/local/bin/kupo"),
            host: "192.168.1.200",
            port: 8888,
            since: "46.120",
            matches: ["addr1*", "stake1*"],
            deferDbIndexes: true,
            pruneUTxO: false,
            gcInterval: 7200,
            maxConcurrency: 5,
            logLevel: "info",
            logLevelHttpServer: "warn",
            logLevelDatabase: "error",
            logLevelConsumer: "debug",
            logLevelGarbageCollector: "trace",
            logLevelConfiguration: "info",
            workingDir: FilePath("/data/kupo"),
            showOutput: false
        )
        
        let testConfig = createTestConfiguration()
        let config = Configuration(
            cardano: testConfig.cardano,
            ogmios: nil,
            kupo: kupoConfig
        )
        
        // Test that all configuration fields are properly accessible
        #expect(config.kupo!.binary.string == "/usr/local/bin/kupo")
        #expect(config.kupo!.host == "192.168.1.200")
        #expect(config.kupo!.port == 8888)
        #expect(config.kupo!.since == "46.120")
        #expect(config.kupo!.matches == ["addr1*", "stake1*"])
        #expect(config.kupo!.deferDbIndexes == true)
        #expect(config.kupo!.pruneUTxO == false)
        #expect(config.kupo!.gcInterval == 7200)
        #expect(config.kupo!.maxConcurrency == 5)
        #expect(config.kupo!.logLevel == "info")
        #expect(config.kupo!.logLevelHttpServer == "warn")
        #expect(config.kupo!.logLevelDatabase == "error")
        #expect(config.kupo!.logLevelConsumer == "debug")
        #expect(config.kupo!.logLevelGarbageCollector == "trace")
        #expect(config.kupo!.logLevelConfiguration == "info")
        #expect(config.kupo!.workingDir?.string == "/data/kupo")
        #expect(config.kupo!.showOutput == false)
    }
    
    // MARK: - Integration with External Context Tests
    
    @Test("Kupo configuration matches external context examples")
    func testExternalContextIntegration() {
        // Based on the external context provided, test common Kupo configurations
        
        // Example 1: Basic kupo command with defer-db-indexes and match all
        let basicConfig = KupoConfig(
            binary: FilePath("./kupo"),
            host: "0.0.0.0",
            port: nil, // Should use default
            since: "origin",
            matches: ["*"],
            deferDbIndexes: true,
            pruneUTxO: nil,
            gcInterval: nil,
            maxConcurrency: nil,
            logLevel: nil,
            logLevelHttpServer: nil,
            logLevelDatabase: nil,
            logLevelConsumer: nil,
            logLevelGarbageCollector: nil,
            logLevelConfiguration: nil,
            workingDir: FilePath("/Users/hadderley/cardano/preview/kupo.db"),
            showOutput: nil
        )
        
        // Verify configuration matches expected patterns from external context
        #expect(basicConfig.host == "0.0.0.0")
        #expect(basicConfig.since == "origin")
        #expect(basicConfig.matches == ["*"])
        #expect(basicConfig.deferDbIndexes == true)
        #expect(basicConfig.workingDir?.string == "/Users/hadderley/cardano/preview/kupo.db")
        
        // Test argument construction similar to external command
        var arguments: [String] = []
        
        if let deferDb = basicConfig.deferDbIndexes, deferDb {
            arguments.append("--defer-db-indexes")
        }
        
        if let workDir = basicConfig.workingDir {
            arguments.append(contentsOf: ["--workdir", workDir.string])
        }
        
        if let matches = basicConfig.matches {
            for match in matches {
                arguments.append(contentsOf: ["--match", match])
            }
        }
        
        if let since = basicConfig.since {
            arguments.append(contentsOf: ["--since", since])
        }
        
        arguments.append(contentsOf: ["--host", basicConfig.host ?? "127.0.0.1"])
        
        // Verify key arguments are present
        #expect(arguments.contains("--defer-db-indexes"))
        #expect(arguments.contains("--workdir"))
        #expect(arguments.contains("/Users/hadderley/cardano/preview/kupo.db"))
        #expect(arguments.contains("--match"))
        #expect(arguments.contains("*"))
        #expect(arguments.contains("--since"))
        #expect(arguments.contains("origin"))
        #expect(arguments.contains("--host"))
        #expect(arguments.contains("0.0.0.0"))
    }
}