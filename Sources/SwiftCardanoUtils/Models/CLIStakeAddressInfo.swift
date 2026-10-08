import Foundation
import SwiftCardanoCore

// MARK: - Stake Address Info (cardano-cli output)

/// One entry of `cardano-cli query stake-address-info` output.
///
/// Older cardano-cli versions print delegations as strings (`"pool1..."`, `"keyHash-..."`),
/// newer ones print objects:
///
/// ```json
/// "stakeDelegation": { "stakePoolBech32": "pool1...", "stakePoolHex": "..." },
/// "voteDelegation":  { "cip129Bech32": "drep1...", "cip129Hex": "...", "keyHash": "..." }
/// ```
///
/// Both forms are accepted and mapped onto `StakeAddressInfo`.
struct CLIStakeAddressInfo: Decodable {
    let address: String
    let govActionDeposits: [String: UInt64]?
    let rewardAccountBalance: Int64?
    let stakeDelegation: PoolOperator?
    let stakeRegistrationDeposit: Int64?
    let voteDelegation: DRep?

    private enum CodingKeys: String, CodingKey {
        case address
        case govActionDeposits
        case rewardAccountBalance
        case stakeDelegation
        case stakeRegistrationDeposit
        case voteDelegation
    }

    private enum StakeDelegationKeys: String, CodingKey {
        case stakePoolBech32
        case stakePoolHex
    }

    private enum VoteDelegationKeys: String, CodingKey {
        case cip129Bech32
        case keyHash
        case scriptHash
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.address = try container.decode(String.self, forKey: .address)
        self.govActionDeposits = try container.decodeIfPresent([String: UInt64].self, forKey: .govActionDeposits)
        self.rewardAccountBalance = try container.decodeIfPresent(Int64.self, forKey: .rewardAccountBalance)
        self.stakeRegistrationDeposit = try container.decodeIfPresent(Int64.self, forKey: .stakeRegistrationDeposit)
        self.stakeDelegation = try Self.decodeStakeDelegation(from: container)
        self.voteDelegation = try Self.decodeVoteDelegation(from: container)
    }

    private static func decodeStakeDelegation(
        from container: KeyedDecodingContainer<CodingKeys>
    ) throws -> PoolOperator? {
        guard container.contains(.stakeDelegation),
              try !container.decodeNil(forKey: .stakeDelegation) else {
            return nil
        }

        if let poolId = try? container.decode(String.self, forKey: .stakeDelegation) {
            return try PoolOperator(from: poolId)
        }

        let object = try container.nestedContainer(keyedBy: StakeDelegationKeys.self, forKey: .stakeDelegation)
        if let bech32 = try object.decodeIfPresent(String.self, forKey: .stakePoolBech32) {
            return try PoolOperator(from: bech32)
        }
        if let hex = try object.decodeIfPresent(String.self, forKey: .stakePoolHex) {
            return try PoolOperator(from: hex.hexStringToData)
        }
        throw SwiftCardanoUtilsError.invalidOutput("Unrecognized stakeDelegation format")
    }

    private static func decodeVoteDelegation(
        from container: KeyedDecodingContainer<CodingKeys>
    ) throws -> DRep? {
        guard container.contains(.voteDelegation),
              try !container.decodeNil(forKey: .voteDelegation) else {
            return nil
        }

        // String form, including "alwaysAbstain" / "alwaysNoConfidence": DRep's own JSON decoding handles it
        if (try? container.decode(String.self, forKey: .voteDelegation)) != nil {
            return try container.decode(DRep.self, forKey: .voteDelegation)
        }

        let object = try container.nestedContainer(keyedBy: VoteDelegationKeys.self, forKey: .voteDelegation)
        if let hex = try object.decodeIfPresent(String.self, forKey: .keyHash) {
            return try DRep(from: hex.hexStringToData, as: .keyHash)
        }
        if let hex = try object.decodeIfPresent(String.self, forKey: .scriptHash) {
            return try DRep(from: hex.hexStringToData, as: .scriptHash)
        }
        if let bech32 = try object.decodeIfPresent(String.self, forKey: .cip129Bech32) {
            return try DRep(from: bech32)
        }
        throw SwiftCardanoUtilsError.invalidOutput("Unrecognized voteDelegation format")
    }

    var stakeAddressInfo: StakeAddressInfo {
        StakeAddressInfo(
            address: address,
            govActionDeposits: govActionDeposits,
            rewardAccountBalance: rewardAccountBalance ?? 0,
            stakeDelegation: stakeDelegation,
            stakeRegistrationDeposit: stakeRegistrationDeposit,
            voteDelegation: voteDelegation
        )
    }
}
