# CardanoCLITools

A Swift package providing a convenient interface for interacting with Cardano CLI tools, including cardano-cli, cardano-node, Ogmios, and Kupo.

[![Swift](https://img.shields.io/badge/Swift-6.0+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2014+-blue.svg)](https://developer.apple.com/macos/)
[![Tests](https://img.shields.io/badge/Tests-293%20passing-green.svg)](#testing)


## Requirements

- **macOS 14.0+**
- **Swift 6.0+**
- **cardano-cli 8.0.0+** (installed separately)
- **cardano-node** (for socket connection)
- **cardano-hw-cli** (optional, for hardware wallet support)
- **cardano-signer** (optional, for advanced signing operations)

## Installation

### Swift Package Manager

Add CardanoCLITools to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/Kingpin-Apps/cardano-cli-tools.git", from: "0.1.0")
]
```

Then add it to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "CardanoCLITools", package: "cardano-cli-tools")
    ]
)
```

### Installing Cardano CLI Tools

Before using this package, you need to install the Cardano CLI tools:

#### Manual Installation

1. Download the latest release from [Cardano Node releases](https://github.com/IntersectMBO/cardano-node/releases)
2. Extract and place binaries in your PATH (e.g., `/usr/local/bin/`)

#### Hardware Wallet Support (Optional)

1. Download the latest release from [Cardano HW CLI releases](https://github.com/vacuumlabs/cardano-hw-cli/releases)
2. Extract and place binaries in your PATH (e.g., `/usr/local/bin/`)

#### Cardano Signer Support (Optional)

1. Download the latest release from [Cardano Signer releases](https://github.com/gitmachtl/cardano-signer/releases)
2. Extract and place binaries in your PATH (e.g., `/usr/local/bin/`)


## Quick Start

### Basic Setup

```swift
import CardanoCLITools
import SwiftCardanoCore
import System

// Create configuration
let cardanoConfig = CardanoConfig(
    cli: FilePath("/usr/local/bin/cardano-cli"),
    node: FilePath("/usr/local/bin/cardano-node"),
    hwCli: FilePath("/usr/local/bin/cardano-hw-cli"), // Optional
    signer: FilePath("/usr/local/bin/cardano-signer"), // Optional
    socket: FilePath("/tmp/cardano-node.socket"),
    config: FilePath("/path/to/config.json"),
    topology: FilePath("/path/to/topology.json"), // Optional
    database: FilePath("/path/to/database"), // Optional
    port: 3001, // Optional
    hostAddr: "127.0.0.1", // Optional
    network: .preview, // .mainnet, .preprod, .guildnet, .sanchonet, .custom(Int)
    era: .conway,
    ttlBuffer: 3600,
    workingDir: FilePath("/tmp"),
    showOutput: true // Optional
)

let configuration = Configuration(
    cardano: cardanoConfig,
    ogmios: nil,
    kupo: nil
)

// Initialize CLI
let cli = try await CardanoCLI(configuration: configuration)
```

### Basic Operations

#### Check Node Status

```swift
// Get cardano-cli version
let version = try await cli.version()
print("Cardano CLI version: \(version)")

// Check node sync progress
let syncProgress = try await cli.getSyncProgress()
print("Sync progress: \(syncProgress)%")

// Get current era
if let era = try await cli.getEra() {
    print("Current era: \(era)")
}

// Get current epoch
let epoch = try await cli.getEpoch()
print("Current epoch: \(epoch)")
```

#### Query Chain Information

```swift
// Get current tip (latest slot)
let tip = try await cli.getTip()
print("Current tip: \(tip)")

// Get chain tip details
let chainTip = try await cli.query.tip()
print("Block: \(chainTip.block)")
print("Epoch: \(chainTip.epoch)")
print("Era: \(chainTip.era)")
print("Hash: \(chainTip.hash)")
print("Slot: \(chainTip.slot)")
print("Sync Progress: \(chainTip.syncProgress)%")

// Get protocol parameters
let protocolParams = try await cli.getProtocolParameters()
print("Min fee A: \(protocolParams.txFeePerByte)")
print("Min fee B: \(protocolParams.txFeeFixed)")
```

### Address Operations

```swift
// Build an address
let address = try await cli.address.build(arguments: [
    "--payment-verification-key-file", "payment.vkey",
    "--stake-verification-key-file", "stake.vkey",
    "--testnet-magic", "2"
])
print("Generated address: \(address)")

// Get address info
let addressInfo = try await cli.query.addressInfo(
    address: "addr_test1...",
    arguments: ["--testnet-magic", "2"]
)
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
```

### Hardware Wallet Support

```swift
// Assuming you have cardano-hw-cli installed and configured
let hwCli = try await CardanoHWCLI(configuration: configuration)

// Get hardware wallet address
let hwAddress = try await hwCli.address.show(arguments: [
    "--payment-path", "1852'/1815'/0'/0/0",
    "--stake-path", "1852'/1815'/0'/2/0",
    "--testnet-magic", "2"
])
```

## Configuration

### JSON Configuration File

You can also load configuration from a JSON file:

```json
{
  "cardano": {
    "cli": "/usr/local/bin/cardano-cli",
    "node": "/usr/local/bin/cardano-node",
    "hw_cli": "/usr/local/bin/cardano-hw-cli",
    "signer": "/usr/local/bin/cardano-signer",
    "socket": "/tmp/cardano-node.socket",
    "config": "/path/to/config.json",
    "topology": "/path/to/topology.json",
    "database": "/path/to/database",
    "port": 3001,
    "host_addr": "127.0.0.1",
    "network": "preview",
    "era": "conway",
    "ttl_buffer": 3600,
    "working_dir": "/tmp",
    "show_output": true
  },
  "ogmios": {
    "binary": "/usr/local/bin/ogmios",
    "host": "0.0.0.0",
    "port": 1337,
    "timeout": 30,
    "max_in_flight": 100,
    "log_level": "info",
    "working_dir": "/tmp",
    "show_output": true
  },
  "kupo": {
    "binary": "/usr/local/bin/kupo",
    "host": "0.0.0.0",
    "port": 1442,
    "since": "origin",
    "matches": ["*"],
    "defer_db_indexes": false,
    "prune_utxo": false,
    "gc_interval": 300,
    "max_concurrency": 10,
    "log_level": "info",
    "working_dir": "/tmp",
    "show_output": true
  }
}
```

```swift
// Load from JSON file
let configData = try Data(contentsOf: URL(fileURLWithPath: "config.json"))
let configuration = try JSONDecoder().decode(Configuration.self, from: configData)
let cli = try await CardanoCLI(configuration: configuration)
```

### Network Types

The package supports different Cardano networks:

```swift
// Available networks
.mainnet       // Cardano mainnet
.preview       // Preview testnet (magic: 2)
.preprod       // Pre-production testnet (magic: 1)
.guildnet      // Guild testnet (magic: 141)
.sanchonet     // SanchoNet testnet (magic: 4)
.custom(Int)   // Custom network with magic number
```

### Network Configuration

Each network provides convenient properties:

```swift
let network = Network.preview
print(network.testnetMagic)  // Optional(2)
print(network.arguments)     // ["--testnet-magic", "2"]
print(network.description)   // "preview"
```

### Environment Variables

The package supports configuration via environment variables:

```bash
# Core Cardano settings
export CARDANO_SOCKET_PATH="/tmp/cardano-node.socket"
export CARDANO_CONFIG="/path/to/config.json"
export CARDANO_TOPOLOGY="/path/to/topology.json"
export CARDANO_DATABASE_PATH="/path/to/database"
export CARDANO_LOG_DIR="/path/to/logs"
export CARDANO_PORT="3001"
export CARDANO_BIND_ADDR="127.0.0.1"
export NETWORK="preview"

# Optional settings
export DEBUG="true"
export CARDANO_BLOCK_PRODUCER="false"
```

```swift
// Access environment variables programmatically
import CardanoCLITools

// Set environment variables at runtime
Environment.set(.network, value: "preview")
Environment.set(.cardanoSocketPath, value: "/tmp/node.socket")

// Get environment variables
if let network = Environment.get(.network) {
    print("Network: \(network)")
}

// Get file paths from environment
if let socketPath = Environment.getFilePath(.cardanoSocketPath) {
    print("Socket: \(socketPath)")
}
```

### Default Configuration

Generate default configuration from environment variables:

```swift
// Create default CardanoConfig from environment
let defaultCardanoConfig = try CardanoConfig.default()
let configuration = Configuration(
    cardano: defaultCardanoConfig,
    ogmios: try? OgmiosConfig.default(),
    kupo: try? KupoConfig.default()
)
```

### Era Types

```swift
// Available eras
.byron
.shelley
.allegra
.mary
.alonzo
.babbage
.conway
```

## Advanced Usage

### Transaction Building

```swift
// Get UTxOs for an address
let utxos = try await cli.query.utxos(
    address: "addr_test1...",
    arguments: ["--testnet-magic", "2"]
)

// Build transaction
let txBody = try await cli.transaction.build(arguments: [
    "--tx-in", "txhash#0",
    "--tx-out", "addr_test1...+1000000",
    "--change-address", "addr_test1...",
    "--testnet-magic", "2",
    "--out-file", "tx.raw"
])
```

### Stake Pool Operations

```swift
// Query stake pools
let stakePools = try await cli.query.stakePools(
    arguments: ["--testnet-magic", "2"]
)

// Get stake pool information
let poolInfo = try await cli.query.poolParams(
    poolId: "pool1...",
    arguments: ["--testnet-magic", "2"]
)
```

### Protocol Parameters

```swift
// Get current protocol parameters
let params = try await cli.getProtocolParameters()

// Save to file
let paramsFile = FilePath("/tmp/protocol.json")
let _ = try await cli.getProtocolParameters(paramsFile: paramsFile)
```

### Ogmios and Kupo Integration

```swift
// Configure Ogmios for WebSocket queries
let ogmiosConfig = OgmiosConfig(
    binary: FilePath("/usr/local/bin/ogmios"),
    host: "127.0.0.1",
    port: 1337,
    timeout: 30,
    maxInFlight: 100,
    logLevel: "info",
    workingDir: FilePath("/tmp"),
    showOutput: true
)

// Configure Kupo for UTxO indexing
let kupoConfig = KupoConfig(
    binary: FilePath("/usr/local/bin/kupo"),
    host: "127.0.0.1",
    port: 1442,
    since: "origin",
    matches: ["addr_test*", "stake_test*"],
    deferDbIndexes: false,
    pruneUTxO: false,
    gcInterval: 300,
    maxConcurrency: 10,
    logLevel: "info",
    workingDir: FilePath("/tmp"),
    showOutput: true
)

// Initialize services
let ogmios = try await Ogmios(configuration: Configuration(cardano: cardanoConfig, ogmios: ogmiosConfig, kupo: nil))
let kupo = try await Kupo(configuration: Configuration(cardano: cardanoConfig, ogmios: nil, kupo: kupoConfig))

// Start services
try await ogmios.start()
try await kupo.start()

// Check if services are running
print("Ogmios running: \(ogmios.isRunning)")
print("Kupo running: \(kupo.isRunning)")
```

## Error Handling

The package defines comprehensive error types:

```swift
do {
    let tip = try await cli.getTip()
    print("Current tip: \(tip)")
} catch CardanoCLIToolsError.nodeNotSynced(let progress) {
    print("Node not fully synced: \(progress)%")
} catch CardanoCLIToolsError.commandFailed(let command, let message) {
    print("Command failed: \(command)")
    print("Error: \(message)")
} catch CardanoCLIToolsError.binaryNotFound(let path) {
    print("Binary not found at: \(path)")
} catch {
    print("Unexpected error: \(error)")
}
```

### Error Types

Comprehensive error handling with specific error types:

```swift
public enum CardanoCLIToolsError: Error, Equatable {
    case binaryNotFound(String)              // CLI binary not found at path
    case commandFailed([String], String)     // CLI command execution failed
    case nodeNotSynced(Double)              // Node sync progress < 100%
    case invalidOutput(String)              // Command output parsing failed
    case unsupportedVersion(String, String) // CLI version incompatible
    case configurationMissing(String)       // Required config missing
    case fileNotFound(String)              // Required file not found
    case processAlreadyRunning(String)      // Process already running
    case deviceError(String)                // Hardware wallet device error
    case invalidMultiSigConfig(String)      // Multi-signature config invalid
    case versionMismatch(String, String)    // Version compatibility issue
}
```

### Error Context and Recovery

```swift
do {
    let tip = try await cli.getTip()
    print("Current tip: \(tip)")
} catch CardanoCLIToolsError.nodeNotSynced(let progress) {
    print("Node synchronizing: \(String(format: "%.1f", progress))%")
    // Wait and retry logic
} catch CardanoCLIToolsError.commandFailed(let command, let message) {
    print("Command failed: \(command.joined(separator: " "))")
    print("Error details: \(message)")
    // Command-specific error handling
} catch CardanoCLIToolsError.binaryNotFound(let path) {
    print("Install cardano-cli at: \(path)")
    // Installation guidance
} catch CardanoCLIToolsError.unsupportedVersion(let current, let required) {
    print("Version \(current) found, \(required) required")
    // Version upgrade guidance
} catch {
    print("Unexpected error: \(error.localizedDescription)")
}
```

## Architecture & Protocols

### Protocol-Based Design

The package uses a clean protocol-based architecture:

```swift
// Core protocols for binary management
protocol BinaryExecutable {
    static var binaryName: String { get }
    static var minimumVersion: String { get }
    static func getBinaryPath() throws -> FilePath
    static func checkBinary(at path: FilePath) throws
    static func checkVersion(_ version: String) throws
}

protocol BinaryInterfaceable: BinaryExecutable {
    var configuration: Configuration { get }
    var logger: Logger { get }
    func runCommand(_ arguments: [String]) async throws -> String
}

protocol BinaryRunnable: BinaryInterfaceable {
    var isRunning: Bool { get }
    func start() async throws
    func stop() async throws
}
```

### Type-Safe Command Building

```swift
// Commands are strongly typed and validated
let addressCommand = cli.address
let keyCommand = cli.key
let transactionCommand = cli.transaction
let queryCommand = cli.query

// Each command provides specific methods
try await addressCommand.build(arguments: [...])
try await keyCommand.generate(arguments: [...])
try await transactionCommand.sign(arguments: [...])
try await queryCommand.tip()
```

### Process Management

```swift
// Advanced process lifecycle management
let node = try await CardanoNode(configuration: configuration)

// Start node with automatic socket management
try await node.start()
print("Node PID: \(node.process?.processIdentifier ?? -1)")
print("Socket path: \(node.configuration.cardano.socket)")

// Graceful shutdown
try await node.stop()
```

### Hardware Wallet Integration

```swift
// Hardware wallet support with device detection
let hwCli = try await CardanoHWCLI(configuration: configuration)

// Device-specific operations
try await hwCli.device.version()
try await hwCli.address.show(arguments: [
    "--payment-path", "1852'/1815'/0'/0/0",
    "--address-format", "bech32"
])
```

## Performance & Best Practices

### Configuration Optimization

```swift
// Cache configuration for reuse
static let sharedConfiguration: Configuration = {
    do {
        return try Configuration(
            cardano: .default(),
            ogmios: .default(),
            kupo: .default()
        )
    } catch {
        fatalError("Failed to create configuration: \(error)")
    }
}()

// Reuse CLI instances
static let cli = try await CardanoCLI(configuration: sharedConfiguration)
```

### Async/Await Best Practices

```swift
// Concurrent operations
async let tip = cli.getTip()
async let epoch = cli.getEpoch()
async let syncProgress = cli.getSyncProgress()

let (currentTip, currentEpoch, progress) = try await (tip, epoch, syncProgress)
print("Tip: \(currentTip), Epoch: \(currentEpoch), Sync: \(progress)%")

// Task groups for multiple addresses
let addresses = ["addr1...", "addr2...", "addr3..."]
let balances = try await withThrowingTaskGroup(of: (String, UInt64).self) { group in
    for address in addresses {
        group.addTask {
            let balance = try await cli.query.balance(address: address)
            return (address, balance)
        }
    }
    
    var results: [(String, UInt64)] = []
    for try await result in group {
        results.append(result)
    }
    return results
}
```

### Error Handling Patterns

```swift
// Retry with exponential backoff
func executeWithRetry<T>(
    operation: () async throws -> T,
    maxRetries: Int = 3,
    baseDelay: TimeInterval = 1.0
) async throws -> T {
    var lastError: Error?
    
    for attempt in 0..<maxRetries {
        do {
            return try await operation()
        } catch CardanoCLIToolsError.nodeNotSynced {
            // Wait for node sync
            try await Task.sleep(nanoseconds: UInt64(baseDelay * pow(2.0, Double(attempt)) * 1_000_000_000))
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

## Testing

Run the test suite:

```bash
# Run all tests
swift test

# Run tests with coverage
swift test --enable-code-coverage

# Run specific test suites
swift test --filter "EnvironmentTests"
swift test --filter "ConfigurationTests"
```

## Dependencies

- [swift-log](https://github.com/apple/swift-log) `1.6.2+` - Structured logging framework
- [swift-cardano-core](https://github.com/Kingpin-Apps/swift-cardano-core) `0.1.33+` - Cardano protocol types and utilities

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass (`swift test`)
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues and questions:
- Open an issue on [GitHub](https://github.com/Kingpin-Apps/cardano-cli-tools/issues)
- Check the [Cardano Developer Portal](https://developers.cardano.org/)

## Acknowledgments

- [Input Output Global](https://iohk.io/) for Cardano
- [Cardano Foundation](https://cardanofoundation.org/)
- The Cardano community for tools and documentation
