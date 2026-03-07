import Testing
import Foundation
import SwiftCardanoCore
import Command
import Mockable
@testable import SwiftCardanoUtils

// MARK: - Test Fixtures

private let poolHex = "003a75d89895458b5604f4cfb00d4a3511e5b367bcc2582cb476f8c6"
private let poolHex2 = "d8d46a3e430fab5dc8c5a0a7fc82abbf4339a89034a8c804bb7e6012"

private extension CLIResponse {

    static let poolStateSinglePool = """
    {
        "003a75d89895458b5604f4cfb00d4a3511e5b367bcc2582cb476f8c6": {
            "futurePoolParams": null,
            "poolParams": {
                "spsCost": 340000000,
                "spsDeposit": 500000000,
                "spsMargin": 0,
                "spsMetadata": {
                    "hash": "75a1562ee7700c3330a65c650efe1efd9f33fc4fa003be130d5abaaa03c43f65",
                    "url": "https://example.com/MPP6"
                },
                "spsOwners": [
                    "0470daa17236a4291be26c24d9b4bb9ed023e282077572458cdfcf1a"
                ],
                "spsPledge": 500000000,
                "spsRelays": [
                    {
                        "single host address": {
                            "IPv4": "0.0.0.0",
                            "IPv6": null,
                            "port": 3533
                        }
                    }
                ],
                "spsRewardAccount": {
                    "credential": {
                        "keyHash": "0470daa17236a4291be26c24d9b4bb9ed023e282077572458cdfcf1a"
                    },
                    "network": "Testnet"
                },
                "spsVrf": "52a8535d6b2e69025d188d13c10c3940a1ead314ca67cd9b400b3e36472164e0"
            },
            "retiring": null
        }
    }
    """

    static let poolStateAllPools = """
    {
        "003a75d89895458b5604f4cfb00d4a3511e5b367bcc2582cb476f8c6": {
            "futurePoolParams": null,
            "poolParams": {
                "spsCost": 340000000,
                "spsDeposit": 500000000,
                "spsMargin": 0,
                "spsMetadata": {
                    "hash": "75a1562ee7700c3330a65c650efe1efd9f33fc4fa003be130d5abaaa03c43f65",
                    "url": "https://example.com/MPP6"
                },
                "spsOwners": [
                    "0470daa17236a4291be26c24d9b4bb9ed023e282077572458cdfcf1a"
                ],
                "spsPledge": 500000000,
                "spsRelays": [
                    {
                        "single host address": {
                            "IPv4": "0.0.0.0",
                            "IPv6": null,
                            "port": 3533
                        }
                    }
                ],
                "spsRewardAccount": {
                    "credential": {
                        "keyHash": "0470daa17236a4291be26c24d9b4bb9ed023e282077572458cdfcf1a"
                    },
                    "network": "Testnet"
                },
                "spsVrf": "52a8535d6b2e69025d188d13c10c3940a1ead314ca67cd9b400b3e36472164e0"
            },
            "retiring": null
        },
        "d8d46a3e430fab5dc8c5a0a7fc82abbf4339a89034a8c804bb7e6012": {
            "futurePoolParams": null,
            "poolParams": {
                "spsCost": 170000000,
                "spsDeposit": 500000000,
                "spsMargin": 0.02,
                "spsMetadata": null,
                "spsOwners": [
                    "aabbcc1234567890aabbcc1234567890aabbcc1234567890aabbcc12"
                ],
                "spsPledge": 1000000000,
                "spsRelays": [
                    {
                        "single host name": {
                            "dnsName": "relay.example.com",
                            "port": 3001
                        }
                    }
                ],
                "spsRewardAccount": {
                    "credential": {
                        "keyHash": "aabbcc1234567890aabbcc1234567890aabbcc1234567890aabbcc12"
                    },
                    "network": "Testnet"
                },
                "spsVrf": "aaaa535d6b2e69025d188d13c10c3940a1ead314ca67cd9b400b3e36472164e0"
            },
            "retiring": null
        }
    }
    """

    static let poolStateRetiring = """
    {
        "003a75d89895458b5604f4cfb00d4a3511e5b367bcc2582cb476f8c6": {
            "futurePoolParams": null,
            "poolParams": {
                "spsCost": 340000000,
                "spsDeposit": 500000000,
                "spsMargin": 0,
                "spsMetadata": null,
                "spsOwners": [
                    "0470daa17236a4291be26c24d9b4bb9ed023e282077572458cdfcf1a"
                ],
                "spsPledge": 500000000,
                "spsRelays": [],
                "spsRewardAccount": {
                    "credential": {
                        "keyHash": "0470daa17236a4291be26c24d9b4bb9ed023e282077572458cdfcf1a"
                    },
                    "network": "Testnet"
                },
                "spsVrf": "52a8535d6b2e69025d188d13c10c3940a1ead314ca67cd9b400b3e36472164e0"
            },
            "retiring": 550
        }
    }
    """

