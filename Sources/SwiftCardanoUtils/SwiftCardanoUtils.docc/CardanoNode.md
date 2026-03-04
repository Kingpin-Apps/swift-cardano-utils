# CardanoNode

Manage Cardano blockchain node processes programmatically.

## Overview

``CardanoNode`` provides process management and lifecycle control for Cardano blockchain nodes. It handles node startup, configuration, monitoring, and graceful shutdown.

### Key Features

- **Process Management** - Start and stop node processes
- **Configuration Management** - Handle node configuration files and parameters
- **Resource Management** - Efficient process resource handling
- **Socket Management** - Automatic socket path configuration

### Requirements

- macOS 14.0+
- Swift 6.0+
- cardano-node 8.0.0+ (installed separately)

## Installation

Ensure cardano-node is installed and available in your PATH. Download from the [official releases](https://github.com/IntersectMBO/cardano-node/releases) or install via package manager.

## Configuration

```swift
import SwiftCardanoUtils
import System

let cardanoConfig = CardanoConfig(
    cli: FilePath("/usr/local/bin/cardano-cli"),
    node: FilePath("/usr/local/bin/cardano-node"),
    socket: FilePath("/tmp/cardano-node.socket"),
    config: FilePath("/path/to/config.json"),
    topology: FilePath("/path/to/topology.json"),
    database: FilePath("/path/to/database"),
    port: 3001,
    hostAddr: "127.0.0.1",
    network: .preview,
    era: .conway,
    workingDir: FilePath("/tmp"),
    showOutput: true
)

let configuration = Configuration(
    cardano: cardanoConfig,
    ogmios: nil,
    kupo: nil
)

var node = try await CardanoNode(configuration: configuration)
```

## Service Management

### Starting the Node

```swift
// Start the Cardano node
try node.start()

// Check if node is running
print("Node running: \(node.isRunning)")
```

### Stopping the Node

```swift
// Stop the node
node.stop()

// Wait for process to terminate
while node.isRunning {
    try await Task.sleep(for: .seconds(1))
}

print("Node stopped")
```

## Error Handling

```swift
do {
    try node.start()
} catch SwiftCardanoUtilsError.binaryNotFound(let path) {
    print("cardano-node not found at: \(path)")
} catch SwiftCardanoUtilsError.processAlreadyRunning {
    print("Node already running")
} catch {
    print("Failed to start node: \(error)")
}
```

## Container Mode

Run CardanoNode inside Docker or Apple Container instead of a locally-installed binary. See <doc:ContainerSupport> for full details.

```swift
let container = ContainerConfig(
    runtime: .docker,
    imageName: "ghcr.io/intersectmbo/cardano-node:10.0.0",
    containerName: "cardano-node",
    volumes: ["/data/cardano-node:/data", "/ipc:/ipc"],
    environment: ["NETWORK=preview"],
    network: "host",
    restart: "unless-stopped",
    detach: true
)

let cardanoConfig = CardanoConfig(
    socket: FilePath("/ipc/node.socket"),
    config: FilePath("/data/config/config.json"),
    network: .preview,
    era: .conway,
    ttlBuffer: 3600,
    container: container
)

let node = try await CardanoNode(configuration: Config(cardano: cardanoConfig))
try await node.start()  // Runs: docker run --detach ... ghcr.io/intersectmbo/cardano-node:10.0.0
```

CardanoNode provides the foundation for blockchain infrastructure. For blockchain operations, see <doc:CardanoCLI>.
