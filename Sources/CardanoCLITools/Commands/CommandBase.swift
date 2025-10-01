import Foundation
import SwiftCardanoCore
import Logging

// MARK: - Command Base Infrastructure

/// Protocol for command implementations
protocol CommandProtocol {
    var baseCLI: any BinaryInterfaceable { get }
    var baseCommand: [String] { get }
    func executeCommand(_ subcommand: String, arguments: [String]) async throws -> String
}

/// Base class for all command implementations
extension CommandProtocol {
    var era: Era {
        return baseCLI.configuration.cardano.era
    }
    
    var networkArgs: [String] {
        return baseCLI.configuration.cardano.network.arguments
    }
    
    func executeCommand(_ subcommand: String, arguments: [String] = []) async throws -> String {
        let fullCommand = baseCommand + [subcommand] + arguments
        return try await baseCLI.runCommand(fullCommand)
    }
}
