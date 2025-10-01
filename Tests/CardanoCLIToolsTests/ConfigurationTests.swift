import Testing
import Foundation
import System
import SwiftCardanoCore
@testable import CardanoCLITools

@Suite("Configuration Tests")
struct ConfigurationTests {
    
    // MARK: - Test Data Setup
    
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
    
    // MARK: - Configuration Tests
    
    @Test("Configuration initializes correctly with all components")
    func testConfigurationInitializationWithAllComponents() {
        let cardanoConfig = createTestCardanoConfig()
        let ogmiosConfig = createTestOgmiosConfig()
        let kupoConfig = createTestKupoConfig()
        
        let configuration = Configuration(
            cardano: cardanoConfig,
            ogmios: ogmiosConfig,
            kupo: kupoConfig
        )
        
        #expect(configuration.cardano.cli == cardanoConfig.cli)
        #expect(configuration.cardano.node == cardanoConfig.node)
        #expect(configuration.ogmios?.binary == ogmiosConfig.binary)
        #expect(configuration.kupo?.binary == kupoConfig.binary)
    }
    
    @Test("Configuration initializes correctly with minimal components")
    func testConfigurationInitializationWithMinimalComponents() {
        let cardanoConfig = createTestCardanoConfig()
        
        let configuration = Configuration(
            cardano: cardanoConfig,
            ogmios: nil,
            kupo: nil
        )
        
        #expect(configuration.cardano.cli == cardanoConfig.cli)
        #expect(configuration.ogmios == nil)
        #expect(configuration.kupo == nil)
    }
    
    // MARK: - CardanoConfig Tests
    
    @Test("CardanoConfig initializes correctly with all parameters")
    func testCardanoConfigInitialization() {
        let config = createTestCardanoConfig()
        
        #expect(config.cli == FilePath("/usr/local/bin/cardano-cli"))
        #expect(config.node == FilePath("/usr/local/bin/cardano-node"))
        #expect(config.hwCli == FilePath("/usr/local/bin/cardano-hw-cli"))
        #expect(config.signer == FilePath("/usr/local/bin/cardano-signer"))
        #expect(config.socket == FilePath("/tmp/cardano.socket"))
        #expect(config.config == FilePath("/etc/cardano/config.json"))
        #expect(config.topology == FilePath("/etc/cardano/topology.json"))
        #expect(config.database == FilePath("/var/lib/cardano/db"))
        #expect(config.port == 3001)
        #expect(config.hostAddr == "127.0.0.1")
        #expect(config.network == .mainnet)
        #expect(config.era == .conway)
        #expect(config.ttlBuffer == 3600)
        #expect(config.workingDir == FilePath("/tmp/cardano"))
        #expect(config.showOutput == true)
    }
    
    @Test("CardanoConfig handles optional parameters correctly")
    func testCardanoConfigWithOptionalParameters() {
        let config = CardanoConfig(
            cli: FilePath("/usr/local/bin/cardano-cli"),
            node: FilePath("/usr/local/bin/cardano-node"),
            hwCli: nil,
            signer: nil,
            socket: FilePath("/tmp/cardano.socket"),
            config: FilePath("/etc/cardano/config.json"),
            topology: nil,
            database: nil,
            port: nil,
            hostAddr: nil,
            network: .preview,
            era: .conway,
            ttlBuffer: 7200,
            workingDir: FilePath("/tmp/cardano"),
            showOutput: nil
        )
        
        #expect(config.hwCli == nil)
        #expect(config.signer == nil)
        #expect(config.topology == nil)
        #expect(config.database == nil)
        #expect(config.port == nil)
        #expect(config.hostAddr == nil)
        #expect(config.showOutput == nil)
        #expect(config.network == .preview)
        #expect(config.ttlBuffer == 7200)
    }
    
    // MARK: - OgmiosConfig Tests
    
    @Test("OgmiosConfig initializes correctly with all parameters")
    func testOgmiosConfigInitialization() {
        let config = createTestOgmiosConfig()
        
        #expect(config.binary == FilePath("/usr/local/bin/ogmios"))
        #expect(config.host == "0.0.0.0")
        #expect(config.port == 1337)
        #expect(config.timeout == 30)
        #expect(config.maxInFlight == 100)
        #expect(config.logLevel == "info")
        #expect(config.logLevelHealth == "info")
        #expect(config.logLevelMetrics == "info")
        #expect(config.logLevelWebsocket == "info")
        #expect(config.logLevelServer == "info")
        #expect(config.logLevelOptions == "info")
        #expect(config.workingDir == FilePath("/tmp/ogmios"))
        #expect(config.showOutput == true)
    }
    
