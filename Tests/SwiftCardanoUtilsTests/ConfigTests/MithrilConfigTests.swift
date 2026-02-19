import Testing
import Foundation
import SystemPackage
import SwiftCardanoCore
import Configuration
@testable import SwiftCardanoUtils

@Suite("MithrilConfig Tests")
struct MithrilConfigTests {
    
    // MARK: - Test Helper Methods
    
    private func createMinimalConfig() -> MithrilConfig {
        return MithrilConfig(binary: FilePath("/usr/local/bin/mithril-client"))
    }
    
    private func createFullConfig() -> MithrilConfig {
        return MithrilConfig(
            binary: FilePath("/usr/local/bin/mithril-client"),
            aggregatorEndpoint: "https://aggregator.release-mainnet.api.mithril.network/aggregator",
            genesisVerificationKey: "5b3132372c37332c3132342c3136312c362c3133372c3133312c3231332c3230372c3131372c3139382c38352c3137362c3139392c3136322c3234312c36382c3132332c3131392c3134352c31332c3233322c3234332c34392c3232392c322c3234392c3230352c3230352c33392c3232392c3235302c3234322c33342c3233342c3231332c3232352c33372c3231312c3231362c3135302c3233352c3134332c32352c3136342c3235302c3133345d",
            ancillaryVerificationKey: "5b3132372c37332c3132342c3136312c362c3133372c3133312c3231332c3230372c3131372c3139382c38352c3137362c3139392c3136322c3234312c36382c3132332c3131392c3134352c31332c3233322c3234332c34392c3232392c322c3234392c3230352c3230352c33392c3232392c3235302c3234322c33342c3233342c3231332c3232352c33372c3231312c3231362c3135302c3233352c3134332c32352c3136342c3235302c3133345d",
            downloadDir: FilePath("/tmp/mithril-downloads"),
            workingDir: FilePath("/tmp/mithril"),
            showOutput: true
        )
    }
    
    private func createTestJSONConfig() -> String {
        return """
        {
            "mithril": {
                "binary": "/usr/local/bin/mithril-client",
                "aggregator_endpoint": "https://aggregator.release-preprod.api.mithril.network/aggregator",
                "genesis_verification_key": "5b3132372c37332c3132342c3136312c362c3133372c3133312c3231332c3230372c3131372c3139382c38352c3137362c3139392c3136322c3234312c36382c3132332c3131392c3134352c31332c3233322c3234332c34392c3232392c322c3234392c3230352c3230352c33392c3232392c3235302c3234322c33342c3233342c3231332c3232352c33372c3231312c3231362c3135302c3233352c3134332c32352c3136342c3235302c3133345d",
                "ancillary_verification_key": "5b3132372c37332c3132342c3136312c362c3133372c3133312c3231332c3230372c3131372c3139382c38352c3137362c3139392c3136322c3234312c36382c3132332c3131392c3134352c31332c3233322c3234332c34392c3232392c322c3234392c3230352c3230352c33392c3232392c3235302c3234322c33342c3233342c3231332c3232352c33372c3231312c3231362c3135302c3233352c3134332c32352c3136342c3235302c3133345d",
                "download_dir": "/opt/mithril/downloads",
                "working_dir": "/opt/mithril",
                "show_output": false
            }
        }
        """
    }
    
    // MARK: - Initialization Tests
    
    @Test("MithrilConfig initializes with binary path only")
    func testMinimalInitialization() {
        let config = createMinimalConfig()
        
        #expect(config.binary!.string == "/usr/local/bin/mithril-client")
        #expect(config.aggregatorEndpoint == nil)
        #expect(config.genesisVerificationKey == nil)
        #expect(config.ancillaryVerificationKey == nil)
        #expect(config.downloadDir == nil)
        #expect(config.workingDir == nil)
        #expect(config.showOutput == nil)
    }
    
    @Test("MithrilConfig initializes with all parameters")
    func testFullInitialization() {
        let config = createFullConfig()
        
        #expect(config.binary!.string == "/usr/local/bin/mithril-client")
        #expect(config.aggregatorEndpoint == "https://aggregator.release-mainnet.api.mithril.network/aggregator")
        #expect(config.genesisVerificationKey != nil)
        #expect(config.ancillaryVerificationKey != nil)
        #expect(config.downloadDir?.string == "/tmp/mithril-downloads")
        #expect(config.workingDir?.string == "/tmp/mithril")
        #expect(config.showOutput == true)
    }
    
