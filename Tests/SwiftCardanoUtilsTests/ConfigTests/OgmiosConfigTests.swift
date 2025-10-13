import Testing
import Foundation
import SystemPackage
import SwiftCardanoCore
import Configuration
@testable import SwiftCardanoUtils

@Suite("OgmiosConfig Tests")
struct OgmiosConfigTests {
    
    // MARK: - Test Helper Methods
    
    private func createMinimalConfig() -> OgmiosConfig {
        return OgmiosConfig(binary: FilePath("/usr/local/bin/ogmios"))
    }
    
    private func createFullConfig() -> OgmiosConfig {
        return OgmiosConfig(
            binary: FilePath("/usr/local/bin/ogmios"),
            host: "0.0.0.0",
            port: 1337,
            timeout: 30,
            maxInFlight: 100,
            logLevel: "info",
            logLevelHealth: "warn",
            logLevelMetrics: "debug",
            logLevelWebsocket: "info",
            logLevelServer: "error",
            logLevelOptions: "trace",
            workingDir: FilePath("/tmp/ogmios"),
            showOutput: true
        )
    }
    
    private func createTestJSONConfig() -> String {
        return """
        {
            "ogmios": {
                "binary": "/usr/local/bin/ogmios",
                "host": "127.0.0.1",
                "port": 1337,
                "timeout": 60,
                "max_in_flight": 200,
                "log_level": "debug",
                "log_level_health": "info",
                "log_level_metrics": "warn",
                "log_level_websocket": "debug",
                "log_level_server": "info",
                "log_level_options": "trace",
                "working_dir": "/opt/ogmios",
                "show_output": false
            }
        }
        """
    }
    
    // MARK: - Initialization Tests
    
    @Test("OgmiosConfig initializes with binary path only")
    func testMinimalInitialization() {
        let config = createMinimalConfig()
        
        #expect(config.binary!.string == "/usr/local/bin/ogmios")
        #expect(config.host == nil)
        #expect(config.port == nil)
        #expect(config.timeout == nil)
        #expect(config.maxInFlight == nil)
        #expect(config.logLevel == nil)
        #expect(config.workingDir == nil)
        #expect(config.showOutput == nil)
    }
    
    @Test("OgmiosConfig initializes with all parameters")
    func testFullInitialization() {
        let config = createFullConfig()
        
        #expect(config.binary!.string == "/usr/local/bin/ogmios")
        #expect(config.host == "0.0.0.0")
        #expect(config.port == 1337)
        #expect(config.timeout == 30)
        #expect(config.maxInFlight == 100)
        #expect(config.logLevel == "info")
        #expect(config.logLevelHealth == "warn")
        #expect(config.logLevelMetrics == "debug")
        #expect(config.logLevelWebsocket == "info")
        #expect(config.logLevelServer == "error")
        #expect(config.logLevelOptions == "trace")
        #expect(config.workingDir?.string == "/tmp/ogmios")
        #expect(config.showOutput == true)
    }
    
    @Test("OgmiosConfig initializes with selective parameters")
    func testSelectiveInitialization() {
        let config = OgmiosConfig(
            binary: FilePath("/opt/ogmios"),
            host: "localhost",
            port: 8080,
            logLevel: "debug"
        )
        
        #expect(config.binary!.string == "/opt/ogmios")
        #expect(config.host == "localhost")
        #expect(config.port == 8080)
        #expect(config.logLevel == "debug")
        
        // These should be nil
        #expect(config.timeout == nil)
        #expect(config.maxInFlight == nil)
        #expect(config.workingDir == nil)
        #expect(config.showOutput == nil)
    }
    
    // MARK: - JSON Serialization Tests
    
    @Test("OgmiosConfig encodes to JSON with correct keys")
    func testJSONEncoding() throws {
        let config = createFullConfig()
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(config)
        let jsonString = String(data: data, encoding: .utf8)!
        
        // Check snake_case keys are used
        #expect(jsonString.contains("\"max_in_flight\""))
        #expect(jsonString.contains("\"log_level\""))
        #expect(jsonString.contains("\"log_level_health\""))
        #expect(jsonString.contains("\"log_level_metrics\""))
        #expect(jsonString.contains("\"log_level_websocket\""))
        #expect(jsonString.contains("\"log_level_server\""))
        #expect(jsonString.contains("\"log_level_options\""))
        #expect(jsonString.contains("\"working_dir\""))
        #expect(jsonString.contains("\"show_output\""))
    }
    
    @Test("OgmiosConfig decodes from JSON correctly")
    func testJSONDecoding() throws {
        let originalConfig = createFullConfig()
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalConfig)
        
        let decoder = JSONDecoder()
        let decodedConfig = try decoder.decode(OgmiosConfig.self, from: data)
        