    static let poolStateFutureParams = """
    {
        "003a75d89895458b5604f4cfb00d4a3511e5b367bcc2582cb476f8c6": {
            "futurePoolParams": {
                "spsCost": 500000000,
                "spsDeposit": 500000000,
                "spsMargin": 0.01,
                "spsMetadata": null,
                "spsOwners": [
                    "0470daa17236a4291be26c24d9b4bb9ed023e282077572458cdfcf1a"
                ],
                "spsPledge": 750000000,
                "spsRelays": [],
                "spsRewardAccount": {
                    "credential": {
                        "keyHash": "0470daa17236a4291be26c24d9b4bb9ed023e282077572458cdfcf1a"
                    },
                    "network": "Testnet"
                },
                "spsVrf": "52a8535d6b2e69025d188d13c10c3940a1ead314ca67cd9b400b3e36472164e0"
            },
            "poolParams": {
                "spsCost": 340000000,
                "spsDeposit": 500000000,
                "spsMargin": 0,
                "spsMetadata": null,
                "spsOwners": [
                    "0470daa17236a4291be26c24d9b4bb9ed023e282077572458cdfcf1a"
                ],
                "spsPledge": 500000000,
                "spsRelays": [],
                "spsRewardAccount": {
                    "credential": {
                        "keyHash": "0470daa17236a4291be26c24d9b4bb9ed023e282077572458cdfcf1a"
                    },
                    "network": "Testnet"
                },
                "spsVrf": "52a8535d6b2e69025d188d13c10c3940a1ead314ca67cd9b400b3e36472164e0"
            },
            "retiring": null
        }
    }
    """

    static let poolStateMultiHostNameRelay = """
    {
        "003a75d89895458b5604f4cfb00d4a3511e5b367bcc2582cb476f8c6": {
            "futurePoolParams": null,
            "poolParams": {
                "spsCost": 340000000,
                "spsDeposit": 500000000,
                "spsMargin": 0,
                "spsMetadata": null,
                "spsOwners": [],
                "spsPledge": 500000000,
                "spsRelays": [
                    {
                        "multi host name": {
                            "dnsName": "relays.example.com"
                        }
                    }
                ],
                "spsRewardAccount": {
                    "credential": {
                        "keyHash": "0470daa17236a4291be26c24d9b4bb9ed023e282077572458cdfcf1a"
                    },
                    "network": "Testnet"
                },
                "spsVrf": "52a8535d6b2e69025d188d13c10c3940a1ead314ca67cd9b400b3e36472164e0"
            },
            "retiring": null
        }
    }
    """

    static let poolStateSinglePoolNoMetadata = """
    {
        "003a75d89895458b5604f4cfb00d4a3511e5b367bcc2582cb476f8c6": {
            "futurePoolParams": null,
            "poolParams": {
                "spsCost": 340000000,
                "spsDeposit": 500000000,
                "spsMargin": 0,
                "spsMetadata": null,
                "spsOwners": [
                    "0470daa17236a4291be26c24d9b4bb9ed023e282077572458cdfcf1a"
                ],
                "spsPledge": 500000000,
                "spsRelays": [
                    {
                        "single host address": {
                            "IPv4": "0.0.0.0",
                            "IPv6": null,
                            "port": 3533
                        }
                    }
                ],
                "spsRewardAccount": {
                    "credential": {
                        "keyHash": "0470daa17236a4291be26c24d9b4bb9ed023e282077572458cdfcf1a"
                    },
                    "network": "Testnet"
                },
                "spsVrf": "52a8535d6b2e69025d188d13c10c3940a1ead314ca67cd9b400b3e36472164e0"
            },
            "retiring": null
        }
    }
    """
}

// MARK: - PoolRelay Model Tests

@Suite("PoolRelay Model Tests")
struct PoolRelayModelTests {

    @Test("Decodes single host address relay")
    func testDecodeSingleHostAddress() throws {
        let json = """
        { "single host address": { "IPv4": "0.0.0.0", "IPv6": null, "port": 3533 } }
        """
        let data = try #require(json.data(using: .utf8))
        let relay = try JSONDecoder().decode(PoolRelay.self, from: data)

        guard case .singleHostAddress(let ipv4, let ipv6, let port) = relay else {
            Issue.record("Expected singleHostAddress relay")
            return
        }
        #expect(ipv4 == "0.0.0.0")
        #expect(ipv6 == nil)
        #expect(port == 3533)
    }

