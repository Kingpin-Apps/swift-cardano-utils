import Testing
import Foundation
import SystemPackage
import SwiftCardanoCore
import Configuration
@testable import CardanoCLITools

@Suite("KupoConfig Tests")
struct KupoConfigTests {
    
    // MARK: - Test Helper Methods
    
    private func createMinimalConfig() -> KupoConfig {
        return KupoConfig(binary: FilePath("/usr/local/bin/kupo"))
    }
    
    private func createFullConfig() -> KupoConfig {
        return KupoConfig(
            binary: FilePath("/usr/local/bin/kupo"),
            host: "0.0.0.0",
            port: 1442,
            since: "origin",
            matches: ["addr1*", "stake1*", "*"],
            deferDbIndexes: true,
            pruneUTxO: false,
            gcInterval: 300,
            maxConcurrency: 10,
            inMemory: false,
            logLevel: "info",
            logLevelHttpServer: "warn",
            logLevelDatabase: "debug",
            logLevelConsumer: "info",
            logLevelGarbageCollector: "error",
            logLevelConfiguration: "trace",
            workingDir: FilePath("/var/lib/kupo"),
            showOutput: true
        )
    }
    
    private func createTestJSONConfig() -> String {
        return """
        {
            "kupo": {
                "binary": "/usr/local/bin/kupo",
                "host": "127.0.0.1",
                "port": 1442,
                "since": "46.120",
                "matches": ["addr1*", "stake_test*", "pool*"],
                "defer_db_indexes": false,
                "prune_utxo": true,
                "gc_interval": 600,
                "max_concurrency": 20,
                "in_memory": true,
                "log_level": "debug",
                "log_level_http_server": "info",
                "log_level_database": "warn",
                "log_level_consumer": "debug",
                "log_level_garbage_collector": "error",
                "log_level_configuration": "trace",
                "working_dir": "/opt/kupo",
                "show_output": false
            }
        }
        """
    }
    
    // MARK: - Initialization Tests
    
    @Test("KupoConfig initializes with binary path only")
    func testMinimalInitialization() {
        let config = createMinimalConfig()
        
        #expect(config.binary.string == "/usr/local/bin/kupo")
        #expect(config.host == nil)
        #expect(config.port == nil)
        #expect(config.since == nil)
        #expect(config.matches == nil)
        #expect(config.deferDbIndexes == nil)
        #expect(config.pruneUTxO == nil)
        #expect(config.gcInterval == nil)
        #expect(config.maxConcurrency == nil)
        #expect(config.inMemory == nil)
        #expect(config.logLevel == nil)
        #expect(config.workingDir == nil)
        #expect(config.showOutput == nil)
    }
    
    @Test("KupoConfig initializes with all parameters")
    func testFullInitialization() {
        let config = createFullConfig()
        
        #expect(config.binary.string == "/usr/local/bin/kupo")
        #expect(config.host == "0.0.0.0")
        #expect(config.port == 1442)
        #expect(config.since == "origin")
        #expect(config.matches == ["addr1*", "stake1*", "*"])
        #expect(config.deferDbIndexes == true)
        #expect(config.pruneUTxO == false)
        #expect(config.gcInterval == 300)
        #expect(config.maxConcurrency == 10)
        #expect(config.inMemory == false)
        #expect(config.logLevel == "info")
        #expect(config.logLevelHttpServer == "warn")
        #expect(config.logLevelDatabase == "debug")
        #expect(config.logLevelConsumer == "info")
        #expect(config.logLevelGarbageCollector == "error")
        #expect(config.logLevelConfiguration == "trace")
        #expect(config.workingDir?.string == "/var/lib/kupo")
        #expect(config.showOutput == true)
    }
    
    @Test("KupoConfig initializes with selective parameters")
    func testSelectiveInitialization() {
        let config = KupoConfig(
            binary: FilePath("/opt/kupo"),
            host: "localhost",
            port: 8080,
            since: "genesis",
            matches: ["addr_test*"],
            logLevel: "debug"
        )
        
        #expect(config.binary.string == "/opt/kupo")
        #expect(config.host == "localhost")
        #expect(config.port == 8080)
        #expect(config.since == "genesis")
        #expect(config.matches == ["addr_test*"])
        #expect(config.logLevel == "debug")
        
        // These should be nil
        #expect(config.deferDbIndexes == nil)
        #expect(config.pruneUTxO == nil)
        #expect(config.gcInterval == nil)
        #expect(config.maxConcurrency == nil)
        #expect(config.inMemory == nil)
        #expect(config.workingDir == nil)
        #expect(config.showOutput == nil)
    }
    
