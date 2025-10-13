import Foundation

// MARK: - Hash Command Implementation

/// Compute the hash to pass to the various --*-hash arguments of commands.
public struct HashCommandImpl: CommandProtocol {
    var baseCLI: any BinaryInterfaceable
    
    var baseCommand: [String] {
        ["hash"]
    }
    
    init(baseCLI: any BinaryInterfaceable) {
        self.baseCLI = baseCLI
    }
    
    /// Compute the hash of some anchor data (to then pass it to other commands).
    public func anchorData(arguments: [String]) async throws -> String {
        return try await executeCommand("anchor-data", arguments: arguments)
    }
    
    /// Compute the hash of a script (to then pass it to other commands).
    public func script(arguments: [String]) async throws -> String {
        return try await executeCommand("script", arguments: arguments)
    }
    
    /// Compute the hash of a genesis file.
    public func genesisFile(arguments: [String]) async throws -> String {
        return try await executeCommand("genesis-file", arguments: arguments)
    }
    
}
