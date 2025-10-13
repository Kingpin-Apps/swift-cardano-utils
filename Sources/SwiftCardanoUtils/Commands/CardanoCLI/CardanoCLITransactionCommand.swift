import Foundation

// MARK: - Transaction Command Implementation

/// Implementation of transaction utility commands
public struct TransactionCommandImpl: CommandProtocol {
    var baseCLI: any BinaryInterfaceable
    
    var baseCommand: [String] {
        [era.rawValue, "transaction"]
    }
    
    init(baseCLI: any BinaryInterfaceable) {
        self.baseCLI = baseCLI
    }
    
    /// Assemble a tx body and witness(es) to form a transaction
    public func assemble(arguments: [String]) async throws -> String {
        return try await executeCommand("assemble", arguments: arguments)
    }
    
    /// Build a balanced transaction (automatically calculates fees) - returns fee amount
    public func build(arguments: [String]) async throws -> Int {
        let networkArgs = baseCLI.configuration.cardano.network.arguments
        let result = try await executeCommand("build", arguments: arguments + networkArgs)
        return Int(result.components(separatedBy: .whitespaces).last ?? "0") ?? 0
    }
    
    /// Build a balanced transaction without access to a live node (automatically estimates fees)
    public func buildEstimate(arguments: [String]) async throws -> String {
        return try await executeCommand("build-estimate", arguments: arguments)
    }
    
    /// Build a transaction (low-level, inconvenient)
    public func buildRaw(arguments: [String]) async throws -> String {
        return try await executeCommand("build-raw", arguments: arguments)
    }
    
    /// Calculate the minimum fee for a transaction - returns fee amount
    public func calculateMinFee(arguments: [String]) async throws -> Int {
        let networkArgs = baseCLI.configuration.cardano.network.arguments
        let result = try await executeCommand("calculate-min-fee", arguments: arguments + networkArgs)
        return Int(result.components(separatedBy: .whitespaces).first ?? "0") ?? 0
    }
    
    /// Calculate the minimum required UTxO for a transaction output - returns amount
    public func calculateMinRequiredUtxo(arguments: [String]) async throws -> Int {
        let result = try await executeCommand("calculate-min-required-utxo", arguments: arguments)
        return Int(result.components(separatedBy: .whitespaces).last ?? "0") ?? 0
    }
    
    /// Calculate the hash of script data
    public func hashScriptData(arguments: [String]) async throws -> String {
        return try await executeCommand("hash-script-data", arguments: arguments)
    }
    
    /// Sign a transaction
    public func sign(arguments: [String]) async throws -> String {
        let networkArgs = baseCLI.configuration.cardano.network.arguments
        return try await executeCommand("sign", arguments: arguments + networkArgs)
    }
    
    /// Create a transaction witness
    public func witness(arguments: [String]) async throws -> String {
        let networkArgs = baseCLI.configuration.cardano.network.arguments
        return try await executeCommand("witness", arguments: arguments + networkArgs)
    }
    
    /// Submit a transaction to the local node
    public func submit(arguments: [String]) async throws -> String {
        let networkArgs = baseCLI.configuration.cardano.network.arguments
        return try await executeCommand("submit", arguments: arguments + networkArgs)
    }
    
    /// Print a transaction identifier
    public func txId(arguments: [String]) async throws -> String {
        let result = try await executeCommand("txid", arguments: arguments)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Transform transaction
    public func transform(arguments: [String]) async throws -> String {
        let result = try await executeCommand("transform", arguments: arguments)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Calculate policy ID
    public func policyId(arguments: [String]) async throws -> String {
        let result = try await executeCommand("policyid", arguments: arguments)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// View transaction
    public func view(arguments: [String]) async throws -> String {
        let result = try await executeCommand("view", arguments: arguments)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