    @Test("MithrilConfig initializes with selective parameters")
    func testSelectiveInitialization() {
        let config = MithrilConfig(
            binary: FilePath("/opt/mithril"),
            aggregatorEndpoint: "https://aggregator.release-preprod.api.mithril.network/aggregator",
            downloadDir: FilePath("/tmp/downloads")
        )
        
        #expect(config.binary!.string == "/opt/mithril")
        #expect(config.aggregatorEndpoint == "https://aggregator.release-preprod.api.mithril.network/aggregator")
        #expect(config.downloadDir?.string == "/tmp/downloads")
        
        // These should be nil
        #expect(config.genesisVerificationKey == nil)
        #expect(config.ancillaryVerificationKey == nil)
        #expect(config.workingDir == nil)
        #expect(config.showOutput == nil)
    }
    
    // MARK: - JSON Serialization Tests
    
    @Test("MithrilConfig encodes to JSON with correct keys")
    func testJSONEncoding() throws {
        let config = createFullConfig()
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(config)
        let jsonString = String(data: data, encoding: .utf8)!
        
        // Check snake_case keys are used
        #expect(jsonString.contains("\"aggregator_endpoint\""))
        #expect(jsonString.contains("\"genesis_verification_key\""))
        #expect(jsonString.contains("\"ancillary_verification_key\""))
        #expect(jsonString.contains("\"download_dir\""))
        #expect(jsonString.contains("\"working_dir\""))
        #expect(jsonString.contains("\"show_output\""))
    }
    
    @Test("MithrilConfig decodes from JSON correctly")
    func testJSONDecoding() throws {
        let originalConfig = createFullConfig()
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalConfig)
        
        let decoder = JSONDecoder()
        let decodedConfig = try decoder.decode(MithrilConfig.self, from: data)
        
