import Foundation
import SwiftCardanoCore

// MARK: - Mithril Stake Distribution Command Implementation

/// Implementation of mithril-stake-distribution commands for Mithril client (alias: msd)
public struct MithrilStakeDistributionCommandImpl: MithrilCommandProtocol {
    var baseCLI: any BinaryInterfaceable
    var mithrilConfig: MithrilConfig
    
    var baseCommand: [String] {
        ["mithril-stake-distribution"]
    }
    
    init(baseCLI: any BinaryInterfaceable, mithrilConfig: MithrilConfig) {
        self.baseCLI = baseCLI
        self.mithrilConfig = mithrilConfig
    }
    
    /// List available Mithril stake distributions
    public func list(arguments: [String] = []) async throws -> String {
        return try await executeCommand("list", arguments: arguments)
    }
    
    /// Download and verify a Mithril stake distribution
    /// - Parameters:
    ///   - artifactHash: The artifact hash to download
    ///   - arguments: Additional arguments
    public func download(artifactHash: String, arguments: [String] = []) async throws -> String {
        return try await executeCommand("download", arguments: [artifactHash] + arguments)
    }
}
