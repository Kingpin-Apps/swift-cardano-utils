import Foundation
import SwiftCardanoCore
import Logging

// MARK: - Mithril Command Base Infrastructure

/// Protocol for Mithril command implementations
protocol MithrilCommandProtocol {
    var baseCLI: any BinaryInterfaceable { get }
    var baseCommand: [String] { get }
    func executeCommand(_ subcommand: String, arguments: [String]) async throws -> String
}

/// Base implementation for Mithril command protocol
extension MithrilCommandProtocol {
    
    /// Get the aggregator endpoint arguments if configured
    var aggregatorArgs: [String] {
        if let mithrilConfig = baseCLI.configuration.mithril,
           let endpoint = mithrilConfig.aggregatorEndpoint {
            return ["--aggregator-endpoint", endpoint]
        }
        return []
    }
    
    /// Get the genesis verification key arguments if configured
    var genesisVerificationKeyArgs: [String] {
        if let mithrilConfig = baseCLI.configuration.mithril,
           let key = mithrilConfig.genesisVerificationKey {
            return ["--genesis-verification-key", key]
        }
        return []
    }
    
    /// Execute a command with aggregator endpoint included
    func executeCommand(_ subcommand: String, arguments: [String] = []) async throws -> String {
        let fullCommand = baseCommand + [subcommand] + aggregatorArgs + arguments
        return try await baseCLI.runCommand(fullCommand)
    }
    
    /// Execute a command without additional processing
    func executeRawCommand(_ subcommand: String, arguments: [String] = []) async throws -> String {
        let fullCommand = baseCommand + [subcommand] + arguments
        return try await baseCLI.runCommand(fullCommand)
    }
}
