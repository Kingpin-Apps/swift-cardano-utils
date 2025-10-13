# ``SwiftCardanoUtils``

A comprehensive Swift package providing convenient interfaces for interacting with Cardano CLI tools, including cardano-cli, cardano-node, Ogmios, Kupo, hardware wallets, and advanced signing operations.

## Overview

SwiftCardanoUtils is a Swift package that provides type-safe, async/await-based wrappers for essential Cardano blockchain tools. Whether you're building a DApp, managing transactions, or integrating hardware wallet support, this package streamlines interaction with the Cardano ecosystem.

### Key Features

- **Type-safe CLI interactions** - Strongly-typed Swift interfaces for all Cardano CLI tools
- **Async/await support** - Modern Swift concurrency for all operations
- **Hardware wallet integration** - Support for Ledger and Trezor devices
- **Advanced signing** - CIP-8, CIP-30, and CIP-36 compliance
- **Node management** - Start and manage Cardano nodes programmatically
- **Real-time data** - WebSocket integration with Ogmios
- **UTxO indexing** - Kupo integration for efficient chain queries
- **Multi-network support** - Mainnet, testnet, and custom networks
- **Comprehensive error handling** - Detailed error types and recovery strategies

### Supported Networks

- Cardano Mainnet
- Preview Testnet (magic: 2)
- Pre-production Testnet (magic: 1)
- SanchoNet (magic: 4)
- Custom networks

### Requirements

- **macOS 14.0+**
- **Swift 6.0+**
- **Cardano CLI 8.0.0+** (installed separately)
- Optional: cardano-node, cardano-hw-cli, cardano-signer, Ogmios, Kupo

## Quick Start

```swift
import SwiftCardanoUtils
import SwiftCardanoCore
import System

// Create configuration
let configuration = try Config.default()

// Initialize CLI
let cli = try await CardanoCLI(configuration: configuration)

// Check node status
let syncProgress = try await cli.getSyncProgress()
print("Node sync: \(syncProgress)%")

// Query chain tip
let tip = try await cli.getTip()
print("Current tip: \(tip)")
```

## Topics

### CLI Tools

- <doc:CardanoCLI>
- <doc:CardanoHWCLI>
- <doc:CardanoSigner>
- <doc:CardanoNode>
- <doc:Ogmios>
- <doc:Kupo>

### Configuration

- ``Config``
- ``CardanoConfig``
- ``OgmiosConfig``
- ``KupoConfig``

### Command Groups

- ``AddressCommandImpl``
- ``KeyCommandImpl``
- ``TransactionCommandImpl``
- ``QueryCommandImpl``
- ``GovernanceCommandImpl``
- ``StakeAddressCommandImpl``
- ``StakePoolCommandImpl``
- ``GenesisCommandImpl``

### Tutorials

- <doc:MintingNativeTokenWithHardwareWallet>
- <doc:BuildingDAppBackendWithOgmios>
