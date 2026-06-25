import Foundation
import SwiftCardanoCore
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - Pool State

/// Pool metadata as returned by the `cardano-cli query pool-state` command.
public struct PoolStateMetadata: Codable, Sendable {
    /// Blake2b hash of the pool metadata JSON
    public let hash: String
    /// URL where the pool metadata is hosted
    public let url: String
}

/// Network the `cardano-cli query pool-state` response was produced on.
///
/// cardano-cli 11.0+ no longer embeds the network inside the pool's account id, so
/// it is threaded into the decoder via `userInfo` (as the string `"Mainnet"` or
/// `"Testnet"`) when decoding a ``PoolState`` so that ``PoolStateRewardAccount``
/// can still reconstruct the correct reward-account header byte.
public extension CodingUserInfoKey {
    static let poolStateNetwork = CodingUserInfoKey(rawValue: "swiftCardanoUtils.poolStateNetwork")!
}

/// Credential used in a pool's reward account (legacy CLI shape).
public struct PoolStateCredential: Codable, Sendable {
    public let keyHash: String
}

/// Reward account associated with a stake pool.
///
/// Two CLI shapes are accepted:
/// - cardano-cli 11.0+: `"spsAccountId": { "keyHash": "<hex>" }` — flat, no network.
/// - older CLIs: `"spsRewardAccount": { "credential": { "keyHash": "<hex>" }, "network": "Testnet" }`.
///
/// When the JSON omits the network (the 11.0+ shape) it is taken from the value
/// threaded in via `decoder.userInfo[.poolStateNetwork]`, defaulting to `"Testnet"`.
public struct PoolStateRewardAccount: Codable, Sendable {
    public let keyHash: String
    public let network: String

    /// Backward-compatible accessor for the legacy nested `credential` shape.
    public var credential: PoolStateCredential { PoolStateCredential(keyHash: keyHash) }

    private enum CodingKeys: String, CodingKey {
        case keyHash
        case credential
        case network
    }

    private enum CredentialKeys: String, CodingKey {
        case keyHash
    }

    public init(keyHash: String, network: String) {
        self.keyHash = keyHash
        self.network = network
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let keyHash = try container.decodeIfPresent(String.self, forKey: .keyHash) {
            // cardano-cli 11.0+ flat shape: { "keyHash": "<hex>" }
            self.keyHash = keyHash
        } else {
            // Legacy nested shape: { "credential": { "keyHash": "<hex>" }, ... }
            let credential = try container.nestedContainer(keyedBy: CredentialKeys.self, forKey: .credential)
            self.keyHash = try credential.decode(String.self, forKey: .keyHash)
        }

        if let network = try container.decodeIfPresent(String.self, forKey: .network) {
            self.network = network
        } else {
            self.network = (decoder.userInfo[.poolStateNetwork] as? String) ?? "Testnet"
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(keyHash, forKey: .keyHash)
        try container.encode(network, forKey: .network)
    }
}

// MARK: - PoolRelay

private struct SingleHostAddressData: Codable {
    let ipv4: String?
    let ipv6: String?
    let port: Int?

    enum CodingKeys: String, CodingKey {
        case ipv4 = "IPv4"
        case ipv6 = "IPv6"
        case port
    }
}

private struct SingleHostNameData: Codable {
    let dnsName: String
    let port: Int?
}

private struct MultiHostNameData: Codable {
    let dnsName: String
}

/// A relay entry for a stake pool, matching the CLI pool-state JSON format.
public enum PoolRelay: Codable, Sendable {
    case singleHostAddress(ipv4: String?, ipv6: String?, port: Int?)
    case singleHostName(dnsName: String, port: Int?)
    case multiHostName(dnsName: String)

    private enum TypeKey: String, CodingKey {
        case singleHostAddress = "single host address"
        case singleHostName = "single host name"
        case multiHostName = "multi host name"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: TypeKey.self)
        if container.contains(.singleHostAddress) {
            let data = try container.decode(SingleHostAddressData.self, forKey: .singleHostAddress)
            self = .singleHostAddress(ipv4: data.ipv4, ipv6: data.ipv6, port: data.port)
        } else if container.contains(.singleHostName) {
            let data = try container.decode(SingleHostNameData.self, forKey: .singleHostName)
            self = .singleHostName(dnsName: data.dnsName, port: data.port)
        } else if container.contains(.multiHostName) {
            let data = try container.decode(MultiHostNameData.self, forKey: .multiHostName)
            self = .multiHostName(dnsName: data.dnsName)
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Unknown relay type"
            ))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: TypeKey.self)
        switch self {
        case .singleHostAddress(let ipv4, let ipv6, let port):
            let data = SingleHostAddressData(ipv4: ipv4, ipv6: ipv6, port: port)
            try container.encode(data, forKey: .singleHostAddress)
        case .singleHostName(let dnsName, let port):
            let data = SingleHostNameData(dnsName: dnsName, port: port)
            try container.encode(data, forKey: .singleHostName)
        case .multiHostName(let dnsName):
            let data = MultiHostNameData(dnsName: dnsName)
            try container.encode(data, forKey: .multiHostName)
        }
    }
}

