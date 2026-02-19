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

