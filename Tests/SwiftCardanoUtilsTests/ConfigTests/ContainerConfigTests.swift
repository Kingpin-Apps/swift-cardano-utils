import Testing
import Foundation
import SystemPackage
import SwiftCardanoCore
@testable import SwiftCardanoUtils

// MARK: - ContainerConfig Tests

@Suite("ContainerConfig Tests")
struct ContainerConfigTests {

    // MARK: - Helpers

    private func makeMinimalConfig() -> ContainerConfig {
        ContainerConfig(runtime: .docker, imageName: "alpine:latest")
    }

    private func makeFullConfig() -> ContainerConfig {
        ContainerConfig(
            runtime: .docker,
            imageName: "ghcr.io/intersectmbo/cardano-node:10.0.0",
            containerName: "my-node",
            volumes: ["/data:/data", "/ipc:/ipc"],
            environment: ["NETWORK=mainnet", "CARDANO_NODE_SOCKET_PATH=/ipc/socket"],
            ports: ["3001:3001"],
            network: "host",
            restart: "unless-stopped",
            workingDir: "/app",
            user: "1000:1000",
            hostname: "cardano-node",
            privileged: false,
            removeOnExit: false,
            detach: true,
            entrypoint: "/usr/local/bin/entrypoint.sh",
            platform: "linux/amd64",
            memory: "4g",
            cpus: "2.0",
            capAdd: ["NET_ADMIN"],
            capDrop: ["ALL"],
            readOnly: false,
            logDriver: "json-file",
            logOptions: ["max-size=100m", "max-file=3"],
            labels: ["service=cardano-node", "env=mainnet"]
        )
    }

    // MARK: - ContainerRuntime Tests

    @Test("ContainerRuntime.docker executable is 'docker'")
    func testDockerExecutable() {
        #expect(ContainerRuntime.docker.executable == "docker")
        #expect(ContainerRuntime.docker.rawValue == "docker")
    }

    @Test("ContainerRuntime.appleContainer executable is 'container'")
    func testAppleContainerExecutable() {
        #expect(ContainerRuntime.appleContainer.executable == "container")
        #expect(ContainerRuntime.appleContainer.rawValue == "container")
    }

    @Test("ContainerRuntime allCases contains both runtimes")
    func testAllCases() {
        #expect(ContainerRuntime.allCases.count == 2)
        #expect(ContainerRuntime.allCases.contains(.docker))
        #expect(ContainerRuntime.allCases.contains(.appleContainer))
    }

    @Test("ContainerRuntime is Codable — docker encodes to 'docker'")
    func testDockerCodable() throws {
        let data = try JSONEncoder().encode(ContainerRuntime.docker)
        let json = String(data: data, encoding: .utf8)!
        #expect(json == "\"docker\"")
        let decoded = try JSONDecoder().decode(ContainerRuntime.self, from: data)
        #expect(decoded == .docker)
    }

    @Test("ContainerRuntime is Codable — appleContainer encodes to 'container'")
    func testAppleContainerCodable() throws {
        let data = try JSONEncoder().encode(ContainerRuntime.appleContainer)
        let json = String(data: data, encoding: .utf8)!
        #expect(json == "\"container\"")
        let decoded = try JSONDecoder().decode(ContainerRuntime.self, from: data)
        #expect(decoded == .appleContainer)
    }

    @Test("ContainerRuntime rejects unknown raw values")
    func testUnknownRuntimeRejected() {
        #expect(ContainerRuntime(rawValue: "podman") == nil)
        #expect(ContainerRuntime(rawValue: "") == nil)
    }

    // MARK: - ContainerConfig Initialization Tests

    @Test("ContainerConfig initializes with minimal parameters (imageName only)")
    func testMinimalInit() {
        let config = makeMinimalConfig()

        #expect(config.runtime == .docker)
        #expect(config.imageName == "alpine:latest")
        #expect(config.containerName == nil)
        #expect(config.volumes == nil)
        #expect(config.environment == nil)
        #expect(config.ports == nil)
        #expect(config.network == nil)
        #expect(config.restart == nil)
        #expect(config.workingDir == nil)
        #expect(config.user == nil)
        #expect(config.hostname == nil)
        #expect(config.privileged == nil)
        #expect(config.removeOnExit == nil)
        #expect(config.detach == nil)
        #expect(config.entrypoint == nil)
        #expect(config.platform == nil)
        #expect(config.memory == nil)
        #expect(config.cpus == nil)
        #expect(config.capAdd == nil)
        #expect(config.capDrop == nil)
        #expect(config.readOnly == nil)
        #expect(config.logDriver == nil)
        #expect(config.logOptions == nil)
        #expect(config.labels == nil)
    }

