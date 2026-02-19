import Testing
import Foundation
import Logging
import SystemPackage
import SwiftCardanoCore
import Command
import Path
import Mockable
@testable import SwiftCardanoUtils

@Suite("Mithril Client Tests")
struct MithrilClientTests {
    
    // MARK: - Initialization Tests
    
    @Test("Command initialization")
    func testCommandInitialization() async throws {
        let config = createMithrilTestConfiguration()
        let runner = createMithrilClientMockCommandRunner(config: config)
        let client = try await MithrilClient(configuration: config, commandRunner: runner)
        
        // Verify that all command groups are accessible
        _ = client.cardanoDb
        _ = client.mithrilStakeDistribution
        _ = client.cardanoTransaction
        _ = client.cardanoStakeDistribution
        _ = client.tools
        
        // Verify configuration access
        _ = client.configuration
        
        // If we reach here without throwing, initialization succeeded
        #expect(Bool(true))
    }
    
    @Test("Configuration defaults")
    func testConfigurationDefaults() async throws {
        let config = createMithrilTestConfiguration()
        let runner = createMithrilClientMockCommandRunner(config: config)
        let client = try await MithrilClient(configuration: config, commandRunner: runner)
        
        let mithrilConfig = client.configuration.mithril
        
        // Test configuration values
        #expect(mithrilConfig?.aggregatorEndpoint == "https://aggregator.release-preprod.api.mithril.network/aggregator")
        #expect(mithrilConfig?.genesisVerificationKey != nil)
    }
    
    // MARK: - Version Tests
    
    @Test("MithrilClient version parsing")
    func testVersion() async throws {
        let config = createMithrilTestConfiguration()
        let runner = createMithrilClientMockCommandRunner(config: config)
        
        given(runner)
            .run(
                arguments: .value([config.mithril!.binary!.string, "--version"]),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(
                        .standardOutput([UInt8](MithrilCLIResponse.version.utf8))
                    )
                    continuation.finish()
                }
            )
        
        let client = try await MithrilClient(configuration: config, commandRunner: runner)
        let version = try await client.version()
        
