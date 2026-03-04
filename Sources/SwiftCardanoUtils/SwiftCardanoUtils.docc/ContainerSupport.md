# Container Support

Run Cardano tools inside Docker or Apple Container without local binary installations.

## Overview

SwiftCardanoUtils supports executing all CLI tools inside containers managed by Docker or [Apple Container](https://github.com/apple/container). Attach a ``ContainerConfig`` to any service configuration (`CardanoConfig`, `OgmiosConfig`, `KupoConfig`, `MithrilConfig`) to route commands through the container runtime instead of a locally-installed binary.

**Why use container mode?**
- **Reproducible environments** — pin exact tool versions via image tags
- **No local installs** — ship a Docker Compose file instead of host binaries
- **Apple Silicon** — run `linux/amd64` images transparently via Rosetta
- **CI/CD** — integrate with containerised pipelines without installing Cardano tooling

### Execution Modes

Commands are dispatched in one of two ways depending on the tool type:

| Mode | Tools | Container Command |
|------|-------|-------------------|
| **Run** | CardanoNode, Ogmios, Kupo | `docker run [flags] <image> <binary> [args]` |
| **Exec** | CardanoCLI, CardanoHWCLI, CardanoSigner, MithrilClient | `docker exec <name> <binary> [args]` |

Run-mode tools launch a new container each time `start()` is called and default to `--detach`. Exec-mode tools issue one-shot commands against a *pre-existing* named container; `containerName` is therefore **required** for exec-mode tools.

### Supported Runtimes

| Runtime | Executable | Raw Value |
|---------|------------|-----------|
| ``ContainerRuntime/docker`` | `docker` | `"docker"` |
| ``ContainerRuntime/appleContainer`` | `container` | `"container"` |

## ContainerConfig

Create a ``ContainerConfig`` with the fields appropriate for your use case. Only `imageName` is required; all other fields are optional.

```swift
let container = ContainerConfig(
    runtime: .docker,                          // .docker or .appleContainer
    imageName: "ghcr.io/intersectmbo/cardano-node:10.0.0",
    containerName: "cardano-node",             // Required for exec mode
    volumes: ["/data:/data", "/ipc:/ipc"],
    environment: ["NETWORK=mainnet"],
    ports: ["3001:3001"],
    network: "host",
    restart: "unless-stopped",
    workingDir: "/app",
    user: "1000:1000",
    detach: true,
    memory: "4g",
    cpus: "2.0"
)
```

## Run-Mode Tools (Daemons)

Daemon tools launch a new container each time `start()` is called. `containerName` is optional — if omitted the runtime assigns a random name.

### CardanoNode

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
try await node.start()
```

### Ogmios

```swift
let container = ContainerConfig(
    runtime: .docker,
    imageName: "cardanosolutions/ogmios:v6.13",
    containerName: "ogmios",
    volumes: ["/ipc:/ipc"],
    ports: ["1337:1337"],
    restart: "unless-stopped",
    detach: true
)

let ogmiosConfig = OgmiosConfig(
    host: "0.0.0.0",
    port: 1337,
    container: container
)
```

### Kupo

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

## Exec-Mode Tools (One-Shot)

Exec-mode tools run commands inside a *running* named container. Start the container first (e.g., via ``CardanoNode`` in run-mode), then initialise these tools.

> Important: `containerName` is **required** for exec-mode tools. A command issued without a running named container will throw ``SwiftCardanoUtilsError/configurationMissing(_:)``.

### CardanoCLI

```swift
// Assumes a container named "cardano-node" is already running
let container = ContainerConfig(
    runtime: .docker,
    imageName: "ghcr.io/intersectmbo/cardano-node:10.0.0",
    containerName: "cardano-node"   // Required
)

let cardanoConfig = CardanoConfig(
    socket: FilePath("/ipc/node.socket"),
    config: FilePath("/data/config/config.json"),
    network: .preview,
    era: .conway,
    ttlBuffer: 3600,
    container: container
)

let cli = try await CardanoCLI(configuration: Config(cardano: cardanoConfig))
let tip = try await cli.getTip()
```

### MithrilClient

```swift
let container = ContainerConfig(
    runtime: .docker,
    imageName: "ghcr.io/input-output-hk/mithril-client:latest",
    containerName: "mithril-client",
    volumes: ["/data:/data"]
)

let mithrilConfig = MithrilConfig(
    aggregatorEndpoint: "https://aggregator.release-mainnet.api.mithril.network/aggregator",
    container: container
)
```

## Apple Container Runtime

Replace `.docker` with `.appleContainer` and ensure the `container` CLI is installed ([Apple Container](https://github.com/apple/container)). Start the daemon before running if it isn't already running:

```bash
container system start   # start the Apple Container virtualization service
container system status  # verify it is running
```

```swift
let container = ContainerConfig(
    runtime: .appleContainer,
    imageName: "ghcr.io/intersectmbo/cardano-node:10.0.0",
    containerName: "cardano-node",
    volumes: ["/data:/data", "/ipc:/ipc"],
    detach: true
)
```

## JSON Configuration

The `container` block can be nested inside any service config key. All keys use `snake_case`:

```json
{
  "cardano": {
    "socket": "/ipc/node.socket",
    "config": "/data/config/config.json",
    "network": "preview",
    "era": "conway",
    "ttl_buffer": 3600,
    "container": {
      "runtime": "docker",
      "image_name": "ghcr.io/intersectmbo/cardano-node:10.0.0",
      "container_name": "cardano-node",
      "volumes": ["/data:/data", "/ipc:/ipc"],
      "network": "host",
      "restart": "unless-stopped",
      "detach": true
    }
  },
  "ogmios": {
    "host": "0.0.0.0",
    "port": 1337,
    "container": {
      "runtime": "docker",
      "image_name": "cardanosolutions/ogmios:v6.13",
      "container_name": "ogmios",
      "ports": ["1337:1337"],
      "detach": true
    }
  },
  "kupo": {
    "host": "0.0.0.0",
    "port": 1442,
    "container": {
      "runtime": "docker",
      "image_name": "cardanosolutions/kupo:v2.10",
      "container_name": "kupo",
      "volumes": ["/data:/db", "/ipc:/ipc"],
      "ports": ["1442:1442"],
      "detach": true
    }
  }
}
```

## Pre-Flight Image Check

On initialisation, container-mode tools call ``ContainerChecks/checkImage(config:logger:)`` to verify the image exists locally before attempting to start. Pull images in advance:

```bash
# Docker
docker pull ghcr.io/intersectmbo/cardano-node:10.0.0
docker pull cardanosolutions/ogmios:v6.13
docker pull cardanosolutions/kupo:v2.10
docker pull ghcr.io/input-output-hk/mithril-client:latest

# Apple Container (start the service first if needed)
container system start
container pull ghcr.io/intersectmbo/cardano-node:10.0.0
container pull cardanosolutions/ogmios:v6.13
container pull cardanosolutions/kupo:v2.10
```

## Error Handling

```swift
do {
    let node = try await CardanoNode(configuration: configuration)
    try await node.start()
} catch SwiftCardanoUtilsError.binaryNotFound(let message) {
    // Image not found locally — pull it first
    print("Image missing: \(message)")
} catch SwiftCardanoUtilsError.configurationMissing(let message) {
    // containerName missing in exec mode, or runtime/image_name absent in config
    print("Configuration error: \(message)")
} catch SwiftCardanoUtilsError.commandFailed(let cmd, let message) {
    // docker/container CLI invocation failed
    print("Container command failed [\(cmd.joined(separator: " "))]: \(message)")
}
```

## Topics

### Container Configuration

- ``ContainerConfig``
- ``ContainerRuntime``

### Container Execution

- ``ContainerizedCommandRunner``
- ``ContainerChecks``
