# MithrilClient

Download and verify certified Cardano blockchain snapshots using Mithril's stake-based threshold multi-signatures protocol.

## Overview

``MithrilClient`` provides a type-safe, async/await-based Swift interface to the Mithril client CLI tool. Mithril enables fast bootstrapping of Cardano nodes by downloading certified snapshots of the blockchain database, verified through a stake-based multi-signature scheme.

### Key Capabilities

- **Cardano DB Snapshots** - List, download, and verify certified blockchain database snapshots
- **Fast Node Bootstrap** - Reduce node sync time from days to minutes
- **Stake Distribution** - Access Mithril and Cardano stake distribution data
- **Transaction Certification** - Verify transactions are included in certified sets
- **Certificate Chain Verification** - Automatic verification of multi-signature certificates

### Requirements

- macOS 14.0+
- Swift 6.0+
- mithril-client 0.12.38+ (installed separately)
- Network access to Mithril aggregator endpoints

## Installation

Download the Mithril client from the [official releases](https://github.com/input-output-hk/mithril/releases) or use the installation script:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/input-output-hk/mithril/refs/heads/main/mithril-install.sh | sh -s -- -c mithril-client -d latest -p /usr/local/bin
```

## Configuration

The MithrilClient requires a ``Config`` object with Mithril-specific settings:

### Basic Configuration

```swift
import SwiftCardanoUtils
import SwiftCardanoCore
import System

let mithrilConfig = MithrilConfig(
    binary: FilePath("/usr/local/bin/mithril-client"),
    aggregatorEndpoint: "https://aggregator.release-mainnet.api.mithril.network/aggregator",
    genesisVerificationKey: "GENESIS_VERIFICATION_KEY",
    ancillaryVerificationKey: "ANCILLARY_VERIFICATION_KEY",
    downloadDir: FilePath("/var/lib/cardano/db"),
    workingDir: FilePath("/tmp/mithril"),
    showOutput: true
)

let cardanoConfig = CardanoConfig(
    cli: FilePath("/usr/local/bin/cardano-cli"),
    node: FilePath("/usr/local/bin/cardano-node"),
    socket: FilePath("/tmp/cardano-node.socket"),
    config: FilePath("/path/to/config.json"),
    database: FilePath("/var/lib/cardano/db"),
    network: .mainnet,
    era: .conway,
    ttlBuffer: 3600,
    workingDir: FilePath("/tmp")
)

let configuration = Config(
    cardano: cardanoConfig,
    ogmios: nil,
    kupo: nil,
    mithril: mithrilConfig
)

let mithril = try await MithrilClient(configuration: configuration)
```

### Network-Specific Aggregator Endpoints

Each Cardano network has its own Mithril aggregator:

| Network | Aggregator Endpoint |
|---------|---------------------|
| Mainnet | `https://aggregator.release-mainnet.api.mithril.network/aggregator` |
| Preprod | `https://aggregator.release-preprod.api.mithril.network/aggregator` |
| Preview | `https://aggregator.testing-preview.api.mithril.network/aggregator` |

You can also use the auto-discovery format: `auto:mainnet`, `auto:preprod`, or `auto:preview`.

### Environment Variables

MithrilClient supports configuration via environment variables:

```swift
// Set environment variables
Environment.set(.aggregatorEndpoint, value: "https://aggregator.release-mainnet.api.mithril.network/aggregator")
Environment.set(.genesisVerificationKey, value: "GENESIS_KEY")
Environment.set(.ancillaryVerificationKey, value: "ANCILLARY_KEY")

// Create default configuration
let configuration = try Config.default()
let mithril = try await MithrilClient(configuration: configuration)
```

### JSON Configuration

```json
{
  "cardano": {
    "cli": "/usr/local/bin/cardano-cli",
    "database": "/var/lib/cardano/db",
    "network": "mainnet"
  },
  "mithril": {
    "binary": "/usr/local/bin/mithril-client",
    "aggregator_endpoint": "https://aggregator.release-mainnet.api.mithril.network/aggregator",
    "genesis_verification_key": "GENESIS_KEY",
    "ancillary_verification_key": "ANCILLARY_KEY",
    "download_dir": "/var/lib/cardano/db",
    "working_dir": "/tmp/mithril",
    "show_output": true
  }
}
```

## Basic Usage

### Bootstrap a Cardano Node

The primary use case for MithrilClient is to bootstrap a Cardano node quickly:

```swift
// Download the latest certified snapshot with ancillary files for fast bootstrap
let result = try await mithril.downloadLatestSnapshot()
print("Download complete!")

// Or use the cardanoDb command group directly
try await mithril.cardanoDb.download(
    digest: "latest",
    downloadDir: "/var/lib/cardano/db",
    includeAncillary: true,
    ancillaryVerificationKey: "YOUR_KEY"
)
```

### List Available Snapshots

```swift
// List all available snapshots
let snapshots = try await mithril.listSnapshots()
print(snapshots)

// Or use the command group
let snapshotList = try await mithril.cardanoDb.snapshotList()
```

### Show Snapshot Details

```swift
// Get details about a specific snapshot
let details = try await mithril.cardanoDb.snapshotShow(digest: "abc123def456")
print(details)
```

### Download Without Ancillary Files

For faster downloads when you don't need fast bootstrap (node will compute ledger state from genesis):

```swift
// Fast download, slower node startup
try await mithril.cardanoDb.downloadSkipAncillary(
    digest: "latest",
    downloadDir: "/var/lib/cardano/db"
)
```

## Stake Distribution

### Mithril Stake Distribution

Query the stake distribution used by Mithril signers:

```swift
// List available Mithril stake distributions
let distributions = try await mithril.mithrilStakeDistribution.list()
print(distributions)

// Download a specific stake distribution
try await mithril.mithrilStakeDistribution.download(artifactHash: "abc123")
```

### Cardano Stake Distribution

Query certified Cardano stake distributions:

```swift
// List available Cardano stake distributions
let cardanoDistributions = try await mithril.cardanoStakeDistribution.list()
print(cardanoDistributions)
```

## Transaction Certification

Verify that transactions are included in the certified Cardano transaction set:

```swift
// Certify a single transaction
let result = try await mithril.certifyTransaction(
    transactionHash: "abc123def456789..."
)
print(result)

// Certify multiple transactions
let results = try await mithril.cardanoTransaction.certify(
    transactionHashes: [
        "abc123def456789...",
        "def789abc123456..."
    ]
)
```

### Transaction Snapshots

```swift
// List transaction snapshots
let txSnapshots = try await mithril.cardanoTransaction.snapshotList()

// Show transaction snapshot details
let txDetails = try await mithril.cardanoTransaction.snapshotShow(
    hash: "snapshot123"
)
```

## Tools

### UTXO-HD Snapshot Converter

Since Cardano node v10.4.1, Mithril produces snapshots using the InMemory UTXO-HD flavor. Convert snapshots for different node configurations:

```swift
// Convert ledger state snapshot to LMDB format
try await mithril.tools.utxoHdSnapshotConverter(
    inputFormat: "InMemory",
    outputFormat: "LMDB",
    snapshotPath: "/var/lib/cardano/db/ledger"
)

// Convert to Legacy format (for Cardano node v10.3 and earlier)
try await mithril.tools.utxoHdSnapshotConverter(
    inputFormat: "InMemory",
    outputFormat: "Legacy",
    snapshotPath: "/var/lib/cardano/db/ledger"
)
```

## Error Handling

```swift
do {
    try await mithril.downloadLatestSnapshot()
} catch SwiftCardanoUtilsError.binaryNotFound(let path) {
    print("Mithril client not found at: \(path)")
    // Installation guidance
} catch SwiftCardanoUtilsError.unsupportedVersion(let current, let required) {
    print("Version \(current) found, \(required) required")
    // Version upgrade guidance
} catch SwiftCardanoUtilsError.commandFailed(let command, let message) {
    print("Command failed: \(command.joined(separator: " "))")
    print("Error: \(message)")
    // Check network connectivity, aggregator status
} catch {
    print("Unexpected error: \(error)")
}
```

### Common Issues

1. **Network Errors** - Ensure the aggregator endpoint is reachable
2. **Verification Failures** - Check genesis and ancillary verification keys
3. **Disk Space** - Ensure sufficient space for snapshot download
4. **Permissions** - Verify write access to download directory

## Best Practices

### Pre-Download Validation

```swift
// List snapshots first to verify connectivity
let snapshots = try await mithril.listSnapshots()

// Check available space before downloading
let fileManager = FileManager.default
let attributes = try fileManager.attributesOfFileSystem(forPath: "/var/lib/cardano")
let freeSpace = attributes[.systemFreeSize] as? UInt64 ?? 0

// Mainnet snapshot typically requires 100GB+
guard freeSpace > 100_000_000_000 else {
    throw NSError(domain: "InsufficientSpace", code: 1)
}

// Proceed with download
try await mithril.downloadLatestSnapshot()
```

### Progress Monitoring

The Mithril client outputs progress to stdout. Enable output visibility:

```swift
let mithrilConfig = MithrilConfig(
    binary: FilePath("/usr/local/bin/mithril-client"),
    aggregatorEndpoint: "https://aggregator.release-mainnet.api.mithril.network/aggregator",
    showOutput: true  // Enable progress output
)
```

### Automation Script

```swift
/// Bootstrap a new Cardano node using Mithril
func bootstrapCardanoNode(
    databasePath: String,
    network: Network
) async throws {
    let aggregatorEndpoint: String
    switch network {
    case .mainnet:
        aggregatorEndpoint = "https://aggregator.release-mainnet.api.mithril.network/aggregator"
    case .preprod:
        aggregatorEndpoint = "https://aggregator.release-preprod.api.mithril.network/aggregator"
    case .preview:
        aggregatorEndpoint = "https://aggregator.testing-preview.api.mithril.network/aggregator"
    default:
        throw SwiftCardanoUtilsError.valueError("Unsupported network for Mithril")
    }
    
    let mithrilConfig = MithrilConfig(
        aggregatorEndpoint: aggregatorEndpoint,
        downloadDir: FilePath(databasePath),
        showOutput: true
    )
    
    let config = Config(
        cardano: CardanoConfig(network: network, era: .conway, ttlBuffer: 3600),
        mithril: mithrilConfig
    )
    
    let mithril = try await MithrilClient(configuration: config)
    
    print("Downloading latest snapshot for \(network)...")
    try await mithril.downloadLatestSnapshot()
    print("Bootstrap complete! Start your Cardano node.")
}
```

## Command Groups

MithrilClient organizes functionality into logical command groups:

### Cardano DB Commands (``CardanoDbCommandImpl``)

- `snapshotList()` - List available database snapshots
- `snapshotShow(digest:)` - Show snapshot details
- `download(digest:downloadDir:includeAncillary:)` - Download and verify snapshot
- `downloadSkipAncillary(digest:downloadDir:)` - Download without ancillary files
- `verify()` - Verify downloaded snapshot (v2 backend)

### Mithril Stake Distribution Commands (``MithrilStakeDistributionCommandImpl``)

- `list()` - List available Mithril stake distributions
- `download(artifactHash:)` - Download stake distribution

### Cardano Transaction Commands (``CardanoTransactionCommandImpl``)

- `snapshotList()` - List transaction snapshots
- `snapshotShow(hash:)` - Show transaction snapshot details
- `certify(transactionHashes:)` - Certify transactions

### Cardano Stake Distribution Commands (``CardanoStakeDistributionCommandImpl``)

- `list()` - List available Cardano stake distributions

### Tools Commands (``ToolsCommandImpl``)

- `utxoHdSnapshotConverter(inputFormat:outputFormat:snapshotPath:)` - Convert UTXO-HD snapshots

## Integration with CardanoCLI

Use MithrilClient alongside CardanoCLI for a complete node management workflow:

```swift
// 1. Bootstrap database with Mithril
let mithril = try await MithrilClient(configuration: config)
try await mithril.downloadLatestSnapshot(downloadDir: "/var/lib/cardano/db")

// 2. Start Cardano node (using CardanoNode)
var node = try await CardanoNode(configuration: config)
try node.start()

// 3. Wait for node to be ready
let cli = try await CardanoCLI(configuration: config)
while try await cli.getSyncProgress() < 100.0 {
    try await Task.sleep(for: .seconds(10))
}

// 4. Node is ready for operations
let tip = try await cli.getTip()
print("Node synced to slot: \(tip)")
```

This enables rapid deployment of Cardano infrastructure with minimal sync time.