// MARK: - PoolStateParams

/// Pool parameters as returned by the `cardano-cli query pool-state` command.
public struct PoolStateParams: Codable, Sendable {
    /// Fixed pool cost (in lovelace)
    public let cost: UInt64
    /// Pool deposit (in lovelace)
    public let deposit: UInt64
    /// Pool margin as a fraction (0.0–1.0)
    public let margin: Double
    /// Optional pool metadata
    public let metadata: PoolStateMetadata?
    /// Pool owner key hashes (hex-encoded)
    public let owners: [String]
    /// Pool pledge (in lovelace)
    public let pledge: UInt64
    /// Pool relays
    public let relays: [PoolRelay]
    /// Pool reward account
    public let rewardAccount: PoolStateRewardAccount
    /// VRF key hash (hex-encoded)
    public let vrf: String

    enum CodingKeys: String, CodingKey {
        case cost = "spsCost"
        case deposit = "spsDeposit"
        case margin = "spsMargin"
        case metadata = "spsMetadata"
        case owners = "spsOwners"
        case pledge = "spsPledge"
        case relays = "spsRelays"
        // cardano-cli 11.0+ renamed the reward account from `spsRewardAccount`
        // to `spsAccountId`. Accept both so the model decodes across CLI versions.
        case rewardAccount = "spsAccountId"
        case legacyRewardAccount = "spsRewardAccount"
        case vrf = "spsVrf"
    }

    public init(
        cost: UInt64,
        deposit: UInt64,
        margin: Double,
        metadata: PoolStateMetadata?,
        owners: [String],
        pledge: UInt64,
        relays: [PoolRelay],
        rewardAccount: PoolStateRewardAccount,
        vrf: String
    ) {
        self.cost = cost
        self.deposit = deposit
        self.margin = margin
        self.metadata = metadata
        self.owners = owners
        self.pledge = pledge
        self.relays = relays
        self.rewardAccount = rewardAccount
        self.vrf = vrf
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.cost = try container.decode(UInt64.self, forKey: .cost)
        self.deposit = try container.decode(UInt64.self, forKey: .deposit)
        self.margin = try container.decode(Double.self, forKey: .margin)
        self.metadata = try container.decodeIfPresent(PoolStateMetadata.self, forKey: .metadata)
        self.owners = try container.decode([String].self, forKey: .owners)
        self.pledge = try container.decode(UInt64.self, forKey: .pledge)
        self.relays = try container.decode([PoolRelay].self, forKey: .relays)
        self.vrf = try container.decode(String.self, forKey: .vrf)
        if container.contains(.rewardAccount) {
            self.rewardAccount = try container.decode(PoolStateRewardAccount.self, forKey: .rewardAccount)
        } else {
            self.rewardAccount = try container.decode(PoolStateRewardAccount.self, forKey: .legacyRewardAccount)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(cost, forKey: .cost)
        try container.encode(deposit, forKey: .deposit)
        try container.encode(margin, forKey: .margin)
        try container.encodeIfPresent(metadata, forKey: .metadata)
        try container.encode(owners, forKey: .owners)
        try container.encode(pledge, forKey: .pledge)
        try container.encode(relays, forKey: .relays)
        try container.encode(rewardAccount, forKey: .rewardAccount)
        try container.encode(vrf, forKey: .vrf)
    }
}

// MARK: - PoolStateEntry

/// The state of a single pool as returned by `cardano-cli query pool-state`.
public struct PoolStateEntry: Codable, Sendable {
    /// Current registered pool parameters
    public let poolParams: PoolStateParams
    /// Future pool parameters pending an on-chain update, if any
    public let futurePoolParams: PoolStateParams?
    /// Epoch in which the pool is scheduled to retire, if any
    public let retiring: UInt32?
}

// MARK: - PoolStateParams + Conversion

extension PoolStateParams {

