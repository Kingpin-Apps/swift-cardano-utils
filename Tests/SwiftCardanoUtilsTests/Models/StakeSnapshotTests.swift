import Testing
import Foundation
import SwiftCardanoCore
import Command
import Mockable
@testable import SwiftCardanoUtils

// MARK: - Test Fixtures

private let poolHex = "d8d46a3e430fab5dc8c5a0a7fc82abbf4339a89034a8c804bb7e6012"
private let poolHex2 = "003a75d89895458b5604f4cfb00d4a3511e5b367bcc2582cb476f8c6"

private extension CLIResponse {
    static let stakeSnapshotSinglePool = """
    {
        "pools": {
            "d8d46a3e430fab5dc8c5a0a7fc82abbf4339a89034a8c804bb7e6012": {
                "stakeGo": 13492420330,
                "stakeMark": 13492420330,
                "stakeSet": 13492420330
            }
        },
        "total": {
            "stakeGo": 1085961958357586,
            "stakeMark": 1086917928821107,
            "stakeSet": 1086330152985191
        }
    }
    """

    static let stakeSnapshotAllPools = """
    {
        "pools": {
            "d8d46a3e430fab5dc8c5a0a7fc82abbf4339a89034a8c804bb7e6012": {
                "stakeGo": 1000000000,
                "stakeMark": 1100000000,
                "stakeSet": 1050000000
            },
            "003a75d89895458b5604f4cfb00d4a3511e5b367bcc2582cb476f8c6": {
                "stakeGo": 13492420330,
                "stakeMark": 13492420330,
                "stakeSet": 13492420330
            }
        },
        "total": {
            "stakeGo": 1085961958357586,
            "stakeMark": 1086917928821107,
            "stakeSet": 1086330152985191
        }
    }
    """

    static let stakeSnapshotEmptyPools = """
    {
        "pools": {},
        "total": {
            "stakeGo": 1085961958357586,
            "stakeMark": 1086917928821107,
            "stakeSet": 1086330152985191
        }
    }
    """
}

// MARK: - PoolStakeSnapshot Model Tests

@Suite("PoolStakeSnapshot Model Tests")
struct PoolStakeSnapshotModelTests {

    @Test("Basic initialization stores all properties")
    func testBasicInitialization() {
        let snapshot = PoolStakeSnapshot(
            stakeMark: 1_086_917_928_821_107,
            stakeSet: 1_086_330_152_985_191,
            stakeGo: 1_085_961_958_357_586
        )

        #expect(snapshot.stakeMark == 1_086_917_928_821_107)
        #expect(snapshot.stakeSet == 1_086_330_152_985_191)
        #expect(snapshot.stakeGo == 1_085_961_958_357_586)
    }

    @Test("Decodes from JSON")
    func testDecodeFromJSON() throws {
        let json = """
        { "stakeGo": 100, "stakeMark": 200, "stakeSet": 150 }
        """
        let data = try #require(json.data(using: .utf8))
        let snapshot = try JSONDecoder().decode(PoolStakeSnapshot.self, from: data)

        #expect(snapshot.stakeGo == 100)
        #expect(snapshot.stakeMark == 200)
        #expect(snapshot.stakeSet == 150)
    }

    @Test("Throws on missing fields")
    func testThrowsOnMissingFields() {
        let json = #"{ "stakeGo": 100 }"#
        let data = json.data(using: .utf8)!
        #expect(throws: Error.self) {
            _ = try JSONDecoder().decode(PoolStakeSnapshot.self, from: data)
        }
    }
}

// MARK: - StakeSnapshot Model Tests

@Suite("StakeSnapshot Model Tests")
struct StakeSnapshotModelTests {

    // MARK: - Initialization

    @Test("Basic initialization stores all properties")
    func testBasicInitialization() {
        let total = PoolStakeSnapshot(stakeMark: 1000, stakeSet: 900, stakeGo: 800)
        let snapshot = StakeSnapshot(pools: [:], total: total)

        #expect(snapshot.pools.isEmpty)
        #expect(snapshot.total.stakeMark == 1000)
        #expect(snapshot.total.stakeSet == 900)
        #expect(snapshot.total.stakeGo == 800)
    }

    // MARK: - JSON Decoding