    @Test("Decodes single host name relay")
    func testDecodeSingleHostName() throws {
        let json = """
        { "single host name": { "dnsName": "relay.example.com", "port": 3001 } }
        """
        let data = try #require(json.data(using: .utf8))
        let relay = try JSONDecoder().decode(PoolRelay.self, from: data)

        guard case .singleHostName(let dnsName, let port) = relay else {
            Issue.record("Expected singleHostName relay")
            return
        }
        #expect(dnsName == "relay.example.com")
        #expect(port == 3001)
    }

    @Test("Decodes single host name relay without port")
    func testDecodeSingleHostNameWithoutPort() throws {
        let json = """
        { "single host name": { "dnsName": "relay.example.com", "port": null } }
        """
        let data = try #require(json.data(using: .utf8))
        let relay = try JSONDecoder().decode(PoolRelay.self, from: data)

        guard case .singleHostName(let dnsName, let port) = relay else {
            Issue.record("Expected singleHostName relay")
            return
        }
        #expect(dnsName == "relay.example.com")
        #expect(port == nil)
    }

    @Test("Decodes multi host name relay")
    func testDecodeMultiHostName() throws {
        let json = """
        { "multi host name": { "dnsName": "relays.example.com" } }
        """
        let data = try #require(json.data(using: .utf8))
        let relay = try JSONDecoder().decode(PoolRelay.self, from: data)

        guard case .multiHostName(let dnsName) = relay else {
            Issue.record("Expected multiHostName relay")
            return
        }
        #expect(dnsName == "relays.example.com")
    }

    @Test("Throws on unknown relay type")
    func testThrowsOnUnknownRelayType() {
        let json = """
        { "unknown relay type": { "data": "value" } }
        """
        let data = json.data(using: .utf8)!
        #expect(throws: Error.self) {
            _ = try JSONDecoder().decode(PoolRelay.self, from: data)
        }
    }

    @Test("Round-trip encode/decode preserves single host address")
    func testRoundTripSingleHostAddress() throws {
        let json = """
        { "single host address": { "IPv4": "192.168.1.1", "IPv6": null, "port": 6000 } }
        """
        let data = try #require(json.data(using: .utf8))
        let original = try JSONDecoder().decode(PoolRelay.self, from: data)

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PoolRelay.self, from: encoded)

        guard case .singleHostAddress(let ipv4, _, let port) = decoded else {
            Issue.record("Expected singleHostAddress relay after round-trip")
            return
        }
        #expect(ipv4 == "192.168.1.1")
        #expect(port == 6000)
    }

    @Test("Round-trip encode/decode preserves multi host name")
    func testRoundTripMultiHostName() throws {
        let json = """
        { "multi host name": { "dnsName": "relays.example.com" } }
        """
        let data = try #require(json.data(using: .utf8))
        let original = try JSONDecoder().decode(PoolRelay.self, from: data)

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PoolRelay.self, from: encoded)

        guard case .multiHostName(let dnsName) = decoded else {
            Issue.record("Expected multiHostName relay after round-trip")
            return
        }
        #expect(dnsName == "relays.example.com")
    }
}

// MARK: - PoolStateParams Model Tests

@Suite("PoolStateParams Model Tests")
struct PoolStateParamsModelTests {

    @Test("Decodes all sps* fields correctly")
    func testDecodesAllFields() throws {
        let json = """
        {
            "spsCost": 340000000,
            "spsDeposit": 500000000,
            "spsMargin": 0.015,
            "spsMetadata": {
                "hash": "75a1562ee7700c3330a65c650efe1efd9f33fc4fa003be130d5abaaa03c43f65",
                "url": "https://example.com/meta.json"
            },
            "spsOwners": ["0470daa17236a4291be26c24d9b4bb9ed023e282077572458cdfcf1a"],
            "spsPledge": 500000000,
            "spsRelays": [],
            "spsRewardAccount": {
                "credential": { "keyHash": "0470daa17236a4291be26c24d9b4bb9ed023e282077572458cdfcf1a" },
                "network": "Testnet"
            },
            "spsVrf": "52a8535d6b2e69025d188d13c10c3940a1ead314ca67cd9b400b3e36472164e0"
        }
        """
        let data = try #require(json.data(using: .utf8))
        let params = try JSONDecoder().decode(PoolStateParams.self, from: data)

        #expect(params.cost == 340_000_000)
        #expect(params.deposit == 500_000_000)
        #expect(params.margin == 0.015)
        #expect(params.metadata?.hash == "75a1562ee7700c3330a65c650efe1efd9f33fc4fa003be130d5abaaa03c43f65")
        #expect(params.metadata?.url == "https://example.com/meta.json")
        #expect(params.owners.count == 1)
        #expect(params.owners[0] == "0470daa17236a4291be26c24d9b4bb9ed023e282077572458cdfcf1a")
        #expect(params.pledge == 500_000_000)
        #expect(params.relays.isEmpty)
        #expect(params.rewardAccount.credential.keyHash == "0470daa17236a4291be26c24d9b4bb9ed023e282077572458cdfcf1a")
        #expect(params.rewardAccount.network == "Testnet")
        #expect(params.vrf == "52a8535d6b2e69025d188d13c10c3940a1ead314ca67cd9b400b3e36472164e0")
    }