        #expect(version == "0.12.38")
    }
    
    // MARK: - Help Tests
    
    @Test("MithrilClient help command")
    func testHelp() async throws {
        let config = createMithrilTestConfiguration()
        let runner = createMithrilClientMockCommandRunner(config: config)
        
        given(runner)
            .run(
                arguments: .value([config.mithril!.binary!.string, "help"]),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(
                        .standardOutput([UInt8](MithrilCLIResponse.help.utf8))
                    )
                    continuation.finish()
                }
            )
        
        let client = try await MithrilClient(configuration: config, commandRunner: runner)
        let help = try await client.help()
        
        #expect(help.contains("mithril-client"))
        #expect(help.contains("cardano-db"))
    }
    
    // MARK: - Cardano DB Commands Tests
    
    @Test("MithrilClient cardano-db snapshot list")
    func testCardanoDbSnapshotList() async throws {
        let config = createMithrilTestConfiguration()
        let runner = createMithrilClientMockCommandRunner(config: config)
        
        given(runner)
            .run(
                arguments: .value([config.mithril!.binary!.string] + MithrilCLICommands.cardanoDbSnapshotList(config)),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(
                        .standardOutput([UInt8](MithrilCLIResponse.snapshotList.utf8))
                    )
                    continuation.finish()
                }
            )
        
        let client = try await MithrilClient(configuration: config, commandRunner: runner)
        let result = try await client.cardanoDb.snapshotList()
        
        #expect(result.contains("digest"))
        #expect(result.contains("network"))
    }
    
    @Test("MithrilClient cardano-db snapshot show")
    func testCardanoDbSnapshotShow() async throws {
        let config = createMithrilTestConfiguration()
        let runner = createMithrilClientMockCommandRunner(config: config)
        let digest = "abc123def456"
        
        given(runner)
            .run(
                arguments: .value([config.mithril!.binary!.string] + MithrilCLICommands.cardanoDbSnapshotShow(config, digest: digest)),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(
                        .standardOutput([UInt8](MithrilCLIResponse.snapshotShow.utf8))
                    )
                    continuation.finish()
                }
            )
        
        let client = try await MithrilClient(configuration: config, commandRunner: runner)
        let result = try await client.cardanoDb.snapshotShow(digest: digest)
        
        #expect(result.contains("digest"))
        #expect(result.contains("beacon"))
    }
    
    @Test("MithrilClient cardano-db download")
    func testCardanoDbDownload() async throws {
        let config = createMithrilTestConfiguration()
        let runner = createMithrilClientMockCommandRunner(config: config)
        
        given(runner)
            .run(
                arguments: .value([config.mithril!.binary!.string] + MithrilCLICommands.cardanoDbDownload(config)),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(
                        .standardOutput([UInt8](MithrilCLIResponse.downloadSuccess.utf8))
                    )
                    continuation.finish()
                }
            )
        
        let client = try await MithrilClient(configuration: config, commandRunner: runner)
        let result = try await client.cardanoDb.download(digest: "latest")
        
        #expect(result.contains("Download"))
    }
    
    @Test("MithrilClient cardano-db download with ancillary")
    func testCardanoDbDownloadWithAncillary() async throws {
        let config = createMithrilTestConfiguration()
        let runner = createMithrilClientMockCommandRunner(config: config)
        
        given(runner)
            .run(
                arguments: .value([config.mithril!.binary!.string] + MithrilCLICommands.cardanoDbDownloadWithAncillaryNoDir(config)),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(
                        .standardOutput([UInt8](MithrilCLIResponse.downloadSuccess.utf8))
                    )
                    continuation.finish()
                }
            )
        
        let client = try await MithrilClient(configuration: config, commandRunner: runner)
        let result = try await client.cardanoDb.download(
            digest: "latest",
            includeAncillary: true,
            ancillaryVerificationKey: config.mithril?.ancillaryVerificationKey
        )
        
        #expect(result.contains("Download"))
    }
    
    // MARK: - Mithril Stake Distribution Commands Tests
    
    @Test("MithrilClient mithril-stake-distribution list")
    func testMithrilStakeDistributionList() async throws {
        let config = createMithrilTestConfiguration()
        let runner = createMithrilClientMockCommandRunner(config: config)
        
        given(runner)
            .run(
                arguments: .value([config.mithril!.binary!.string] + MithrilCLICommands.mithrilStakeDistributionList(config)),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(
                        .standardOutput([UInt8](MithrilCLIResponse.stakeDistributionList.utf8))
                    )
                    continuation.finish()
                }
            )
        
        let client = try await MithrilClient(configuration: config, commandRunner: runner)
        let result = try await client.mithrilStakeDistribution.list()
        
        #expect(result.contains("epoch"))
        #expect(result.contains("hash"))
    }
    
    @Test("MithrilClient mithril-stake-distribution download")
    func testMithrilStakeDistributionDownload() async throws {
        let config = createMithrilTestConfiguration()
        let runner = createMithrilClientMockCommandRunner(config: config)
        let artifactHash = "abc123"
        
        given(runner)
            .run(
                arguments: .value([config.mithril!.binary!.string] + MithrilCLICommands.mithrilStakeDistributionDownload(config, hash: artifactHash)),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(
                        .standardOutput([UInt8](MithrilCLIResponse.downloadSuccess.utf8))
                    )
                    continuation.finish()
                }
            )
        
        let client = try await MithrilClient(configuration: config, commandRunner: runner)
        let result = try await client.mithrilStakeDistribution.download(artifactHash: artifactHash)
        
        #expect(result.contains("Download"))
    }
    
    // MARK: - Cardano Transaction Commands Tests
    
    @Test("MithrilClient cardano-transaction snapshot list")
    func testCardanoTransactionSnapshotList() async throws {
        let config = createMithrilTestConfiguration()
        let runner = createMithrilClientMockCommandRunner(config: config)
        
        given(runner)
            .run(
                arguments: .value([config.mithril!.binary!.string] + MithrilCLICommands.cardanoTransactionSnapshotList(config)),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(
                        .standardOutput([UInt8](MithrilCLIResponse.transactionSnapshotList.utf8))
                    )
                    continuation.finish()
                }
            )
        
        let client = try await MithrilClient(configuration: config, commandRunner: runner)
        let result = try await client.cardanoTransaction.snapshotList()
        
        #expect(result.contains("merkle_root"))
    }
    
    @Test("MithrilClient cardano-transaction certify")
    func testCardanoTransactionCertify() async throws {
        let config = createMithrilTestConfiguration()
        let runner = createMithrilClientMockCommandRunner(config: config)
        let txHash = "abc123def456789"
        
        given(runner)
            .run(
                arguments: .value([config.mithril!.binary!.string] + MithrilCLICommands.cardanoTransactionCertify(config, txHash: txHash)),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(
                        .standardOutput([UInt8](MithrilCLIResponse.certifySuccess.utf8))
                    )
                    continuation.finish()
                }
            )
        
        let client = try await MithrilClient(configuration: config, commandRunner: runner)
        let result = try await client.cardanoTransaction.certify(transactionHashes: [txHash])
        
        #expect(result.contains("certified"))
    }
    
    // MARK: - Cardano Stake Distribution Commands Tests
    
    @Test("MithrilClient cardano-stake-distribution list")
    func testCardanoStakeDistributionList() async throws {
        let config = createMithrilTestConfiguration()
        let runner = createMithrilClientMockCommandRunner(config: config)
        
        given(runner)
            .run(
                arguments: .value([config.mithril!.binary!.string] + MithrilCLICommands.cardanoStakeDistributionList(config)),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(
                        .standardOutput([UInt8](MithrilCLIResponse.cardanoStakeDistributionList.utf8))
                    )
                    continuation.finish()
                }
            )
        
        let client = try await MithrilClient(configuration: config, commandRunner: runner)
        let result = try await client.cardanoStakeDistribution.list()
        
        #expect(result.contains("epoch"))
    }
    
    // MARK: - High-Level Utility Methods Tests
    
    @Test("MithrilClient listSnapshots helper")
    func testListSnapshotsHelper() async throws {
        let config = createMithrilTestConfiguration()
        let runner = createMithrilClientMockCommandRunner(config: config)
        
        given(runner)
            .run(
                arguments: .value([config.mithril!.binary!.string] + MithrilCLICommands.cardanoDbSnapshotListJson(config)),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(
                        .standardOutput([UInt8](MithrilCLIResponse.snapshotList.utf8))
                    )
                    continuation.finish()
                }
            )
        
        let client = try await MithrilClient(configuration: config, commandRunner: runner)
        let result = try await client.listSnapshots()
        
        #expect(result.contains("digest"))
    }
    
    @Test("MithrilClient certifyTransaction helper")
    func testCertifyTransactionHelper() async throws {
        let config = createMithrilTestConfiguration()
        let runner = createMithrilClientMockCommandRunner(config: config)
        let txHash = "abc123def456789"
        
        given(runner)
            .run(
                arguments: .value([config.mithril!.binary!.string] + MithrilCLICommands.cardanoTransactionCertify(config, txHash: txHash)),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(
                        .standardOutput([UInt8](MithrilCLIResponse.certifySuccess.utf8))
                    )
                    continuation.finish()
                }
            )
        
        let client = try await MithrilClient(configuration: config, commandRunner: runner)
        let result = try await client.certifyTransaction(transactionHash: txHash)
        
        #expect(result.contains("certified"))
    }
    
    // MARK: - Working Directory Tests
    
    @Test("MithrilClient creates working directory")
    func testWorkingDirectoryCreation() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("mithril-client-test-\(UUID().uuidString)")
        
        var config = createMithrilTestConfiguration()
        config.mithril?.workingDir = FilePath(tempDir.path)
        
        let runner = createMithrilClientMockCommandRunner(config: config)
        
        let client = try await MithrilClient(configuration: config, commandRunner: runner)
        
        // Verify working directory was created
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: tempDir.path, isDirectory: &isDirectory)
        
        #expect(exists)
        #expect(isDirectory.boolValue)
        #expect(client.workingDirectory.string == tempDir.path)
        
        // Cleanup
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    // MARK: - Configuration Property Access Tests
    
    @Test("MithrilClient configuration property access")
    func testConfigurationPropertyAccess() async throws {
        let config = createMithrilTestConfiguration()
        let runner = createMithrilClientMockCommandRunner(config: config)
        let client = try await MithrilClient(configuration: config, commandRunner: runner)
        
        #expect(client.configuration.mithril?.aggregatorEndpoint == "https://aggregator.release-preprod.api.mithril.network/aggregator")
        #expect(client.configuration.mithril?.genesisVerificationKey != nil)
    }
}

