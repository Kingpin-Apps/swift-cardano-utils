# CardanoCLI

The primary interface for interacting with the Cardano blockchain through the official cardano-cli tool.

## Overview

``CardanoCLI`` provides a type-safe, async/await-based Swift interface to the official Cardano CLI tool. It supports all major operations including address management, key generation, transaction building and submission, chain queries, and governance operations.

### Key Capabilities

- **Chain Queries** - Get current tip, epoch, era, sync progress
- **Address Operations** - Generate addresses, query balances and UTxOs
- **Transaction Management** - Build, sign, and submit transactions
- **Key Management** - Generate and convert cryptographic keys
- **Governance** - DRep registration, voting, committee operations
- **Stake Pool Operations** - Query pools, create certificates
- **Protocol Parameters** - Fetch current network parameters

### Requirements

- macOS 14.0+
- Swift 6.0+
- cardano-cli 8.0.0+ (installed and in PATH)
- A running Cardano node (for most operations)

## Configuration

The CardanoCLI requires a ``Config`` object that specifies paths to binaries and network settings:

### Basic Configuration

```swift
import SwiftCardanoUtils
import SwiftCardanoCore
import System

let cardanoConfig = CardanoConfig(
    cli: FilePath("/usr/local/bin/cardano-cli"),
    node: FilePath("/usr/local/bin/cardano-node"),
    hwCli: nil, // Optional hardware wallet CLI
    signer: nil, // Optional cardano-signer
    socket: FilePath("/tmp/cardano-node.socket"),
    config: FilePath("/path/to/config.json"),
    topology: FilePath("/path/to/topology.json"),
    database: FilePath("/path/to/database"),
    port: 3001,
    hostAddr: "127.0.0.1",
    network: .preview, // .mainnet, .preprod, .preview, etc.
    era: .conway,
    ttlBuffer: 3600,
    workingDir: FilePath("/tmp"),
    showOutput: false
)

let configuration = Configuration(
    cardano: cardanoConfig,
    ogmios: nil,
    kupo: nil
)

let cli = try await CardanoCLI(configuration: configuration)
```

### Configuration from Environment Variables

You can also create configuration from environment variables:

```swift
// Set environment variables
Environment.set(.network, value: "preview")
Environment.set(.cardanoSocketPath, value: "/tmp/node.socket")
Environment.set(.cardanoConfig, value: "/path/to/config.json")

// Create default configuration
let configuration = try Configuration(
    cardano: .default(),
    ogmios: nil,
    kupo: nil
)
```

### JSON Configuration

Load configuration from a JSON file:

```json
{
  "cardano": {
    "cli": "/usr/local/bin/cardano-cli",
    "node": "/usr/local/bin/cardano-node",
    "socket": "/tmp/cardano-node.socket",
    "config": "/path/to/config.json",
    "network": "preview",
    "era": "conway",
    "ttl_buffer": 3600,
    "working_dir": "/tmp",
    "show_output": false
  }
}
```

```swift
let configData = try Data(contentsOf: URL(fileURLWithPath: "config.json"))
let configuration = try JSONDecoder().decode(Configuration.self, from: configData)
let cli = try await CardanoCLI(configuration: configuration)
```

## Basic Usage

### Node Status and Chain Information

```swift
// Get cardano-cli version
let version = try await cli.version()
print("Cardano CLI version: \(version)")

// Check node sync progress
let syncProgress = try await cli.getSyncProgress()
print("Sync progress: \(syncProgress)%")

// Ensure node is fully synced before operations
try await cli.checkOnline()

// Get current era
if let era = try await cli.getEra() {
    print("Current era: \(era)")
}

// Get current epoch
let epoch = try await cli.getEpoch()
print("Current epoch: \(epoch)")

// Get current tip (latest slot)
let tip = try await cli.getTip()
print("Current tip: \(tip)")

// Get chain tip details
let chainTip = try await cli.query.tip()
print("Block: \(chainTip.block)")
print("Epoch: \(chainTip.epoch)")
print("Hash: \(chainTip.hash)")
print("Slot: \(chainTip.slot)")
```

### Address Operations

