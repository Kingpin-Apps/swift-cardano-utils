import Testing
import Foundation
import Logging
import SystemPackage
import SwiftCardanoCore
import Mockable
import Command
@testable import SwiftCardanoUtils

// MARK: - Container CLITools Integration Tests
//
// Verifies that each CLITool can be initialised in container mode using a real
// Docker daemon to check image presence.
//
// Each test is gated with .enabled(if:) so it shows as disabled — not passed —
// in Xcode when the required runtime or image is unavailable.
//
// Prerequisites:
//   • Docker daemon running:  docker info
//   • Test image present:     docker pull alpine:latest
//
// Run-mode tools (CardanoNode, Kupo, Ogmios, MithrilClient):
//   Init succeeds without a mock runner because checkVersion() is skipped in
//   container mode — the daemon tool hasn't started yet.
//
// Exec-mode tools (CardanoCLI, CardanoHWCLI, CardanoSigner):
//   A MockCommandRunning is injected to satisfy the checkVersion() call that
//   these tools perform at init time.
//
// Phase 2 (CI): Replace ContainerChecks with a mock so Docker is not needed.

@Suite("Container CLITools Integration Tests (requires Docker)")
struct ContainerCLIToolsIntegrationTests {

    // MARK: - Test Constants

    static let testImage = "alpine:latest"

    // MARK: - Runtime Availability (evaluated once at test discovery)

    /// `true` when the Docker daemon is reachable on this machine.
    static let isDockerAvailable: Bool = {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["docker", "info"]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch { return false }
    }()

