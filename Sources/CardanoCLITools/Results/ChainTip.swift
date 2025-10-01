import Foundation

/// Structure representing the chain tip
public struct ChainTip: Codable {
    let block: Int
    let epoch: Int
    let era: String
    let hash: String
    let slot: Int
    let slotInEpoch: Int
    let slotsToEpochEnd: Int
    let syncProgress: String
}