// MARK: - Test Helpers

/// Creates a mock configuration for Mithril testing
func createMithrilTestConfiguration() -> Config {
    let cardanoConfig = CardanoConfig(
        cli: FilePath("/usr/bin/true"),
        node: FilePath("/usr/bin/true"),
        hwCli: FilePath("/usr/bin/true"),
        signer: nil,
        socket: FilePath("/tmp/test-socket"),
        config: FilePath("/tmp/test-config.json"),
        topology: nil,
        database: FilePath("/tmp/cardano-db"),
        port: nil,
        hostAddr: nil,
        network: Network.preview,
        era: Era.conway,
        ttlBuffer: 3600,
        workingDir: FilePath("/tmp/cardano-cli-tools"),
        showOutput: false
    )
    
    let mithrilConfig = MithrilConfig(
        binary: FilePath("/usr/bin/true"),
        aggregatorEndpoint: "https://aggregator.release-preprod.api.mithril.network/aggregator",
        genesisVerificationKey: "5b3132372c37332c3132342c3136312c362c3133372c3133312c3231332c3230372c3131372c3139382c38352c3137362c3139392c3136322c3234312c36382c3132332c3131392c3134352c31332c3233322c3234332c34392c3232392c322c3234392c3230352c3230352c33392c3232392c3235302c3234322c33342c3233342c3231332c3232352c33372c3231312c3231362c3135302c3233352c3134332c32352c3136342c3235302c3133345d",
        ancillaryVerificationKey: "5b3132372c37332c3132342c3136312c362c3133372c3133312c3231332c3230372c3131372c3139382c38352c3137362c3139392c3136322c3234312c36382c3132332c3131392c3134352c31332c3233322c3234332c34392c3232392c322c3234392c3230352c3230352c33392c3232392c3235302c3234322c33342c3233342c3231332c3232352c33372c3231312c3231362c3135302c3233352c3134332c32352c3136342c3235302c3133345d",
        downloadDir: FilePath("/tmp/mithril-downloads"),
        workingDir: FilePath("/tmp/mithril-working"),
        showOutput: false
    )
    
    return Config(
        cardano: cardanoConfig,
        ogmios: nil,
        kupo: nil,
        mithril: mithrilConfig
    )
}