    @Test("Decodes with null metadata")
    func testDecodesWithNullMetadata() throws {
        let json = """
        {
            "spsCost": 170000000,
            "spsDeposit": 500000000,
            "spsMargin": 0,
            "spsMetadata": null,
            "spsOwners": [],
            "spsPledge": 1000000000,
            "spsRelays": [],
            "spsRewardAccount": {
                "credential": { "keyHash": "abcdef1234567890abcdef1234567890abcdef1234567890abcdef12" },
                "network": "Testnet"
            },
            "spsVrf": "aaaa535d6b2e69025d188d13c10c3940a1ead314ca67cd9b400b3e36472164e0"
        }
        """
        let data = try #require(json.data(using: .utf8))
        let params = try JSONDecoder().decode(PoolStateParams.self, from: data)

        #expect(params.metadata == nil)
        #expect(params.margin == 0)
        #expect(params.owners.isEmpty)
    }

    @Test("Decodes multiple owners")
    func testDecodesMultipleOwners() throws {
        let json = """
        {
            "spsCost": 340000000,
            "spsDeposit": 500000000,
            "spsMargin": 0,
            "spsMetadata": null,
            "spsOwners": [
                "0470daa17236a4291be26c24d9b4bb9ed023e282077572458cdfcf1a",
                "aabbcc1234567890aabbcc1234567890aabbcc1234567890aabbcc12"
            ],
            "spsPledge": 500000000,
            "spsRelays": [],
            "spsRewardAccount": {
                "credential": { "keyHash": "0470daa17236a4291be26c24d9b4bb9ed023e282077572458cdfcf1a" },
                "network": "Testnet"
            },
            "spsVrf": "52a8535d6b2e69025d188d13c10c3940a1ead314ca67cd9b400b3e36472164e0"
        }
        """
        let data = try #require(json.data(using: .utf8))
        let params = try JSONDecoder().decode(PoolStateParams.self, from: data)

        #expect(params.owners.count == 2)
    }

    @Test("Decodes relay list with single host address")
    func testDecodesRelayList() throws {
        let json = """
        {
            "spsCost": 340000000,
            "spsDeposit": 500000000,
            "spsMargin": 0,
            "spsMetadata": null,
            "spsOwners": [],
            "spsPledge": 500000000,
            "spsRelays": [
                { "single host address": { "IPv4": "1.2.3.4", "IPv6": null, "port": 3000 } }
            ],
            "spsRewardAccount": {
                "credential": { "keyHash": "0470daa17236a4291be26c24d9b4bb9ed023e282077572458cdfcf1a" },
                "network": "Testnet"
            },
            "spsVrf": "52a8535d6b2e69025d188d13c10c3940a1ead314ca67cd9b400b3e36472164e0"
        }
        """
        let data = try #require(json.data(using: .utf8))
        let params = try JSONDecoder().decode(PoolStateParams.self, from: data)

        #expect(params.relays.count == 1)
        guard case .singleHostAddress(let ipv4, _, let port) = params.relays[0] else {
            Issue.record("Expected singleHostAddress relay in poolParams")
            return
        }
        #expect(ipv4 == "1.2.3.4")
        #expect(port == 3000)
    }

    @Test("Throws on missing required fields")
    func testThrowsOnMissingFields() {
        let json = #"{ "spsCost": 340000000 }"#
        let data = json.data(using: .utf8)!
        #expect(throws: Error.self) {
            _ = try JSONDecoder().decode(PoolStateParams.self, from: data)
        }
    }
}

// MARK: - PoolState Model Tests

@Suite("PoolState Model Tests")
struct PoolStateModelTests {

    // MARK: - Initialization

