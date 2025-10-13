# CardanoHWCLI

Hardware wallet integration for Cardano transactions using Ledger and Trezor devices.

## Overview

``CardanoHWCLI`` provides secure hardware wallet integration for Cardano transactions. It supports both Ledger and Trezor devices, enabling secure key storage and transaction signing without exposing private keys to the host system.

### Key Features

- **Multi-Device Support** - Ledger Nano S/X/S Plus and Trezor Model T/One
- **Secure Signing** - Private keys never leave the hardware device
- **Device Detection** - Automatic device type recognition and compatibility checking
- **Transaction Verification** - On-device transaction confirmation
- **Derivation Paths** - Standard and custom key derivation paths
- **Address Generation** - Hardware-verified address generation

### Supported Hardware

| Device | Minimum Firmware | Supported |
|--------|------------------|-----------|
| Ledger Nano S | Cardano App 4.0.0+ | ✅ |
| Ledger Nano X | Cardano App 4.0.0+ | ✅ |
| Ledger Nano S Plus | Cardano App 4.0.0+ | ✅ |
| Trezor Model T | Firmware 2.4.3+ | ✅ |

### Requirements

- macOS 14.0+
- Swift 6.0+
- cardano-hw-cli 1.10.0+ (installed separately)
- Compatible hardware wallet with Cardano app installed

## Installation

### Installing cardano-hw-cli