func createMithrilClientMockCommandRunner(
    config: Config
) -> MockCommandRunning {
    let commandRunner = MockCommandRunning()
    given(commandRunner)
        .run(
            arguments: .value([config.mithril!.binary!.string, "--version"]),
            environment: .any,
            workingDirectory: .any
        )
        .willReturn(
            AsyncThrowingStream<CommandEvent, any Error> { continuation in
                continuation.yield(
                    .standardOutput([UInt8](MithrilCLIResponse.version.utf8))
                )
                continuation.finish()
            }
        )
    
    return commandRunner
}

// MARK: - Mithril CLI Commands

struct MithrilCLICommands {
    static func cardanoDbSnapshotList(_ config: Config) -> [String] {
        ["cardano-db", "snapshot", "--aggregator-endpoint", config.mithril!.aggregatorEndpoint!, "list"]
    }
    
    static func cardanoDbSnapshotListJson(_ config: Config) -> [String] {
        ["cardano-db", "snapshot", "--aggregator-endpoint", config.mithril!.aggregatorEndpoint!, "list", "--json"]
    }
    
    static func cardanoDbSnapshotShow(_ config: Config, digest: String) -> [String] {
        ["cardano-db", "snapshot", "--aggregator-endpoint", config.mithril!.aggregatorEndpoint!, "show", digest]
    }
    
    static func cardanoDbDownload(_ config: Config) -> [String] {
        ["cardano-db", "download", "--aggregator-endpoint", config.mithril!.aggregatorEndpoint!, "latest"]
    }
    
    static func cardanoDbDownloadWithAncillary(_ config: Config) -> [String] {
        ["cardano-db", "download", "--aggregator-endpoint", config.mithril!.aggregatorEndpoint!, "--download-dir", config.mithril!.downloadDir!.string, "--include-ancillary", "--ancillary-verification-key", config.mithril!.ancillaryVerificationKey!, "latest"]
    }
    