    @Test("Basic initialization stores pools")
    func testBasicInitialization() {
        let state = PoolState(pools: [:])
        #expect(state.pools.isEmpty)
    }

    // MARK: - JSON Decoding

    @Test("Decodes single-pool response")
    func testDecodeSinglePool() throws {
        let data = try #require(CLIResponse.poolStateSinglePool.data(using: .utf8))
        let state = try JSONDecoder().decode(PoolState.self, from: data)

        #expect(state.pools.count == 1)
        let entry = try #require(Array(state.pools.values).first)
        #expect(entry.poolParams.cost == 340_000_000)
        #expect(entry.poolParams.deposit == 500_000_000)
        #expect(entry.poolParams.margin == 0)
        #expect(entry.poolParams.pledge == 500_000_000)
        #expect(entry.poolParams.metadata?.url == "https://example.com/MPP6")
        #expect(entry.poolParams.metadata?.hash == "75a1562ee7700c3330a65c650efe1efd9f33fc4fa003be130d5abaaa03c43f65")
        #expect(entry.poolParams.owners.count == 1)
        #expect(entry.poolParams.relays.count == 1)
        #expect(entry.poolParams.rewardAccount.network == "Testnet")
        #expect(entry.poolParams.vrf == "52a8535d6b2e69025d188d13c10c3940a1ead314ca67cd9b400b3e36472164e0")
        #expect(entry.futurePoolParams == nil)
        #expect(entry.retiring == nil)
    }

    @Test("Decodes all-pools response with multiple pools")
    func testDecodeAllPools() throws {
        let data = try #require(CLIResponse.poolStateAllPools.data(using: .utf8))
        let state = try JSONDecoder().decode(PoolState.self, from: data)

        #expect(state.pools.count == 2)
    }

    @Test("Pool keys are decoded as PoolOperator values")
    func testPoolKeysArePoolOperators() throws {
        let data = try #require(CLIResponse.poolStateSinglePool.data(using: .utf8))
        let state = try JSONDecoder().decode(PoolState.self, from: data)

        let expectedPool = try PoolOperator(from: poolHex.hexStringToData)
        #expect(state.pools[expectedPool] != nil)
        #expect(state.pools[expectedPool]?.poolParams.cost == 340_000_000)
    }

    @Test("Decodes retiring pool with epoch number")
    func testDecodeRetiringPool() throws {
        let data = try #require(CLIResponse.poolStateRetiring.data(using: .utf8))
        let state = try JSONDecoder().decode(PoolState.self, from: data)

        let entry = try #require(Array(state.pools.values).first)
        #expect(entry.retiring == 550)
        #expect(entry.futurePoolParams == nil)
    }

    @Test("Decodes pool with future params")
    func testDecodePoolWithFutureParams() throws {
        let data = try #require(CLIResponse.poolStateFutureParams.data(using: .utf8))
        let state = try JSONDecoder().decode(PoolState.self, from: data)

        let entry = try #require(Array(state.pools.values).first)
        #expect(entry.futurePoolParams != nil)
        #expect(entry.futurePoolParams?.cost == 500_000_000)
        #expect(entry.futurePoolParams?.pledge == 750_000_000)
        #expect(entry.futurePoolParams?.margin == 0.01)
        #expect(entry.poolParams.cost == 340_000_000)
        #expect(entry.retiring == nil)
    }

    @Test("Decodes pool with multi host name relay")
    func testDecodeMultiHostNameRelay() throws {
        let data = try #require(CLIResponse.poolStateMultiHostNameRelay.data(using: .utf8))
        let state = try JSONDecoder().decode(PoolState.self, from: data)

        let entry = try #require(Array(state.pools.values).first)
        #expect(entry.poolParams.relays.count == 1)
        guard case .multiHostName(let dnsName) = entry.poolParams.relays[0] else {
            Issue.record("Expected multiHostName relay")
            return
        }
        #expect(dnsName == "relays.example.com")
    }

    @Test("Decodes pool with single host name relay")
    func testDecodeSingleHostNameRelay() throws {
        let data = try #require(CLIResponse.poolStateAllPools.data(using: .utf8))
        let state = try JSONDecoder().decode(PoolState.self, from: data)

        let pool2 = try PoolOperator(from: poolHex2.hexStringToData)
        let entry = try #require(state.pools[pool2])
        #expect(entry.poolParams.relays.count == 1)
        guard case .singleHostName(let dnsName, let port) = entry.poolParams.relays[0] else {
            Issue.record("Expected singleHostName relay")
            return
        }
        #expect(dnsName == "relay.example.com")
        #expect(port == 3001)
    }

    // MARK: - JSON Round-Trip