    // MARK: - JSON Serialization Tests
    
    @Test("KupoConfig encodes to JSON with correct keys")
    func testJSONEncoding() throws {
        let config = createFullConfig()
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(config)
        let jsonString = String(data: data, encoding: .utf8)!
        
        // Check snake_case keys are used
        #expect(jsonString.contains("\"defer_db_indexes\""))
        #expect(jsonString.contains("\"prune_utxo\""))
        #expect(jsonString.contains("\"gc_interval\""))
        #expect(jsonString.contains("\"max_concurrency\""))
        #expect(jsonString.contains("\"in_memory\""))
        #expect(jsonString.contains("\"log_level\""))
        #expect(jsonString.contains("\"log_level_http_server\""))
        #expect(jsonString.contains("\"log_level_database\""))
        #expect(jsonString.contains("\"log_level_consumer\""))
        #expect(jsonString.contains("\"log_level_garbage_collector\""))
        #expect(jsonString.contains("\"log_level_configuration\""))
        #expect(jsonString.contains("\"working_dir\""))
        #expect(jsonString.contains("\"show_output\""))
    }
    
    @Test("KupoConfig decodes from JSON correctly")
    func testJSONDecoding() throws {
        let originalConfig = createFullConfig()
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalConfig)
        
        let decoder = JSONDecoder()
        let decodedConfig = try decoder.decode(KupoConfig.self, from: data)
        
