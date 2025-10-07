import Testing
import Foundation
import SystemPackage
import SwiftCardanoCore
import Configuration
@testable import CardanoCLITools

@Suite("CardanoCLIToolsConfig Tests")
struct CardanoCLIToolsConfigTests {
    
    // MARK: - Test Helper Methods
    
    private func createTestCardanoConfig() -> CardanoConfig {
        return CardanoConfig(
            cli: FilePath("/usr/local/bin/cardano-cli"),
            node: FilePath("/usr/local/bin/cardano-node"),
            hwCli: FilePath("/usr/local/bin/cardano-hw-cli"),
            signer: FilePath("/usr/local/bin/cardano-signer"),
            socket: FilePath("/tmp/cardano.socket"),
            config: FilePath("/etc/cardano/config.json"),
            topology: FilePath("/etc/cardano/topology.json"),
            database: FilePath("/var/lib/cardano/db"),
            port: 3001,
            hostAddr: "127.0.0.1",
            network: .mainnet,
            era: .conway,
            ttlBuffer: 3600,
            workingDir: FilePath("/tmp/cardano"),
            showOutput: true
        )
    }
    
    private func createTestOgmiosConfig() -> OgmiosConfig {
        return OgmiosConfig(
            binary: FilePath("/usr/local/bin/ogmios"),
            host: "0.0.0.0",
            port: 1337,
            timeout: 30,
            maxInFlight: 100,
            logLevel: "info",
            logLevelHealth: "info",
            logLevelMetrics: "info",
            logLevelWebsocket: "info",
            logLevelServer: "info",
            logLevelOptions: "info",
            workingDir: FilePath("/tmp/ogmios"),
            showOutput: true
        )
    }
    
    private func createTestKupoConfig() -> KupoConfig {
        return KupoConfig(
            binary: FilePath("/usr/local/bin/kupo"),
            host: "0.0.0.0",
            port: 1442,
            since: "origin",
            matches: ["*"],
            deferDbIndexes: false,
            pruneUTxO: false,
            gcInterval: 300,
            maxConcurrency: 10,
            inMemory: false,
            logLevel: "info",
            logLevelHttpServer: "info",
            logLevelDatabase: "info",
            logLevelConsumer: "info",
            logLevelGarbageCollector: "info",
            logLevelConfiguration: "info",
            workingDir: FilePath("/tmp/kupo"),
            showOutput: true
        )
    }
    
    private func createTempFile() -> FilePath {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "test-config-\(UUID().uuidString).json"
        return FilePath(tempDir.appendingPathComponent(fileName).path)
    }
    
    // MARK: - Initialization Tests
    
    @Test("CardanoCLIToolsConfig initializes with all components")
    func testInitializationWithAllComponents() {
        let cardanoConfig = createTestCardanoConfig()
        let ogmiosConfig = createTestOgmiosConfig()
        let kupoConfig = createTestKupoConfig()
        
        let config = CardanoCLIToolsConfig(
            cardano: cardanoConfig,
            ogmios: ogmiosConfig,
            kupo: kupoConfig
        )
        
        #expect(config.cardano.cli == cardanoConfig.cli)
        #expect(config.cardano.node == cardanoConfig.node)
        #expect(config.ogmios?.binary == ogmiosConfig.binary)
        #expect(config.kupo?.binary == kupoConfig.binary)
    }
    
    @Test("CardanoCLIToolsConfig initializes with minimal components")
    func testInitializationWithMinimalComponents() {
        let cardanoConfig = createTestCardanoConfig()
        
        let config = CardanoCLIToolsConfig(
            cardano: cardanoConfig,
            ogmios: nil,
            kupo: nil
        )
        
        #expect(config.cardano.cli == cardanoConfig.cli)
        #expect(config.ogmios == nil)
        #expect(config.kupo == nil)
    }
    