    @Test("Round-trip encode/decode preserves single-pool data")
    func testRoundTripSinglePool() throws {
        let data = try #require(CLIResponse.poolStateSinglePool.data(using: .utf8))
        let original = try JSONDecoder().decode(PoolState.self, from: data)

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PoolState.self, from: encoded)

        #expect(decoded.pools.count == original.pools.count)

        for (key, entry) in original.pools {
            let decodedEntry = try #require(decoded.pools[key])
            #expect(decodedEntry.poolParams.cost == entry.poolParams.cost)
            #expect(decodedEntry.poolParams.deposit == entry.poolParams.deposit)
            #expect(decodedEntry.poolParams.pledge == entry.poolParams.pledge)
            #expect(decodedEntry.poolParams.margin == entry.poolParams.margin)
            #expect(decodedEntry.poolParams.vrf == entry.poolParams.vrf)
            #expect(decodedEntry.retiring == entry.retiring)
        }
    }

    @Test("Round-trip encode/decode preserves multi-pool data")
    func testRoundTripAllPools() throws {
        let data = try #require(CLIResponse.poolStateAllPools.data(using: .utf8))
        let original = try JSONDecoder().decode(PoolState.self, from: data)

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PoolState.self, from: encoded)

        #expect(decoded.pools.count == original.pools.count)
        for (key, entry) in original.pools {
            #expect(decoded.pools[key]?.poolParams.cost == entry.poolParams.cost)
        }
    }

    @Test("Round-trip encode/decode preserves retiring epoch")
    func testRoundTripRetiringPool() throws {
        let data = try #require(CLIResponse.poolStateRetiring.data(using: .utf8))
        let original = try JSONDecoder().decode(PoolState.self, from: data)

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PoolState.self, from: encoded)

        let entry = try #require(Array(decoded.pools.values).first)
        #expect(entry.retiring == 550)
    }
}

// MARK: - PoolState CLI Query Tests

@Suite("PoolState CLI Query Tests")
struct PoolStateCLITests {

    @Test("query.poolState(pool:) sends correct args and decodes response")
    func testQueryPoolStateSinglePool() async throws {
        let config = createTestConfiguration()
        let runner = createCardanoCLIMockCommandRunner(config: config)

        let pool = try PoolOperator(from: poolHex.hexStringToData)
        let poolBech32 = try pool.toBech32()
        let expectedArgs = [
            config.cardano!.cli!.string,
            "conway", "query", "pool-state",
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
                        .standardOutput([UInt8](CLIResponse.poolStateSinglePool.utf8))
                    )
                    continuation.finish()
                }
            )

        let cli = try await CardanoCLI(configuration: config, commandRunner: runner)
        let state = try await cli.query.poolState(pool: pool)

        #expect(state.pools.count == 1)
        #expect(state.pools[pool] != nil)
        #expect(state.pools[pool]?.poolParams.cost == 340_000_000)
        #expect(state.pools[pool]?.poolParams.pledge == 500_000_000)
        #expect(state.pools[pool]?.poolParams.vrf == "52a8535d6b2e69025d188d13c10c3940a1ead314ca67cd9b400b3e36472164e0")
        #expect(state.pools[pool]?.futurePoolParams == nil)
        #expect(state.pools[pool]?.retiring == nil)
    }

    @Test("query.poolState() sends correct args for all pools and decodes response")
    func testQueryPoolStateAllPools() async throws {
        let config = createTestConfiguration()
        let runner = createCardanoCLIMockCommandRunner(config: config)

        let expectedArgs = [
            config.cardano!.cli!.string,
            "conway", "query", "pool-state",
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
                        .standardOutput([UInt8](CLIResponse.poolStateAllPools.utf8))
                    )
                    continuation.finish()
                }
            )

        let cli = try await CardanoCLI(configuration: config, commandRunner: runner)
        let state = try await cli.query.poolState()

        #expect(state.pools.count == 2)
    }

    @Test("query.poolState() decodes retiring pool correctly")
    func testQueryPoolStateRetiring() async throws {
        let config = createTestConfiguration()
        let runner = createCardanoCLIMockCommandRunner(config: config)

        let expectedArgs = [
            config.cardano!.cli!.string,
            "conway", "query", "pool-state",
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
                        .standardOutput([UInt8](CLIResponse.poolStateRetiring.utf8))
                    )
                    continuation.finish()
                }
            )

        let cli = try await CardanoCLI(configuration: config, commandRunner: runner)
        let state = try await cli.query.poolState()

        let pool = try PoolOperator(from: poolHex.hexStringToData)
        #expect(state.pools[pool]?.retiring == 550)
    }

    @Test("query.poolState() decodes pool with future params correctly")
    func testQueryPoolStateFutureParams() async throws {
        let config = createTestConfiguration()
        let runner = createCardanoCLIMockCommandRunner(config: config)

        let expectedArgs = [
            config.cardano!.cli!.string,
            "conway", "query", "pool-state",
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
                        .standardOutput([UInt8](CLIResponse.poolStateFutureParams.utf8))
                    )
                    continuation.finish()
                }
            )

        let cli = try await CardanoCLI(configuration: config, commandRunner: runner)
        let state = try await cli.query.poolState()

        let pool = try PoolOperator(from: poolHex.hexStringToData)
        #expect(state.pools[pool]?.futurePoolParams != nil)
        #expect(state.pools[pool]?.futurePoolParams?.cost == 500_000_000)
        #expect(state.pools[pool]?.poolParams.cost == 340_000_000)
    }

    @Test("query.poolState() throws on invalid JSON response")
    func testQueryPoolStateThrowsOnInvalidJSON() async throws {
        let config = createTestConfiguration()
        let runner = createCardanoCLIMockCommandRunner(config: config)

        let expectedArgs = [
            config.cardano!.cli!.string,
            "conway", "query", "pool-state",
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
            _ = try await cli.query.poolState()
        }
    }

    @Test("query.poolState(pool:) throws on invalid JSON response")
    func testQueryPoolStateSinglePoolThrowsOnInvalidJSON() async throws {
        let config = createTestConfiguration()
        let runner = createCardanoCLIMockCommandRunner(config: config)

        let pool = try PoolOperator(from: poolHex.hexStringToData)
        let poolBech32 = try pool.toBech32()
        let expectedArgs = [
            config.cardano!.cli!.string,
            "conway", "query", "pool-state",
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
            _ = try await cli.query.poolState(pool: pool)
        }
    }
}