```swift
// Build an address from keys
let address = try await cli.address.build(arguments: [
    "--payment-verification-key-file", "payment.vkey",
    "--stake-verification-key-file", "stake.vkey"
])
print("Generated address: \(address)")

// Get address information
let addressInfo = try await cli.query.addressInfo(
    address: "addr_test1...",
    arguments: []
)

// Query UTxOs at an address
let utxos = try await cli.query.utxo(arguments: [
    "--address", "addr_test1...",
    "--out-file", "/dev/stdout"
])
```

### Key Management

```swift
// Generate payment key pair
try await cli.key.generate(arguments: [
    "--verification-key-file", "payment.vkey",
    "--signing-key-file", "payment.skey"
])

// Generate stake key pair  
try await cli.key.generate(arguments: [
    "--verification-key-file", "stake.vkey",
    "--signing-key-file", "stake.skey"
])

// Convert Byron keys to Shelley format
try await cli.key.convertByronKey(arguments: [
    "--byron-payment-key-type",
    "--byron-signing-key-file", "byron.skey",
    "--out-file", "shelley.skey"
])
```

### Transaction Operations

```swift
// Build a transaction
let fee = try await cli.transaction.build(arguments: [
    "--tx-in", "txhash#0",
    "--tx-out", "addr_test1...+1000000",
    "--change-address", "addr_test1...",
    "--out-file", "tx.raw"
])
print("Estimated fee: \(fee) lovelace")

// Sign a transaction with signing keys
let signedTxFile = try await cli.signTransaction(
    txFile: FilePath("tx.raw"),
    signingKeys: [FilePath("payment.skey")]
)

// Submit transaction to the blockchain
let txId = try await cli.submitTransaction(
    signedTxFile: signedTxFile,
    cleanup: true
)
print("Transaction submitted: \(txId)")

// Calculate minimum fee
let minFee = try await cli.transaction.calculateMinFee(arguments: [
    "--tx-body-file", "tx.raw",
    "--tx-in-count", "1",
    "--tx-out-count", "2",
    "--witness-count", "1"
])
print("Minimum fee: \(minFee) lovelace")
```

### Protocol Parameters

```swift
// Get current protocol parameters
let protocolParams = try await cli.getProtocolParameters()
print("Min fee per byte: \(protocolParams.txFeePerByte)")
print("Min fee fixed: \(protocolParams.txFeeFixed)")
print("Max tx size: \(protocolParams.maxTxSize)")

// Save protocol parameters to file
let paramsFile = FilePath("/tmp/protocol.json")
let _ = try await cli.getProtocolParameters(paramsFile: paramsFile)
```

### Advanced Queries

```swift
// Query stake address information
let stakeAddr = try Address.fromBech32("stake_test1...")
let stakeInfo = try await cli.stakeAddressInfo(address: stakeAddr)
print("Stake info: \(stakeInfo)")

// Get UTxOs for an address (using high-level API)
let address = try Address.fromBech32("addr_test1...")
let utxos = try await cli.utxos(address: address)
for utxo in utxos {
    print("UTxO: \(utxo.input.transactionId)#\(utxo.input.index)")
    print("Value: \(utxo.output.amount.coin) lovelace")
}
```

## Error Handling

CardanoCLI provides comprehensive error handling with specific error types:

```swift
do {
    let tip = try await cli.getTip()
    print("Current tip: \(tip)")
} catch SwiftCardanoUtilsError.nodeNotSynced(let progress) {
    print("Node not fully synced: \(progress)%")
    // Wait and retry logic
} catch SwiftCardanoUtilsError.commandFailed(let command, let message) {
    print("Command failed: \(command.joined(separator: " "))")
    print("Error: \(message)")
} catch SwiftCardanoUtilsError.binaryNotFound(let path) {
    print("CLI binary not found at: \(path)")
    // Installation guidance
} catch SwiftCardanoUtilsError.unsupportedVersion(let current, let required) {
    print("Version \(current) found, \(required) required")
    // Version upgrade guidance
} catch {
    print("Unexpected error: \(error)")
}
```

### Common Error Scenarios