    /// Converts this CLI pool state parameters to a ``PoolParams`` model.
    ///
    /// The pool operator is required as a parameter because it is the outer dictionary key
    /// in the CLI JSON response and is not stored within `PoolStateParams` itself.
    ///
    /// - Parameter poolOperator: The pool operator that owns these parameters.
    /// - Returns: A ``PoolParams`` instance populated from this CLI response.
    /// - Throws: If any field value is malformed (e.g. invalid URL, invalid hex).
    public func toPoolParams(poolOperator: PoolOperator, strict: Bool = false, session: URLSession = .shared) async throws -> PoolParams {

        // VRF key hash
        let vrfKeyHash = VrfKeyHash(payload: vrf.hexStringToData)

        // Margin: convert Double (0.0–1.0) to a reduced UnitInterval fraction
        let unitInterval = marginToUnitInterval(margin)

        // Reward account: prepend the Cardano network header byte to the 28-byte key hash.
        // Key-based stake addresses use 0xE0 (Testnet) or 0xE1 (Mainnet).
        let networkByte: UInt8 = rewardAccount.network.lowercased() == "mainnet" ? 0xE1 : 0xE0
        let rewardAccountHash = RewardAccountHash(
            payload: Data([networkByte]) + rewardAccount.keyHash.hexStringToData
        )

        // Pool owners
        let ownerHashes = owners.map { VerificationKeyHash(payload: $0.hexStringToData) }
        let poolOwners = ListOrOrderedSet<VerificationKeyHash>.list(ownerHashes)

        // Relays
        let coreRelays: [Relay] = relays.map { relay in
            switch relay {
            case .singleHostAddress(let ipv4String, let ipv6String, let port):
                return .singleHostAddr(SingleHostAddr(
                    port: port,
                    ipv4: ipv4String.flatMap { IPv4Address($0) },
                    ipv6: ipv6String.flatMap { IPv6Address($0) }
                ))
            case .singleHostName(let dnsName, let port):
                return .singleHostName(SingleHostName(port: port, dnsName: dnsName))
            case .multiHostName(let dnsName):
                return .multiHostName(MultiHostName(dnsName: dnsName))
            }
        }

        // Pool metadata. The on-chain `url` + `hash` are always preserved; only the
        // *verification* of the off-chain document is governed by `strict`.
        let poolMetadata: PoolMetadata?
        if let meta = metadata {
            let metaUrl = try Url(meta.url)
            let metaHash = PoolMetadataHash(payload: meta.hash.hexStringToData)
            if strict {
                // Download the off-chain document and verify its hash; any failure
                // (unreachable URL or hash mismatch) is fatal.
                poolMetadata = try await PoolMetadata.fetch(
                    url: metaUrl,
                    poolMetadataHash: metaHash,
                    session: session
                )
            } else {
                // Lenient: try to enrich with the off-chain document (name, ticker,
                // …) without verifying it, but never fail — and always keep the
                // on-chain url + hash even when the document is unreachable or no
                // longer matches.
                let fetched = try? await PoolMetadata.fetch(
                    url: metaUrl,
                    poolMetadataHash: nil,
                    session: session
                )
                poolMetadata = (try? PoolMetadata(
                    name: fetched?.name,
                    description: fetched?.desc,
                    ticker: fetched?.ticker,
                    homepage: fetched?.homepage,
                    url: metaUrl,
                    poolMetadataHash: metaHash
                )) ?? (try? PoolMetadata(url: metaUrl, poolMetadataHash: metaHash))
            }
        } else {
            poolMetadata = nil
        }

        return PoolParams(
            poolOperator: poolOperator.poolKeyHash,
            vrfKeyHash: vrfKeyHash,
            pledge: Int(pledge),
            cost: Int(cost),
            margin: unitInterval,
            rewardAccount: rewardAccountHash,
            poolOwners: poolOwners,
            relays: coreRelays,
            poolMetadata: poolMetadata
        )
    }
}

/// Converts a margin `Double` (0.0–1.0) to a ``UnitInterval`` with a reduced numerator/denominator.
private func marginToUnitInterval(_ value: Double) -> UnitInterval {
    if value <= 0 { return UnitInterval(numerator: 0, denominator: 1) }
    if value >= 1 { return UnitInterval(numerator: 1, denominator: 1) }
    let denominator: UInt64 = 10_000_000_000
    let numerator = UInt64((value * Double(denominator)).rounded())
    let g = gcd(numerator, denominator)
    return UnitInterval(numerator: numerator / g, denominator: denominator / g)
}

private func gcd(_ a: UInt64, _ b: UInt64) -> UInt64 {
    b == 0 ? a : gcd(b, a % b)
}

// MARK: - PoolState

/// Pool state response from `cardano-cli query pool-state`, keyed by pool operator.
public struct PoolState: Codable, Sendable {
    /// Per-pool state entries, keyed by pool operator
    public let pools: [PoolOperator: PoolStateEntry]

    public init(pools: [PoolOperator: PoolStateEntry]) {
        self.pools = pools
    }

    public init(from decoder: Decoder) throws {
        let raw = try [String: PoolStateEntry](from: decoder)
        var pools: [PoolOperator: PoolStateEntry] = [:]
        for (hexKey, entry) in raw {
            let poolOperator = try PoolOperator(from: hexKey.hexStringToData)
            pools[poolOperator] = entry
        }
        self.pools = pools
    }

    public func encode(to encoder: Encoder) throws {
        var raw: [String: PoolStateEntry] = [:]
        for (poolOperator, entry) in pools {
            raw[try poolOperator.id(.hex)] = entry
        }
        try raw.encode(to: encoder)
    }
}
