import Foundation
import SwiftCardanoCore

// MARK: - Cardano Stake Distribution Command Implementation

/// Implementation of cardano-stake-distribution commands for Mithril client (alias: csd)
public struct CardanoStakeDistributionCommandImpl: MithrilCommandProtocol {
    var baseCLI: any BinaryInterfaceable
    
    var baseCommand: [String] {
        ["cardano-stake-distribution"]
    }
    
    init(baseCLI: any BinaryInterfaceable) {
        self.baseCLI = baseCLI
    }
    
    /// List available Cardano stake distributions
    public func list(arguments: [String] = []) async throws -> String {
        return try await executeCommand("list", arguments: arguments)
    }
}