1. **Node Not Synced** - Most operations require a fully synced node
2. **Binary Not Found** - Ensure cardano-cli is installed and in PATH
3. **Invalid Configuration** - Check socket path, config files exist
4. **Network Errors** - Node may be offline or unreachable
5. **Version Incompatibility** - Update cardano-cli to supported version

## Best Practices

### Performance Optimization

```swift
// Cache configuration for reuse
static let sharedConfiguration: Configuration = {
    try! Configuration(cardano: .default(), ogmios: nil, kupo: nil)
}()

// Reuse CLI instances
static let cli = try await CardanoCLI(configuration: sharedConfiguration)

// Use concurrent operations for independent queries
async let tip = cli.getTip()
async let epoch = cli.getEpoch()
async let syncProgress = cli.getSyncProgress()

let (currentTip, currentEpoch, progress) = try await (tip, epoch, syncProgress)
```

### Security Considerations

1. **Private Key Management** - Never log or expose signing keys
2. **Network Configuration** - Use appropriate network for environment
3. **Transaction Validation** - Always validate transaction outputs before signing
4. **Socket Security** - Ensure node socket has proper permissions

### Retry Logic for Node Synchronization

```swift
func executeWithRetry<T>(
    operation: () async throws -> T,
    maxRetries: Int = 3,
    baseDelay: TimeInterval = 1.0
) async throws -> T {
    var lastError: Error?
    
    for attempt in 0..<maxRetries {
        do {
            return try await operation()
        } catch SwiftCardanoUtilsError.nodeNotSynced {
            let delay = baseDelay * pow(2.0, Double(attempt))
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            lastError = error
        } catch {
            throw error // Don't retry for other errors
        }
    }
    
    throw lastError!
}

// Usage
let tip = try await executeWithRetry {
    try await cli.getTip()
}
```

## Command Groups

CardanoCLI organizes functionality into logical command groups:

### Address Commands (``AddressCommandImpl``)

- `build()` - Create payment addresses
- `info()` - Get address information
- `keyGen()` - Generate address key pairs
- `keyHash()` - Calculate key hashes

### Key Commands (``KeyCommandImpl``)

- `verificationKey()` - Extract public keys
- `convertByronKey()` - Convert legacy keys
- `convertItnKey()` - Convert ITN keys

### Transaction Commands (``TransactionCommandImpl``)

- `build()` - Build balanced transactions
- `sign()` - Sign transactions
- `submit()` - Submit to blockchain
- `calculateMinFee()` - Estimate fees

### Query Commands (``QueryCommandImpl``)

- `tip()` - Get chain tip
- `utxo()` - Query UTxOs
- `protocolParameters()` - Get protocol params
- `stakeAddressInfo()` - Query stake info

### Governance Commands (``GovernanceCommandImpl``)

- `drepKeyGen()` - Generate DRep keys
- `drepRegistration()` - Create DRep certificates
- `createVote()` - Create governance votes

## Integration Examples

### Building a Simple Wallet

```swift
class SimpleWallet {
    let cli: CardanoCLI
    
    init() async throws {
        let config = try Configuration(cardano: .default(), ogmios: nil, kupo: nil)
        self.cli = try await CardanoCLI(configuration: config)
    }
    
    func getBalance(address: String) async throws -> UInt64 {
        let addr = try Address.fromBech32(address)
        let utxos = try await cli.utxos(address: addr)
        return utxos.reduce(0) { $0 + UInt64($1.output.amount.coin) }
    }
    
    func sendAda(
        from: String,
        to: String, 
        amount: UInt64,
        signingKey: FilePath
    ) async throws -> String {
        // Build transaction
        let fee = try await cli.transaction.build(arguments: [
            "--tx-in", from,
            "--tx-out", "\(to)+\(amount)",
            "--change-address", to,
            "--out-file", "tx.raw"
        ])
        
        // Sign transaction
        let signedTx = try await cli.signTransaction(
            txFile: FilePath("tx.raw"),
            signingKeys: [signingKey]
        )
        
        // Submit transaction
        return try await cli.submitTransaction(signedTxFile: signedTx)
    }
}
```

This guide covers the essential aspects of using CardanoCLI for Cardano blockchain interactions. For hardware wallet integration, see <doc:CardanoHWCLI>. For advanced signing operations, see <doc:CardanoSigner>.
