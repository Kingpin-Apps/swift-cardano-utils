import Foundation
import SwiftCardanoCore

// MARK: - Stake Snapshot

/// Stake amounts at the three ledger snapshots (mark, set, go) for a pool.
public struct PoolStakeSnapshot: Codable, Sendable {
    /// Stake at the "mark" snapshot (most recent, used for voting power calculation)
    public let stakeMark: UInt64
    /// Stake at the "set" snapshot (active stake for current epoch rewards)
    public let stakeSet: UInt64
    /// Stake at the "go" snapshot (oldest, used for block production eligibility)
    public let stakeGo: UInt64

    public init(stakeMark: UInt64, stakeSet: UInt64, stakeGo: UInt64) {
        self.stakeMark = stakeMark
        self.stakeSet = stakeSet
        self.stakeGo = stakeGo
    }
}

/// The three stake snapshots for a pool and the network totals.
public struct StakeSnapshot: Codable, Sendable {
    /// Per-pool stake snapshots, keyed by pool operator
    public let pools: [PoolOperator: PoolStakeSnapshot]
    /// Network-wide totals at each snapshot
    public let total: PoolStakeSnapshot

    public init(pools: [PoolOperator: PoolStakeSnapshot], total: PoolStakeSnapshot) {
        self.pools = pools
        self.total = total
    }

    enum CodingKeys: String, CodingKey {
        case pools
        case total
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let rawPools = try container.decode([String: PoolStakeSnapshot].self, forKey: .pools)
        var pools: [PoolOperator: PoolStakeSnapshot] = [:]
        for (hexKey, snapshot) in rawPools {
            let poolOperator = try PoolOperator(from: hexKey.hexStringToData)
            pools[poolOperator] = snapshot
        }
        self.pools = pools

        self.total = try container.decode(PoolStakeSnapshot.self, forKey: .total)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        var rawPools: [String: PoolStakeSnapshot] = [:]
        for (poolOperator, snapshot) in pools {
            rawPools[try poolOperator.id(.hex)] = snapshot
        }
        try container.encode(rawPools, forKey: .pools)

        try container.encode(total, forKey: .total)
    }
}