    @Test("Decodes single-pool response")
    func testDecodeSinglePool() throws {
        let data = try #require(CLIResponse.stakeSnapshotSinglePool.data(using: .utf8))
        let snapshot = try JSONDecoder().decode(StakeSnapshot.self, from: data)

        #expect(snapshot.pools.count == 1)
        #expect(snapshot.total.stakeGo == 1_085_961_958_357_586)
        #expect(snapshot.total.stakeMark == 1_086_917_928_821_107)
        #expect(snapshot.total.stakeSet == 1_086_330_152_985_191)

        let poolValues = Array(snapshot.pools.values)
        #expect(poolValues[0].stakeGo == 13_492_420_330)
        #expect(poolValues[0].stakeMark == 13_492_420_330)
        #expect(poolValues[0].stakeSet == 13_492_420_330)
    }

    @Test("Decodes all-pools response with multiple pools")
    func testDecodeAllPools() throws {
        let data = try #require(CLIResponse.stakeSnapshotAllPools.data(using: .utf8))
        let snapshot = try JSONDecoder().decode(StakeSnapshot.self, from: data)

        #expect(snapshot.pools.count == 2)
        #expect(snapshot.total.stakeGo == 1_085_961_958_357_586)
    }

    @Test("Decodes response with empty pools dictionary")
    func testDecodeEmptyPools() throws {
        let data = try #require(CLIResponse.stakeSnapshotEmptyPools.data(using: .utf8))
        let snapshot = try JSONDecoder().decode(StakeSnapshot.self, from: data)

        #expect(snapshot.pools.isEmpty)
        #expect(snapshot.total.stakeGo == 1_085_961_958_357_586)
    }

    @Test("Pool keys are decoded as PoolOperator values")
    func testPoolKeysArePoolOperators() throws {
        let data = try #require(CLIResponse.stakeSnapshotSinglePool.data(using: .utf8))
        let snapshot = try JSONDecoder().decode(StakeSnapshot.self, from: data)

        let expectedPool = try PoolOperator(from: poolHex.hexStringToData)
        #expect(snapshot.pools[expectedPool] != nil)
        #expect(snapshot.pools[expectedPool]?.stakeGo == 13_492_420_330)
    }

    @Test("Throws on missing total field")
    func testThrowsOnMissingTotal() {
        let json = #"{ "pools": {} }"#
        let data = json.data(using: .utf8)!
        #expect(throws: Error.self) {
            _ = try JSONDecoder().decode(StakeSnapshot.self, from: data)
        }
    }

    // MARK: - JSON Round-Trip

    @Test("Round-trip encode/decode preserves single-pool data")
    func testRoundTripSinglePool() throws {
        let data = try #require(CLIResponse.stakeSnapshotSinglePool.data(using: .utf8))
        let original = try JSONDecoder().decode(StakeSnapshot.self, from: data)

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(StakeSnapshot.self, from: encoded)

        #expect(decoded.pools.count == original.pools.count)
        #expect(decoded.total.stakeGo == original.total.stakeGo)
        #expect(decoded.total.stakeMark == original.total.stakeMark)
        #expect(decoded.total.stakeSet == original.total.stakeSet)

        for (key, value) in original.pools {
            #expect(decoded.pools[key]?.stakeGo == value.stakeGo)
            #expect(decoded.pools[key]?.stakeMark == value.stakeMark)
            #expect(decoded.pools[key]?.stakeSet == value.stakeSet)
        }
    }

    @Test("Round-trip encode/decode preserves multi-pool data")
    func testRoundTripAllPools() throws {
        let data = try #require(CLIResponse.stakeSnapshotAllPools.data(using: .utf8))
        let original = try JSONDecoder().decode(StakeSnapshot.self, from: data)

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(StakeSnapshot.self, from: encoded)

        #expect(decoded.pools.count == original.pools.count)
        for (key, value) in original.pools {
            #expect(decoded.pools[key]?.stakeGo == value.stakeGo)
        }
    }
}

// MARK: - StakeSnapshot CLI Query Tests

@Suite("StakeSnapshot CLI Query Tests")
struct StakeSnapshotCLITests {

    @Test("query.stakeSnapshot(pool:) sends correct args and decodes response")
    func testQueryStakeSnapshotSinglePool() async throws {
        let config = createTestConfiguration()
        let runner = createCardanoCLIMockCommandRunner(config: config)

        let pool = try PoolOperator(from: poolHex.hexStringToData)
        let poolBech32 = try pool.toBech32()
        let expectedArgs = [
            config.cardano!.cli!.string,
            "conway", "query", "stake-snapshot",
            "--stake-pool-id", poolBech32,
            "--testnet-magic", "2"
        ]

        given(runner)
            .run(
                arguments: .value(expectedArgs),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(
                        .standardOutput([UInt8](CLIResponse.stakeSnapshotSinglePool.utf8))
                    )
                    continuation.finish()
                }
            )

