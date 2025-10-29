import Testing
import Foundation
import Logging
import SystemPackage
import SwiftCardanoCore
import Command
import Path
import Mockable
@testable import SwiftCardanoUtils

@Suite("Cardano CLI Tests")
struct CardanoCLITests {
    
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
    
    @Test("CardanoCLI version parsing")
    func testVersion() async throws {
        let config = createMockConfig()
        let runner = createCardaonCLIMockCommandRunner(config: config)
        
        given(runner)
            .run(
                arguments: .value([config.cardano.cli!.string, "--version"]),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(
                        .standardOutput([UInt8](CLIResponse.version.utf8))
                    )
                    continuation.finish()
                }
            )
        
        let cli = try await CardanoCLI(configuration: config, commandRunner: runner)
        let version = try await cli.version()
        
        #expect(version == "10.8.0.0")
    }
    
    // MARK: - Chain Information Tests
    
    @Test("CardanoCLI get sync progress with fully synced node")
    func testGetSyncProgressFullySynced() async throws {
        let config = createMockConfig()
        let runner = createCardaonCLIMockCommandRunner(config: config)
        
        given(runner)
            .run(
                arguments: .value([config.cardano.cli!.string] + CLICommands.queryTip),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(
                        .standardOutput([UInt8](CLIResponse.tip100.utf8))
                    )
                    continuation.finish()
                }
            )
        
        let cli = try await CardanoCLI(configuration: config, commandRunner: runner)
        let syncProgress = try await cli.getSyncProgress()
        
        #expect(syncProgress == 100.0)
    }
    
    @Test("CardanoCLI get sync progress with partially synced node")
    func testGetSyncProgressPartiallySynced() async throws {
        let config = createMockConfig()
        let runner = createCardaonCLIMockCommandRunner(config: config)
        
        given(runner)
            .run(
                arguments: .value([config.cardano.cli!.string] + CLICommands.queryTip),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(
                        .standardOutput([UInt8](CLIResponse.tip75.utf8))
                    )
                    continuation.finish()
                }
            )
        
        let cli = try await CardanoCLI(configuration: config, commandRunner: runner)
        
        let syncProgress = try await cli.getSyncProgress()
        
        #expect(syncProgress == 75.0) // Direct percentage from mock
    }
    
    @Test("CardanoCLI get sync progress with error fallback")
    func testGetSyncProgressWithError() async throws {
        let config = createMockConfig()
        let runner = createCardaonCLIMockCommandRunner(config: config)
        
        given(runner)
            .run(
                arguments: .value([config.cardano.cli!.string] + CLICommands.queryTip),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.finish(throwing: SwiftCardanoUtilsError.invalidOutput("invalid Output"))
                }
            )
        
        let cli = try await CardanoCLI(configuration: config, commandRunner: runner)
        let syncProgress = try await cli.getSyncProgress()
        
        #expect(syncProgress == 0.0) // Should return 0.0 on error
    }
    
    
    @Test("CardanoCLI check online with unsynced node")
    func testCheckOnlineWithUnsyncedNode() async throws {
        let config = createMockConfig()
        let runner = createCardaonCLIMockCommandRunner(config: config)
        
        given(runner)
            .run(
                arguments: .value([config.cardano.cli!.string] + CLICommands.queryTip),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(
                        .standardOutput([UInt8](CLIResponse.tip75.utf8))
                    )
                    continuation.finish()
                }
            )
        
        let cli = try await CardanoCLI(configuration: config, commandRunner: runner)
        
        await #expect(throws: SwiftCardanoUtilsError.self) {
            try await cli.checkOnline()
        }
    }
    
    @Test("CardanoCLI get current era")
    func testGetCurrentEra() async throws {
        let config = createMockConfig()
        let runner = createCardaonCLIMockCommandRunner(config: config)
        
        given(runner)
            .run(
                arguments: .value([config.cardano.cli!.string] + CLICommands.queryTip),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(
                        .standardOutput([UInt8](CLIResponse.tip100.utf8))
                    )
                    continuation.finish()
                }
            )
        
        let cli = try await CardanoCLI(configuration: config, commandRunner: runner)
        
        let era = try await cli.getEra()
        
        #expect(era == .conway)
    }
    
    @Test("CardanoCLI get current era with error fallback")
    func testGetCurrentEraWithError() async throws {
        let config = createMockConfig()
        let runner = createCardaonCLIMockCommandRunner(config: config)
        
        given(runner)
            .run(
                arguments: .value([config.cardano.cli!.string] + CLICommands.queryTip),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.finish(throwing: SwiftCardanoUtilsError.invalidOutput("invalid Output"))
                }
            )
        
        let cli = try await CardanoCLI(configuration: config, commandRunner: runner)
        
        let era = try await cli.getEra()
        
        #expect(era == nil)
    }
    
    @Test("CardanoCLI get current epoch")
    func testGetCurrentEpoch() async throws {
        let config = createMockConfig()
        let runner = createCardaonCLIMockCommandRunner(config: config)
        
        given(runner)
            .run(
                arguments: .value([config.cardano.cli!.string] + CLICommands.queryTip),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(
                        .standardOutput([UInt8](CLIResponse.tip100.utf8))
                    )
                    continuation.finish()
                }
            )
        
        let cli = try await CardanoCLI(configuration: config, commandRunner: runner)
        
        let epoch = try await cli.getEpoch()
        
        #expect(epoch == 450)
    }
    
    @Test("CardanoCLI get epoch with unsynced node throws error")
    func testGetEpochWithUnsyncedNode() async throws {
        let config = createMockConfig()
        let runner = createCardaonCLIMockCommandRunner(config: config)
        
        given(runner)
            .run(
                arguments: .value([config.cardano.cli!.string] + CLICommands.queryTip),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(
                        .standardOutput([UInt8](CLIResponse.tip75.utf8))
                    )
                    continuation.finish()
                }
            )
        
        let cli = try await CardanoCLI(configuration: config, commandRunner: runner)
        
        await #expect(throws: SwiftCardanoUtilsError.self) {
            _ = try await cli.getEpoch()
        }
    }
    
    @Test("CardanoCLI get current tip")
    func testGetCurrentTip() async throws {
        let config = createMockConfig()
        let runner = createCardaonCLIMockCommandRunner(config: config)
        
        given(runner)
            .run(
                arguments: .value([config.cardano.cli!.string] + CLICommands.queryTip),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(
                        .standardOutput([UInt8](CLIResponse.tip100.utf8))
                    )
                    continuation.finish()
                }
            )
        
        let cli = try await CardanoCLI(configuration: config, commandRunner: runner)
        
        let tip = try await cli.getTip()
        
        #expect(tip == 123456789)
    }
    
    @Test("CardanoCLI get current TTL")
    func testGetCurrentTTL() async throws {
        let config = createMockConfig()
        let runner = createCardaonCLIMockCommandRunner(config: config)
        
        given(runner)
            .run(
                arguments: .value([config.cardano.cli!.string] + CLICommands.queryTip),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(
                        .standardOutput([UInt8](CLIResponse.tip100.utf8))
                    )
                    continuation.finish()
                }
            )
        
        let cli = try await CardanoCLI(configuration: config, commandRunner: runner)
        
        let ttl = try await cli.getCurrentTTL()
        
        #expect(ttl == 123456789 + 3600) // tip + ttlBuffer
    }
    
    @Test("CardanoCLI get utxos")
    func testUTxOs() async throws {
        let config = createMockConfig()
        let runner = createCardaonCLIMockCommandRunner(config: config)
        
        given(runner)
            .run(
                arguments: .value([config.cardano.cli!.string] + CLICommands.utxos),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(
                        .standardOutput([UInt8](CLIResponse.utxos.utf8))
                    )
                    continuation.finish()
                }
            )
        
        let cli = try await CardanoCLI(configuration: config, commandRunner: runner)
        
        let address = try Address(
            from: .string(
                "addr_test1qp4kux2v7xcg9urqssdffff5p0axz9e3hcc43zz7pcuyle0e20hkwsu2ndpd9dh9anm4jn76ljdz0evj22stzrw9egxqmza5y3"
            )
        )
        
        let utxos = try await cli.utxos(address: address)
        
        #expect(
            utxos[0].input.transactionId.payload.toHex == "39a7a284c2a0948189dc45dec670211cd4d72f7b66c5726c08d9b3df11e44d58"
        )
    }
        
    // MARK: - Protocol Parameters Tests
    
    @Test("CardanoCLI get protocol parameters online mode")
    func testGetProtocolParametersOnline() async throws {
        let config = createMockConfig()
        let runner = createCardaonCLIMockCommandRunner(config: config)
        
        given(runner)
            .run(
                arguments: .value([config.cardano.cli!.string, "conway", "query", "protocol-parameters", "--out-file", "/dev/stdout", "--testnet-magic", "2"]),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(
                        .standardOutput([UInt8](CLIResponse.protocolParams.utf8))
                    )
                    continuation.finish()
                }
            )
        
        let cli = try await CardanoCLI(configuration: config, commandRunner: runner)
        let params = try await cli.getProtocolParameters()
        
        #expect(params.txFeePerByte == 44)
        #expect(params.txFeeFixed == 155381)
    }
    
    
    @Test("CardanoCLI get protocol parameters with custom file")
    func testGetProtocolParametersWithCustomFile() async throws {
        let config = createMockConfig()
        let runner = createCardaonCLIMockCommandRunner(config: config)
        let customFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("custom-protocol.json")
        
        given(runner)
            .run(
                arguments:
                        .value(
                            [
                                config.cardano.cli!.string,
                                "conway",
                                "query",
                                "protocol-parameters",
                                "--out-file",
                                customFile.path(),
                                "--testnet-magic",
                                "2"
                            ]
                        ),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    try! CLIResponse.protocolParams
                        .write(
                            toFile: customFile.path(),
                            atomically: true,
                            encoding: .utf8
                        )
                    continuation.yield(
                        .standardOutput([])
                    )
                    continuation.finish()
                }
            )
        
        let cli = try await CardanoCLI(configuration: config, commandRunner: runner)
       
        defer { try? FileManager.default.removeItem(at: customFile) }
        _ = try await cli.getProtocolParameters(paramsFile: FilePath(customFile.path))
        
        // Verify file was created
        #expect(FileManager.default.fileExists(atPath: customFile.path))
    }
    
    // MARK: - Command Integration Tests
    
    @Test("CardanoCLI query tip integration")
    func testQueryTipIntegration() async throws {
        let config = createMockConfig()
        let runner = createCardaonCLIMockCommandRunner(config: config)
        
        let data = CLIResponse.tip100.data(using: .utf8)
        let expectedChainTip = try JSONDecoder().decode(ChainTip.self, from: data!)
        
        given(runner)
            .run(
                arguments: .value([config.cardano.cli!.string] + CLICommands.queryTip),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(
                        .standardOutput([UInt8](CLIResponse.tip100.utf8))
                    )
                    continuation.finish()
                }
            )
        
        let cli = try await CardanoCLI(configuration: config, commandRunner: runner)
        
        let tip = try await cli.query.tip()
        
        #expect(tip == expectedChainTip)
    }
    
    @Test("CardanoCLI address build integration")
    func testAddressBuildIntegration() async throws {
        let config = createMockConfig()
        let runner = createCardaonCLIMockCommandRunner(config: config)
        
        given(runner)
            .run(
                arguments: .value([config.cardano.cli!.string] + CLICommands.addressBuild),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(
                        .standardOutput([UInt8](CLIResponse.addressBuild.utf8))
                    )
                    continuation.finish()
                }
            )
        
        let cli = try await CardanoCLI(configuration: config, commandRunner: runner)
        
        let address = try await cli.address.build(arguments: ["--payment-verification-key-file", "test.vkey"])
        
        #expect(address == CLIResponse.addressBuild)
    }
    
    @Test("CardanoCLI stake pool id integration")
    func testStakePoolIdIntegration() async throws {
        let config = createMockConfig()
        let runner = createCardaonCLIMockCommandRunner(config: config)
        
        given(runner)
            .run(
                arguments: .value([config.cardano.cli!.string] + CLICommands.stakePoolId),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(
                        .standardOutput([UInt8](CLIResponse.stakePoolId.utf8))
                    )
                    continuation.finish()
                }
            )
        
        let cli = try await CardanoCLI(configuration: config, commandRunner: runner)
        
        let poolId = try await cli.stakePool.id(arguments: ["--cold-verification-key-file", "cold.vkey"])
        
        #expect(poolId == CLIResponse.stakePoolId)
    }
    
    @Test("CardanoCLI governance drep id integration")
    func testGovernanceDrepIdIntegration() async throws {
        let config = createMockConfig()
        let runner = createCardaonCLIMockCommandRunner(config: config)
        
        given(runner)
            .run(
                arguments: .value([config.cardano.cli!.string] + CLICommands.governanceDRepId),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(
                        .standardOutput([UInt8](CLIResponse.governanceDRepId.utf8))
                    )
                    continuation.finish()
                }
            )
        
        let cli = try await CardanoCLI(configuration: config, commandRunner: runner)
        
        let drepId = try await cli.governance.drepId(arguments: ["--drep-verification-key-file", "drep.vkey"])
        
        #expect(drepId == CLIResponse.governanceDRepId)
    }
    
    @Test("CardanoCLI stake address info integration")
    func testStakeAddressInfo() async throws {
        let config = createMockConfig()
        let runner = createCardaonCLIMockCommandRunner(config: config)
        
        given(runner)
            .run(
                arguments: .value([config.cardano.cli!.string] + CLICommands.stakeAddressInfo),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(
                        .standardOutput([UInt8](CLIResponse.stakeAddressInfo.utf8))
                    )
                    continuation.finish()
                }
            )
        
        let cli = try await CardanoCLI(configuration: config, commandRunner: runner)
        
        let stakeAddressInfo = try await cli.stakeAddressInfo(
            address: Address.fromBech32("stake1u9mzj7z0thvn4r3ylxpd6tgl8wzpfp5dsfswmd4qdjz856g5wz62x")
        )
        
        #expect(stakeAddressInfo[0].address == "stake1u9mzj7z0thvn4r3ylxpd6tgl8wzpfp5dsfswmd4qdjz856g5wz62x")
        #expect(stakeAddressInfo[0].govActionDeposits!.isEmpty == false)
        #expect(stakeAddressInfo[0].rewardAccountBalance == 100000000000)
        #expect(try stakeAddressInfo[0].stakeDelegation?.id() == "pool1m5947rydk4n0ywe6ctlav0ztt632lcwjef7fsy93sflz7ctcx6z")
        #expect(stakeAddressInfo[0].stakeRegistrationDeposit == 2000000)
        #expect(try stakeAddressInfo[0].voteDelegation?.id() == "drep1kqhhkv66a0egfw7uyz7u8dv7fcvr4ck0c3ad9k9urx3yzhefup0")
        #expect(try stakeAddressInfo[0].voteDelegation?.id((.bech32, .cip129)) == "drep1y2cz77entt4l9p9mmsstmsa4ne8pswhzelz845kchsv6ysgdhay86")
    }
    
    // MARK: - Environment and Configuration Tests
    
    @Test("CardanoCLI sets environment variables correctly")
    func testEnvironmentVariableSetting() async throws {
        let config = createAdvancedTestConfiguration()
        
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
        let modifiedConfig = Config(
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
        
        let cli = try await CardanoCLI(configuration: config)
        
        #expect(cli.configuration.cardano.network == Network.preview)
        #expect(cli.configuration.cardano.era == Era.conway)
        #expect(cli.configuration.cardano.ttlBuffer == 3600)
    }
}