        #expect(decodedConfig.binary == originalConfig.binary)
        #expect(decodedConfig.host == originalConfig.host)
        #expect(decodedConfig.port == originalConfig.port)
        #expect(decodedConfig.timeout == originalConfig.timeout)
        #expect(decodedConfig.maxInFlight == originalConfig.maxInFlight)
        #expect(decodedConfig.logLevel == originalConfig.logLevel)
        #expect(decodedConfig.logLevelHealth == originalConfig.logLevelHealth)
        #expect(decodedConfig.workingDir == originalConfig.workingDir)
        #expect(decodedConfig.showOutput == originalConfig.showOutput)
    }
    
    // MARK: - ConfigReader Integration Tests
    
    @Test("OgmiosConfig initializes from ConfigReader")
    func testConfigReaderInitialization() async throws {
        let jsonData = createTestJSONConfig()
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "test-ogmios-config-\(UUID().uuidString).json"
        let tempFile = tempDir.appendingPathComponent(fileName)
        
        try jsonData.write(to: tempFile, atomically: true, encoding: .utf8)
        
        let jsonProvider = try await JSONProvider(filePath: .init(tempFile.path))
        let configReader = ConfigReader(providers: [jsonProvider])
        
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        let config = try OgmiosConfig(config: configReader)
        
        #expect(config.binary!.string == "/usr/local/bin/ogmios")
        #expect(config.host == "127.0.0.1")
        #expect(config.port == 1337)
        #expect(config.timeout == 60)
        #expect(config.maxInFlight == 200)
        #expect(config.logLevel == "debug")
        #expect(config.logLevelHealth == "info")
        #expect(config.logLevelMetrics == "warn")
        #expect(config.logLevelWebsocket == "debug")
        #expect(config.logLevelServer == "info")
        #expect(config.logLevelOptions == "trace")
        #expect(config.workingDir?.string == "/opt/ogmios")
        #expect(config.showOutput == false)
    }
    
    // MARK: - Log Level Validation Tests
    
    @Test("OgmiosConfig handles all log levels")
    func testLogLevels() throws {
        let logLevels = ["trace", "debug", "info", "warn", "error", "off"]
        
        for level in logLevels {
            let config = OgmiosConfig(
                binary: FilePath("/usr/bin/ogmios"),
                logLevel: level,
                logLevelHealth: level,
                logLevelMetrics: level,
                logLevelWebsocket: level,
                logLevelServer: level,
                logLevelOptions: level
            )
            
            #expect(config.logLevel == level)
            #expect(config.logLevelHealth == level)
            #expect(config.logLevelMetrics == level)
            #expect(config.logLevelWebsocket == level)
            #expect(config.logLevelServer == level)
            #expect(config.logLevelOptions == level)
        }
    }
    
    @Test("OgmiosConfig handles mixed log levels")
    func testMixedLogLevels() {
        let config = OgmiosConfig(
            binary: FilePath("/usr/bin/ogmios"),
            logLevel: "info",
            logLevelHealth: "warn",
            logLevelMetrics: "debug",
            logLevelWebsocket: "error",
            logLevelServer: "trace",
            logLevelOptions: "off"
        )
        
        #expect(config.logLevel == "info")
        #expect(config.logLevelHealth == "warn")
        #expect(config.logLevelMetrics == "debug")
        #expect(config.logLevelWebsocket == "error")
        #expect(config.logLevelServer == "trace")
        #expect(config.logLevelOptions == "off")
    }
    
    
    // MARK: - Performance Configuration Tests
    
    @Test("OgmiosConfig handles timeout configurations")
    func testTimeoutConfigurations() throws {
        let timeouts = [5, 10, 30, 60, 120, 300]
        
        for timeout in timeouts {
            let config = OgmiosConfig(
                binary: FilePath("/usr/bin/ogmios"),
                timeout: timeout
            )
            
            #expect(config.timeout == timeout)
        }
    }
    
    @Test("OgmiosConfig handles maxInFlight configurations")
    func testMaxInFlightConfigurations() throws {
        let maxInFlightValues = [1, 10, 50, 100, 500, 1000]
        
        for maxInFlight in maxInFlightValues {
            let config = OgmiosConfig(
                binary: FilePath("/usr/bin/ogmios"),
                maxInFlight: maxInFlight
            )
            
            #expect(config.maxInFlight == maxInFlight)
        }
    }
    
    // MARK: - FilePath Handling Tests
    
    @Test("OgmiosConfig handles various binary paths")
    func testBinaryPathHandling() throws {
        let paths = [
            "/usr/local/bin/ogmios",
            "/opt/cardano/bin/ogmios",
            "./ogmios",
            "../bin/ogmios",
            "~/bin/ogmios",
            "/usr/bin/ogmios"
        ]
        
        for path in paths {
            let config = OgmiosConfig(binary: FilePath(path))
            #expect(config.binary!.string == path)
        }
    }
    
    @Test("OgmiosConfig handles working directory paths")
    func testWorkingDirectoryHandling() throws {
        let workingDirs = [
            "/tmp/ogmios",
            "/opt/ogmios",
            "./ogmios-data",
            "../ogmios",
            "/var/lib/ogmios"
        ]
        
        for workDir in workingDirs {
            let config = OgmiosConfig(
                binary: FilePath("/usr/bin/ogmios"),
                workingDir: FilePath(workDir)
            )
            
            #expect(config.workingDir?.string == workDir)
        }
    }
    
    // MARK: - Boolean Configuration Tests
    
    @Test("OgmiosConfig handles show output flag")
    func testShowOutputFlag() throws {
        let config1 = OgmiosConfig(
            binary: FilePath("/usr/bin/ogmios"),
            showOutput: true
        )
        #expect(config1.showOutput == true)
        
        let config2 = OgmiosConfig(
            binary: FilePath("/usr/bin/ogmios"),
            showOutput: false
        )
        #expect(config2.showOutput == false)
        
        let config3 = OgmiosConfig(binary: FilePath("/usr/bin/ogmios"))
        #expect(config3.showOutput == nil)
    }
    
    // MARK: - Edge Cases and Error Handling Tests
    
    @Test("OgmiosConfig handles empty binary path")
    func testEmptyBinaryPath() {
        let config = OgmiosConfig(binary: FilePath(""))
        #expect(config.binary!.string == "")
    }
    
    @Test("OgmiosConfig handles zero values")
    func testZeroValues() throws {
        let config = OgmiosConfig(
            binary: FilePath("/usr/bin/ogmios"),
            port: 0,
            timeout: 0,
            maxInFlight: 0
        )
        
        #expect(config.port == 0)
        #expect(config.timeout == 0)
        #expect(config.maxInFlight == 0)
    }
    
    @Test("OgmiosConfig handles extreme values")
    func testExtremeValues() throws {
        let config = OgmiosConfig(
            binary: FilePath("/usr/bin/ogmios"),
            port: 65535,
            timeout: Int.max,
            maxInFlight: Int.max
        )
        
        #expect(config.port == 65535)
        #expect(config.timeout == Int.max)
        #expect(config.maxInFlight == Int.max)
    }
    
    // MARK: - Configuration Validation Tests
    
    @Test("OgmiosConfig validates typical production configuration")
    func testProductionConfiguration() throws {
        let config = OgmiosConfig(
            binary: FilePath("/usr/local/bin/ogmios"),
            host: "0.0.0.0",
            port: 1337,
            timeout: 60,
            maxInFlight: 1000,
            logLevel: "info",
            logLevelHealth: "warn",
            logLevelMetrics: "info",
            logLevelWebsocket: "warn",
            logLevelServer: "info",
            logLevelOptions: "error",
            workingDir: FilePath("/var/lib/ogmios"),
            showOutput: false
        )
        
        #expect(config.binary!.string == "/usr/local/bin/ogmios")
        #expect(config.host == "0.0.0.0")
        #expect(config.port == 1337)
        #expect(config.timeout == 60)
        #expect(config.maxInFlight == 1000)
        #expect(config.showOutput == false)
    }
    
    @Test("OgmiosConfig validates typical development configuration")
    func testDevelopmentConfiguration() throws {
        let config = OgmiosConfig(
            binary: FilePath("./ogmios"),
            host: "127.0.0.1",
            port: 1337,
            timeout: 30,
            maxInFlight: 10,
            logLevel: "debug",
            logLevelHealth: "debug",
            logLevelMetrics: "debug",
            logLevelWebsocket: "debug",
            logLevelServer: "debug",
            logLevelOptions: "debug",
            workingDir: FilePath("./ogmios-data"),
            showOutput: true
        )
        
        #expect(config.host == "127.0.0.1")
        #expect(config.logLevel == "debug")
        #expect(config.maxInFlight == 10)
        #expect(config.showOutput == true)
    }
    
    // MARK: - Serialization Round-trip Tests
    
    @Test("OgmiosConfig serialization round-trip preserves all data")
    func testSerializationRoundTrip() throws {
        let originalConfig = createFullConfig()
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalConfig)
        
        let decoder = JSONDecoder()
        let decodedConfig = try decoder.decode(OgmiosConfig.self, from: data)
        
        // Re-encode to verify everything is preserved
        let reEncodedData = try encoder.encode(decodedConfig)
        let reDecodedConfig = try decoder.decode(OgmiosConfig.self, from: reEncodedData)
        
        #expect(reDecodedConfig.binary == originalConfig.binary)
        #expect(reDecodedConfig.host == originalConfig.host)
        #expect(reDecodedConfig.port == originalConfig.port)
        #expect(reDecodedConfig.timeout == originalConfig.timeout)
        #expect(reDecodedConfig.maxInFlight == originalConfig.maxInFlight)
        #expect(reDecodedConfig.logLevel == originalConfig.logLevel)
        #expect(reDecodedConfig.workingDir == originalConfig.workingDir)
        #expect(reDecodedConfig.showOutput == originalConfig.showOutput)
    }
}
