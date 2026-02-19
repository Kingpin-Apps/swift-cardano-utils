import Foundation

// MARK: - Stake Address Command Implementation

/// Implementation of stake address commands
public struct StakeAddressCommandImpl: CommandProtocol {
    var baseCLI: any BinaryInterfaceable
    
    var baseCommand: [String] {
        [era.rawValue, "stake-address"]
    }
    
    init(baseCLI: any BinaryInterfaceable) {
        self.baseCLI = baseCLI
    }
    
    /// Create a stake address key pair
    public func keyGen(arguments: [String]) async throws -> String {
        return try await executeCommand("key-gen", arguments: arguments)
    }
    
    /// Print the hash of a stake address key
    public func keyHash(arguments: [String]) async throws -> String {
        return try await executeCommand("key-hash", arguments: arguments)
    }
    
    /// Build a stake address
    public func build(arguments: [String]) async throws -> String {
        return try await executeCommand("build", arguments: arguments + networkArgs)
    }
    
    /// Create a stake address registration certificate
    public func registrationCertificate(arguments: [String]) async throws -> String {
        return try await executeCommand("registration-certificate", arguments: arguments)
    }
    
    /// Create a stake address deregistration certificate
    public func deregistrationCertificate(arguments: [String]) async throws -> String {
        return try await executeCommand("deregistration-certificate", arguments: arguments)
    }
    
    /// Create a stake address stake delegation certificate
    public func stakeDelegationCertificate(arguments: [String]) async throws -> String {
        return try await executeCommand("stake-delegation-certificate", arguments: arguments)
    }
    
    /// Create a stake address stake and vote delegation certificate
    public func stakeAndVoteDelegationCertificate(arguments: [String]) async throws -> String {
        return try await executeCommand("stake-and-vote-delegation-certificate", arguments: arguments)
    }
    
    /// Create a stake address vote delegation certificate
    public func voteDelegationCertificate(arguments: [String]) async throws -> String {
        return try await executeCommand("vote-delegation-certificate", arguments: arguments)
    }
    
    /// Create a stake address registration and delegation certificate
    public func registrationAndDelegationCertificate(arguments: [String]) async throws -> String {
        return try await executeCommand("registration-and-delegation-certificate", arguments: arguments)
    }
    
    /// Create a stake address registration and vote delegation certificate
    public func registrationAndVoteDelegationCertificate(arguments: [String]) async throws -> String {
        return try await executeCommand("registration-and-vote-delegation-certificate", arguments: arguments)
    }
    
    /// Create a stake address registration, stake delegation and vote delegation certificate
    public func registrationStakeAndVoteDelegationCertificate(arguments: [String]) async throws -> String {
        return try await executeCommand("registration-stake-and-vote-delegation-certificate", arguments: arguments)
    }
}
