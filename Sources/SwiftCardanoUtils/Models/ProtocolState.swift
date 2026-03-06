import Foundation
import SwiftCardanoCore

// MARK: - Protocol State

/// The current protocol state of the node.
public struct ProtocolState: Codable, Sendable {
    public let candidateNonce: String
    public let epochNonce: String
    public let evolvingNonce: String
    public let labNonce: String
    public let lastEpochBlockNonce: String
    public let lastSlot: UInt64
    public let oCertCounters: [PoolOperator: UInt64]

    public init(
        candidateNonce: String,
        epochNonce: String,
        evolvingNonce: String,
        labNonce: String,
        lastEpochBlockNonce: String,
        lastSlot: UInt64,
        oCertCounters: [PoolOperator: UInt64]
    ) {
        self.candidateNonce = candidateNonce
        self.epochNonce = epochNonce
        self.evolvingNonce = evolvingNonce
        self.labNonce = labNonce
        self.lastEpochBlockNonce = lastEpochBlockNonce
        self.lastSlot = lastSlot
        self.oCertCounters = oCertCounters
    }

    enum CodingKeys: String, CodingKey {
        case candidateNonce
        case epochNonce
        case evolvingNonce
        case labNonce
        case lastEpochBlockNonce
        case lastSlot
        case oCertCounters
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        candidateNonce = try container.decode(String.self, forKey: .candidateNonce)
        epochNonce = try container.decode(String.self, forKey: .epochNonce)
        evolvingNonce = try container.decode(String.self, forKey: .evolvingNonce)
        labNonce = try container.decode(String.self, forKey: .labNonce)
        lastEpochBlockNonce = try container.decode(String.self, forKey: .lastEpochBlockNonce)
        lastSlot = try container.decode(UInt64.self, forKey: .lastSlot)

        let rawCounters = try container.decode([String: UInt64].self, forKey: .oCertCounters)
        var counters: [PoolOperator: UInt64] = [:]
        for (hexKey, value) in rawCounters {
            let poolOperator = try PoolOperator(from: hexKey.hexStringToData)
            counters[poolOperator] = value
        }
        oCertCounters = counters
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(candidateNonce, forKey: .candidateNonce)
        try container.encode(epochNonce, forKey: .epochNonce)
        try container.encode(evolvingNonce, forKey: .evolvingNonce)
        try container.encode(labNonce, forKey: .labNonce)
        try container.encode(lastEpochBlockNonce, forKey: .lastEpochBlockNonce)
        try container.encode(lastSlot, forKey: .lastSlot)

        var rawCounters: [String: UInt64] = [:]
        for (poolOperator, value) in oCertCounters {
            rawCounters[try poolOperator.id(.hex)] = value
        }
        try container.encode(rawCounters, forKey: .oCertCounters)
    }
}