    @Test("ContainerConfig initializes with all parameters")
    func testFullInit() {
        let config = makeFullConfig()

        #expect(config.runtime == .docker)
        #expect(config.imageName == "ghcr.io/intersectmbo/cardano-node:10.0.0")
        #expect(config.containerName == "my-node")
        #expect(config.volumes == ["/data:/data", "/ipc:/ipc"])
        #expect(config.environment == ["NETWORK=mainnet", "CARDANO_NODE_SOCKET_PATH=/ipc/socket"])
        #expect(config.ports == ["3001:3001"])
        #expect(config.network == "host")
        #expect(config.restart == "unless-stopped")
        #expect(config.workingDir == "/app")
        #expect(config.user == "1000:1000")
        #expect(config.hostname == "cardano-node")
        #expect(config.privileged == false)
        #expect(config.removeOnExit == false)
        #expect(config.detach == true)
        #expect(config.entrypoint == "/usr/local/bin/entrypoint.sh")
        #expect(config.platform == "linux/amd64")
        #expect(config.memory == "4g")
        #expect(config.cpus == "2.0")
        #expect(config.capAdd == ["NET_ADMIN"])
        #expect(config.capDrop == ["ALL"])
        #expect(config.readOnly == false)
        #expect(config.logDriver == "json-file")
        #expect(config.logOptions == ["max-size=100m", "max-file=3"])
        #expect(config.labels == ["service=cardano-node", "env=mainnet"])
    }

    @Test("ContainerConfig runtime defaults to .docker")
    func testDefaultRuntime() {
        let config = ContainerConfig(imageName: "alpine:latest")
        #expect(config.runtime == .docker)
    }

    @Test("ContainerConfig supports Apple Container runtime")
    func testAppleContainerRuntimeInit() {
        let config = ContainerConfig(runtime: .appleContainer, imageName: "alpine:latest")
        #expect(config.runtime == .appleContainer)
        #expect(config.runtime.executable == "container")
    }

    // MARK: - JSON Encoding Tests

    @Test("ContainerConfig encodes with snake_case keys for multi-word fields")
    func testJSONEncodingSnakeCaseKeys() throws {
        let config = makeFullConfig()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(config)
        let json = String(data: data, encoding: .utf8)!

        #expect(json.contains("\"image_name\""))
        #expect(json.contains("\"container_name\""))
        #expect(json.contains("\"working_dir\""))
        #expect(json.contains("\"remove_on_exit\""))
        #expect(json.contains("\"cap_add\""))
        #expect(json.contains("\"cap_drop\""))
        #expect(json.contains("\"read_only\""))
        #expect(json.contains("\"log_driver\""))
        #expect(json.contains("\"log_options\""))

        // camelCase should NOT appear as keys
        #expect(!json.contains("\"imageName\""))
        #expect(!json.contains("\"containerName\""))
        #expect(!json.contains("\"workingDir\""))
    }

    @Test("ContainerConfig encodes imageName value correctly")
    func testJSONEncodingImageNameValue() throws {
        let config = ContainerConfig(
            runtime: .docker,
            imageName: "ghcr.io/intersectmbo/cardano-node:10.0.0"
        )
        let data = try JSONEncoder().encode(config)
        // JSONEncoder may escape forward slashes as \/; normalise before checking.
        let json = String(data: data, encoding: .utf8)!.replacingOccurrences(of: "\\/", with: "/")
        #expect(json.contains("ghcr.io/intersectmbo/cardano-node:10.0.0"))
    }

    @Test("ContainerConfig round-trips through JSON encoding/decoding")
    func testJSONRoundTrip() throws {
        let original = makeFullConfig()
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ContainerConfig.self, from: data)