        let cli = try await CardanoCLI(configuration: config, commandRunner: runner)
        let snapshot = try await cli.query.stakeSnapshot(pool: pool)

        #expect(snapshot.pools.count == 1)
        #expect(snapshot.pools[pool] != nil)
        #expect(snapshot.pools[pool]?.stakeGo == 13_492_420_330)
        #expect(snapshot.pools[pool]?.stakeMark == 13_492_420_330)
        #expect(snapshot.pools[pool]?.stakeSet == 13_492_420_330)
        #expect(snapshot.total.stakeGo == 1_085_961_958_357_586)
        #expect(snapshot.total.stakeMark == 1_086_917_928_821_107)
        #expect(snapshot.total.stakeSet == 1_086_330_152_985_191)
    }

    @Test("query.stakeSnapshot() sends --all-stake-pools and decodes response")
    func testQueryStakeSnapshotAllPools() async throws {
        let config = createTestConfiguration()
        let runner = createCardanoCLIMockCommandRunner(config: config)

        let expectedArgs = [
            config.cardano!.cli!.string,
            "conway", "query", "stake-snapshot",
            "--all-stake-pools",
            "--testnet-magic", "2"
        ]

        given(runner)
            .run(
                arguments: .value(expectedArgs),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(
                        .standardOutput([UInt8](CLIResponse.stakeSnapshotAllPools.utf8))
                    )
                    continuation.finish()
                }
            )

        let cli = try await CardanoCLI(configuration: config, commandRunner: runner)
        let snapshot = try await cli.query.stakeSnapshot()

        #expect(snapshot.pools.count == 2)
        #expect(snapshot.total.stakeGo == 1_085_961_958_357_586)
    }

    @Test("query.stakeSnapshot() with empty pools response")
    func testQueryStakeSnapshotEmptyPools() async throws {
        let config = createTestConfiguration()
        let runner = createCardanoCLIMockCommandRunner(config: config)

        let expectedArgs = [
            config.cardano!.cli!.string,
            "conway", "query", "stake-snapshot",
            "--all-stake-pools",
            "--testnet-magic", "2"
        ]

        given(runner)
            .run(
                arguments: .value(expectedArgs),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(
                        .standardOutput([UInt8](CLIResponse.stakeSnapshotEmptyPools.utf8))
                    )
                    continuation.finish()
                }
            )

        let cli = try await CardanoCLI(configuration: config, commandRunner: runner)
        let snapshot = try await cli.query.stakeSnapshot()

        #expect(snapshot.pools.isEmpty)
        #expect(snapshot.total.stakeGo == 1_085_961_958_357_586)
    }

    @Test("query.stakeSnapshot() throws on invalid JSON response")
    func testQueryStakeSnapshotThrowsOnInvalidJSON() async throws {
        let config = createTestConfiguration()
        let runner = createCardanoCLIMockCommandRunner(config: config)

        let expectedArgs = [
            config.cardano!.cli!.string,
            "conway", "query", "stake-snapshot",
            "--all-stake-pools",
            "--testnet-magic", "2"
        ]

        given(runner)
            .run(
                arguments: .value(expectedArgs),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(
                        .standardOutput([UInt8]("not valid json".utf8))
                    )
                    continuation.finish()
                }
            )

        let cli = try await CardanoCLI(configuration: config, commandRunner: runner)

        await #expect(throws: Error.self) {
            _ = try await cli.query.stakeSnapshot()
        }
    }

    @Test("query.stakeSnapshot(pool:) throws on invalid JSON response")
    func testQueryStakeSnapshotSinglePoolThrowsOnInvalidJSON() async throws {
        let config = createTestConfiguration()
        let runner = createCardanoCLIMockCommandRunner(config: config)

        let pool = try PoolOperator(from: poolHex.hexStringToData)
        let poolBech32 = try pool.toBech32()
        let expectedArgs = [
            config.cardano!.cli!.string,
            "conway", "query", "stake-snapshot",
            "--stake-pool-id", poolBech32,
            "--testnet-magic", "2"
        ]

        given(runner)
            .run(
                arguments: .value(expectedArgs),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(
                        .standardOutput([UInt8]("not valid json".utf8))
                    )
                    continuation.finish()
                }
            )

        let cli = try await CardanoCLI(configuration: config, commandRunner: runner)

        await #expect(throws: Error.self) {
            _ = try await cli.query.stakeSnapshot(pool: pool)
        }
    }
}
