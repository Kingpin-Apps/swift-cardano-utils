import Foundation

// MARK: - Legacy Command Implementation

/// Legacy commands
public struct LegacyCommandImpl: CommandProtocol {
    var baseCLI: any BinaryInterfaceable
    
    var baseCommand: [String] {
        ["legacy"]
    }
    
    init(baseCLI: any BinaryInterfaceable) {
        self.baseCLI = baseCLI
    }
    
    /// Genesis block commands
    public func genesis(arguments: [String]) async throws -> String {
        return try await executeCommand("genesis", arguments: arguments)
    }
    
    /// Governance commands
    public func governance(arguments: [String]) async throws -> String {
        return try await executeCommand("governance", arguments: arguments)
    }
}
