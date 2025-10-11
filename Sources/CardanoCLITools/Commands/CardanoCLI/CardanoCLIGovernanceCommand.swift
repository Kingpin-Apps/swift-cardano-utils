import Foundation

// MARK: - Governance Command Implementation

/// Implementation of governance commands
public struct GovernanceCommandImpl: CommandProtocol {
    var baseCLI: any BinaryInterfaceable
    
    var baseCommand: [String] {
        [era.rawValue, "governance"]
    }
    
    init(baseCLI: any BinaryInterfaceable) {
        self.baseCLI = baseCLI
    }
    
    /// Governance action commands
    public func action(arguments: [String]) async throws -> String {
        return try await executeCommand("action", arguments: arguments)
    }
    
    /// Committee member commands
    public func committee(arguments: [String]) async throws -> String {
        return try await executeCommand("committee", arguments: arguments)
    }
    
    /// DRep member commands
    public func drep(arguments: [String]) async throws -> String {
        return try await executeCommand("drep", arguments: arguments)
    }
    
    /// Vote commands
    public func vote(arguments: [String]) async throws -> String {
        return try await executeCommand("vote", arguments: arguments)
    }
    
    // MARK: - Convenience Methods for Common Operations
    
    /// Generate DRep key pair
    public func drepKeyGen(arguments: [String]) async throws -> String {
        return try await executeCommand("drep", arguments: ["key-gen"] + arguments)
    }
    
    /// Print DRep ID
    public func drepId(arguments: [String]) async throws -> String {
        let result = try await executeCommand("drep", arguments: ["id"] + arguments)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Create DRep registration certificate
    public func drepRegistration(arguments: [String]) async throws -> String {
        return try await executeCommand("drep", arguments: ["registration-certificate"] + arguments)
    }
    
    /// Create DRep retirement certificate
    public func drepRetirement(arguments: [String]) async throws -> String {
        return try await executeCommand("drep", arguments: ["retirement-certificate"] + arguments)
    }
    
    /// Create DRep update certificate
    public func drepUpdate(arguments: [String]) async throws -> String {
        return try await executeCommand("drep", arguments: ["update-certificate"] + arguments)
    }
    
    /// Create DRep metadata hash
    public func drepMetadataHash(arguments: [String]) async throws -> String {
        let result = try await executeCommand("drep", arguments: ["metadata-hash"] + arguments)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Create committee key hash
    public func committeeKeyHash(arguments: [String]) async throws -> String {
        let result = try await executeCommand("committee", arguments: ["key-hash"] + arguments)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Create committee key generation
    public func committeeKeyGen(arguments: [String]) async throws -> String {
        return try await executeCommand("committee", arguments: ["key-gen-cold"] + arguments)
    }
    
    /// Create committee hot key generation
    public func committeeKeyGenHot(arguments: [String]) async throws -> String {
        return try await executeCommand("committee", arguments: ["key-gen-hot"] + arguments)
    }
    
    /// Create committee authorization certificate
    public func committeeAuthorization(arguments: [String]) async throws -> String {
        return try await executeCommand("committee", arguments: ["create-hot-key-authorization-certificate"] + arguments)
    }
    
    /// Create committee resignation certificate
    public func committeeResignation(arguments: [String]) async throws -> String {
        return try await executeCommand("committee", arguments: ["create-hot-key-resignation-certificate"] + arguments)
    }
    
    /// Create vote
    public func createVote(arguments: [String]) async throws -> String {
        return try await executeCommand("vote", arguments: ["create"] + arguments)
    }
    
    /// View vote
    public func viewVote(arguments: [String]) async throws -> String {
        return try await executeCommand("vote", arguments: ["view"] + arguments)
    }
}