// MARK: - PoolStateParams toPoolParams Tests

@Suite("PoolStateParams toPoolParams Tests")
struct PoolStateParamsToPoolParamsTests {

    private var sampleParams: PoolStateParams {
        get throws {
            let data = try #require(CLIResponse.poolStateSinglePoolNoMetadata.data(using: .utf8))
            let state = try JSONDecoder().decode(PoolState.self, from: data)
            return try #require(Array(state.pools.values).first?.poolParams)
        }
    }

    private var samplePool: PoolOperator {
        get throws { try PoolOperator(from: poolHex.hexStringToData) }
    }

    @Test("toPoolParams returns a PoolParams with correct cost and pledge")
    func testCostAndPledge() async throws {
        let params = try sampleParams
        let pool = try samplePool
        let result = try await params.toPoolParams(poolOperator: pool)

        #expect(result.cost == 340_000_000)
        #expect(result.pledge == 500_000_000)
    }

    @Test("toPoolParams maps poolOperator key hash from the supplied PoolOperator")
    func testPoolOperatorKeyHash() async throws {
        let params = try sampleParams
        let pool = try samplePool
        let result = try await params.toPoolParams(poolOperator: pool)

        #expect(result.poolOperator.payload == pool.poolKeyHash.payload)
    }

    @Test("toPoolParams converts VRF key hash from hex string")
    func testVrfKeyHash() async throws {
        let params = try sampleParams
        let pool = try samplePool
        let result = try await params.toPoolParams(poolOperator: pool)

        #expect(result.vrfKeyHash.payload == params.vrf.hexStringToData)
    }

    @Test("toPoolParams converts zero margin to UnitInterval(0, 1)")
    func testZeroMargin() async throws {
        let params = try sampleParams
        let pool = try samplePool
        let result = try await params.toPoolParams(poolOperator: pool)

        #expect(result.margin.numerator == 0)
        #expect(result.margin.denominator == 1)
    }

    @Test("toPoolParams converts non-zero margin to a reduced UnitInterval fraction")
    func testNonZeroMargin() async throws {
        let data = try #require(CLIResponse.poolStateAllPools.data(using: .utf8))
        let state = try JSONDecoder().decode(PoolState.self, from: data)
        let pool2 = try PoolOperator(from: poolHex2.hexStringToData)
        let params = try #require(state.pools[pool2]?.poolParams)
        // poolHex2 has spsMargin: 0.02 → should reduce to 1/50
        let result = try await params.toPoolParams(poolOperator: pool2)

        let ratio = Double(result.margin.numerator) / Double(result.margin.denominator)
        #expect(abs(ratio - 0.02) < 1e-9)
    }

