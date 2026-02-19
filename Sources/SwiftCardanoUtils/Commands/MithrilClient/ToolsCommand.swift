import Foundation
import SwiftCardanoCore

// MARK: - Tools Command Implementation

/// Implementation of tools commands for Mithril client
public struct ToolsCommandImpl: MithrilCommandProtocol {
    var baseCLI: any BinaryInterfaceable
    
    var baseCommand: [String] {
        ["tools"]
    }
    
    init(baseCLI: any BinaryInterfaceable) {
        self.baseCLI = baseCLI
    }
    
    /// Convert UTXO-HD ledger state snapshot to a different format
    /// 
    /// Since Cardano node v.10.4.1, the Mithril aggregator produces snapshots using the InMemory UTXO-HD flavor.
    /// This command converts the restored ledger state snapshot to the required format (LMDB or Legacy).
    /// 
    /// - Parameters:
    ///   - inputFormat: The source format (e.g., "InMemory")
    ///   - outputFormat: The target format (e.g., "LMDB" or "Legacy")
    ///   - snapshotPath: Path to the ledger state snapshot
    ///   - arguments: Additional arguments
    public func utxoHdSnapshotConverter(
        inputFormat: String? = nil,
        outputFormat: String? = nil,
        snapshotPath: String? = nil,
        arguments: [String] = []
    ) async throws -> String {
        var args: [String] = []
        
        if let input = inputFormat {
            args.append(contentsOf: ["--input-format", input])
        }
        
        if let output = outputFormat {
            args.append(contentsOf: ["--output-format", output])
        }
        
        if let path = snapshotPath {
            args.append(contentsOf: ["--snapshot-path", path])
        }
        
        args.append(contentsOf: arguments)
        
        return try await executeRawCommand("utxo-hd", arguments: ["snapshot-converter"] + args)
    }
}