        #expect(decoded.runtime == original.runtime)
        #expect(decoded.imageName == original.imageName)
        #expect(decoded.containerName == original.containerName)
        #expect(decoded.volumes == original.volumes)
        #expect(decoded.environment == original.environment)
        #expect(decoded.ports == original.ports)
        #expect(decoded.network == original.network)
        #expect(decoded.restart == original.restart)
        #expect(decoded.workingDir == original.workingDir)
        #expect(decoded.user == original.user)
        #expect(decoded.hostname == original.hostname)
        #expect(decoded.privileged == original.privileged)
        #expect(decoded.removeOnExit == original.removeOnExit)
        #expect(decoded.detach == original.detach)
        #expect(decoded.entrypoint == original.entrypoint)
        #expect(decoded.platform == original.platform)
        #expect(decoded.memory == original.memory)
        #expect(decoded.cpus == original.cpus)
        #expect(decoded.capAdd == original.capAdd)
        #expect(decoded.capDrop == original.capDrop)
        #expect(decoded.readOnly == original.readOnly)
        #expect(decoded.logDriver == original.logDriver)
        #expect(decoded.logOptions == original.logOptions)
        #expect(decoded.labels == original.labels)
    }

    @Test("ContainerConfig with nil optionals round-trips cleanly")
    func testMinimalJSONRoundTrip() throws {
        let original = makeMinimalConfig()
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ContainerConfig.self, from: data)

        #expect(decoded.runtime == original.runtime)
        #expect(decoded.imageName == original.imageName)
        #expect(decoded.containerName == nil)
        #expect(decoded.volumes == nil)
        #expect(decoded.environment == nil)
        #expect(decoded.detach == nil)
    }

    @Test("ContainerConfig decodes docker runtime from JSON string 'docker'")
    func testDecodeDockerRuntime() throws {
        let json = """
        {"runtime":"docker","image_name":"alpine:latest"}
        """.data(using: .utf8)!
        let config = try JSONDecoder().decode(ContainerConfig.self, from: json)
        #expect(config.runtime == .docker)
        #expect(config.imageName == "alpine:latest")
    }

    @Test("ContainerConfig decodes apple container runtime from JSON string 'container'")
    func testDecodeAppleContainerRuntime() throws {
        let json = """
        {"runtime":"container","image_name":"alpine:latest"}
        """.data(using: .utf8)!
        let config = try JSONDecoder().decode(ContainerConfig.self, from: json)
        #expect(config.runtime == .appleContainer)
    }

    @Test("ContainerConfig decode fails for unknown runtime string")
    func testDecodeUnknownRuntimeFails() {
        let json = """
        {"runtime":"podman","image_name":"alpine:latest"}
        """.data(using: .utf8)!
        #expect(throws: Error.self) {
            _ = try JSONDecoder().decode(ContainerConfig.self, from: json)
        }
    }

    // MARK: - Service Config Container Field Tests

    @Test("CardanoConfig encodes container field when set")
    func testCardanoConfigContainerJSONEncoding() throws {
        let container = ContainerConfig(
            runtime: .docker,
            imageName: "ghcr.io/intersectmbo/cardano-node:10.0.0",
            containerName: "cardano-node"
        )
        let config = CardanoConfig(
            network: .preview,
            era: .conway,
            ttlBuffer: 3600,
            container: container
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(config)
        // JSONEncoder may escape forward slashes as \/; normalise before checking.
        let json = String(data: data, encoding: .utf8)!.replacingOccurrences(of: "\\/", with: "/")

        #expect(json.contains("\"container\""))
        #expect(json.contains("\"image_name\""))
        #expect(json.contains("ghcr.io/intersectmbo/cardano-node:10.0.0"))
    }

    @Test("CardanoConfig round-trips container through JSON")
    func testCardanoConfigContainerRoundTrip() throws {
        let container = ContainerConfig(
            runtime: .docker,
            imageName: "ghcr.io/intersectmbo/cardano-node:10.0.0",
            containerName: "cardano-node",
            volumes: ["/ipc:/ipc", "/data:/data"]
        )
        let original = CardanoConfig(
            network: .preview,
            era: .conway,
            ttlBuffer: 3600,
            container: container
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CardanoConfig.self, from: data)

        #expect(decoded.container != nil)
        #expect(decoded.container?.runtime == .docker)
        #expect(decoded.container?.imageName == "ghcr.io/intersectmbo/cardano-node:10.0.0")
        #expect(decoded.container?.containerName == "cardano-node")
        #expect(decoded.container?.volumes == ["/ipc:/ipc", "/data:/data"])
    }

    @Test("CardanoConfig round-trips with nil container")
    func testCardanoConfigNilContainerRoundTrip() throws {
        let original = CardanoConfig(network: .preview, era: .conway, ttlBuffer: 3600)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CardanoConfig.self, from: data)
        #expect(decoded.container == nil)
    }

    @Test("KupoConfig round-trips container through JSON")
    func testKupoConfigContainerRoundTrip() throws {
        let container = ContainerConfig(
            runtime: .docker,
            imageName: "cardanosolutions/kupo:v2.10",
            containerName: "kupo",
            ports: ["1442:1442"]
        )
        let original = KupoConfig(
            host: "0.0.0.0",
            port: 1442,
            container: container
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(KupoConfig.self, from: data)

        #expect(decoded.container != nil)
        #expect(decoded.container?.imageName == "cardanosolutions/kupo:v2.10")
        #expect(decoded.container?.ports == ["1442:1442"])
        #expect(decoded.binary == nil)
    }

    @Test("OgmiosConfig round-trips container through JSON")
    func testOgmiosConfigContainerRoundTrip() throws {
        let container = ContainerConfig(
            runtime: .docker,
            imageName: "cardanosolutions/ogmios:v6.13",
            containerName: "ogmios",
            ports: ["1337:1337"]
        )
        let original = OgmiosConfig(
            host: "0.0.0.0",
            port: 1337,
            container: container
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(OgmiosConfig.self, from: data)

        #expect(decoded.container != nil)
        #expect(decoded.container?.imageName == "cardanosolutions/ogmios:v6.13")
        #expect(decoded.binary == nil)
    }

    @Test("MithrilConfig round-trips container through JSON")
    func testMithrilConfigContainerRoundTrip() throws {
        let container = ContainerConfig(
            runtime: .docker,
            imageName: "ghcr.io/input-output-hk/mithril-client:latest",
            containerName: "mithril-client"
        )
        let original = MithrilConfig(
            aggregatorEndpoint: "https://aggregator.release-mainnet.api.mithril.network/aggregator",
            container: container
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MithrilConfig.self, from: data)

        #expect(decoded.container != nil)
        #expect(decoded.container?.imageName == "ghcr.io/input-output-hk/mithril-client:latest")
        #expect(decoded.binary == nil)
    }
}