    static func cardanoDbDownloadWithAncillaryNoDir(_ config: Config) -> [String] {
        ["cardano-db", "download", "--aggregator-endpoint", config.mithril!.aggregatorEndpoint!, "--include-ancillary", "--ancillary-verification-key", config.mithril!.ancillaryVerificationKey!, "latest"]
    }
    
    static func mithrilStakeDistributionList(_ config: Config) -> [String] {
        ["mithril-stake-distribution", "list", "--aggregator-endpoint", config.mithril!.aggregatorEndpoint!]
    }
    
    static func mithrilStakeDistributionDownload(_ config: Config, hash: String) -> [String] {
        ["mithril-stake-distribution", "download", "--aggregator-endpoint", config.mithril!.aggregatorEndpoint!, hash]
    }
    
    static func cardanoTransactionSnapshotList(_ config: Config) -> [String] {
        ["cardano-transaction", "snapshot", "--aggregator-endpoint", config.mithril!.aggregatorEndpoint!, "list"]
    }
    
    static func cardanoTransactionCertify(_ config: Config, txHash: String) -> [String] {
        ["cardano-transaction", "certify", "--aggregator-endpoint", config.mithril!.aggregatorEndpoint!, "--transaction-hash", txHash]
    }
    
    static func cardanoStakeDistributionList(_ config: Config) -> [String] {
        ["cardano-stake-distribution", "list", "--aggregator-endpoint", config.mithril!.aggregatorEndpoint!]
    }
}

// MARK: - Mithril CLI Responses

struct MithrilCLIResponse {
    static let version = """
    mithril-client 0.12.38+abc123
    """
    
    static let help = """
    This program shows, downloads and verifies certified blockchain artifacts.

    Usage: mithril-client [OPTIONS] <COMMAND>

    Commands:
      cardano-db                   Cardano db management (alias: cdb)
      mithril-stake-distribution   Mithril stake distribution management (alias: msd)
      cardano-transaction          Cardano transactions management (alias: ctx)
      cardano-stake-distribution   Cardano stake distribution management (alias: csd)
      tools                        Tools commands
      help                         Print this message or the help of the given subcommand(s)
    """
    
    static let snapshotList = """
    [
        {
            "digest": "abc123def456",
            "network": "preprod",
            "beacon": {
                "epoch": 100,
                "immutable_file_number": 1234
            },
            "size": 12345678,
            "created_at": "2024-01-01T00:00:00Z"
        }
    ]
    """
    
    static let snapshotShow = """
    {
        "digest": "abc123def456",
        "network": "preprod",
        "beacon": {
            "epoch": 100,
            "immutable_file_number": 1234
        },
        "size": 12345678,
        "locations": ["https://example.com/snapshot.tar.gz"],
        "compression_algorithm": "zstd",
        "cardano_node_version": "8.7.3",
        "created_at": "2024-01-01T00:00:00Z"
    }
    """
    
    static let downloadSuccess = """
    1/6 - Checking local disk info…
    2/6 - Fetching the certificate's information…
    3/6 - Verifying the certificate chain…
    4/6 - Downloading and unpacking the snapshot…
    5/6 - Computing the snapshot digest…
    6/6 - Verifying the snapshot signature…
    Download completed successfully!
    """
    
    static let stakeDistributionList = """
    [
        {
            "epoch": 100,
            "hash": "abc123",
            "certificate_hash": "def456",
            "created_at": "2024-01-01T00:00:00Z"
        }
    ]
    """
    
    static let transactionSnapshotList = """
    [
        {
            "merkle_root": "abc123def456",
            "epoch": 100,
            "block_number": 12345,
            "hash": "snapshot123",
            "created_at": "2024-01-01T00:00:00Z"
        }
    ]
    """
    
    static let certifySuccess = """
    Transaction abc123def456789 is certified and included in the Cardano transactions set.
    """
    
    static let cardanoStakeDistributionList = """
    [
        {
            "epoch": 100,
            "hash": "abc123",
            "certificate_hash": "def456",
            "created_at": "2024-01-01T00:00:00Z"
        }
    ]
    """
}