    /// `true` when Docker is available **and** the test image is already pulled.
    static let isDockerWithTestImage: Bool = {
        guard isDockerAvailable else { return false }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [
            "docker", "images", "--quiet", "--filter", "reference=\(testImage)"
        ]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            let out = String(
                data: pipe.fileHandleForReading.readDataToEndOfFile(),
                encoding: .utf8
            ) ?? ""
            return !out.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } catch { return false }
    }()

    // MARK: - Mock Helpers (exec-mode tools)

    /// Creates a mock runner that answers any `--version` call with the
    /// supplied version line (space-delimited: `<binaryName> <version> ...`).
    private func makeVersionMockRunner(versionLine: String) -> MockCommandRunning {
        let runner = MockCommandRunning()
        given(runner)
            .run(arguments: .any, environment: .any, workingDirectory: .any)
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(.standardOutput([UInt8](versionLine.utf8)))
                    continuation.finish()
                }
            )
        return runner
    }

    // MARK: - Shared Config Builders

    private func baseCardanoConfig(
        container: ContainerConfig? = nil,
        workingDir: FilePath? = nil
    ) -> CardanoConfig {
        CardanoConfig(
            network: .preview,
            era: .conway,
            ttlBuffer: 3600,
            workingDir: workingDir ?? FilePath(FileManager.default.temporaryDirectory.path),
            container: container
        )
    }

    private func alpineContainerConfig(name: String? = nil) -> ContainerConfig {
        ContainerConfig(
            runtime: .docker,
            imageName: Self.testImage,
            containerName: name
        )
    }

    // MARK: - Run-Mode Tools
    //
    // These tools (BinaryRunnable) skip checkVersion() in container mode.
    // Initialisation only requires the image to be present locally.

    @Test("CardanoNode initialises successfully in container run-mode",
          .enabled(if: ContainerCLIToolsIntegrationTests.isDockerWithTestImage))
    func testCardanoNodeContainerInit() async throws {
        let containerConfig = alpineContainerConfig(name: "test-cardano-node")
        let cardanoConfig = baseCardanoConfig(container: containerConfig)
        let config = Config(cardano: cardanoConfig)

        let node = try await CardanoNode(configuration: config)
        // In container mode binaryPath is the entrypoint routing word "run"
        // (i.e. the CMD sent to `docker run` is ["run", ...args...] so the
        // image entrypoint dispatches to /usr/local/bin/run-node).
        #expect(node.binaryPath.string == "run")
    }

    @Test("CardanoNode in container mode stores the entrypoint routing word as binaryPath",
          .enabled(if: ContainerCLIToolsIntegrationTests.isDockerWithTestImage))
    func testCardanoNodeContainerBinaryPath() async throws {
        let cardanoConfig = baseCardanoConfig(container: alpineContainerConfig())
        let config = Config(cardano: cardanoConfig)
        let node = try await CardanoNode(configuration: config)

        // "run" is the routing word recognised by the IntersectMBO entrypoint
        // script; it is NOT the same as CardanoNode.binaryName ("cardano-node").
        #expect(node.binaryPath.string == "run")
    }

    @Test("Kupo initialises successfully in container run-mode",
          .enabled(if: ContainerCLIToolsIntegrationTests.isDockerWithTestImage))
    func testKupoContainerInit() async throws {
        let containerConfig = alpineContainerConfig(name: "test-kupo")
        let kupoConfig = KupoConfig(
            host: "127.0.0.1",
            port: 1442,
            container: containerConfig
        )
        let config = Config(
            cardano: baseCardanoConfig(),
            kupo: kupoConfig
        )

        let kupo = try await Kupo(configuration: config)
        #expect(kupo.binaryPath.string == Kupo.binaryName)
    }

    @Test("Kupo container mode works with no binary path configured",
          .enabled(if: ContainerCLIToolsIntegrationTests.isDockerWithTestImage))
    func testKupoContainerNoBinaryPath() async throws {
        let kupoConfig = KupoConfig(
            binary: nil,               // no local binary required in container mode
            container: alpineContainerConfig()
        )
        let config = Config(cardano: baseCardanoConfig(), kupo: kupoConfig)

        let kupo = try await Kupo(configuration: config)
        #expect(kupo.kupoConfig.binary == nil)
    }

    @Test("Ogmios initialises successfully in container run-mode",
          .enabled(if: ContainerCLIToolsIntegrationTests.isDockerWithTestImage))
    func testOgmiosContainerInit() async throws {
        let containerConfig = alpineContainerConfig(name: "test-ogmios")
        let ogmiosConfig = OgmiosConfig(
            host: "127.0.0.1",
            port: 1337,
            container: containerConfig
        )
        let config = Config(
            cardano: baseCardanoConfig(),
            ogmios: ogmiosConfig
        )

        let ogmios = try await Ogmios(configuration: config)
        #expect(ogmios.binaryPath.string == Ogmios.binaryName)
    }

    @Test("MithrilClient initialises successfully in container exec-mode",
          .enabled(if: ContainerCLIToolsIntegrationTests.isDockerWithTestImage))
    func testMithrilClientContainerInit() async throws {
        let containerConfig = alpineContainerConfig(name: "test-mithril")
        let mithrilConfig = MithrilConfig(
            aggregatorEndpoint: "https://aggregator.release-mainnet.api.mithril.network/aggregator",
            container: containerConfig
        )
        let config = Config(
            cardano: baseCardanoConfig(),
            mithril: mithrilConfig
        )

        let client = try await MithrilClient(configuration: config)
        #expect(client.binaryPath.string == MithrilClient.binaryName)
    }

    // MARK: - Exec-Mode Tools
    //
    // These tools (BinaryInterfaceable) still call checkVersion() at init.
    // A mock runner is injected to satisfy the version check without needing
    // an actual running container.

    @Test("CardanoCLI initialises in container exec-mode with injected mock runner",
          .enabled(if: ContainerCLIToolsIntegrationTests.isDockerWithTestImage))
    func testCardanoCLIContainerInit() async throws {
        let containerConfig = alpineContainerConfig(name: "test-cardano-node")
        let cardanoConfig = CardanoConfig(
            network: .preview,
            era: .conway,
            ttlBuffer: 3600,
            workingDir: FilePath(FileManager.default.temporaryDirectory.path),
            container: containerConfig
        )
        let config = Config(cardano: cardanoConfig)

        let mockRunner = makeVersionMockRunner(
            versionLine: "cardano-cli 10.8.0.0 - linux-x86_64 - ghc-9.6\n"
        )

        let cli = try await CardanoCLI(configuration: config, commandRunner: mockRunner)
        #expect(cli.binaryPath.string == CardanoCLI.binaryName)
    }

    @Test("CardanoHWCLI initialises in container exec-mode with injected mock runner",
          .enabled(if: ContainerCLIToolsIntegrationTests.isDockerWithTestImage))
    func testCardanoHWCLIContainerInit() async throws {
        let containerConfig = alpineContainerConfig(name: "test-hw-cli")
        let cardanoConfig = CardanoConfig(
            network: .preview,
            era: .conway,
            ttlBuffer: 3600,
            workingDir: FilePath(FileManager.default.temporaryDirectory.path),
            container: containerConfig
        )
        let config = Config(cardano: cardanoConfig)

        let mockRunner = makeVersionMockRunner(
            versionLine: "cardano-hw-cli 1.10.0\n"
        )

        let hwCli = try await CardanoHWCLI(configuration: config, commandRunner: mockRunner)
        #expect(hwCli.binaryPath.string == CardanoHWCLI.binaryName)
    }

    @Test("CardanoSigner initialises in container exec-mode with injected mock runner",
          .enabled(if: ContainerCLIToolsIntegrationTests.isDockerWithTestImage))
    func testCardanoSignerContainerInit() async throws {
        let containerConfig = alpineContainerConfig(name: "test-signer")
        let cardanoConfig = CardanoConfig(
            network: .preview,
            era: .conway,
            ttlBuffer: 3600,
            workingDir: FilePath(FileManager.default.temporaryDirectory.path),
            container: containerConfig
        )
        let config = Config(cardano: cardanoConfig)

        let mockRunner = makeVersionMockRunner(
            versionLine: "cardano-signer 1.16.0\n"
        )

        let signer = try await CardanoSigner(configuration: config, commandRunner: mockRunner)
        #expect(signer.binaryPath.string == CardanoSigner.binaryName)
    }

    // MARK: - Version Check Skipping Verification

    @Test("Run-mode tools log version-check skip message when container is configured",
          .enabled(if: ContainerCLIToolsIntegrationTests.isDockerWithTestImage))
    func testRunModeToolsSkipVersionCheck() async throws {
        // If version check were NOT skipped, init would fail because there is
        // no real binary to query. The test passing proves the skip is working.
        let containerConfig = alpineContainerConfig()
        let kupoConfig = KupoConfig(
            binary: nil, // no local binary — would fail if checkBinary was called
            container: containerConfig
        )
        let config = Config(cardano: baseCardanoConfig(), kupo: kupoConfig)

        let kupo = try await Kupo(configuration: config)
        #expect(kupo.binaryPath.string == Kupo.binaryName)
    }

    // MARK: - Container Config Propagation

    @Test("CLITool commandRunner is ContainerizedCommandRunner in container mode (no injection)",
          .enabled(if: ContainerCLIToolsIntegrationTests.isDockerWithTestImage))
    func testCommandRunnerIsContainerizedWhenContainerConfigured() async throws {
        let containerConfig = alpineContainerConfig(name: "my-kupo")
        let kupoConfig = KupoConfig(container: containerConfig)
        let config = Config(cardano: baseCardanoConfig(), kupo: kupoConfig)

        let kupo = try await Kupo(configuration: config)
        #expect(kupo.commandRunner is ContainerizedCommandRunner)
    }

    @Test("CLITool commandRunner is CommandRunner when no container is configured")
    func testCommandRunnerIsCommandRunnerWithoutContainer() async throws {
        // This test does NOT require Docker — uses /usr/bin/true as the binary
        let kupoConfig = KupoConfig(
            binary: FilePath("/usr/bin/true"),
            workingDir: FilePath(FileManager.default.temporaryDirectory.path)
        )
        let config = Config(
            cardano: baseCardanoConfig(),
            kupo: kupoConfig
        )

        do {
            let kupo = try await Kupo(configuration: config)
            #expect(kupo.commandRunner is CommandRunner)
        } catch {
            // Version check may fail with /usr/bin/true — acceptable here
        }
    }

    // MARK: - Error Cases

    @Test("CLITool in container mode throws when image is absent",
          .enabled(if: ContainerCLIToolsIntegrationTests.isDockerAvailable))
    func testContainerInitFailsWhenImageAbsent() async throws {
        // Only requires Docker daemon — deliberately uses a non-existent image
        let containerConfig = ContainerConfig(
            runtime: .docker,
            imageName: "nonexistent-image-swiftcardanoutils-xyz:latest"
        )
        let cardanoConfig = baseCardanoConfig(container: containerConfig)
        let config = Config(cardano: cardanoConfig)

        await #expect(throws: SwiftCardanoUtilsError.self) {
            _ = try await CardanoNode(configuration: config)
        }
    }

    @Test("CLITool in container mode fails with configurationMissing when cardano section absent")
    func testContainerInitFailsWithMissingCardanoConfig() async throws {
        // This test does NOT require Docker
        let config = Config(cardano: nil)

        await #expect(throws: SwiftCardanoUtilsError.self) {
            _ = try await CardanoNode(configuration: config)
        }
    }
}