        #expect(decodedConfig.binary == originalConfig.binary)
        #expect(decodedConfig.aggregatorEndpoint == originalConfig.aggregatorEndpoint)
        #expect(decodedConfig.genesisVerificationKey == originalConfig.genesisVerificationKey)
        #expect(decodedConfig.ancillaryVerificationKey == originalConfig.ancillaryVerificationKey)
        #expect(decodedConfig.downloadDir == originalConfig.downloadDir)
        #expect(decodedConfig.workingDir == originalConfig.workingDir)
        #expect(decodedConfig.showOutput == originalConfig.showOutput)
    }
    
    // MARK: - ConfigReader Integration Tests
    
    @Test("MithrilConfig initializes from ConfigReader")
    func testConfigReaderInitialization() async throws {
        let jsonData = createTestJSONConfig()
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "test-mithril-config-\(UUID().uuidString).json"
        let tempFile = tempDir.appendingPathComponent(fileName)
        
        try jsonData.write(to: tempFile, atomically: true, encoding: .utf8)
        
        let jsonProvider = try await JSONProvider(filePath: .init(tempFile.path))
        let configReader = ConfigReader(providers: [jsonProvider])
        
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        let config = try MithrilConfig(config: configReader)
        
        #expect(config.binary!.string == "/usr/local/bin/mithril-client")
        #expect(config.aggregatorEndpoint == "https://aggregator.release-preprod.api.mithril.network/aggregator")
        #expect(config.genesisVerificationKey != nil)
        #expect(config.ancillaryVerificationKey != nil)
        #expect(config.downloadDir?.string == "/opt/mithril/downloads")
        #expect(config.workingDir?.string == "/opt/mithril")
        #expect(config.showOutput == false)
    }
    
    // MARK: - Aggregator Endpoint Tests
    
    @Test("MithrilConfig handles various aggregator endpoints")
    func testAggregatorEndpoints() {
        let endpoints = [
            "https://aggregator.release-mainnet.api.mithril.network/aggregator",
            "https://aggregator.release-preprod.api.mithril.network/aggregator",
            "https://aggregator.testing-preview.api.mithril.network/aggregator",
            "http://localhost:8080/aggregator",
            "auto:mainnet",
            "auto:preprod",
            "auto:preview"
        ]
        
        for endpoint in endpoints {
            let config = MithrilConfig(
                binary: FilePath("/usr/bin/mithril-client"),
                aggregatorEndpoint: endpoint
            )
            #expect(config.aggregatorEndpoint == endpoint)
        }
    }
    
    // MARK: - Verification Key Tests
    
    @Test("MithrilConfig handles genesis verification keys")
    func testGenesisVerificationKey() {
        let key = "5b3132372c37332c3132342c3136312c362c3133372c3133312c3231332c3230372c3131372c3139382c38352c3137362c3139392c3136322c3234312c36382c3132332c3131392c3134352c31332c3233322c3234332c34392c3232392c322c3234392c3230352c3230352c33392c3232392c3235302c3234322c33342c3233342c3231332c3232352c33372c3231312c3231362c3135302c3233352c3134332c32352c3136342c3235302c3133345d"
        
        let config = MithrilConfig(
            binary: FilePath("/usr/bin/mithril-client"),
            genesisVerificationKey: key
        )
        
        #expect(config.genesisVerificationKey == key)
    }
    
    @Test("MithrilConfig handles ancillary verification keys")
    func testAncillaryVerificationKey() {
        let key = "5b3132372c37332c3132342c3136312c362c3133372c3133312c3231332c3230372c3131372c3139382c38352c3137362c3139392c3136322c3234312c36382c3132332c3131392c3134352c31332c3233322c3234332c34392c3232392c322c3234392c3230352c3230352c33392c3232392c3235302c3234322c33342c3233342c3231332c3232352c33372c3231312c3231362c3135302c3233352c3134332c32352c3136342c3235302c3133345d"
        
        let config = MithrilConfig(
            binary: FilePath("/usr/bin/mithril-client"),
            ancillaryVerificationKey: key
        )
        
        #expect(config.ancillaryVerificationKey == key)
    }
    
    // MARK: - FilePath Handling Tests
    
    @Test("MithrilConfig handles various binary paths")
    func testBinaryPathHandling() {
        let paths = [
            "/usr/local/bin/mithril-client",
            "/opt/cardano/bin/mithril-client",
            "./mithril-client",
            "../bin/mithril-client",
            "~/bin/mithril-client",
            "/usr/bin/mithril-client"
        ]
        
        for path in paths {
            let config = MithrilConfig(binary: FilePath(path))
            #expect(config.binary!.string == path)
        }
    }
    
    @Test("MithrilConfig handles download directory paths")
    func testDownloadDirectoryHandling() {
        let downloadDirs = [
            "/tmp/mithril-downloads",
            "/opt/cardano/mithril/downloads",
            "./downloads",
            "../mithril-data",
            "/var/lib/mithril/downloads"
        ]
        
        for downloadDir in downloadDirs {
            let config = MithrilConfig(
                binary: FilePath("/usr/bin/mithril-client"),
                downloadDir: FilePath(downloadDir)
            )
            
            #expect(config.downloadDir?.string == downloadDir)
        }
    }
    
    @Test("MithrilConfig handles working directory paths")
    func testWorkingDirectoryHandling() {
        let workingDirs = [
            "/tmp/mithril",
            "/opt/mithril",
            "./mithril-data",
            "../mithril",
            "/var/lib/mithril"
        ]
        
        for workDir in workingDirs {
            let config = MithrilConfig(
                binary: FilePath("/usr/bin/mithril-client"),
                workingDir: FilePath(workDir)
            )
            
            #expect(config.workingDir?.string == workDir)
        }
    }
    
    // MARK: - Boolean Configuration Tests
    
    @Test("MithrilConfig handles show output flag")
    func testShowOutputFlag() {
        let config1 = MithrilConfig(
            binary: FilePath("/usr/bin/mithril-client"),
            showOutput: true
        )
        #expect(config1.showOutput == true)
        
        let config2 = MithrilConfig(
            binary: FilePath("/usr/bin/mithril-client"),
            showOutput: false
        )
        #expect(config2.showOutput == false)
        
        let config3 = MithrilConfig(binary: FilePath("/usr/bin/mithril-client"))
        #expect(config3.showOutput == nil)
    }
    
    // MARK: - Edge Cases and Error Handling Tests
    
    @Test("MithrilConfig handles empty binary path")
    func testEmptyBinaryPath() {
        let config = MithrilConfig(binary: FilePath(""))
        #expect(config.binary!.string == "")
    }
    
    @Test("MithrilConfig handles nil values gracefully")
    func testNilValues() {
        let config = MithrilConfig()
        
        #expect(config.binary == nil)
        #expect(config.aggregatorEndpoint == nil)
        #expect(config.genesisVerificationKey == nil)
        #expect(config.ancillaryVerificationKey == nil)
        #expect(config.downloadDir == nil)
        #expect(config.workingDir == nil)
        #expect(config.showOutput == nil)
    }
    
    // MARK: - Configuration Validation Tests
    
    @Test("MithrilConfig validates typical mainnet configuration")
    func testMainnetConfiguration() {
        let config = MithrilConfig(
            binary: FilePath("/usr/local/bin/mithril-client"),
            aggregatorEndpoint: "https://aggregator.release-mainnet.api.mithril.network/aggregator",
            genesisVerificationKey: "5b3132372c37332c3132342c3136312c362c3133372c3133312c3231332c3230372c3131372c3139382c38352c3137362c3139392c3136322c3234312c36382c3132332c3131392c3134352c31332c3233322c3234332c34392c3232392c322c3234392c3230352c3230352c33392c3232392c3235302c3234322c33342c3233342c3231332c3232352c33372c3231312c3231362c3135302c3233352c3134332c32352c3136342c3235302c3133345d",
            downloadDir: FilePath("/var/lib/cardano/db"),
            workingDir: FilePath("/var/lib/mithril"),
            showOutput: false
        )
        
        #expect(config.binary!.string == "/usr/local/bin/mithril-client")
        #expect(config.aggregatorEndpoint!.contains("mainnet"))
        #expect(config.showOutput == false)
    }
    
    @Test("MithrilConfig validates typical preprod configuration")
    func testPreprodConfiguration() {
        let config = MithrilConfig(
            binary: FilePath("/usr/local/bin/mithril-client"),
            aggregatorEndpoint: "https://aggregator.release-preprod.api.mithril.network/aggregator",
            genesisVerificationKey: "5b3132372c37332c3132342c3136312c362c3133372c3133312c3231332c3230372c3131372c3139382c38352c3137362c3139392c3136322c3234312c36382c3132332c3131392c3134352c31332c3233322c3234332c34392c3232392c322c3234392c3230352c3230352c33392c3232392c3235302c3234322c33342c3233342c3231332c3232352c33372c3231312c3231362c3135302c3233352c3134332c32352c3136342c3235302c3133345d",
            downloadDir: FilePath("/tmp/cardano-db"),
            workingDir: FilePath("/tmp/mithril"),
            showOutput: true
        )
        
        #expect(config.aggregatorEndpoint!.contains("preprod"))
        #expect(config.showOutput == true)
    }
    
    @Test("MithrilConfig validates auto-endpoint configuration")
    func testAutoEndpointConfiguration() {
        let config = MithrilConfig(
            binary: FilePath("/usr/local/bin/mithril-client"),
            aggregatorEndpoint: "auto:mainnet"
        )
        
        #expect(config.aggregatorEndpoint == "auto:mainnet")
    }
    
    // MARK: - Serialization Round-trip Tests
    
    @Test("MithrilConfig serialization round-trip preserves all data")
    func testSerializationRoundTrip() throws {
        let originalConfig = createFullConfig()
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalConfig)
        
        let decoder = JSONDecoder()
        let decodedConfig = try decoder.decode(MithrilConfig.self, from: data)
        
        // Re-encode to verify everything is preserved
        let reEncodedData = try encoder.encode(decodedConfig)
        let reDecodedConfig = try decoder.decode(MithrilConfig.self, from: reEncodedData)
        
        #expect(reDecodedConfig.binary == originalConfig.binary)
        #expect(reDecodedConfig.aggregatorEndpoint == originalConfig.aggregatorEndpoint)
        #expect(reDecodedConfig.genesisVerificationKey == originalConfig.genesisVerificationKey)
        #expect(reDecodedConfig.ancillaryVerificationKey == originalConfig.ancillaryVerificationKey)
        #expect(reDecodedConfig.downloadDir == originalConfig.downloadDir)
        #expect(reDecodedConfig.workingDir == originalConfig.workingDir)
        #expect(reDecodedConfig.showOutput == originalConfig.showOutput)
    }
    
    @Test("MithrilConfig handles partial JSON data")
    func testPartialJSONDecoding() throws {
        let partialJSON = """
        {
            "binary": "/usr/bin/mithril-client",
            "aggregator_endpoint": "https://example.com/aggregator",
            "genesis_verification_key": null,
            "ancillary_verification_key": null,
            "download_dir": null,
            "working_dir": null,
            "show_output": null
        }
        """
        
        let data = partialJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        let config = try decoder.decode(MithrilConfig.self, from: data)
        
        #expect(config.binary!.string == "/usr/bin/mithril-client")
        #expect(config.aggregatorEndpoint == "https://example.com/aggregator")
        #expect(config.genesisVerificationKey == nil)
        #expect(config.downloadDir == nil)
        #expect(config.workingDir == nil)
        #expect(config.showOutput == nil)
    }
}
