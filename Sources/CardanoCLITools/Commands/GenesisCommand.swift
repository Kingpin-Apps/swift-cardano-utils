import Foundation

// MARK: - Genesis Command Implementation

/// Implementation of genesis commands
public struct GenesisCommandImpl: CommandProtocol {
    var baseCLI: any BinaryInterfaceable
    
    var baseCommand: [String] {
        [era.rawValue, "genesis"]
    }
    
    init(baseCLI: any BinaryInterfaceable) {
        self.baseCLI = baseCLI
    }
    
    /// Create a Shelley genesis key pair
    public func keyGenGenesis(arguments: [String]) async throws -> String {
        return try await executeCommand("key-gen-genesis", arguments: arguments)
    }
    
    /// Create a Shelley genesis delegate key pair
    public func keyGenDelegate(arguments: [String]) async throws -> String {
        return try await executeCommand("key-gen-delegate", arguments: arguments)
    }
    
    /// Create a Shelley genesis UTxO key pair
    public func keyGenUtxo(arguments: [String]) async throws -> String {
        return try await executeCommand("key-gen-utxo", arguments: arguments)
    }
    
    /// Print the identifier (hash) of a public key
    public func keyHash(arguments: [String]) async throws -> String {
        return try await executeCommand("key-hash", arguments: arguments)
    }
    
    /// Derive the verification key from a signing key
    public func getVerKey(arguments: [String]) async throws -> String {
        return try await executeCommand("get-ver-key", arguments: arguments)
    }
    
    /// Get the address for an initial UTxO based on the verification key
    public func initialAddr(arguments: [String]) async throws -> String {
        return try await executeCommand("initial-addr", arguments: arguments)
    }
    
    /// Get the TxIn for an initial UTxO based on the verification key
    public func initialTxin(arguments: [String]) async throws -> String {
        return try await executeCommand("initial-txin", arguments: arguments)
    }
    
    /// Create a Byron and Shelley genesis file from a genesis template and keys
    public func createCardano(arguments: [String]) async throws -> String {
        return try await executeCommand("create-cardano", arguments: arguments)
    }
    
    /// Create a Shelley genesis file from a genesis template and keys
    public func create(arguments: [String]) async throws -> String {
        return try await executeCommand("create", arguments: arguments)
    }
    
    /// Create a staked Shelley genesis file from a genesis template and keys
    public func createStaked(arguments: [String]) async throws -> String {
        return try await executeCommand("create-staked", arguments: arguments)
    }
    
    /// Create data to use for starting a testnet
    public func createTestnetData(arguments: [String]) async throws -> String {
        return try await executeCommand("create-testnet-data", arguments: arguments)
    }
    
    /// Compute the hash of a genesis file
    public func hash(arguments: [String]) async throws -> String {
        return try await executeCommand("hash", arguments: arguments)
    }
}
