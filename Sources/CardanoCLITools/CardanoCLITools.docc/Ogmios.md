# Ogmios

WebSocket API server service management for Cardano blockchain data access.

## Overview

``Ogmios`` provides process management for the Ogmios WebSocket API server that connects to a Cardano node.

### Requirements

- macOS 14.0+
- Swift 6.0+
- Ogmios 6.13.0+ (installed separately)
- Running Cardano node with accessible socket

## Installation

Ensure Ogmios is installed and available in your PATH. Download from the [official releases](https://github.com/CardanoSolutions/ogmios/releases) or use Docker.

## Configuration

```swift
import CardanoCLITools
import System

let ogmiosConfig = OgmiosConfig(
    binary: FilePath("/usr/local/bin/ogmios"),
    host: "127.0.0.1",
    port: 1337,
    timeout: 90,
    maxInFlight: 100,
    logLevel: "info",
    workingDir: FilePath("/tmp"),
    showOutput: true
)

let cardanoConfig = CardanoConfig(
    cli: FilePath("/usr/local/bin/cardano-cli"),
    node: FilePath("/usr/local/bin/cardano-node"),
    socket: FilePath("/tmp/cardano-node.socket"),
    config: FilePath("/path/to/config.json"),
    network: .preview,
    era: .conway,
    workingDir: FilePath("/tmp")
)

let configuration = Configuration(
    cardano: cardanoConfig,
    ogmios: ogmiosConfig,
    kupo: nil
)

var ogmios = try await Ogmios(configuration: configuration)
```

## Service Management

### Starting Ogmios

```swift
// Start Ogmios server
try ogmios.start()

// Check if running
print("Ogmios running: \(ogmios.isRunning)")
```

### Stopping Ogmios

```swift
// Stop Ogmios server
ogmios.stop()

// Wait for graceful shutdown
while ogmios.isRunning {
    try await Task.sleep(for: .seconds(1))
}

print("Ogmios stopped")
```

## Error Handling

```swift
do {
    try ogmios.start()
} catch CardanoCLIToolsError.binaryNotFound(let path) {
    print("Ogmios not found at: \(path)")
} catch CardanoCLIToolsError.processAlreadyRunning {
    print("Ogmios already running")
} catch {
    print("Failed to start Ogmios: \(error)")
}
```

Ogmios provides WebSocket API access to blockchain data. For blockchain operations, see <doc:CardanoCLI>. For node management, see <doc:CardanoNode>.
