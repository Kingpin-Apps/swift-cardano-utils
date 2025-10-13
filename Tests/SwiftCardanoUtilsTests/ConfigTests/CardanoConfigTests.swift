import Testing
import Foundation
import SystemPackage
import SwiftCardanoCore
import Configuration
@testable import SwiftCardanoUtils

@Suite("CardanoConfig Tests")
struct CardanoConfigTests {
    
    // MARK: - Test Helper Methods
    
    private func createMinimalConfig() -> CardanoConfig {
        return CardanoConfig(
            network: .preview,
            era: .conway,
            ttlBuffer: 3600,
            workingDir: FilePath("/tmp/cardano")
        )
    }
    
    private func createFullConfig() -> CardanoConfig {
        return CardanoConfig(
            cli: FilePath("/usr/local/bin/cardano-cli"),
            node: FilePath("/usr/local/bin/cardano-node"),
            hwCli: FilePath("/usr/local/bin/cardano-hw-cli"),
            signer: FilePath("/usr/local/bin/cardano-signer"),
            socket: FilePath("/tmp/cardano.socket"),
            config: FilePath("/etc/cardano/config.json"),
            topology: FilePath("/etc/cardano/topology.json"),
            database: FilePath("/var/lib/cardano/db"),
            immutableDatabase: FilePath("/var/lib/cardano/db/immutable"),
            volatileDatabase: FilePath("/var/lib/cardano/db/volatile"),
            port: 3001,
            hostAddr: "127.0.0.1",
            hostIPv6Addr: "::1",
            validateDb: true,
            nonProducingNode: false,
            tracerSocketPathAccept: FilePath("/tmp/tracer-accept.socket"),
            tracerSocketPathConnect: FilePath("/tmp/tracer-connect.socket"),
            byronDelegationCertificate: FilePath("/keys/byron-delegation.cert"),
            byronSigningKey: FilePath("/keys/byron-signing.key"),
            shelleyKesKey: FilePath("/keys/shelley-kes.skey"),
            shelleyVrfKey: FilePath("/keys/shelley-vrf.skey"),
            shelleyOperationalCertificate: FilePath("/keys/shelley-operational.cert"),
            bulkCredentialsFile: FilePath("/keys/bulk-credentials.json"),
            shutdownIpc: 42,
            shutdownOnSlotSynced: 1000000,
            shutdownOnBlockSynced: "block123abc",
            mempoolCapacityOverride: 2048,
            noMempoolCapacityOverride: false,
            network: .mainnet,
            era: .conway,
            ttlBuffer: 7200,
            workingDir: FilePath("/opt/cardano"),
            showOutput: true
        )
    }
    
    // MARK: - Initialization Tests
    
    @Test("CardanoConfig initializes with required parameters only")
    func testMinimalInitialization() {
        let config = createMinimalConfig()
        
        #expect(config.cli == nil)
        #expect(config.node == nil)
        #expect(config.network == .preview)
        #expect(config.era == .conway)
        #expect(config.ttlBuffer == 3600)
        #expect(config.workingDir!.string == "/tmp/cardano")
    }
    
    @Test("CardanoConfig initializes with all parameters")
    func testFullInitialization() {
        let config = createFullConfig()
        
        // Binary paths
        #expect(config.cli?.string == "/usr/local/bin/cardano-cli")
        #expect(config.node?.string == "/usr/local/bin/cardano-node")
        #expect(config.hwCli?.string == "/usr/local/bin/cardano-hw-cli")
        #expect(config.signer?.string == "/usr/local/bin/cardano-signer")
        
        // Configuration files
        #expect(config.socket?.string == "/tmp/cardano.socket")
        #expect(config.config?.string == "/etc/cardano/config.json")
        #expect(config.topology?.string == "/etc/cardano/topology.json")
        
        // Database paths
        #expect(config.database?.string == "/var/lib/cardano/db")
        #expect(config.immutableDatabase?.string == "/var/lib/cardano/db/immutable")
        #expect(config.volatileDatabase?.string == "/var/lib/cardano/db/volatile")
        
        // Network configuration
        #expect(config.port == 3001)
        #expect(config.hostAddr == "127.0.0.1")
        #expect(config.hostIPv6Addr == "::1")
        
        // Node behavior flags
        #expect(config.validateDb == true)
        #expect(config.nonProducingNode == false)
        
        // Required parameters
        #expect(config.network == .mainnet)
        #expect(config.era == .conway)
        #expect(config.ttlBuffer == 7200)
        #expect(config.showOutput == true)
    }
    