Download the latest cardano-hw-cli from the [official releases](https://github.com/vacuumlabs/cardano-hw-cli/releases):

```bash
# Download and install cardano-hw-cli
curl -L https://github.com/vacuumlabs/cardano-hw-cli/releases/latest/download/cardano-hw-cli-macos -o cardano-hw-cli
chmod +x cardano-hw-cli
sudo mv cardano-hw-cli /usr/local/bin/
```

### Device Setup

#### Ledger Setup
1. Install the Cardano app on your Ledger device using Ledger Live
2. Ensure the Cardano app version is 4.0.0 or higher
3. Enable "Expert mode" in the Cardano app settings for advanced features

#### Trezor Setup
1. Update your Trezor firmware to version 2.4.3 or higher
2. Cardano support is built into the firmware (no additional app needed)

## Configuration

CardanoHWCLI requires the hardware wallet CLI path to be configured:

```swift
import SwiftCardanoUtils
import System

let cardanoConfig = CardanoConfig(
    cli: FilePath("/usr/local/bin/cardano-cli"),
    node: FilePath("/usr/local/bin/cardano-node"),
    hwCli: FilePath("/usr/local/bin/cardano-hw-cli"), // Required
    signer: nil,
    socket: FilePath("/tmp/cardano-node.socket"),
    config: FilePath("/path/to/config.json"),
    topology: nil,
    database: nil,
    port: nil,
    hostAddr: nil,
    network: .preview,
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

let hwCli = try await CardanoHWCLI(configuration: configuration)
```

## API Overview

CardanoHWCLI provides structured access to hardware wallet functionality through specialized command namespaces:

### Command Namespaces

- **`address`** - Address generation, key derivation, and verification
- **`transaction`** - Transaction signing, witnessing, validation, and transformation
- **`node`** - Stake pool operations (cold keys, operational certificates)
- **`vote`** - Catalyst voting registration metadata generation
- **`device`** - Device detection, version checking, and communication
- **`key`** - Key management operations

### Quick Reference

```swift
let hwCli = try await CardanoHWCLI(configuration: configuration)

// Address operations
hwCli.address.keyGen(...)     // Generate hardware signing files
hwCli.address.show(...)       // Display/verify addresses

// Transaction operations  
hwCli.transaction.witness(...)    // Sign transactions
hwCli.transaction.validate(...)   // Validate transaction files
hwCli.transaction.transform(...)  // Transform for hardware compatibility
hwCli.transaction.policyId(...)   // Generate policy IDs

// Node operations (for stake pool operators)
hwCli.node.keyGen(...)           // Generate cold keys
hwCli.node.issueOpCert(...)      // Issue operational certificates

// Voting operations
hwCli.vote.registrationMetadata(...) // Generate Catalyst voting metadata

// Device operations
hwCli.device.version()           // Check device version
hwCli.startHardwareWallet()      // Initialize device connection
```

## Basic Usage

### Device Initialization

```swift
// Initialize hardware wallet CLI
let hwCli = try await CardanoHWCLI(configuration: configuration)

// Check device version
let deviceVersion = try await hwCli.device.version()
print("Device version: \(deviceVersion)")

// Start hardware wallet interaction
let deviceType = try await hwCli.startHardwareWallet()
print("Connected device: \(deviceType.displayName)")
```

### Address Generation

```swift
// Generate a payment address with hardware wallet verification
let address = try await hwCli.address.show(
    paymentPath: "1852'/1815'/0'/0/0",
    stakingPath: "1852'/1815'/0'/2/0",
    addressFile: FilePath("/tmp/address.addr")
)
print("Hardware wallet address: \(address)")

// Generate address using script hashes
let scriptAddress = try await hwCli.address.show(
    paymentScriptHash: "abcd1234",
    stakingScriptHash: "efgh5678",
    addressFile: FilePath("/tmp/script-address.addr"),
    derivationType: .ledger
)
```

### Standard Derivation Paths

CardanoHWCLI supports standard BIP44 derivation paths for Cardano:

```swift
// Account 0, External chain, Address index 0
let paymentPath = "1852'/1815'/0'/0/0"

// Account 0, Staking keys, Address index 0  
let stakePath = "1852'/1815'/0'/2/0"

// Account 1, External chain, Address index 5
let customPath = "1852'/1815'/1'/0/5"
```

## Address Commands

CardanoHWCLI provides two main address commands that wrap the underlying `cardano-hw-cli address` functionality:

### Key Generation (`address key-gen`)

Generate hardware wallet signing files and verification keys from derivation paths:

```swift
// Generate keys for a single derivation path
try await hwCli.address.keyGen(
    paths: ["1852'/1815'/0'/0/0"],
    hwFiles: [FilePath("/tmp/payment.hwsfile")],
    vkeyFiles: [FilePath("/tmp/payment.vkey")],
    derivationType: .icarus
)

// Generate keys for multiple derivation paths
try await hwCli.address.keyGen(
    paths: [
        "1852'/1815'/0'/0/0", // Payment key
        "1852'/1815'/0'/2/0"  // Staking key
    ],
    hwFiles: [
        FilePath("/tmp/payment.hwsfile"),
        FilePath("/tmp/stake.hwsfile")
    ],
    vkeyFiles: [
        FilePath("/tmp/payment.vkey"),
        FilePath("/tmp/stake.vkey")
    ]
)
```

**Parameters:**
- `paths`: Array of BIP44 derivation paths
- `hwFiles`: Array of output file paths for hardware signing files (.hwsfile)
- `vkeyFiles`: Array of output file paths for verification key files (.vkey)
- `derivationType`: Optional derivation type (`.ledger`, `.icarus`, `.icarusTrezor`)

**Note:** All arrays must have the same count, and at least one path must be provided.

### Address Display (`address show`)

Display addresses from hardware wallet using derivation paths or script hashes:

```swift
// Show address using derivation paths
let address = try await hwCli.address.show(
    paymentPath: "1852'/1815'/0'/0/0",
    stakingPath: "1852'/1815'/0'/2/0",
    addressFile: FilePath("/tmp/address.addr")
)
print("Generated address: \(address)")

// Show address using script hashes
let scriptAddress = try await hwCli.address.show(
    paymentScriptHash: "a1b2c3d4e5f6",
    stakingScriptHash: "f6e5d4c3b2a1",
    addressFile: FilePath("/tmp/script-address.addr"),
    derivationType: .ledger
)

// Mix derivation path and script hash
let mixedAddress = try await hwCli.address.show(
    paymentPath: "1852'/1815'/0'/0/0",
    stakingScriptHash: "f6e5d4c3b2a1",
    addressFile: FilePath("/tmp/mixed-address.addr")
)
```

**Parameters:**
- `paymentPath`: Payment derivation path (mutually exclusive with `paymentScriptHash`)
- `paymentScriptHash`: Payment script hash in hex format (mutually exclusive with `paymentPath`)
- `stakingPath`: Staking derivation path (mutually exclusive with `stakingScriptHash`)
- `stakingScriptHash`: Staking script hash in hex format (mutually exclusive with `stakingPath`)
- `addressFile`: Output file path for the generated address
- `derivationType`: Optional derivation type

**Validation Rules:**
- Exactly one of `paymentPath` OR `paymentScriptHash` must be provided
- Exactly one of `stakingPath` OR `stakingScriptHash` must be provided
- The `addressFile` parameter is required

### Derivation Types

CardanoHWCLI supports three derivation types:

```swift
public enum DerivationType: String {
    case ledger = "LEDGER"           // Ledger-specific derivation
    case icarus = "ICARUS"           // Icarus wallet derivation
    case icarusTrezor = "ICARUS_TREZOR" // Icarus derivation for Trezor (default)
}
```

**Usage Examples:**

```swift
// Explicit derivation type for Ledger devices
try await hwCli.address.keyGen(
    paths: ["1852'/1815'/0'/0/0"],
    hwFiles: [FilePath("/tmp/payment.hwsfile")],
    vkeyFiles: [FilePath("/tmp/payment.vkey")],
    derivationType: .ledger
)

// Default derivation (ICARUS_TREZOR) - compatible with most devices
try await hwCli.address.keyGen(
    paths: ["1852'/1815'/0'/0/0"],
    hwFiles: [FilePath("/tmp/payment.hwsfile")],
    vkeyFiles: [FilePath("/tmp/payment.vkey")]
    // derivationType: nil uses default
)
```

### Error Handling

Address commands can throw `SwiftCardanoUtilsError` for various validation failures:

```swift
do {
    try await hwCli.address.keyGen(
        paths: ["1852'/1815'/0'/0/0", "1852'/1815'/0'/0/1"],
        hwFiles: [FilePath("/tmp/payment.hwsfile")], // Mismatch: 2 paths, 1 file
        vkeyFiles: [FilePath("/tmp/payment.vkey")],
        derivationType: .icarus
    )
} catch SwiftCardanoUtilsError.invalidParameters(let message) {
    print("Parameter validation failed: \(message)")
} catch SwiftCardanoUtilsError.deviceError(let message) {
    print("Hardware wallet error: \(message)")
} catch {
    print("Unexpected error: \(error)")
}
```

### Complete Address Workflow

Here's a complete example showing key generation and address display:

```swift
// 1. Start hardware wallet
let deviceType = try await hwCli.startHardwareWallet()
print("Using \(deviceType.displayName) device")

// 2. Generate hardware signing files
try await hwCli.address.keyGen(
    path: "1852'/1815'/0'/0/0", // Payment key
    hwFile: FilePath("/tmp/payment.hwsfile"),
    vkeyFile: FilePath("/tmp/payment.vkey"),
    derivationType: deviceType == .ledger ? .ledger : .icarusTrezor
)

// 3. Generate address
let address = try await hwCli.address.show(
    paymentPath: "1852'/1815'/0'/0/0",
    stakingPath: "1852'/1815'/0'/2/0",
    addressFile: FilePath("/tmp/wallet.addr")
)

print("Generated wallet address: \(address)")
```

## Transaction Commands

CardanoHWCLI provides comprehensive transaction commands that wrap the underlying `cardano-hw-cli transaction` functionality:

### Policy ID Generation (`transaction policyid`)

Generate a policy ID from a native script file:

```swift
// Generate policy ID from native script
let policyId = try await hwCli.transaction.policyId(
    scriptFile: FilePath("/tmp/native-script.json")
)
print("Policy ID: \(policyId)")
```

### Transaction Witnessing (`transaction witness`)

Create a witness for a transaction using hardware wallet:

```swift
// Basic transaction witnessing
let witnessOutput = try await hwCli.transaction.witness(
    txFile: FilePath("/tmp/tx.raw"),
    hwSigningFile: FilePath("/tmp/payment.hwsfile"),
    outFile: FilePath("/tmp/tx.witness")
)

// Transaction witnessing with network specification
let witnessWithNetwork = try await hwCli.transaction.witness(
    txFile: FilePath("/tmp/tx.raw"),
    hwSigningFile: FilePath("/tmp/payment.hwsfile"),
    outFile: FilePath("/tmp/tx.witness"),
    derivationType: .ledger,
    network: .mainnet
)
```

### Transaction Validation (`transaction validate`)

Validate a transaction file:

```swift
// Validate transaction integrity
try await hwCli.transaction.validate(
    txFile: FilePath("/tmp/tx.signed")
)
print("Transaction validation passed")
```

### Transaction Transformation (`transaction transform`)

Transform transaction to canonical order for hardware wallets:

```swift
// Transform transaction file
try await hwCli.transaction.transform(
    txFile: FilePath("/tmp/tx.raw"),
    outFile: FilePath("/tmp/tx.corrected")
)

// In-place transformation (overwrites original file)
try await hwCli.transaction.transformInPlace(
    txFile: FilePath("/tmp/tx.raw")
)
```

## Node Commands

CardanoHWCLI provides node-related commands for stake pool operators:

### Cold Key Generation (`node key-gen`)

Generate cold keys for stake pool operations:

```swift
// Generate stake pool cold keys
try await hwCli.node.keyGen(
    path: "1853'/1815'/0'/0'", // Pool operator path
    hwSigningFile: FilePath("/pool/keys/cold.hwsfile"),
    coldVerificationKeyFile: FilePath("/pool/keys/cold.vkey"),
    operationalCertificateIssueCounterFile: FilePath("/pool/keys/cold.counter")
)
```

### Operational Certificate Issuance (`node issue-op-cert`)

Issue operational certificates for stake pools:

```swift
// Issue operational certificate
try await hwCli.node.issueOpCert(
    kesVerificationKeyFile: FilePath("/pool/keys/kes.vkey"),
    kesPeriod: 120,
    operationalCertificateIssueCounterFile: FilePath("/pool/keys/cold.counter"),
    hwSigningFile: FilePath("/pool/keys/cold.hwsfile"),
    outFile: FilePath("/pool/certs/node.opcert")
)

// Issue with deprecated parameter format (for compatibility)
try await hwCli.node.issueOpCertDeprecated(
    kesVerificationKeyFile: FilePath("/pool/keys/kes.vkey"),
    kesPeriod: 120,
    operationalCertificateIssueCounterFile: FilePath("/pool/keys/cold.counter"),
    hwSigningFile: FilePath("/pool/keys/cold.hwsfile"),
    outFile: FilePath("/pool/certs/node.opcert")
)
```

### Complete Stake Pool Setup

Generate keys for a complete stake pool setup:

```swift
// Complete stake pool key generation workflow
let poolKeys = try await hwCli.node.generateStakePoolKeys(
    poolPath: "1853'/1815'/0'/0'",
    hwSigningFile: FilePath("/pool/keys/cold.hwsfile"),
    coldVerificationKeyFile: FilePath("/pool/keys/cold.vkey"),
    operationalCertificateIssueCounterFile: FilePath("/pool/keys/cold.counter"),
    kesVerificationKeyFile: FilePath("/pool/keys/kes.vkey"),
    kesPeriod: 120,
    operationalCertificateFile: FilePath("/pool/certs/node.opcert")
)
```

## Vote Commands

CardanoHWCLI supports Catalyst voting registration through hardware wallets:

### Voting Registration Metadata (`vote registration-metadata`)

Generate voting registration metadata for Catalyst:

```swift
// Single vote public key registration
let voteKeys = [VotePublicKeyInput.string("vote1abcd1234...")]
let voteWeights = [UInt64(1)]

try await hwCli.vote.registrationMetadata(
    votePublicKeys: voteKeys,
    voteWeights: voteWeights,
    stakeSigningKeyHwsFile: FilePath("/tmp/stake.hwsfile"),
    paymentAddress: "addr1q9x...",
    nonce: 12345678,
    metadataCborOutFile: FilePath("/tmp/vote-registration.cbor"),
    network: .mainnet
)

// Multiple vote public keys with different input formats
let multipleVoteKeys = [
    VotePublicKeyInput.hwsFile(FilePath("/tmp/vote1.hwsfile")),
    VotePublicKeyInput.file(FilePath("/tmp/vote2.vkey")),
    VotePublicKeyInput.string("vote1xyz789...")
]
let multipleWeights = [UInt64(1), UInt64(2), UInt64(1)]

try await hwCli.vote.registrationMetadata(
    votePublicKeys: multipleVoteKeys,
    voteWeights: multipleWeights,
    stakeSigningKeyHwsFile: FilePath("/tmp/stake.hwsfile"),
    paymentAddress: "addr1q9x...",
    nonce: 12345678,
    metadataCborOutFile: FilePath("/tmp/multi-vote-registration.cbor"),
    network: .testnet,
    votingPurpose: "catalyst",
    paymentAddressSigningKeyHwsFile: FilePath("/tmp/payment.hwsfile"),
    derivationType: .ledger
)
```

### Vote Public Key Input Types

CardanoHWCLI supports multiple vote public key input formats:

```swift
public enum VotePublicKeyInput {
    /// Vote public key from jcli format file (ed25519extended format)
    case jcli(FilePath)
    /// Bech32-encoded vote public key string
    case string(String)
    /// Vote public key from hardware wallet signing file format
    case hwsFile(FilePath)
    /// Vote public key from cardano-cli file format
    case file(FilePath)
}
```

**Usage Examples:**

```swift
// Different input format examples
let jcliKey = VotePublicKeyInput.jcli(FilePath("/tmp/vote.jcli"))
let stringKey = VotePublicKeyInput.string("vote1abcd1234...")
let hwsKey = VotePublicKeyInput.hwsFile(FilePath("/tmp/vote.hwsfile"))
let fileKey = VotePublicKeyInput.file(FilePath("/tmp/vote.vkey"))

// Mixed formats in single registration
let mixedKeys = [jcliKey, stringKey, hwsKey, fileKey]
let weights = [UInt64(1), UInt64(1), UInt64(2), UInt64(1)]

try await hwCli.vote.registrationMetadata(
    votePublicKeys: mixedKeys,
    voteWeights: weights,
    stakeSigningKeyHwsFile: FilePath("/tmp/stake.hwsfile"),
    paymentAddress: "addr1q9x...",
    nonce: 12345678,
    metadataCborOutFile: FilePath("/tmp/mixed-vote-registration.cbor")
)
```

## Transaction Signing

### Basic Transaction Signing Flow

```swift
// 1. Build transaction using CardanoCLI
let cli = try await CardanoCLI(configuration: configuration)

let fee = try await cli.transaction.build(arguments: [
    "--tx-in", "txhash#0",
    "--tx-out", "addr_test1...+1000000",
    "--change-address", "addr_test1...",
    "--out-file", "tx.raw"
])

// 2. Autocorrect transaction body for hardware wallet compatibility
try await hwCli.autocorrectTxBodyFile(txBodyFile: "tx.raw")

// 3. Create hardware wallet signing file
// This step depends on your address derivation
let hwSigningFile = FilePath("payment.hwsfile")
// Note: Hardware signing files contain derivation paths, not private keys

// 4. Generate witness with hardware wallet
let witness = try await hwCli.transaction.witness(
    txFile: FilePath("tx.raw"),
    hwSigningFile: hwSigningFile,
    outFile: FilePath("tx.witness")
)

// 5. Assemble transaction with witness
let signedTx = try await cli.transaction.assemble(arguments: [
    "--tx-body-file", "tx.raw",
    "--witness-file", "tx.witness",
    "--out-file", "tx.signed"
])

// 6. Submit transaction
let txId = try await cli.submitTransaction(signedTxFile: FilePath("tx.signed"))
print("Transaction submitted: \(txId)")
```

### Multi-Signature Transactions

For transactions requiring multiple hardware wallet signatures:

```swift
// Generate multiple witnesses
let witness1 = try await hwCli.transaction.witness(
    txFile: FilePath("tx.raw"),
    hwSigningFile: FilePath("payment1.hwsfile"),
    outFile: FilePath("tx.witness1")
)

let witness2 = try await hwCli.transaction.witness(
    txFile: FilePath("tx.raw"),
    hwSigningFile: FilePath("payment2.hwsfile"),
    outFile: FilePath("tx.witness2")
)

// Assemble with multiple witnesses
let signedTx = try await cli.transaction.assemble(arguments: [
    "--tx-body-file", "tx.raw",
    "--witness-file", "tx.witness1",
    "--witness-file", "tx.witness2",
    "--out-file", "tx.signed"
])
```

## Device-Specific Operations

### Device Type Detection and Validation

```swift
// Start hardware wallet with specific device type requirement
let deviceType = try await hwCli.startHardwareWallet(onlyForType: .ledger)

switch deviceType {
case .ledger:
    print("Ledger device connected")
    // Ledger-specific operations
case .trezor:
    print("Trezor device connected")
    // Trezor-specific operations
}
```

### Device Version Validation

CardanoHWCLI automatically validates device firmware versions:

```swift
do {
    let deviceType = try await hwCli.startHardwareWallet()
    // Device validation passed
} catch SwiftCardanoUtilsError.deviceError(let message) {
    if message.contains("version") {
        print("Device firmware needs updating")
        print("Minimum required versions:")
        print("- Ledger Cardano App: \(CardanoHWCLI.minLedgerCardanoApp)")
        print("- Trezor Firmware: \(CardanoHWCLI.minTrezorCardanoApp)")
    }
}
```

## Advanced Features

### Transaction Validation

Validate a transaction before submission:

```swift
// Validate transaction integrity
let validation = try await hwCli.transaction.validate(txFile: "tx.signed")
print("Transaction validation: \(validation)")
```

### Address Verification

Verify an address was generated correctly:

```swift
// Display and verify address on device
let verifiedAddress = try await hwCli.address.show(arguments: [
    "--payment-path", "1852'/1815'/0'/0/0",
    "--address-format", "bech32"
])

// The address will be shown on the hardware device for user confirmation
print("Verified address: \(verifiedAddress)")
```

## Error Handling

Hardware wallet operations can fail for various reasons:

```swift
do {
    let deviceType = try await hwCli.startHardwareWallet()
    let address = try await hwCli.address.show(arguments: ["--payment-path", "1852'/1815'/0'/0/0"])
} catch SwiftCardanoUtilsError.deviceError(let message) {
    if message.contains("not found") {
        print("Hardware wallet not connected or unlocked")
        print("Please connect and unlock your hardware wallet")
    } else if message.contains("app") {
        print("Cardano app not open on device")
        print("Please open the Cardano app on your hardware wallet")
    } else if message.contains("version") {
        print("Firmware or app version too old")
    } else {
        print("Device error: \(message)")
    }
} catch SwiftCardanoUtilsError.binaryNotFound(let path) {
    print("cardano-hw-cli not found at: \(path)")
    print("Please install cardano-hw-cli")
} catch {
    print("Unexpected error: \(error)")
}
```

### Common Error Scenarios

1. **Device Not Connected** - Hardware wallet is unplugged
2. **Device Locked** - User hasn't entered PIN
3. **App Not Open** - Cardano app not running on Ledger
4. **User Cancellation** - User rejected transaction on device
5. **Firmware Too Old** - Device firmware needs updating
6. **Connection Issues** - USB/transport layer problems

## Security Best Practices

### Device Security

1. **Verify Addresses** - Always verify addresses on device screen
2. **Check Transaction Details** - Review amounts and recipients on device
3. **Secure Derivation Paths** - Use standard paths unless specifically needed
4. **Firmware Updates** - Keep device firmware up to date
5. **Physical Security** - Keep devices secure when not in use

### Application Security

```swift
// Example of secure hardware wallet integration
class SecureHWWallet {
    private let hwCli: CardanoHWCLI
    private let cli: CardanoCLI
    
    init(configuration: Configuration) async throws {
        self.cli = try await CardanoCLI(configuration: configuration)
        self.hwCli = try await CardanoHWCLI(configuration: configuration)
    }
    
    func secureTransfer(
        amount: UInt64,
        toAddress: String,
        fromPath: String = "1852'/1815'/0'/0/0"
    ) async throws -> String {
        // 1. Verify device is connected and compatible
        let deviceType = try await hwCli.startHardwareWallet()
        print("Using \(deviceType.displayName) for transaction")
        
        // 2. Generate and verify source address
        let sourceAddress = try await hwCli.address.show(arguments: [
            "--payment-path", fromPath
        ])
        print("Sending from verified address: \(sourceAddress)")
        
        // 3. Build transaction
        let fee = try await cli.transaction.build(arguments: [
            "--tx-in", "auto", // Simplified - would need actual UTxO
            "--tx-out", "\(toAddress)+\(amount)",
            "--change-address", sourceAddress,
            "--out-file", "secure-tx.raw"
        ])
        
        // 4. Autocorrect for hardware wallet
        try await hwCli.transaction.transformInPlace(txFile: FilePath("secure-tx.raw"))
        
        // 5. Sign with hardware wallet (user must approve on device)
        let witness = try await hwCli.transaction.witness(
            txFile: FilePath("secure-tx.raw"),
            hwSigningFile: FilePath("payment.hwsfile"),
            outFile: FilePath("secure-tx.witness")
        )
        
        // 6. Assemble and submit
        let signedTx = try await cli.transaction.assemble(arguments: [
            "--tx-body-file", "secure-tx.raw",
            "--witness-file", "secure-tx.witness",
            "--out-file", "secure-tx.signed"
        ])
        
        let txId = try await cli.submitTransaction(signedTxFile: FilePath("secure-tx.signed"))
        
        // 7. Cleanup sensitive files
        try? FileManager.default.removeItem(atPath: "secure-tx.raw")
        try? FileManager.default.removeItem(atPath: "secure-tx.witness")
        try? FileManager.default.removeItem(atPath: "secure-tx.signed")
        
        return txId
    }
}
```

### Key Management

- **Never Store Private Keys** - Hardware wallets keep keys secure on-device
- **Derivation Paths Only** - Applications only store derivation paths
- **Address Verification** - Always verify addresses match expected derivation
- **Backup Hardware Seeds** - Ensure proper seed phrase backup

## Integration with CardanoCLI

CardanoHWCLI works seamlessly with <doc:CardanoCLI> for complete transaction workflows:

```swift
class HardwareWalletService {
    let cli: CardanoCLI
    let hwCli: CardanoHWCLI
    
    init(configuration: Configuration) async throws {
        self.cli = try await CardanoCLI(configuration: configuration)
        self.hwCli = try await CardanoHWCLI(configuration: configuration)
    }
    
    func sendWithHardwareWallet(
        to address: String,
        amount: UInt64,
        fromDerivationPath: String
    ) async throws -> String {
        // Start hardware wallet
        _ = try await hwCli.startHardwareWallet()
        
        // Get source address from hardware wallet
        let sourceAddr = try await hwCli.address.show(arguments: [
            "--payment-path", fromDerivationPath
        ])
        
        // Build transaction with CardanoCLI
        let fee = try await cli.transaction.build(arguments: [
            "--tx-in-sel", sourceAddr,
            "--tx-out", "\(address)+\(amount)",
            "--change-address", sourceAddr,
            "--out-file", "hw-tx.raw"
        ])
        
        // Sign with hardware wallet
        try await hwCli.transaction.transformInPlace(txFile: FilePath("hw-tx.raw"))
        
        let witness = try await hwCli.transaction.witness(
            txFile: FilePath("hw-tx.raw"),
            hwSigningFile: FilePath("payment.hwsfile"),
            outFile: FilePath("hw-tx.witness")
        )
        
        // Assemble and submit with CardanoCLI
        let signedTx = try await cli.transaction.assemble(arguments: [
            "--tx-body-file", "hw-tx.raw",
            "--witness-file", "hw-tx.witness", 
            "--out-file", "hw-tx.signed"
        ])
        
        return try await cli.submitTransaction(signedTxFile: FilePath("hw-tx.signed"))
    }
}
```

## Troubleshooting

### Device Connection Issues

```bash
# Check if device is detected
cardano-hw-cli device version

# List connected devices
cardano-hw-cli device list

# Test device communication
cardano-hw-cli address show --payment-path "1852'/1815'/0'/0/0"
```

### Common Solutions

1. **Device Not Found**
   - Reconnect USB cable
   - Try different USB port
   - Restart the device

2. **App Not Responding**
   - Close and reopen Cardano app
   - Update Cardano app to latest version
   - Reset the device connection

3. **Transaction Rejection**
   - Check transaction amounts on device
   - Verify recipient addresses
   - Ensure sufficient balance

4. **Version Incompatibility**
   - Update device firmware
   - Update Cardano app
   - Update cardano-hw-cli binary

## Feature Compatibility Matrix

| Feature | Ledger | Trezor | cardano-hw-cli Version |
|---------|--------|--------|------------------------|
| Address Generation | ✅ | ✅ | 1.10.0+ |
| Transaction Signing | ✅ | ✅ | 1.10.0+ |
| Policy ID Generation | ✅ | ✅ | 1.10.0+ |
| Node Operations | ✅ | ✅ | 1.10.0+ |
| Vote Registration | ✅ | ✅ | 1.10.0+ |
| Multi-Signature | ✅ | ✅ | 1.10.0+ |
| Script Addresses | ✅ | ✅ | 1.10.0+ |

## Changelog

### Recent Updates

- **v1.2.0** - Added comprehensive Transaction, Node, and Vote command implementations
- **v1.1.0** - Enhanced Address commands with improved parameter validation
- **v1.0.0** - Initial CardanoHWCLI implementation with basic device support

## See Also

This guide covers secure hardware wallet integration with CardanoCLI. For related functionality:

- <doc:CardanoCLI> - Basic CLI operations and transaction building
- <doc:CardanoSigner> - Advanced signing without hardware wallets 
- <doc:CardanoNode> - Node management and stake pool operations