    @Test("CardanoCLIToolsConfig initializes with only Ogmios")
    func testInitializationWithOnlyOgmios() {
        let cardanoConfig = createTestCardanoConfig()
        let ogmiosConfig = createTestOgmiosConfig()
        
        let config = CardanoCLIToolsConfig(
            cardano: cardanoConfig,
            ogmios: ogmiosConfig,
            kupo: nil
        )
        
        #expect(config.cardano.cli == cardanoConfig.cli)
        #expect(config.ogmios?.binary == ogmiosConfig.binary)
        #expect(config.kupo == nil)
    }
    
    @Test("CardanoCLIToolsConfig initializes with only Kupo")
    func testInitializationWithOnlyKupo() {
        let cardanoConfig = createTestCardanoConfig()
        let kupoConfig = createTestKupoConfig()
        
        let config = CardanoCLIToolsConfig(
            cardano: cardanoConfig,
            ogmios: nil,
            kupo: kupoConfig
        )
        
        #expect(config.cardano.cli == cardanoConfig.cli)
        #expect(config.ogmios == nil)
        #expect(config.kupo?.binary == kupoConfig.binary)
    }
    
    // MARK: - JSON Serialization Tests
    
    @Test("CardanoCLIToolsConfig encodes to JSON correctly")
    func testJSONEncoding() throws {
        let cardanoConfig = createTestCardanoConfig()
        let ogmiosConfig = createTestOgmiosConfig()
        let kupoConfig = createTestKupoConfig()
        
        let config = CardanoCLIToolsConfig(
            cardano: cardanoConfig,
            ogmios: ogmiosConfig,
            kupo: kupoConfig
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(config)
        let jsonString = String(data: data, encoding: .utf8)!
        
        // Verify JSON structure
        #expect(jsonString.contains("\"cardano\""))
        #expect(jsonString.contains("\"ogmios\""))
        #expect(jsonString.contains("\"kupo\""))
        #expect(jsonString.contains("\"binary\""))
        #expect(jsonString.contains("\"cli\""))
        #expect(jsonString.contains("\"node\""))
    }
    
    @Test("CardanoCLIToolsConfig decodes from JSON correctly")
    func testJSONDecoding() throws {
        let originalConfig = CardanoCLIToolsConfig(
            cardano: createTestCardanoConfig(),
            ogmios: createTestOgmiosConfig(),
            kupo: createTestKupoConfig()
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalConfig)
        
        let decoder = JSONDecoder()
        let decodedConfig = try decoder.decode(CardanoCLIToolsConfig.self, from: data)
        
        #expect(decodedConfig.cardano.cli == originalConfig.cardano.cli)
        #expect(decodedConfig.cardano.network == originalConfig.cardano.network)
        #expect(decodedConfig.ogmios?.binary == originalConfig.ogmios?.binary)
        #expect(decodedConfig.kupo?.binary == originalConfig.kupo?.binary)
    }
    
    // MARK: - File I/O Tests
    
    @Test("CardanoCLIToolsConfig saves to file successfully")
    func testSaveToFile() throws {
        let config = CardanoCLIToolsConfig(
            cardano: createTestCardanoConfig(),
            ogmios: createTestOgmiosConfig(),
            kupo: createTestKupoConfig()
        )
        
        let tempFile = createTempFile()
        defer { try? FileManager.default.removeItem(atPath: tempFile.string) }
        
        try config.save(to: tempFile)
        
        // Verify file exists
        #expect(FileManager.default.fileExists(atPath: tempFile.string))
        
        // Verify file content is valid JSON
        let data = try Data(contentsOf: URL(fileURLWithPath: tempFile.string))
        let _ = try JSONSerialization.jsonObject(with: data)
    }
    
    @Test("CardanoCLIToolsConfig throws error when file already exists")
    func testSaveToExistingFile() throws {
        let config = CardanoCLIToolsConfig(cardano: createTestCardanoConfig())
        let tempFile = createTempFile()
        
        // Create the file first
        try "test".write(to: URL(fileURLWithPath: tempFile.string), atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: tempFile.string) }
        
        #expect(throws: CardanoCLIToolsError.self) {
            try config.save(to: tempFile)
        }
    }
    
    @Test("CardanoCLIToolsConfig loads from file successfully")
    func testLoadFromFile() async throws {
        let configPath = try getFilePath(
            forResource: configJSONFilePath.forResource,
            ofType: configJSONFilePath.ofType,
            inDirectory: configJSONFilePath.inDirectory
        )!
        
        // Load config
        let loadedConfig = try await CardanoCLIToolsConfig.load(
            path: FilePath(configPath)
        )   
        
        #expect(loadedConfig.cardano.cli == FilePath("cardano-cli"))
        #expect(loadedConfig.ogmios?.binary == FilePath("ogmios"))
        #expect(loadedConfig.kupo?.binary == FilePath("kupo"))
    }
    
    @Test("CardanoCLIToolsConfig load throws error for non-existent file")
    func testLoadFromNonExistentFile() async {
        let nonExistentFile = FilePath("/tmp/non-existent-\(UUID().uuidString).json")
        
        await #expect(throws: Error.self) {
            _ = try await CardanoCLIToolsConfig.load(path: nonExistentFile)
        }
    }
    
    @Test("CardanoCLIToolsConfig initializes from ConfigReader with JSON data")
    func testConfigReaderInitializationWithJSON() async throws {
        let jsonData = """
        {
            "cardano": {
                "cli": "/usr/local/bin/cardano-cli",
                "node": "/usr/local/bin/cardano-node",
                "network": "preview",
                "era": "conway",
                "ttl_buffer": 7200,
                "working_dir": "/tmp/test"
            },
            "ogmios": {
                "binary": "/usr/local/bin/ogmios",
                "host": "127.0.0.1",
                "port": 1337,
                "timeout": 60
            },
            "kupo": {
                "binary": "/usr/local/bin/kupo",
                "host": "127.0.0.1",
                "port": 1442,
                "since": "origin"
            }
        }
        """
        
        let tempFile = createTempFile()
        defer { try? FileManager.default.removeItem(atPath: tempFile.string) }
        
        try jsonData.write(to: URL(fileURLWithPath: tempFile.string), atomically: true, encoding: .utf8)
        
        let jsonProvider = try await JSONProvider(filePath: .init(tempFile.string))
        let configReader = ConfigReader(providers: [jsonProvider])
        
        let config = try CardanoCLIToolsConfig(config: configReader)
        
        #expect(config.cardano.cli?.string == "/usr/local/bin/cardano-cli")
        #expect(config.cardano.network == .preview)
        #expect(config.cardano.ttlBuffer == 7200)
        #expect(config.ogmios?.binary.string == "/usr/local/bin/ogmios")
        #expect(config.ogmios?.host == "127.0.0.1")
        #expect(config.kupo?.binary.string == "/usr/local/bin/kupo")
    }
    
    // MARK: - Default Configuration Tests
    
    @Test("CardanoCLIToolsConfig default configuration contains required components")
    func testDefaultConfiguration() {
        #expect(throws: Never.self) {
            let config = try CardanoCLIToolsConfig.default()
            
            // Cardano config should always be present
            #expect(config.cardano.network == .mainnet)
            #expect(config.cardano.era == .conway)
            #expect(config.cardano.ttlBuffer > 0)
            #expect(config.cardano.workingDir.string.isEmpty == false)
        }
    }
    
    
    @Test("CardanoCLIToolsConfig handles malformed JSON gracefully")
    func testMalformedJSON() {
        let malformedJSON = """
        {
            "cardano": {
                "network": "invalid_network",
                "era": "invalid_era"
            }
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        
        #expect(throws: Error.self) {
            _ = try decoder.decode(CardanoCLIToolsConfig.self, from: malformedJSON)
        }
    }
    
    @Test("CardanoCLIToolsConfig validates required fields")
    func testRequiredFieldValidation() {
        let incompleteJSON = """
        {
            "cardano": {
                "network": "preview"
            }
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        
        // Should throw because required fields (era, ttlBuffer, workingDir) are missing
        #expect(throws: Error.self) {
            _ = try decoder.decode(CardanoCLIToolsConfig.self, from: incompleteJSON)
        }
    }
}
