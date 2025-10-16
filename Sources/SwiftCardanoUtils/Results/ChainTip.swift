import Foundation

/// Structure representing the chain tip
public struct ChainTip: Codable, Equatable {
    public let block: Int
    public let epoch: Int
    public let era: String
    public let hash: String
    public let slot: Int
    public let slotInEpoch: Int
    public let slotsToEpochEnd: Int
    public let syncProgress: String
}
