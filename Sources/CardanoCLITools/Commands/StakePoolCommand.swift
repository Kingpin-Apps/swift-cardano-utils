import Foundation

// MARK: - Stake Pool Command Implementation

/// Implementation of stake pool commands
public struct StakePoolCommandImpl: CommandProtocol {
    var baseCLI: any BinaryInterfaceable
    
    var baseCommand: [String] {
        [era.rawValue, "stake-pool"]
    }
    
    init(baseCLI: any BinaryInterfaceable) {
        self.baseCLI = baseCLI
    }
    
    private var networkArgs: [String] {
        return baseCLI.configuration.cardano.network.arguments
    }
    
    /// Calculate the hash of a stake pool metadata file
    public func metadataHash(arguments: [String]) async throws -> String {
        return try await executeCommand("metadata-hash", arguments: arguments)
    }
    
    /// Create a stake pool registration certificate
    public func registrationCertificate(arguments: [String]) async throws -> String {
        return try await executeCommand("registration-certificate", arguments: arguments + networkArgs)
    }
    
    /// Create a stake pool deregistration certificate
    public func deregistrationCertificate(arguments: [String]) async throws -> String {
        return try await executeCommand("deregistration-certificate", arguments: arguments)
    }
    
    /// Build pool id from the offline key
    public func id(arguments: [String]) async throws -> String {
        return try await executeCommand("id", arguments: arguments)
    }
}