    @Test("CardanoConfig handles optional parameters correctly")
    func testOptionalParameters() {
        let config = CardanoConfig(
            cli: FilePath("/usr/local/bin/cardano-cli"),
            node: FilePath("/usr/local/bin/cardano-node"),
            network: .preview,
            era: .conway,
            ttlBuffer: 3600,
            workingDir: FilePath("/tmp/cardano")
        )
        
        // These should be nil
        #expect(config.hwCli == nil)
        #expect(config.signer == nil)
        #expect(config.topology == nil)
        #expect(config.database == nil)
        #expect(config.port == nil)
        #expect(config.hostAddr == nil)
        #expect(config.showOutput == nil)
        
        // These should have values
        #expect(config.cli != nil)
        #expect(config.node != nil)
        #expect(config.network == .preview)
    }
    
    // MARK: - JSON Serialization Tests
    
    @Test("CardanoConfig encodes to JSON with correct keys")
    func testJSONEncoding() throws {
        let config = createFullConfig()
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(config)
        let jsonString = String(data: data, encoding: .utf8)!
        
        // Check snake_case keys are used
        #expect(jsonString.contains("\"hw_cli\""))
        #expect(jsonString.contains("\"host_addr\""))
        #expect(jsonString.contains("\"host_ipv6_addr\""))
        #expect(jsonString.contains("\"validate_db\""))
        #expect(jsonString.contains("\"non_producing_node\""))
        #expect(jsonString.contains("\"ttl_buffer\""))
        #expect(jsonString.contains("\"working_dir\""))
        #expect(jsonString.contains("\"show_output\""))
        
        // Check complex keys
        #expect(jsonString.contains("\"immutable_database\""))
        #expect(jsonString.contains("\"volatile_database\""))
        #expect(jsonString.contains("\"tracer_socket_path_accept\""))
        #expect(jsonString.contains("\"byron_delegation_certificate\""))
        #expect(jsonString.contains("\"shelley_kes_key\""))
        #expect(jsonString.contains("\"shutdown_on_slot_synced\""))
        #expect(jsonString.contains("\"mempool_capacity_override\""))
    }
    
    @Test("CardanoConfig decodes from JSON correctly")
    func testJSONDecoding() throws {
        let originalConfig = createFullConfig()
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalConfig)
        
        let decoder = JSONDecoder()
        let decodedConfig = try decoder.decode(CardanoConfig.self, from: data)
        
        #expect(decodedConfig.cli == originalConfig.cli)
        #expect(decodedConfig.network == originalConfig.network)
        #expect(decodedConfig.era == originalConfig.era)
        #expect(decodedConfig.ttlBuffer == originalConfig.ttlBuffer)
        #expect(decodedConfig.validateDb == originalConfig.validateDb)
        #expect(decodedConfig.shutdownOnSlotSynced == originalConfig.shutdownOnSlotSynced)
    }
    
    // MARK: - Default Configuration Tests
    
    @Test("CardanoConfig default configuration is valid")
    func testDefaultConfiguration() {
        #expect(throws: Never.self) {
            let config = try CardanoConfig.default()
            
            #expect(config.network == .mainnet)
            #expect(config.era == .conway)
            #expect(config.ttlBuffer == 3600)
            #expect(config.workingDir!.string.isEmpty == false)
        }
    }
    
    // MARK: - Validation Tests
    
    @Test("CardanoConfig validates TTL buffer range")
    func testTTLBufferValidation() throws {
        // Very small TTL buffer should still work
        let config1 = CardanoConfig(
            network: .preview,
            era: .conway,
            ttlBuffer: 1,
            workingDir: FilePath("/tmp")
        )
        #expect(config1.ttlBuffer == 1)
        
        // Large TTL buffer should work
        let config2 = CardanoConfig(
            network: .preview,
            era: .conway,
            ttlBuffer: 86400, // 1 day
            workingDir: FilePath("/tmp")
        )
        #expect(config2.ttlBuffer == 86400)
    }
    
    // MARK: - Error Handling Tests
    
    @Test("CardanoConfig handles invalid network gracefully")
    func testInvalidNetwork() {
        let jsonData = """
        {
            "network": "invalid_network",
            "era": "conway",
            "ttl_buffer": 3600,
            "working_dir": "/tmp"
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        
        #expect(throws: Error.self) {
            _ = try decoder.decode(CardanoConfig.self, from: jsonData)
        }
    }
    
    @Test("CardanoConfig handles invalid era gracefully")
    func testInvalidEra() {
        let jsonData = """
        {
            "network": "preview",
            "era": "invalid_era",
            "ttl_buffer": 3600,
            "working_dir": "/tmp"
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        
        #expect(throws: Error.self) {
            _ = try decoder.decode(CardanoConfig.self, from: jsonData)
        }
    }
    
    @Test("CardanoConfig requires mandatory fields")
    func testMandatoryFields() {
        let incompleteJSON = """
        {
            "network": "preview"
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        
        #expect(throws: Error.self) {
            _ = try decoder.decode(CardanoConfig.self, from: incompleteJSON)
        }
    }
}
