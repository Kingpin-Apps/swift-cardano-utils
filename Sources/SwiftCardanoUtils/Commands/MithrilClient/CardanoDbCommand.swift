import Foundation
import SwiftCardanoCore

// MARK: - Cardano DB Command Implementation

/// Implementation of cardano-db commands for Mithril client (alias: cdb)
public struct CardanoDbCommandImpl: MithrilCommandProtocol {
    var baseCLI: any BinaryInterfaceable
    
    var baseCommand: [String] {
        ["cardano-db"]
    }
    
    init(baseCLI: any BinaryInterfaceable) {
        self.baseCLI = baseCLI
    }
    
    // MARK: - Snapshot Commands
    
    /// List available Cardano database snapshots
    public func snapshotList(arguments: [String] = []) async throws -> String {
        return try await executeCommand("snapshot", arguments: ["list"] + arguments)
    }
    
    /// Show detailed information about a specific Cardano database snapshot
    /// - Parameter digest: The snapshot digest to show details for
    public func snapshotShow(digest: String, arguments: [String] = []) async throws -> String {
        return try await executeCommand("snapshot", arguments: ["show", digest] + arguments)
    }
    
    // MARK: - Download Commands
    
    /// Download and verify a Cardano database snapshot
    /// - Parameters:
    ///   - digest: The snapshot digest to download (use "latest" for the latest snapshot)
    ///   - downloadDir: Optional directory to download the snapshot to
    ///   - includeAncillary: Whether to include ancillary files (ledger state snapshot and last immutable file)
    ///   - ancillaryVerificationKey: The ancillary verification key (required if includeAncillary is true)
    ///   - arguments: Additional arguments
    public func download(
        digest: String = "latest",
        downloadDir: String? = nil,
        includeAncillary: Bool = false,
        ancillaryVerificationKey: String? = nil,
        arguments: [String] = []
    ) async throws -> String {
        var args: [String] = []
        
        if let dir = downloadDir {
            args.append(contentsOf: ["--download-dir", dir])
        }
        
        if includeAncillary {
            args.append("--include-ancillary")
            if let key = ancillaryVerificationKey {
                args.append(contentsOf: ["--ancillary-verification-key", key])
            }
        }
        
        args.append(digest)
        args.append(contentsOf: arguments)
        
        return try await executeCommand("download", arguments: args)
    }
    
    /// Download snapshot without ancillary files (fast download, slower node startup)
    /// - Parameters:
    ///   - digest: The snapshot digest to download (use "latest" for the latest snapshot)
    ///   - downloadDir: Optional directory to download the snapshot to
    ///   - arguments: Additional arguments
    public func downloadSkipAncillary(
        digest: String = "latest",
        downloadDir: String? = nil,
        arguments: [String] = []
    ) async throws -> String {
        return try await download(
            digest: digest,
            downloadDir: downloadDir,
            includeAncillary: false,
            arguments: arguments
        )
    }
    
    // MARK: - Verify Commands (v2 backend only)
    
    /// Verify a downloaded Cardano database snapshot
    /// - Parameter arguments: Additional arguments for verification
    public func verify(arguments: [String] = []) async throws -> String {
        return try await executeCommand("verify", arguments: arguments)
    }
}