        #expect(decodedConfig.binary == originalConfig.binary)
        #expect(decodedConfig.host == originalConfig.host)
        #expect(decodedConfig.port == originalConfig.port)
        #expect(decodedConfig.since == originalConfig.since)
        #expect(decodedConfig.matches == originalConfig.matches)
        #expect(decodedConfig.deferDbIndexes == originalConfig.deferDbIndexes)
        #expect(decodedConfig.pruneUTxO == originalConfig.pruneUTxO)
        #expect(decodedConfig.gcInterval == originalConfig.gcInterval)
        #expect(decodedConfig.maxConcurrency == originalConfig.maxConcurrency)
        #expect(decodedConfig.inMemory == originalConfig.inMemory)
        #expect(decodedConfig.logLevel == originalConfig.logLevel)
        #expect(decodedConfig.logLevelHttpServer == originalConfig.logLevelHttpServer)
        #expect(decodedConfig.workingDir == originalConfig.workingDir)
        #expect(decodedConfig.showOutput == originalConfig.showOutput)
    }
    // MARK: - ConfigReader Integration Tests
    
    @Test("KupoConfig initializes from ConfigReader")
    func testConfigReaderInitialization() async throws {
        let jsonData = createTestJSONConfig()
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "test-kupo-config-\(UUID().uuidString).json"
        let tempFile = tempDir.appendingPathComponent(fileName)
        
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        try jsonData.write(to: tempFile, atomically: true, encoding: .utf8)
        
        let jsonProvider = try await JSONProvider(filePath: .init(tempFile.path))
        let configReader = ConfigReader(providers: [jsonProvider])
        
        let config = try KupoConfig(config: configReader)
        
        #expect(config.binary.string == "/usr/local/bin/kupo")
        #expect(config.host == "127.0.0.1")
        #expect(config.port == 1442)
        #expect(config.since == "46.120")
        #expect(config.matches == ["addr1*", "stake_test*", "pool*"])
        #expect(config.deferDbIndexes == false)
        #expect(config.pruneUTxO == true)
        #expect(config.gcInterval == 600)
        #expect(config.maxConcurrency == 20)
        #expect(config.inMemory == true)
        #expect(config.logLevel == "debug")
        #expect(config.logLevelHttpServer == "info")
        #expect(config.logLevelDatabase == "warn")
        #expect(config.logLevelConsumer == "debug")
        #expect(config.logLevelGarbageCollector == "error")
        #expect(config.logLevelConfiguration == "trace")
        #expect(config.workingDir?.string == "/opt/kupo")
        #expect(config.showOutput == false)
    }
    
    // MARK: - Match Pattern Tests
    
    @Test("KupoConfig handles various match patterns")
    func testMatchPatterns() throws {
        let patterns = [
            ["*"],                    // Match all
            ["addr1*"],              // Mainnet addresses
            ["addr_test*"],          // Testnet addresses
            ["stake1*"],             // Stake addresses
            ["pool*"],               // Pool addresses
            ["asset*"],              // Asset patterns
            ["addr1*", "stake1*"],   // Multiple patterns
            ["*/policyId"],          // Policy-specific patterns
            []                       // Empty patterns
        ]
        
        for pattern in patterns {
            let config = KupoConfig(
                binary: FilePath("/usr/bin/kupo"),
                matches: pattern.isEmpty ? nil : pattern
            )
            
            if pattern.isEmpty {
                #expect(config.matches == nil)
            } else {
                #expect(config.matches == pattern)
            }
        }
    }
    
    // MARK: - Since Parameter Tests
    
    @Test("KupoConfig handles various 'since' parameters")
    func testSinceParameters() throws {
        let sinceValues = [
            "origin",           // From genesis
            "genesis",          // Alternative genesis
            "46.120",          // Specific slot
            "1234567",         // Numeric slot
            "0",               // Genesis slot
            "latest"           // Start from current tip
        ]
        
        for sinceValue in sinceValues {
            let config = KupoConfig(
                binary: FilePath("/usr/bin/kupo"),
                since: sinceValue
            )
            
            #expect(config.since == sinceValue)
        }
    }
    
    // MARK: - Boolean Configuration Tests
    
    @Test("KupoConfig handles all boolean flags")
    func testBooleanFlags() throws {
        let config = KupoConfig(
            binary: FilePath("/usr/bin/kupo"),
            deferDbIndexes: true,
            pruneUTxO: false,
            inMemory: true,
            showOutput: false
        )
        
        #expect(config.deferDbIndexes == true)
        #expect(config.pruneUTxO == false)
        #expect(config.inMemory == true)
        #expect(config.showOutput == false)
    }
    
    @Test("KupoConfig handles mixed boolean configurations")
    func testMixedBooleanConfigurations() throws {
        let configurations = [
            (deferValue: true, prune: true, memory: false, output: true),
            (deferValue: false, prune: false, memory: true, output: false),
            (deferValue: true, prune: false, memory: true, output: true),
            (deferValue: false, prune: true, memory: false, output: false)
        ]
        
        for (deferValue, prune, memory, output) in configurations {
            let config = KupoConfig(
                binary: FilePath("/usr/bin/kupo"),
                deferDbIndexes: deferValue,
                pruneUTxO: prune,
                inMemory: memory,
                showOutput: output
            )
            
            #expect(config.deferDbIndexes == deferValue)
            #expect(config.pruneUTxO == prune)
            #expect(config.inMemory == memory)
            #expect(config.showOutput == output)
        }
    }
    
    // MARK: - Performance Configuration Tests
    
    @Test("KupoConfig handles garbage collection intervals")
    func testGarbageCollectionIntervals() throws {
        let intervals = [60, 300, 600, 1800, 3600, 7200] // 1min to 2hrs
        
        for interval in intervals {
            let config = KupoConfig(
                binary: FilePath("/usr/bin/kupo"),
                gcInterval: interval
            )
            
            #expect(config.gcInterval == interval)
        }
    }
    
    @Test("KupoConfig handles max concurrency values")
    func testMaxConcurrencyValues() throws {
        let concurrencyValues = [1, 5, 10, 20, 50, 100]
        
        for concurrency in concurrencyValues {
            let config = KupoConfig(
                binary: FilePath("/usr/bin/kupo"),
                maxConcurrency: concurrency
            )
            
            #expect(config.maxConcurrency == concurrency)
        }
    }
    
    // MARK: - Log Level Tests
    
    @Test("KupoConfig handles all log levels")
    func testLogLevels() throws {
        let logLevels = ["trace", "debug", "info", "warn", "error", "off"]
        
        for level in logLevels {
            let config = KupoConfig(
                binary: FilePath("/usr/bin/kupo"),
                logLevel: level,
                logLevelHttpServer: level,
                logLevelDatabase: level,
                logLevelConsumer: level,
                logLevelGarbageCollector: level,
                logLevelConfiguration: level
            )
            
            #expect(config.logLevel == level)
            #expect(config.logLevelHttpServer == level)
            #expect(config.logLevelDatabase == level)
            #expect(config.logLevelConsumer == level)
            #expect(config.logLevelGarbageCollector == level)
            #expect(config.logLevelConfiguration == level)
        }
    }
    
    @Test("KupoConfig handles mixed log levels")
    func testMixedLogLevels() {
        let config = KupoConfig(
            binary: FilePath("/usr/bin/kupo"),
            logLevel: "info",
            logLevelHttpServer: "warn",
            logLevelDatabase: "debug",
            logLevelConsumer: "error",
            logLevelGarbageCollector: "trace",
            logLevelConfiguration: "off"
        )
        
        #expect(config.logLevel == "info")
        #expect(config.logLevelHttpServer == "warn")
        #expect(config.logLevelDatabase == "debug")
        #expect(config.logLevelConsumer == "error")
        #expect(config.logLevelGarbageCollector == "trace")
        #expect(config.logLevelConfiguration == "off")
    }
    
    // MARK: - Network Configuration Tests
    
    @Test("KupoConfig handles various host configurations")
    func testHostConfigurations() throws {
        let hosts = [
            "0.0.0.0",          // All interfaces
            "127.0.0.1",        // Localhost
            "::1",              // IPv6 localhost
            "::",               // IPv6 all interfaces
            "localhost",        // Hostname
            "kupo.local",       // Custom hostname
            "192.168.1.100"     // Specific IP
        ]
        
        for host in hosts {
            let config = KupoConfig(
                binary: FilePath("/usr/bin/kupo"),
                host: host
            )
            
            #expect(config.host == host)
        }
    }
    
    @Test("KupoConfig handles various port configurations")
    func testPortConfigurations() throws {
        let ports = [1442, 8080, 3000, 8443, 9999, 65535]
        
        for port in ports {
            let config = KupoConfig(
                binary: FilePath("/usr/bin/kupo"),
                port: port
            )
            
            #expect(config.port == port)
        }
    }
    
    // MARK: - FilePath Handling Tests
    
    @Test("KupoConfig handles various binary paths")
    func testBinaryPathHandling() throws {
        let paths = [
            "/usr/local/bin/kupo",
            "/opt/cardano/bin/kupo",
            "./kupo",
            "../bin/kupo",
            "~/bin/kupo",
            "/usr/bin/kupo"
        ]
        
        for path in paths {
            let config = KupoConfig(binary: FilePath(path))
            #expect(config.binary.string == path)
        }
    }
    
    @Test("KupoConfig handles working directory paths")
    func testWorkingDirectoryHandling() throws {
        let workingDirs = [
            "/tmp/kupo",
            "/opt/kupo",
            "./kupo-data",
            "../kupo.db",
            "/var/lib/kupo"
        ]
        
        for workDir in workingDirs {
            let config = KupoConfig(
                binary: FilePath("/usr/bin/kupo"),
                workingDir: FilePath(workDir)
            )
            
            #expect(config.workingDir?.string == workDir)
        }
    }
    
    // MARK: - Edge Cases and Error Handling Tests
    
    @Test("KupoConfig handles empty binary path")
    func testEmptyBinaryPath() {
        let config = KupoConfig(binary: FilePath(""))
        #expect(config.binary.string == "")
    }
    
    @Test("KupoConfig handles zero values")
    func testZeroValues() throws {
        let config = KupoConfig(
            binary: FilePath("/usr/bin/kupo"),
            port: 0,
            gcInterval: 0,
            maxConcurrency: 0
        )
        
        #expect(config.port == 0)
        #expect(config.gcInterval == 0)
        #expect(config.maxConcurrency == 0)
    }
    
    @Test("KupoConfig handles extreme values")
    func testExtremeValues() throws {
        let config = KupoConfig(
            binary: FilePath("/usr/bin/kupo"),
            port: 65535,
            gcInterval: Int.max,
            maxConcurrency: Int.max
        )
        
        #expect(config.port == 65535)
        #expect(config.gcInterval == Int.max)
        #expect(config.maxConcurrency == Int.max)
    }
    
    // MARK: - Configuration Scenario Tests
    
    @Test("KupoConfig validates mainnet production configuration")
    func testMainnetProductionConfiguration() throws {
        let config = KupoConfig(
            binary: FilePath("/usr/local/bin/kupo"),
            host: "0.0.0.0",
            port: 1442,
            since: "origin",
            matches: ["addr1*", "stake1*"],
            deferDbIndexes: false,
            pruneUTxO: true,
            gcInterval: 3600,
            maxConcurrency: 50,
            inMemory: false,
            logLevel: "info",
            logLevelHttpServer: "warn",
            logLevelDatabase: "info",
            logLevelConsumer: "info",
            logLevelGarbageCollector: "warn",
            logLevelConfiguration: "error",
            workingDir: FilePath("/var/lib/kupo"),
            showOutput: false
        )
        
        #expect(config.host == "0.0.0.0")
        #expect(config.matches == ["addr1*", "stake1*"])
        #expect(config.pruneUTxO == true)
        #expect(config.inMemory == false)
        #expect(config.showOutput == false)
    }
    
    @Test("KupoConfig validates testnet development configuration")
    func testTestnetDevelopmentConfiguration() throws {
        let config = KupoConfig(
            binary: FilePath("./kupo"),
            host: "127.0.0.1",
            port: 1442,
            since: "origin",
            matches: ["*"],
            deferDbIndexes: true,
            pruneUTxO: false,
            gcInterval: 300,
            maxConcurrency: 5,
            inMemory: true,
            logLevel: "debug",
            logLevelHttpServer: "debug",
            logLevelDatabase: "debug",
            logLevelConsumer: "debug",
            logLevelGarbageCollector: "debug",
            logLevelConfiguration: "debug",
            workingDir: FilePath("./kupo.db"),
            showOutput: true
        )
        
        #expect(config.host == "127.0.0.1")
        #expect(config.matches == ["*"])
        #expect(config.deferDbIndexes == true)
        #expect(config.inMemory == true)
        #expect(config.logLevel == "debug")
        #expect(config.showOutput == true)
    }
    
    @Test("KupoConfig validates minimal memory configuration")
    func testMinimalMemoryConfiguration() throws {
        let config = KupoConfig(
            binary: FilePath("/usr/bin/kupo"),
            host: "127.0.0.1",
            port: 1442,
            since: "latest",
            matches: ["addr_test*"],
            deferDbIndexes: true,
            pruneUTxO: true,
            gcInterval: 60,
            maxConcurrency: 1,
            inMemory: true,
            logLevel: "error",
            showOutput: false
        )
        
        #expect(config.since == "latest")
        #expect(config.pruneUTxO == true)
        #expect(config.gcInterval == 60)
        #expect(config.maxConcurrency == 1)
        #expect(config.inMemory == true)
    }
    
    // MARK: - Serialization Round-trip Tests
    
    @Test("KupoConfig serialization round-trip preserves all data")
    func testSerializationRoundTrip() throws {
        let originalConfig = createFullConfig()
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalConfig)
        
        let decoder = JSONDecoder()
        let decodedConfig = try decoder.decode(KupoConfig.self, from: data)
        
        // Re-encode to verify everything is preserved
        let reEncodedData = try encoder.encode(decodedConfig)
        let reDecodedConfig = try decoder.decode(KupoConfig.self, from: reEncodedData)
        
        #expect(reDecodedConfig.binary == originalConfig.binary)
        #expect(reDecodedConfig.host == originalConfig.host)
        #expect(reDecodedConfig.port == originalConfig.port)
        #expect(reDecodedConfig.since == originalConfig.since)
        #expect(reDecodedConfig.matches == originalConfig.matches)
        #expect(reDecodedConfig.deferDbIndexes == originalConfig.deferDbIndexes)
        #expect(reDecodedConfig.pruneUTxO == originalConfig.pruneUTxO)
        #expect(reDecodedConfig.gcInterval == originalConfig.gcInterval)
        #expect(reDecodedConfig.maxConcurrency == originalConfig.maxConcurrency)
        #expect(reDecodedConfig.inMemory == originalConfig.inMemory)
        #expect(reDecodedConfig.logLevel == originalConfig.logLevel)
        #expect(reDecodedConfig.workingDir == originalConfig.workingDir)
        #expect(reDecodedConfig.showOutput == originalConfig.showOutput)
    }
}
