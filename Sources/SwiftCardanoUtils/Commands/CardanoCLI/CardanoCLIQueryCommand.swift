import Foundation
import SwiftCardanoCore

// MARK: - Query Command Implementation

/// Implementation of query commands for interacting with the chain
public struct QueryCommandImpl: CommandProtocol {
    var baseCLI: any BinaryInterfaceable
    
    var baseCommand: [String] {
        [era.rawValue, "query"]
    }
    
    init(baseCLI: any BinaryInterfaceable) {
        self.baseCLI = baseCLI
    }
    
    /// Get information about the current KES period and node's operational certificate
    public func kesPeriodInfo(arguments: [String]) async throws -> String {
        return try await executeCommand("kes-period-info", arguments: arguments + networkArgs)
    }
    
    /// Get the node's current protocol parameters
    public func protocolParameters(arguments: [String] = []) async throws -> String {
        return try await executeCommand("protocol-parameters", arguments: arguments + networkArgs)
    }
    
    /// Get the slots the node is expected to mint a block in (advanced command)
    public func leadershipSchedule(arguments: [String]) async throws -> String {
        return try await executeCommand("leadership-schedule", arguments: arguments + networkArgs)
    }
    
    /// Get the current delegations and reward accounts filtered by stake address
    public func stakeAddressInfo(arguments: [String]) async throws -> String {
        return try await executeCommand("stake-address-info", arguments: arguments + networkArgs)
    }
    
    /// Get the node's current set of stake pool ids - returns array of pool IDs
    public func stakePools(arguments: [String]) async throws -> [String] {
        let result = try await executeCommand("stake-pools", arguments: arguments + networkArgs)
        return result.components(separatedBy: .newlines).filter { !$0.isEmpty }
    }
    
    /// Get the node's current tip (slot no, hash, block no) - returns JSON
    public func tip(arguments: [String] = []) async throws -> ChainTip {
        let result = try await executeCommand("tip", arguments: arguments + networkArgs)
        guard let data = result.data(using: .utf8),
              let chainTip = try? JSONDecoder().decode(ChainTip.self, from: data)
        else {
            throw DecodingError.valueNotFound(ChainTip.self, DecodingError.Context(codingPath: [], debugDescription: "Failed to decode ChainTip from JSON"))
        }
        return chainTip
    }
    
    /// Get a portion of the current UTxO: by tx in, by address or the whole
    public func utxo(arguments: [String]) async throws -> String {
        return try await executeCommand("utxo", arguments: arguments + networkArgs)
    }
    
    /// Get the node's current aggregated stake distribution
    public func stakeDistribution(arguments: [String]) async throws -> String {
        return try await executeCommand("stake-distribution", arguments: arguments + networkArgs)
    }
    
    /// Dump the current ledger state of the node (advanced command)
    public func ledgerState(arguments: [String]) async throws -> String {
        return try await executeCommand("ledger-state", arguments: arguments + networkArgs)
    }
    
    /// Dump the current protocol state of the node (advanced command)
    public func protocolState(arguments: [String]) async throws -> String {
        return try await executeCommand("protocol-state", arguments: arguments + networkArgs)
    }
    
    /// Obtain the three stake snapshots for a pool (advanced command)
    public func stakeSnapshot(arguments: [String]) async throws -> String {
        return try await executeCommand("stake-snapshot", arguments: arguments + networkArgs)
    }
    
    /// DEPRECATED. Use query pool-state instead
    public func poolParams(arguments: [String]) async throws -> String {
        return try await executeCommand("pool-params", arguments: arguments + networkArgs)
    }
    
    /// Dump the pool state
    public func poolState(arguments: [String]) async throws -> String {
        return try await executeCommand("pool-state", arguments: arguments + networkArgs)
    }
    
    /// Local Mempool info
    public func txMempool(arguments: [String]) async throws -> String {
        return try await executeCommand("tx-mempool", arguments: arguments + networkArgs)
    }
    
    /// Query slot number for UTC timestamp
    public func slotNumber(arguments: [String]) async throws -> String {
        return try await executeCommand("slot-number", arguments: arguments + networkArgs)
    }
    
    /// Calculate the reference input scripts size in bytes for provided transaction inputs
    public func refScriptSize(arguments: [String]) async throws -> String {
        return try await executeCommand("ref-script-size", arguments: arguments + networkArgs)
    }
    
    /// Get the constitution
    public func constitution(arguments: [String]) async throws -> String {
        return try await executeCommand("constitution", arguments: arguments + networkArgs)
    }
    
    /// Get the governance state
    public func govState(arguments: [String]) async throws -> String {
        return try await executeCommand("gov-state", arguments: arguments + networkArgs)
    }
    
    /// Get the DRep state
    public func drepState(arguments: [String]) async throws -> String {
        return try await executeCommand("drep-state", arguments: arguments + networkArgs)
    }
    
    /// Get the DRep stake distribution
    public func drepStakeDistribution(arguments: [String]) async throws -> String {
        return try await executeCommand("drep-stake-distribution", arguments: arguments + networkArgs)
    }
    
    /// Get the SPO stake distribution
    public func spoStakeDistribution(arguments: [String]) async throws -> String {
        return try await executeCommand("spo-stake-distribution", arguments: arguments + networkArgs)
    }
    
    /// Get the committee state
    public func committeeState(arguments: [String]) async throws -> String {
        return try await executeCommand("committee-state", arguments: arguments + networkArgs)
    }
    
    /// Get the treasury value
    public func treasury(arguments: [String]) async throws -> String {
        return try await executeCommand("treasury", arguments: arguments + networkArgs)
    }
}
