import Foundation

// MARK: - Debug Command Implementation

/// Implementation of debug commands
public struct DebugCommandImpl: CommandProtocol {
    var baseCLI: any BinaryInterfaceable
    
    var baseCommand: [String] {
        ["debug"]
    }
    
    init(baseCLI: any BinaryInterfaceable) {
        self.baseCLI = baseCLI
    }
    
    /// Log epoch state of a running node - connects to local node and logs epoch state
    public func logEpochState(arguments: [String]) async throws -> String {
        return try await executeCommand("log-epoch-state", arguments: arguments)
    }
    
    /// View transaction details
    public func transactionView(arguments: [String]) async throws -> String {
        let result = try await executeCommand("transaction", arguments: ["view"] + arguments)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
