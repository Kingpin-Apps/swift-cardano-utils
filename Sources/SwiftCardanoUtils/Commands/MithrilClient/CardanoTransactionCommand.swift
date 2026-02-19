import Foundation
import SwiftCardanoCore

// MARK: - Cardano Transaction Command Implementation

/// Implementation of cardano-transaction commands for Mithril client (alias: ctx)
public struct CardanoTransactionCommandImpl: MithrilCommandProtocol {
    var baseCLI: any BinaryInterfaceable
    
    var baseCommand: [String] {
        ["cardano-transaction"]
    }
    
    init(baseCLI: any BinaryInterfaceable) {
        self.baseCLI = baseCLI
    }
    
    // MARK: - Snapshot Commands
    
    /// List available Cardano transaction snapshots
    public func snapshotList(arguments: [String] = []) async throws -> String {
        return try await executeCommand("snapshot", arguments: ["list"] + arguments)
    }
    
    /// Show detailed information about a specific Cardano transaction snapshot
    /// - Parameter hash: The transaction snapshot hash to show details for
    public func snapshotShow(hash: String, arguments: [String] = []) async throws -> String {
        return try await executeCommand("snapshot", arguments: ["show", hash] + arguments)
    }
    
    // MARK: - Certify Commands
    
    /// Certify that the given list of transaction hashes are included in the Cardano transactions set
    /// - Parameters:
    ///   - transactionHashes: List of transaction hashes to certify
    ///   - arguments: Additional arguments
    public func certify(transactionHashes: [String], arguments: [String] = []) async throws -> String {
        var args: [String] = []
        for hash in transactionHashes {
            args.append(contentsOf: ["--transaction-hash", hash])
        }
        args.append(contentsOf: arguments)
        return try await executeCommand("certify", arguments: args)
    }
}