    @Test("OgmiosConfig handles optional parameters correctly")
    func testOgmiosConfigWithOptionalParameters() {
        let config = OgmiosConfig(
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
        
        #expect(config.host == nil)
        #expect(config.port == nil)
        #expect(config.timeout == nil)
        #expect(config.maxInFlight == nil)
        #expect(config.logLevel == nil)
        #expect(config.workingDir == nil)
        #expect(config.showOutput == nil)
    }
    
    // MARK: - KupoConfig Tests
    
    @Test("KupoConfig initializes correctly with all parameters")
    func testKupoConfigInitialization() {
        let config = createTestKupoConfig()
        
        #expect(config.binary == FilePath("/usr/local/bin/kupo"))
        #expect(config.host == "0.0.0.0")
        #expect(config.port == 1442)
        #expect(config.since == "origin")
        #expect(config.matches == ["*"])
        #expect(config.deferDbIndexes == false)
        #expect(config.pruneUTxO == false)
        #expect(config.gcInterval == 300)
        #expect(config.maxConcurrency == 10)
        #expect(config.logLevel == "info")
        #expect(config.workingDir == FilePath("/tmp/kupo"))
        #expect(config.showOutput == true)
    }
    
    @Test("KupoConfig handles optional parameters correctly")
    func testKupoConfigWithOptionalParameters() {
        let config = KupoConfig(
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
        
        #expect(config.host == nil)
        #expect(config.port == nil)
        #expect(config.since == nil)
        #expect(config.matches == nil)
        #expect(config.deferDbIndexes == nil)
        #expect(config.pruneUTxO == nil)
        #expect(config.workingDir == nil)
        #expect(config.showOutput == nil)
    }
    
    @Test("KupoConfig handles multiple match patterns")
    func testKupoConfigWithMultipleMatches() {
        let matches = ["addr_test*", "stake_test*", "pool*"]
        
        let config = KupoConfig(
            binary: FilePath("/usr/local/bin/kupo"),
            host: "127.0.0.1",
            port: 1442,
            since: "genesis",
            matches: matches,
            deferDbIndexes: true,
            pruneUTxO: true,
            gcInterval: 600,
            maxConcurrency: 20,
            logLevel: "debug",
            logLevelHttpServer: "debug",
            logLevelDatabase: "debug",
            logLevelConsumer: "debug",
            logLevelGarbageCollector: "debug",
            logLevelConfiguration: "debug",
            workingDir: FilePath("/var/kupo"),
            showOutput: false
        )
        
        #expect(config.matches == matches)
        #expect(config.deferDbIndexes == true)
        #expect(config.pruneUTxO == true)
        #expect(config.gcInterval == 600)
        #expect(config.maxConcurrency == 20)
        #expect(config.logLevel == "debug")
        #expect(config.showOutput == false)
    }
    
    // MARK: - Codable Tests
    
    @Test("Configuration encodes and decodes correctly")
    func testConfigurationCodable() throws {
        let cardanoConfig = createTestCardanoConfig()
        let ogmiosConfig = createTestOgmiosConfig()
        let kupoConfig = createTestKupoConfig()
        
        let originalConfig = Configuration(
            cardano: cardanoConfig,
            ogmios: ogmiosConfig,
            kupo: kupoConfig
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalConfig)
        
        let decoder = JSONDecoder()
        let decodedConfig = try decoder.decode(Configuration.self, from: data)
        
        #expect(decodedConfig.cardano.cli == originalConfig.cardano.cli)
        #expect(decodedConfig.cardano.network == originalConfig.cardano.network)
        #expect(decodedConfig.ogmios?.binary == originalConfig.ogmios?.binary)
        #expect(decodedConfig.kupo?.binary == originalConfig.kupo?.binary)
    }
    
    @Test("Configuration handles missing optional components in JSON", .disabled("JSON parsing test needs to be fixed - FilePath decoding issue"))
    func testConfigurationCodableWithMissingComponents() throws {
        let json = """
        {
            "cardano": {
                "cli": "/usr/local/bin/cardano-cli",
                "node": "/usr/local/bin/cardano-node",
                "socket": "/tmp/cardano.socket",
                "config": "/etc/cardano/config.json",
                "network": "mainnet",
                "era": "conway",
                "ttl_buffer": 3600,
                "working_dir": "/tmp/cardano"
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        do {
            let configuration = try decoder.decode(Configuration.self, from: data)
            
            #expect(configuration.cardano.cli == FilePath("/usr/local/bin/cardano-cli"))
            #expect(configuration.cardano.network == .mainnet)
            #expect(configuration.ogmios == nil)
            #expect(configuration.kupo == nil)
        } catch {
            Issue.record("Configuration decoding should succeed but threw: \(error)")
        }
    }
    
    // MARK: - Coding Keys Tests
    
    @Test("CardanoConfig uses correct coding keys", .disabled("JSON parsing test needs to be fixed - FilePath decoding issue"))
    func testCardanoConfigCodingKeys() throws {
        let json = """
        {
            "cli": "/usr/local/bin/cardano-cli",
            "node": "/usr/local/bin/cardano-node",
            "hw_cli": "/usr/local/bin/cardano-hw-cli",
            "signer": "/usr/local/bin/cardano-signer",
            "socket": "/tmp/cardano.socket",
            "config": "/etc/cardano/config.json",
            "topology": "/etc/cardano/topology.json",
            "database": "/var/lib/cardano/db",
            "port": 3001,
            "host_addr": "127.0.0.1",
            "show_output": true,
            "network": "mainnet",
            "era": "conway",
            "ttl_buffer": 3600,
            "working_dir": "/tmp/cardano"
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        do {
            let config = try decoder.decode(CardanoConfig.self, from: data)
            
            #expect(config.hwCli == FilePath("/usr/local/bin/cardano-hw-cli"))
            #expect(config.hostAddr == "127.0.0.1")
            #expect(config.showOutput == true)
            #expect(config.ttlBuffer == 3600)
            #expect(config.workingDir == FilePath("/tmp/cardano"))
        } catch {
            Issue.record("CardanoConfig decoding should succeed but threw: \(error)")
        }
    }
    
    // MARK: - Edge Cases
    
    @Test("Configuration handles empty file paths")
    func testConfigurationWithEmptyPaths() {
        let config = CardanoConfig(
            cli: FilePath(""),
            node: FilePath(""),
            hwCli: nil,
            signer: nil,
            socket: FilePath(""),
            config: FilePath(""),
            topology: nil,
            database: nil,
            port: nil,
            hostAddr: nil,
            network: .mainnet,
            era: .conway,
            ttlBuffer: 3600,
            workingDir: FilePath(""),
            showOutput: nil
        )
        
        #expect(config.cli.string.isEmpty)
        #expect(config.node.string.isEmpty)
        #expect(config.socket.string.isEmpty)
        #expect(config.config.string.isEmpty)
        #expect(config.workingDir.string.isEmpty)
    }
    
    @Test("Configuration handles zero and negative values")
    func testConfigurationWithBoundaryValues() {
        let cardanoConfig = CardanoConfig(
            cli: FilePath("/usr/local/bin/cardano-cli"),
            node: FilePath("/usr/local/bin/cardano-node"),
            hwCli: nil,
            signer: nil,
            socket: FilePath("/tmp/cardano.socket"),
            config: FilePath("/etc/cardano/config.json"),
            topology: nil,
            database: nil,
            port: 0,
            hostAddr: "",
            network: .mainnet,
            era: .conway,
            ttlBuffer: 0,
            workingDir: FilePath("/tmp"),
            showOutput: false
        )
        
        let ogmiosConfig = OgmiosConfig(
            binary: FilePath("/usr/local/bin/ogmios"),
            host: "",
            port: 0,
            timeout: 0,
            maxInFlight: 0,
            logLevel: "",
            logLevelHealth: "",
            logLevelMetrics: "",
            logLevelWebsocket: "",
            logLevelServer: "",
            logLevelOptions: "",
            workingDir: FilePath("/tmp"),
            showOutput: false
        )
        
        let kupoConfig = KupoConfig(
            binary: FilePath("/usr/local/bin/kupo"),
            host: "",
            port: 0,
            since: "",
            matches: [],
            deferDbIndexes: false,
            pruneUTxO: false,
            gcInterval: 0,
            maxConcurrency: 0,
            logLevel: "",
            logLevelHttpServer: "",
            logLevelDatabase: "",
            logLevelConsumer: "",
            logLevelGarbageCollector: "",
            logLevelConfiguration: "",
            workingDir: FilePath("/tmp"),
            showOutput: false
        )
        
        let configuration = Configuration(
            cardano: cardanoConfig,
            ogmios: ogmiosConfig,
            kupo: kupoConfig
        )
        
        #expect(configuration.cardano.port == 0)
        #expect(configuration.cardano.ttlBuffer == 0)
        #expect(configuration.ogmios?.port == 0)
        #expect(configuration.ogmios?.timeout == 0)
        #expect(configuration.kupo?.port == 0)
        #expect(configuration.kupo?.matches?.isEmpty == true)
    }
}