    @Test("toPoolParams constructs reward account with Testnet header byte (0xE0)")
    func testRewardAccountTestnetByte() async throws {
        let params = try sampleParams
        let pool = try samplePool
        let result = try await params.toPoolParams(poolOperator: pool)

        #expect(result.rewardAccount.payload.first == 0xE0)
        let keyHashHex = params.rewardAccount.credential.keyHash
        #expect(result.rewardAccount.payload.dropFirst() == keyHashHex.hexStringToData)
    }

    @Test("toPoolParams populates pool owners from hex strings")
    func testPoolOwners() async throws {
        let params = try sampleParams
        let pool = try samplePool
        let result = try await params.toPoolParams(poolOperator: pool)

        let owners = result.poolOwners.asArray
        #expect(owners.count == 1)
        #expect(owners[0].payload == params.owners[0].hexStringToData)
    }

    @Test("toPoolParams converts single host address relay")
    func testSingleHostAddressRelay() async throws {
        let params = try sampleParams
        let pool = try samplePool
        let result = try await params.toPoolParams(poolOperator: pool)

        #expect(result.relays?.count == 1)
        guard case .singleHostAddr(let addr) = result.relays?.first else {
            Issue.record("Expected singleHostAddr relay")
            return
        }
        #expect(addr.port == 3533)
        #expect(addr.ipv4?.address == "0.0.0.0")
        #expect(addr.ipv6 == nil)
    }

    @Test("toPoolParams converts single host name relay")
    func testSingleHostNameRelay() async throws {
        let data = try #require(CLIResponse.poolStateAllPools.data(using: .utf8))
        let state = try JSONDecoder().decode(PoolState.self, from: data)
        let pool2 = try PoolOperator(from: poolHex2.hexStringToData)
        let params = try #require(state.pools[pool2]?.poolParams)
        let result = try await params.toPoolParams(poolOperator: pool2)

        guard case .singleHostName(let hostName) = result.relays?.first else {
            Issue.record("Expected singleHostName relay")
            return
        }
        #expect(hostName.dnsName == "relay.example.com")
        #expect(hostName.port == 3001)
    }

    @Test("toPoolParams converts multi host name relay")
    func testMultiHostNameRelay() async throws {
        let data = try #require(CLIResponse.poolStateMultiHostNameRelay.data(using: .utf8))
        let state = try JSONDecoder().decode(PoolState.self, from: data)
        let pool = try samplePool
        let params = try #require(state.pools[pool]?.poolParams)
        let result = try await params.toPoolParams(poolOperator: pool)

        guard case .multiHostName(let multiHost) = result.relays?.first else {
            Issue.record("Expected multiHostName relay")
            return
        }
        #expect(multiHost.dnsName == "relays.example.com")
    }

    @Test("toPoolParams populates metadata url and hash")
    func testMetadata() async throws {
        let data = try #require(CLIResponse.poolStateSinglePool.data(using: .utf8))
        let state = try JSONDecoder().decode(PoolState.self, from: data)
        let pool = try samplePool
        let params = try #require(state.pools[pool]?.poolParams)

        let metadataURL = "https://example.com/MPP6"
        let mockMetadataJSON = """
        {"name":"TestPool","description":"A test pool","ticker":"TST","homepage":"https://example.com"}
        """
        MockURLProtocol.responses[metadataURL] = .success(Data(mockMetadataJSON.utf8))
        defer { MockURLProtocol.responses[metadataURL] = nil }

        let session = MockURLProtocol.makeSession()
        let result = try await params.toPoolParams(poolOperator: pool, session: session)

        #expect(result.poolMetadata?.url?.absoluteString == metadataURL)
        #expect(result.poolMetadata?.name == "TestPool")
    }

    @Test("toPoolParams produces nil metadata when spsMetadata is null")
    func testNilMetadata() async throws {
        let data = try #require(CLIResponse.poolStateRetiring.data(using: .utf8))
        let state = try JSONDecoder().decode(PoolState.self, from: data)
        let pool = try samplePool
        let params = try #require(state.pools[pool]?.poolParams)
        let result = try await params.toPoolParams(poolOperator: pool)

        #expect(result.poolMetadata == nil)
    }

    @Test("toPoolParams produces an empty relays list when spsRelays is empty")
    func testEmptyRelays() async throws {
        let data = try #require(CLIResponse.poolStateRetiring.data(using: .utf8))
        let state = try JSONDecoder().decode(PoolState.self, from: data)
        let pool = try samplePool
        let params = try #require(state.pools[pool]?.poolParams)
        let result = try await params.toPoolParams(poolOperator: pool)

        #expect(result.relays?.isEmpty == true)
    }
}
