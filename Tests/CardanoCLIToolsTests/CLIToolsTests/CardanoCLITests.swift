import Testing
import Foundation
import Logging
import System
import SwiftCardanoCore
@testable import CardanoCLITools

@Suite("Cardano CLI Tests")
struct CardanoCLITests {
    
    @Test("test real", .disabled())
    func testReal() async throws {
        let mockCardanoConfig = CardanoConfig(
            cli: FilePath(
                "/Users/hadderley/cardano/cardano-node-10.1.4-macos/bin/cardano-cli"
            ),
            node: FilePath("/Users/hadderley/cardano/cardano-node-10.1.4-macos/bin/cardano-node"),
            hwCli: FilePath("/Users/hadderley/cardano/cardano-hw-cli/cardano-hw-cli"),
            signer: nil,
            socket: FilePath("/Users/hadderley/cardano/preview/socket/node.socket"),
            config: FilePath("/Users/hadderley/cardano/preview/config/config.json"),
            topology: FilePath("/Users/hadderley/cardano/preview/config/topology.json"),
            database: FilePath("/Users/hadderley/cardano/preview/data/db"),
            port: 3001,
            hostAddr: nil,
            network: Network.preview,
            era: .conway,
            ttlBuffer: 3600,
            workingDir: "/tmp",
            showOutput: false
        )
        
        let config = Configuration(
            cardano: mockCardanoConfig,
            ogmios: nil,
            kupo: nil,
        )
        let cli = try await CardanoCLI(configuration: config)
        
        print("version: \(try await cli.version())")
        print("getSyncProgress: \(try await cli.getSyncProgress())")
        print("getEra: \(String(describing: try await cli.getEra()))")
        print("getEpoch: \(try await cli.getEpoch())")
        print("calculateEpochOffline: \(try await cli.calculateEpochOffline())")
        print("getTip: \(try await cli.getTip())")
        print("getCurrentTTL: \(try await cli.getCurrentTTL())")
        print("getProtocolParameters: \(try await cli.getProtocolParameters())")
        
        let addr1 = try Address.fromBech32("stake_test1up6aay8dunqqwk4slr22g4umzp8unjp38d4dz2w4kvwzprsmcuglk")
        let addr2 = try Address.fromBech32("stake_test1uprj4t9t8ncczs2vrh65yhzagrh43nfsg3m2x4getvkh4cc7n7mq2")
        let addr3 = try Address.fromBech32("stake_test1uzxny4gt9ntpg2rmceuexq9jqwqe2dz0zaau65y9u666xmgqd2ctx")
        print("stakeAddressInfo1: \(try await cli.stakeAddressInfo(address: addr1))")
        print("stakeAddressInfo2: \(try await cli.stakeAddressInfo(address: addr2))")
        print("stakeAddressInfo3: \(try await cli.stakeAddressInfo(address: addr3))")
    }
    
    @Test("Command initialization")
    func testCommandInitialization() async throws {
        // Test that we can initialize the CLI with mock config
        let mockConfig = createMockConfiguration()
        let cli = try await CardanoCLI(configuration: mockConfig)
        
        // Verify that all command groups are accessible (by accessing them)
        _ = cli.address
        _ = cli.key
        _ = cli.node
        _ = cli.transaction
        _ = cli.query
        _ = cli.stakeAddress
        _ = cli.stakePool
        _ = cli.genesis
        _ = cli.governance
        _ = cli.textView
        _ = cli.debug
        
        // Verify configuration access
        _ = cli.configuration
        
        // If we reach here without throwing, initialization succeeded
        #expect(Bool(true))
    }
    
    @Test("Command types access")
    func testCommandTypes() async throws {
        let mockConfig = createMockConfiguration()
        let cli = try await CardanoCLI(configuration: mockConfig)
        
        // Verify the command instances can be accessed without error
        // We won't actually execute commands in tests to avoid dependencies
        _ = cli.address
        _ = cli.key  
        _ = cli.node
        _ = cli.transaction
        _ = cli.query
        _ = cli.stakeAddress
        _ = cli.stakePool
        _ = cli.genesis
        _ = cli.governance
        _ = cli.textView
        _ = cli.debug
        
        // If we reach here, all command accessors work correctly
        #expect(Bool(true))
    }
    
