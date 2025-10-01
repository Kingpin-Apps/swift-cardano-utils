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
import CardanoCLITools
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

## Basic Usage

### Device Initialization

```swift
// Initialize hardware wallet CLI
let hwCli = try await CardanoHWCLI(configuration: configuration)

// Check device version
let deviceVersion = try await hwCli.checkDeviceVersion()
print("Device version: \(deviceVersion)")

// Start hardware wallet interaction
let deviceType = try await hwCli.startHardwareWallet()
print("Connected device: \(deviceType.displayName)")
```

### Address Generation

```swift
// Generate a payment address with hardware wallet verification
let address = try await hwCli.address.show(arguments: [
    "--payment-path", "1852'/1815'/0'/0/0",
    "--stake-path", "1852'/1815'/0'/2/0"
])
print("Hardware wallet address: \(address)")

// Generate address without stake delegation
let simpleAddress = try await hwCli.address.show(arguments: [
    "--payment-path", "1852'/1815'/0'/0/0"
])
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
let hwSigningFile = "payment.hwsfile"
// Note: Hardware signing files contain derivation paths, not private keys

// 4. Generate witness with hardware wallet
let witness = try await hwCli.witnessTransaction(
    txBodyFile: "tx.raw",
    signingKeyFile: hwSigningFile,
    addressDerivationPath: "1852'/1815'/0'/0/0",
    outputFile: "tx.witness"
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
let witness1 = try await hwCli.witnessTransaction(
    txBodyFile: "tx.raw",
    signingKeyFile: "payment1.hwsfile",
    addressDerivationPath: "1852'/1815'/0'/0/0",
    outputFile: "tx.witness1"
)

let witness2 = try await hwCli.witnessTransaction(
    txBodyFile: "tx.raw", 
    signingKeyFile: "payment2.hwsfile",
    addressDerivationPath: "1852'/1815'/1'/0/0",
    outputFile: "tx.witness2"
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
} catch CardanoCLIToolsError.deviceError(let message) {
    if message.contains("version") {
        print("Device firmware needs updating")
        print("Minimum required versions:")
        print("- Ledger Cardano App: \(CardanoHWCLI.minLedgerCardanoApp)")
        print("- Trezor Firmware: \(CardanoHWCLI.minTrezorCardanoApp)")
    }
}
```

## Advanced Features

### Transaction Verification

Verify a transaction before submission:

```swift
// Verify transaction integrity
let verification = try await hwCli.verifyTransaction(txFile: "tx.signed")
print("Transaction verification: \(verification)")
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
} catch CardanoCLIToolsError.deviceError(let message) {
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
} catch CardanoCLIToolsError.binaryNotFound(let path) {
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
        try await hwCli.autocorrectTxBodyFile(txBodyFile: "secure-tx.raw")
        
        // 5. Sign with hardware wallet (user must approve on device)
        let witness = try await hwCli.witnessTransaction(
            txBodyFile: "secure-tx.raw",
            signingKeyFile: "payment.hwsfile",
            addressDerivationPath: fromPath,
            outputFile: "secure-tx.witness"
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
        try await hwCli.autocorrectTxBodyFile(txBodyFile: "hw-tx.raw")
        
        let witness = try await hwCli.witnessTransaction(
            txBodyFile: "hw-tx.raw",
            signingKeyFile: "payment.hwsfile",
            addressDerivationPath: fromDerivationPath,
            outputFile: "hw-tx.witness"
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

This guide covers secure hardware wallet integration with CardanoCLI. For advanced signing without hardware wallets, see <doc:CardanoSigner>. For basic CLI operations, see <doc:CardanoCLI>.
