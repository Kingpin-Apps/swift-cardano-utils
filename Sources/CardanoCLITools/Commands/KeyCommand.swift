import Foundation

// MARK: - Key Command Implementation

/// Implementation of key utility commands
public struct KeyCommandImpl: CommandProtocol {
    var baseCLI: any BinaryInterfaceable
    
    var baseCommand: [String] {
        [era.rawValue, "key"]
    }
    
    init(baseCLI: any BinaryInterfaceable) {
        self.baseCLI = baseCLI
    }
    
    /// Get verification key from signing key - supports all key types
    public func verificationKey(arguments: [String]) async throws -> String {
        return try await executeCommand("verification-key", arguments: arguments)
    }
    
    /// Get non-extended verification key from an extended verification key
    public func nonExtendedKey(arguments: [String]) async throws -> String {
        return try await executeCommand("non-extended-key", arguments: arguments)
    }
    
    /// Convert Byron payment, genesis or genesis delegate key to Shelley-format key
    public func convertByronKey(arguments: [String]) async throws -> String {
        return try await executeCommand("convert-byron-key", arguments: arguments)
    }
    
    /// Convert Base64-encoded Byron genesis verification key to Shelley genesis verification key
    public func convertByronGenesisVkey(arguments: [String]) async throws -> String {
        return try await executeCommand("convert-byron-genesis-vkey", arguments: arguments)
    }
    
    /// Convert ITN non-extended (Ed25519) signing/verification key to Shelley stake key
    public func convertItnKey(arguments: [String]) async throws -> String {
        return try await executeCommand("convert-itn-key", arguments: arguments)
    }
    
    /// Convert ITN extended (Ed25519Extended) signing key to Shelley stake signing key
    public func convertItnExtendedKey(arguments: [String]) async throws -> String {
        return try await executeCommand("convert-itn-extended-key", arguments: arguments)
    }
    
    /// Convert ITN BIP32 (Ed25519Bip32) signing key to Shelley stake signing key
    public func convertItnBip32Key(arguments: [String]) async throws -> String {
        return try await executeCommand("convert-itn-bip32-key", arguments: arguments)
    }
    
    /// Convert cardano-address extended signing key to Shelley-format key
    public func convertCardanoAddressKey(arguments: [String]) async throws -> String {
        return try await executeCommand("convert-cardano-address-key", arguments: arguments)
    }
}