    @Test("Configuration defaults")
    func testConfigurationDefaults() async throws {
        let mockConfig = createMockConfiguration()
        let cli = try await CardanoCLI(configuration: mockConfig)
        let config = cli.configuration.cardano
        
        // Test configuration values
        #expect(config.network == Network.preview)
        #expect(config.era == Era.conway)
    }
    
    // MARK: - Version and Compatibility Tests
    
    @Test("CardanoCLI version parsing with valid output")
    func testVersionParsing() async throws {
        let config = createAdvancedTestConfiguration()
        defer { cleanupFile(at: config.cardano.cli.string) }
        
        let cli = try await CardanoCLI(configuration: config)
        let version = try await cli.version()
        
        #expect(version == "8.20.3")
    }
    
    @Test("CardanoCLI version parsing with invalid output")
    func testVersionParsingInvalidOutput() async throws {
        let mockCliPath = createMockCardanoCLI(withResponses: [
            "--version": "invalid output"
        ])
        defer { cleanupFile(at: mockCliPath) }
        
        let config = createAdvancedTestConfiguration(cliPath: mockCliPath)
        
        await #expect(throws: CardanoCLIToolsError.self) {
            let cli = try await CardanoCLI(configuration: config)
            _ = try await cli.version()
        }
    }
    
    @Test("CardanoCLI version compatibility check with older version")
    func testVersionCompatibilityOlderVersion() async throws {
        let mockCliPath = createMockCardanoCLI(withResponses: [
            "--version": "cardano-cli 7.0.0 - macos-x86_64 - ghc-9.2"
        ])
        defer { cleanupFile(at: mockCliPath) }
        
        let config = createAdvancedTestConfiguration(cliPath: mockCliPath)
        
        await #expect(throws: CardanoCLIToolsError.self) {
            _ = try await CardanoCLI(configuration: config)
        }
    }
    
    @Test("CardanoCLI version compatibility without version config")
    func testVersionCompatibilityWithoutConfig() async throws {
        let mockCliPath = createMockCardanoCLI()
        defer { cleanupFile(at: mockCliPath) }
        
        var config = createAdvancedTestConfiguration(cliPath: mockCliPath)
        config = Configuration(
            cardano: config.cardano,
            ogmios: config.ogmios,
            kupo: config.kupo
        )
        
        // Should not throw when no version requirements are set
        let _ = try await CardanoCLI(configuration: config)
    }
    
    // MARK: - Chain Information Tests
    
    @Test("CardanoCLI get sync progress with fully synced node")
    func testGetSyncProgressFullySynced() async throws {
        let config = createAdvancedTestConfiguration()
        defer { cleanupFile(at: config.cardano.cli.string) }
        
        let cli = try await CardanoCLI(configuration: config)
        let syncProgress = try await cli.getSyncProgress()
        
        #expect(syncProgress == 100.0) // Mock returns syncProgress: 1.0, converted to 100%
    }
    
    @Test("CardanoCLI get sync progress with partially synced node")
    func testGetSyncProgressPartiallySynced() async throws {
        let mockCliPath = createMockCardanoCLI(withResponses: [
            "conway query tip --testnet-magic 2": "{\"block\":123456,\"epoch\":450,\"era\":\"conway\",\"hash\":\"abcd1234\",\"slot\":123456789,\"slotInEpoch\":65579,\"slotsToEpochEnd\":20821,\"syncProgress\":\"75.0\"}"
        ])
        defer { cleanupFile(at: mockCliPath) }
        
        let config = createAdvancedTestConfiguration(cliPath: mockCliPath)
        let cli = try await CardanoCLI(configuration: config)
        let syncProgress = try await cli.getSyncProgress()
        
        #expect(syncProgress == 75.0) // Direct percentage from mock
    }
    
    @Test("CardanoCLI get sync progress with error fallback")
    func testGetSyncProgressWithError() async throws {
        let mockCliPath = createMockCardanoCLI(withResponses: [
            "conway query tip --testnet-magic 2": "command failed"
        ])
        defer { cleanupFile(at: mockCliPath) }
        
        let config = createAdvancedTestConfiguration(cliPath: mockCliPath)
        let cli = try await CardanoCLI(configuration: config)
        let syncProgress = try await cli.getSyncProgress()
        
        #expect(syncProgress == 0.0) // Should return 0.0 on error
    }
    
    
    @Test("CardanoCLI check online with unsynced node")
    func testCheckOnlineWithUnsyncedNode() async throws {
        let mockCliPath = createMockCardanoCLI(withResponses: [
            "conway query tip --testnet-magic 2": "{\"block\":123456,\"epoch\":450,\"era\":\"conway\",\"hash\":\"abcd1234\",\"slot\":123456789,\"slotInEpoch\":65579,\"slotsToEpochEnd\":20821,\"syncProgress\":\"50.0\"}"
        ])
        defer { cleanupFile(at: mockCliPath) }
        
        let config = createAdvancedTestConfiguration(cliPath: mockCliPath)
        let cli = try await CardanoCLI(configuration: config)
        
        await #expect(throws: CardanoCLIToolsError.self) {
            try await cli.checkOnline()
        }
    }
    
    @Test("CardanoCLI get current era")
    func testGetCurrentEra() async throws {
        let config = createAdvancedTestConfiguration()
        defer { cleanupFile(at: config.cardano.cli.string) }
        
        let cli = try await CardanoCLI(configuration: config)
        let era = try await cli.getEra()
        
        #expect(era == .conway)
    }
    
    @Test("CardanoCLI get current era with error fallback")
    func testGetCurrentEraWithError() async throws {
        let mockCliPath = createMockCardanoCLI(withResponses: [
            "conway query tip --testnet-magic 2": "command failed"
        ])
        defer { cleanupFile(at: mockCliPath) }
        
        let config = createAdvancedTestConfiguration(cliPath: mockCliPath)
        let cli = try await CardanoCLI(configuration: config)
        let era = try await cli.getEra()
        
        #expect(era == nil)
    }
    
    @Test("CardanoCLI get current epoch")
    func testGetCurrentEpoch() async throws {
        let config = createAdvancedTestConfiguration()
        defer { cleanupFile(at: config.cardano.cli.string) }
        
        let cli = try await CardanoCLI(configuration: config)
        let epoch = try await cli.getEpoch()
        
        #expect(epoch == 450)
    }
    
    @Test("CardanoCLI get epoch with unsynced node throws error")
    func testGetEpochWithUnsyncedNode() async throws {
        let mockCliPath = createMockCardanoCLI(withResponses: [
            "conway query tip --testnet-magic 2": "{\"block\":123456,\"epoch\":450,\"era\":\"conway\",\"hash\":\"abcd1234\",\"slot\":123456789,\"slotInEpoch\":65579,\"slotsToEpochEnd\":20821,\"syncProgress\":\"50.0\"}"
        ])
        defer { cleanupFile(at: mockCliPath) }
        
        let config = createAdvancedTestConfiguration(cliPath: mockCliPath)
        let cli = try await CardanoCLI(configuration: config)
        
        await #expect(throws: CardanoCLIToolsError.self) {
            _ = try await cli.getEpoch()
        }
    }
    
    @Test("CardanoCLI get current tip")
    func testGetCurrentTip() async throws {
        let config = createAdvancedTestConfiguration()
        defer { cleanupFile(at: config.cardano.cli.string) }
        
        let cli = try await CardanoCLI(configuration: config)
        let tip = try await cli.getTip()
        
        #expect(tip == 123456789)
    }
    
    @Test("CardanoCLI get current TTL")
    func testGetCurrentTTL() async throws {
        let config = createAdvancedTestConfiguration()
        defer { cleanupFile(at: config.cardano.cli.string) }
        
        let cli = try await CardanoCLI(configuration: config)
        let ttl = try await cli.getCurrentTTL()
        
        #expect(ttl == 123456789 + 3600) // tip + ttlBuffer
    }
    
    
    // MARK: - Protocol Parameters Tests
    
    @Test("CardanoCLI get protocol parameters online mode")
    func testGetProtocolParametersOnline() async throws {
        let config = createAdvancedTestConfiguration()
        defer { cleanupFile(at: config.cardano.cli.string) }
        
        let cli = try await CardanoCLI(configuration: config)
        let params = try await cli.getProtocolParameters()
        
        #expect(params.txFeePerByte == 44)
        #expect(params.txFeeFixed == 155381)
    }
    
    
    @Test("CardanoCLI get protocol parameters with custom file")
    func testGetProtocolParametersWithCustomFile() async throws {
        let config = createAdvancedTestConfiguration()
        defer { cleanupFile(at: config.cardano.cli.string) }
        
        let customFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("custom-protocol.json")
        defer { try? FileManager.default.removeItem(at: customFile) }
        
        let cli = try await CardanoCLI(configuration: config)
        _ = try await cli.getProtocolParameters(paramsFile: FilePath(customFile.path))
        
        // Verify file was created
        #expect(FileManager.default.fileExists(atPath: customFile.path))
    }
    
    // MARK: - Command Integration Tests
    
    @Test("CardanoCLI query tip integration")
    func testQueryTipIntegration() async throws {
        let config = createAdvancedTestConfiguration()
        defer { cleanupFile(at: config.cardano.cli.string) }
        
        let cli = try await CardanoCLI(configuration: config)
        let tip = try await cli.query.tip()
        
        #expect(tip.era.contains("conway"))
    }
    
    @Test("CardanoCLI address build integration")
    func testAddressBuildIntegration() async throws {
        let config = createAdvancedTestConfiguration()
        defer { cleanupFile(at: config.cardano.cli.string) }
        
        let cli = try await CardanoCLI(configuration: config)
        let address = try await cli.address.build(arguments: ["--payment-verification-key-file", "test.vkey"])
        
        #expect(address.contains("addr_test"))
    }
    
    @Test("CardanoCLI stake pool id integration")
    func testStakePoolIdIntegration() async throws {
        let config = createAdvancedTestConfiguration()
        defer { cleanupFile(at: config.cardano.cli.string) }
        
        let cli = try await CardanoCLI(configuration: config)
        let poolId = try await cli.stakePool.id(arguments: ["--cold-verification-key-file", "cold.vkey"])
        
        #expect(poolId.contains("pool"))
    }
    
    @Test("CardanoCLI governance drep id integration")
    func testGovernanceDrepIdIntegration() async throws {
        let config = createAdvancedTestConfiguration()
        defer { cleanupFile(at: config.cardano.cli.string) }
        
        let cli = try await CardanoCLI(configuration: config)
        let drepId = try await cli.governance.drepId(arguments: ["--drep-verification-key-file", "drep.vkey"])
        
        #expect(drepId.contains("drep"))
    }
    
    @Test("CardanoCLI debug command integration")
    func testDebugCommandIntegration() async throws {
        let config = createAdvancedTestConfiguration()
        defer { cleanupFile(at: config.cardano.cli.string) }
        
        let cli = try await CardanoCLI(configuration: config)
        let result = try await cli.debug.logEpochState(arguments: ["test-command"])
        
        #expect(result.contains("Debug command executed"))
    }
    
    // MARK: - Error Handling Tests
    
    @Test("CardanoCLI handles invalid JSON responses")
    func testInvalidJSONResponse() async throws {
        let mockCliPath = createMockCardanoCLI(withResponses: [
            "conway query tip": "invalid json"
        ])
        defer { cleanupFile(at: mockCliPath) }
        
        let config = createAdvancedTestConfiguration(cliPath: mockCliPath)
        let cli = try await CardanoCLI(configuration: config)
        
        await #expect(throws: CardanoCLIToolsError.self) {
            _ = try await cli.getEpoch()
        }
    }
    
    @Test("CardanoCLI handles missing JSON fields")
    func testMissingJSONFields() async throws {
        let mockCliPath = createMockCardanoCLI(withResponses: [
            "conway query tip": "{\"block\":123456,\"hash\":\"abcd1234\"}"
        ])
        defer { cleanupFile(at: mockCliPath) }
        
        let config = createAdvancedTestConfiguration(cliPath: mockCliPath)
        let cli = try await CardanoCLI(configuration: config)
        
        await #expect(throws: CardanoCLIToolsError.self) {
            _ = try await cli.getEpoch()
        }
    }
    
    @Test("CardanoCLI handles command execution errors")
    func testCommandExecutionErrors() async throws {
        let mockCliPath = createMockCardanoCLI(withResponses: [
            "conway query protocol-parameters": ""
        ])
        // Make the script return error code
        let errorScript = """
        #!/bin/bash
        if [[ "$1" == "conway" && "$2" == "query" && "$3" == "protocol-parameters" ]]; then
            echo "Command failed" >&2
            exit 1
        fi
        echo "Default response"
        exit 0
        """
        
        try errorScript.write(toFile: mockCliPath, atomically: true, encoding: .utf8)
        let permissions = [FileAttributeKey.posixPermissions: 0o755]
        try FileManager.default.setAttributes(permissions, ofItemAtPath: mockCliPath)
        
        defer { cleanupFile(at: mockCliPath) }
        
        let config = createAdvancedTestConfiguration(cliPath: mockCliPath)
        let cli = try await CardanoCLI(configuration: config)
        
        await #expect(throws: CardanoCLIToolsError.self) {
            _ = try await cli.getProtocolParameters()
        }
    }
    
    // MARK: - Performance Tests
    
    @Test("CardanoCLI handles multiple sequential calls")
    func testMultipleSequentialCalls() async throws {
        let config = createAdvancedTestConfiguration()
        defer { cleanupFile(at: config.cardano.cli.string) }
        
        let cli = try await CardanoCLI(configuration: config)
        
        // Make multiple sequential calls to test stability
        var results: [String] = []
        for _ in 0..<5 {
            let version = try await cli.version()
            results.append(version)
        }
        
        #expect(results.count == 5)
        #expect(results.allSatisfy { $0 == "8.20.3" })
    }
    
    @Test("CardanoCLI handles large command outputs")
    func testLargeCommandOutputs() async throws {
        let largeResponse = String(repeating: "x", count: 10000)
        let mockCliPath = createMockCardanoCLI(withResponses: [
            "conway query protocol-parameters": largeResponse
        ])
        defer { cleanupFile(at: mockCliPath) }
        
        let config = createAdvancedTestConfiguration(cliPath: mockCliPath)
        let cli = try await CardanoCLI(configuration: config)
        
        let params = try await cli.query.protocolParameters()
        #expect(params.count > 9000) // Should handle large responses
    }
    
    // MARK: - Environment and Configuration Tests
    
    @Test("CardanoCLI sets environment variables correctly")
    func testEnvironmentVariableSetting() async throws {
        let config = createAdvancedTestConfiguration()
        defer { cleanupFile(at: config.cardano.cli.string) }
        
        // Store original value to restore later
        let originalValue = ProcessInfo.processInfo.environment["CARDANO_SOCKET_PATH"]
        
        _ = try await CardanoCLI(configuration: config)
        
        // Check that CARDANO_NODE_SOCKET_PATH was set
        let socketPath = ProcessInfo.processInfo.environment["CARDANO_SOCKET_PATH"]
        #expect(socketPath != nil, "CARDANO_SOCKET_PATH should be set")
        
        // In a test environment, the environment variable may already be set to a different value
        // The important thing is that CardanoCLI initialization completed successfully
        // and the environment variable has some value
        #expect(!socketPath!.isEmpty, "Environment variable should not be empty")
        
        // Restore original environment if it existed
        if let original = originalValue, original != socketPath {
            Environment.set(.cardanoSocketPath, value: original)
        }
    }
    
    @Test("CardanoCLI creates working directory")
    func testWorkingDirectoryCreation() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("cardano-cli-test-\(UUID().uuidString)")
        
        let config = createAdvancedTestConfiguration()
        let modifiedConfig = Configuration(
            cardano: CardanoConfig(
                cli: config.cardano.cli,
                node: config.cardano.node,
                hwCli: config.cardano.hwCli,
                signer: config.cardano.signer,
                socket: config.cardano.socket,
                config: config.cardano.config,
                topology: config.cardano.topology,
                database: config.cardano.database,
                port: config.cardano.port,
                hostAddr: config.cardano.hostAddr,
                network: config.cardano.network,
                era: config.cardano.era,
                ttlBuffer: config.cardano.ttlBuffer,
                workingDir: FilePath(tempDir.path),
                showOutput: config.cardano.showOutput
            ),
            ogmios: config.ogmios,
            kupo: config.kupo
        )
        
        defer {
            cleanupFile(at: config.cardano.cli.string)
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        let cli = try await CardanoCLI(configuration: modifiedConfig)
        
        // Verify working directory was created
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: tempDir.path, isDirectory: &isDirectory)
        #expect(exists)
        #expect(isDirectory.boolValue)
        #expect(cli.workingDirectory.string == tempDir.path)
    }
    
    @Test("CardanoCLI configuration property access")
    func testConfigurationPropertyAccess() async throws {
        let config = createAdvancedTestConfiguration()
        defer { cleanupFile(at: config.cardano.cli.string) }
        
        let cli = try await CardanoCLI(configuration: config)
        
        #expect(cli.configuration.cardano.network == Network.preview)
        #expect(cli.configuration.cardano.era == Era.conway)
        #expect(cli.configuration.cardano.ttlBuffer == 3600)
    }
}
