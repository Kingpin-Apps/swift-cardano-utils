# Kupo

UTxO indexer service management for Cardano blockchain data.

## Overview

``Kupo`` provides process management for the Kupo UTxO indexer service.

### Requirements

- macOS 14.0+
- Swift 6.0+
- Kupo binary (installed separately)
- Running Cardano node

## Configuration

```swift
import SwiftCardanoUtils

let configuration = Configuration(
    cardano: cardanoConfig,
    kupo: kupoConfig
)

var kupo = try await Kupo(configuration: configuration)
```

## Basic Operations

### Starting Kupo

```swift
// Start Kupo indexer
try kupo.start()

// Check if running
print("Kupo running: \(kupo.isRunning)")
```

### Stopping Kupo

```swift
// Stop Kupo indexer
kupo.stop()
print("Kupo stopped")
```

## Container Mode

Run Kupo inside Docker or Apple Container instead of a locally-installed binary. See <doc:ContainerSupport> for full details.

```swift
let container = ContainerConfig(
    runtime: .docker,
    imageName: "cardanosolutions/kupo:v2.10",
    containerName: "kupo",
    volumes: ["/data:/db", "/ipc:/ipc"],
    ports: ["1442:1442"],
    restart: "unless-stopped",
    detach: true
)

let kupoConfig = KupoConfig(
    host: "0.0.0.0",
    port: 1442,
    container: container
)
```
