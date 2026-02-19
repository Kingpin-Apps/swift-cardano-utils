import Foundation
import SwiftCardanoCore

// MARK: - Cardano DB Command Implementation

/// Implementation of cardano-db commands for Mithril client (alias: cdb)
public struct CardanoDbCommandImpl: MithrilCommandProtocol {
    var baseCLI: any BinaryInterfaceable
    var mithrilConfig: MithrilConfig
    
    var baseCommand: [String] {
        ["cardano-db"]
    }
    
    init(baseCLI: any BinaryInterfaceable, mithrilConfig: MithrilConfig) {
        self.baseCLI = baseCLI
        self.mithrilConfig = mithrilConfig
    }
    
    // MARK: - Snapshot Commands
    
    /// List available Cardano database snapshots
    public func snapshotList(arguments: [String] = []) async throws -> String {
        return try await executeCommand("snapshot", arguments: ["list"] + arguments)
    }
    
    /// Show detailed information about a specific Cardano database snapshot
    /// - Parameters:
    ///   - digest: The snapshot digest to show details for
    ///   - arguments: Additional arguments for the show command
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
            } else if let key = mithrilConfig.ancillaryVerificationKey {
                args.append(contentsOf: ["--ancillary-verification-key", key])
            } else if let key = Environment.get(.ancillaryVerificationKey) {
                args.append(contentsOf: ["--ancillary-verification-key", key])
            } else {
                let ancillaryKeyURL: URL
                switch baseCLI.cardanoConfig.network {
                    case .mainnet:
                        ancillaryKeyURL = URL(
                            string: "https://raw.githubusercontent.com/input-output-hk/mithril/main/mithril-infra/configuration/release-mainnet/ancillary.vkey"
                        )!
                    case .preprod:
                        ancillaryKeyURL = URL(
                            string: "https://raw.githubusercontent.com/input-output-hk/mithril/main/mithril-infra/configuration/release-preprod/ancillary.vkey"
                        )!
                    case .preview:
                        ancillaryKeyURL = URL(
                            string: "https://raw.githubusercontent.com/input-output-hk/mithril/main/mithril-infra/configuration/pre-release-preview/ancillary.vkey"
                        )!
                    default:
                        throw SwiftCardanoUtilsError
                            .unsupportedNetwork(
                                "Ancillary verification key is required for ancillary snapshot download, but not configured for the current network"
                            )
                }
                
                let (key, response) = try await URLSession.shared.data(from: ancillaryKeyURL)
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode)
                else {
                    throw SwiftCardanoUtilsError.networkError("Failed to fetch ancillary verification key from URL: \(ancillaryKeyURL)")
                }
                args.append(contentsOf: ["--ancillary-verification-key", key.toString])
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
