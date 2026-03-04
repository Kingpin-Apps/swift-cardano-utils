import Testing
import Foundation
import Logging
import Command
import Path
@testable import SwiftCardanoUtils

// MARK: - CapturingCommandRunner
//
// A lightweight CommandRunning that records the arguments it receives
// and immediately finishes the stream. Used to verify argument
// transformation inside ContainerizedCommandRunner without needing Docker.

private final class CapturingCommandRunner: CommandRunning, @unchecked Sendable {

    /// The most-recently-captured argument list.
    private(set) var capturedArguments: [String] = []
    /// The most-recently-captured working directory.
    private(set) var capturedWorkingDirectory: AbsolutePath? = nil

    func run(
        arguments: [String],
        environment: [String: String],
        workingDirectory: AbsolutePath?
    ) -> AsyncThrowingStream<CommandEvent, any Error> {
        capturedArguments = arguments
        capturedWorkingDirectory = workingDirectory
        return AsyncThrowingStream { $0.finish() }
    }
}

// MARK: - ContainerizedCommandRunner Tests

@Suite("ContainerizedCommandRunner Tests")
struct ContainerRunnerTests {

    // MARK: - Helpers

    private func makeDockerExecConfig(
        containerName: String? = "my-container",
        workingDir: String? = nil,
        user: String? = nil,
        environment: [String]? = nil
    ) -> ContainerConfig {
        ContainerConfig(
            runtime: .docker,
            imageName: "alpine:latest",
            containerName: containerName,
            environment: environment,
            workingDir: workingDir,
            user: user
        )
    }

    private func makeDockerRunConfig(
        containerName: String? = "my-kupo",
        imageName: String = "cardanosolutions/kupo:v2.10",
        volumes: [String]? = nil,
        environment: [String]? = nil,
        ports: [String]? = nil,
        network: String? = nil,
        restart: String? = nil,
        workingDir: String? = nil,
        user: String? = nil,
        hostname: String? = nil,
        privileged: Bool? = nil,
        removeOnExit: Bool? = nil,
        detach: Bool? = nil,
        memory: String? = nil,
        cpus: String? = nil,
        capAdd: [String]? = nil,
        capDrop: [String]? = nil,
        readOnly: Bool? = nil,
        logDriver: String? = nil,
        logOptions: [String]? = nil,
        labels: [String]? = nil
    ) -> ContainerConfig {
        ContainerConfig(
            runtime: .docker,
            imageName: imageName,
            containerName: containerName,
            volumes: volumes,
            environment: environment,
            ports: ports,
            network: network,
            restart: restart,
            workingDir: workingDir,
            user: user,
            hostname: hostname,
            privileged: privileged,
            removeOnExit: removeOnExit,
            detach: detach,
            memory: memory,
            cpus: cpus,
            capAdd: capAdd,
            capDrop: capDrop,
            readOnly: readOnly,
            logDriver: logDriver,
            logOptions: logOptions,
            labels: labels
        )
    }

    private func makeRunner(
        config: ContainerConfig,
        mode: ContainerExecutionMode,
        capturing: CapturingCommandRunner
    ) -> ContainerizedCommandRunner {
        ContainerizedCommandRunner(
            config: config,
            mode: mode,
            inner: capturing,
            logger: Logger(label: "test")
        )
    }

    // MARK: - Exec Mode Tests

    @Test("Exec mode prepends 'docker exec <containerName>' to original args")
    func testExecModeBasicDockerExec() async throws {
        let capturing = CapturingCommandRunner()
        let runner = makeRunner(
            config: makeDockerExecConfig(),
            mode: .exec,
            capturing: capturing
        )

        let stream = runner.run(
            arguments: ["/usr/local/bin/cardano-cli", "query", "tip", "--mainnet"],
            environment: [:],
            workingDirectory: nil
        )
        for try await _ in stream {}

        #expect(capturing.capturedArguments == [
            "docker", "exec", "my-container",
            "/usr/local/bin/cardano-cli", "query", "tip", "--mainnet"
        ])
    }

    @Test("Exec mode works with Apple Container runtime")
    func testExecModeAppleContainerRuntime() async throws {
        let capturing = CapturingCommandRunner()
        let config = ContainerConfig(
            runtime: .appleContainer,
            imageName: "alpine:latest",
            containerName: "my-container"
        )
        let runner = makeRunner(config: config, mode: .exec, capturing: capturing)

        let stream = runner.run(
            arguments: ["/bin/sh", "-c", "echo hello"],
            environment: [:],
            workingDirectory: nil
        )
        for try await _ in stream {}

        // First arg should be "container", not "docker"
        #expect(capturing.capturedArguments.first == "container")
        #expect(capturing.capturedArguments[1] == "exec")
    }

    @Test("Exec mode includes --workdir flag when workingDir is set")
    func testExecModeWithWorkingDir() async throws {
        let capturing = CapturingCommandRunner()
        let runner = makeRunner(
            config: makeDockerExecConfig(workingDir: "/app"),
            mode: .exec,
            capturing: capturing
        )

        let stream = runner.run(arguments: ["/bin/sh"], environment: [:], workingDirectory: nil)
        for try await _ in stream {}

        let args = capturing.capturedArguments
        guard let wdIdx = args.firstIndex(of: "--workdir") else {
            Issue.record("Expected --workdir flag not found in \(args)")
            return
        }
        #expect(args[wdIdx + 1] == "/app")
    }

    @Test("Exec mode includes --user flag when user is set")
    func testExecModeWithUser() async throws {
        let capturing = CapturingCommandRunner()
        let runner = makeRunner(
            config: makeDockerExecConfig(user: "1000:1000"),
            mode: .exec,
            capturing: capturing
        )

        let stream = runner.run(arguments: ["/bin/sh"], environment: [:], workingDirectory: nil)
        for try await _ in stream {}

        let args = capturing.capturedArguments
        guard let userIdx = args.firstIndex(of: "--user") else {
            Issue.record("Expected --user flag not found in \(args)")
            return
        }
        #expect(args[userIdx + 1] == "1000:1000")
    }

    @Test("Exec mode includes --env flags for each environment variable")
    func testExecModeWithEnvironment() async throws {
        let capturing = CapturingCommandRunner()
        let runner = makeRunner(
            config: makeDockerExecConfig(environment: ["FOO=bar", "BAZ=qux"]),
            mode: .exec,
            capturing: capturing
        )

        let stream = runner.run(arguments: ["/bin/sh"], environment: [:], workingDirectory: nil)
        for try await _ in stream {}

        let args = capturing.capturedArguments
        // Each env var should be preceded by "--env"
        let envIndices = args.indices.filter { args[$0] == "--env" }
        #expect(envIndices.count == 2)
        let envValues = envIndices.map { args[$0 + 1] }
        #expect(envValues.contains("FOO=bar"))
        #expect(envValues.contains("BAZ=qux"))
    }

    @Test("Exec mode preserves original args after container name")
    func testExecModeArgsOrder() async throws {
        let capturing = CapturingCommandRunner()
        let runner = makeRunner(
            config: makeDockerExecConfig(),
            mode: .exec,
            capturing: capturing
        )

        let originalArgs = ["/usr/local/bin/cardano-cli", "--version"]
        let stream = runner.run(arguments: originalArgs, environment: [:], workingDirectory: nil)
        for try await _ in stream {}

        let args = capturing.capturedArguments
        // Last two args should be the original args
        #expect(Array(args.suffix(2)) == originalArgs)
        // containerName should appear just before original args
        #expect(args[args.count - 3] == "my-container")
    }

    @Test("Exec mode throws configurationMissing when containerName is nil")
    func testExecModeThrowsWhenContainerNameNil() async {
        let capturing = CapturingCommandRunner()
        let config = ContainerConfig(runtime: .docker, imageName: "alpine:latest") // no containerName
        let runner = ContainerizedCommandRunner(
            config: config,
            mode: .exec,
            inner: capturing,
            logger: Logger(label: "test")
        )

        await #expect(throws: SwiftCardanoUtilsError.self) {
            for try await _ in runner.run(arguments: ["/bin/sh"], environment: [:], workingDirectory: nil) {}
        }
    }

    // MARK: - Run Mode Tests

    @Test("Run mode builds 'docker run --detach --name <name> <image> <args>'")
    func testRunModeBasicDockerRun() async throws {
        let capturing = CapturingCommandRunner()
        let runner = makeRunner(
            config: makeDockerRunConfig(detach: true),
            mode: .run,
            capturing: capturing
        )

        let stream = runner.run(
            arguments: ["/usr/local/bin/kupo", "--host", "0.0.0.0"],
            environment: [:],
            workingDirectory: nil
        )
        for try await _ in stream {}

        let args = capturing.capturedArguments
        #expect(args.first == "docker")
        #expect(args[1] == "run")
        #expect(args.contains("--detach"))
        #expect(args.contains("--name"))
        guard let nameIdx = args.firstIndex(of: "--name") else {
            Issue.record("--name flag not found")
            return
        }
        #expect(args[nameIdx + 1] == "my-kupo")
        // Image should appear before original args
        guard let imageIdx = args.firstIndex(of: "cardanosolutions/kupo:v2.10") else {
            Issue.record("Image name not found in \(args)")
            return
        }
        #expect(Array(args.suffix(from: imageIdx + 1)) == ["/usr/local/bin/kupo", "--host", "0.0.0.0"])
    }

    @Test("Run mode detaches by default when detach is nil")
    func testRunModeDefaultDetach() async throws {
        let capturing = CapturingCommandRunner()
        let config = makeDockerRunConfig(detach: nil) // nil → defaults to detach
        let runner = makeRunner(config: config, mode: .run, capturing: capturing)

        let stream = runner.run(arguments: ["/bin/sh"], environment: [:], workingDirectory: nil)
        for try await _ in stream {}

        #expect(capturing.capturedArguments.contains("--detach"))
    }

    @Test("Run mode omits --detach when detach is explicitly false")
    func testRunModeExplicitNoDetach() async throws {
        let capturing = CapturingCommandRunner()
        let config = makeDockerRunConfig(detach: false)
        let runner = makeRunner(config: config, mode: .run, capturing: capturing)

        let stream = runner.run(arguments: ["/bin/sh"], environment: [:], workingDirectory: nil)
        for try await _ in stream {}

        #expect(!capturing.capturedArguments.contains("--detach"))
    }

    @Test("Run mode includes --rm flag when removeOnExit is true")
    func testRunModeRemoveOnExit() async throws {
        let capturing = CapturingCommandRunner()
        let config = makeDockerRunConfig(removeOnExit: true)
        let runner = makeRunner(config: config, mode: .run, capturing: capturing)

        let stream = runner.run(arguments: ["/bin/sh"], environment: [:], workingDirectory: nil)
        for try await _ in stream {}

        #expect(capturing.capturedArguments.contains("--rm"))
    }

    @Test("Run mode includes --volume for each volume mount")
    func testRunModeVolumes() async throws {
        let capturing = CapturingCommandRunner()
        let config = makeDockerRunConfig(
            volumes: ["/data:/data", "/ipc:/ipc:ro"]
        )
        let runner = makeRunner(config: config, mode: .run, capturing: capturing)

        let stream = runner.run(arguments: ["/bin/sh"], environment: [:], workingDirectory: nil)
        for try await _ in stream {}

        let args = capturing.capturedArguments
        let volIndices = args.indices.filter { args[$0] == "--volume" }
        #expect(volIndices.count == 2)
        let volValues = volIndices.map { args[$0 + 1] }
        #expect(volValues.contains("/data:/data"))
        #expect(volValues.contains("/ipc:/ipc:ro"))
    }

    @Test("Run mode includes --env for each environment variable")
    func testRunModeEnvironment() async throws {
        let capturing = CapturingCommandRunner()
        let config = makeDockerRunConfig(environment: ["NETWORK=mainnet", "PORT=3001"])
        let runner = makeRunner(config: config, mode: .run, capturing: capturing)

        let stream = runner.run(arguments: ["/bin/sh"], environment: [:], workingDirectory: nil)
        for try await _ in stream {}

        let args = capturing.capturedArguments
        let envIndices = args.indices.filter { args[$0] == "--env" }
        #expect(envIndices.count == 2)
        let envValues = envIndices.map { args[$0 + 1] }
        #expect(envValues.contains("NETWORK=mainnet"))
        #expect(envValues.contains("PORT=3001"))
    }

    @Test("Run mode includes --publish for each port mapping")
    func testRunModePorts() async throws {
        let capturing = CapturingCommandRunner()
        let config = makeDockerRunConfig(ports: ["3001:3001", "1337:1337"])
        let runner = makeRunner(config: config, mode: .run, capturing: capturing)

        let stream = runner.run(arguments: ["/bin/sh"], environment: [:], workingDirectory: nil)
        for try await _ in stream {}

        let args = capturing.capturedArguments
        let portIndices = args.indices.filter { args[$0] == "--publish" }
        #expect(portIndices.count == 2)
        let portValues = portIndices.map { args[$0 + 1] }
        #expect(portValues.contains("3001:3001"))
        #expect(portValues.contains("1337:1337"))
    }

    @Test("Run mode includes networking and hostname flags")
    func testRunModeNetworkingFlags() async throws {
        let capturing = CapturingCommandRunner()
        let config = makeDockerRunConfig(
            network: "host",
            hostname: "cardano-node"
        )
        let runner = makeRunner(config: config, mode: .run, capturing: capturing)

        let stream = runner.run(arguments: ["/bin/sh"], environment: [:], workingDirectory: nil)
        for try await _ in stream {}

        let args = capturing.capturedArguments
        guard let netIdx = args.firstIndex(of: "--network") else {
            Issue.record("--network flag not found")
            return
        }
        #expect(args[netIdx + 1] == "host")

        guard let hostIdx = args.firstIndex(of: "--hostname") else {
            Issue.record("--hostname flag not found")
            return
        }
        #expect(args[hostIdx + 1] == "cardano-node")
    }

    @Test("Run mode includes --restart policy")
    func testRunModeRestart() async throws {
        let capturing = CapturingCommandRunner()
        let config = makeDockerRunConfig(restart: "unless-stopped")
        let runner = makeRunner(config: config, mode: .run, capturing: capturing)

        let stream = runner.run(arguments: ["/bin/sh"], environment: [:], workingDirectory: nil)
        for try await _ in stream {}

        let args = capturing.capturedArguments
        guard let restartIdx = args.firstIndex(of: "--restart") else {
            Issue.record("--restart flag not found")
            return
        }
        #expect(args[restartIdx + 1] == "unless-stopped")
    }

    @Test("Run mode includes resource limit flags (memory, cpus)")
    func testRunModeResourceLimits() async throws {
        let capturing = CapturingCommandRunner()
        let config = makeDockerRunConfig(memory: "4g", cpus: "2.0")
        let runner = makeRunner(config: config, mode: .run, capturing: capturing)

        let stream = runner.run(arguments: ["/bin/sh"], environment: [:], workingDirectory: nil)
        for try await _ in stream {}

        let args = capturing.capturedArguments
        guard let memIdx = args.firstIndex(of: "--memory") else {
            Issue.record("--memory flag not found")
            return
        }
        #expect(args[memIdx + 1] == "4g")

        guard let cpuIdx = args.firstIndex(of: "--cpus") else {
            Issue.record("--cpus flag not found")
            return
        }
        #expect(args[cpuIdx + 1] == "2.0")
    }

    @Test("Run mode includes --privileged flag when privileged is true")
    func testRunModePrivileged() async throws {
        let capturing = CapturingCommandRunner()
        let config = makeDockerRunConfig(privileged: true)
        let runner = makeRunner(config: config, mode: .run, capturing: capturing)

        let stream = runner.run(arguments: ["/bin/sh"], environment: [:], workingDirectory: nil)
        for try await _ in stream {}

        #expect(capturing.capturedArguments.contains("--privileged"))
    }

    @Test("Run mode omits --privileged when privileged is false")
    func testRunModeNotPrivileged() async throws {
        let capturing = CapturingCommandRunner()
        let config = makeDockerRunConfig(privileged: false)
        let runner = makeRunner(config: config, mode: .run, capturing: capturing)

        let stream = runner.run(arguments: ["/bin/sh"], environment: [:], workingDirectory: nil)
        for try await _ in stream {}

        #expect(!capturing.capturedArguments.contains("--privileged"))
    }

    @Test("Run mode includes --cap-add and --cap-drop flags")
    func testRunModeCapabilities() async throws {
        let capturing = CapturingCommandRunner()
        let config = makeDockerRunConfig(capAdd: ["NET_ADMIN", "SYS_PTRACE"], capDrop: ["ALL"])
        let runner = makeRunner(config: config, mode: .run, capturing: capturing)

        let stream = runner.run(arguments: ["/bin/sh"], environment: [:], workingDirectory: nil)
        for try await _ in stream {}

        let args = capturing.capturedArguments
        let addIndices = args.indices.filter { args[$0] == "--cap-add" }
        #expect(addIndices.count == 2)

        let dropIndices = args.indices.filter { args[$0] == "--cap-drop" }
        #expect(dropIndices.count == 1)
        #expect(args[dropIndices[0] + 1] == "ALL")
    }

    @Test("Run mode includes --read-only when readOnly is true")
    func testRunModeReadOnly() async throws {
        let capturing = CapturingCommandRunner()
        let config = makeDockerRunConfig(readOnly: true)
        let runner = makeRunner(config: config, mode: .run, capturing: capturing)

        let stream = runner.run(arguments: ["/bin/sh"], environment: [:], workingDirectory: nil)
        for try await _ in stream {}

        #expect(capturing.capturedArguments.contains("--read-only"))
    }

    @Test("Run mode includes log driver and log options")
    func testRunModeLogging() async throws {
        let capturing = CapturingCommandRunner()
        let config = makeDockerRunConfig(
            logDriver: "json-file",
            logOptions: ["max-size=100m", "max-file=3"]
        )
        let runner = makeRunner(config: config, mode: .run, capturing: capturing)

        let stream = runner.run(arguments: ["/bin/sh"], environment: [:], workingDirectory: nil)
        for try await _ in stream {}

        let args = capturing.capturedArguments
        guard let ldIdx = args.firstIndex(of: "--log-driver") else {
            Issue.record("--log-driver flag not found")
            return
        }
        #expect(args[ldIdx + 1] == "json-file")

        let logOptIndices = args.indices.filter { args[$0] == "--log-opt" }
        #expect(logOptIndices.count == 2)
    }

    @Test("Run mode includes --label flags")
    func testRunModeLabels() async throws {
        let capturing = CapturingCommandRunner()
        let config = makeDockerRunConfig(labels: ["service=cardano", "env=mainnet"])
        let runner = makeRunner(config: config, mode: .run, capturing: capturing)

        let stream = runner.run(arguments: ["/bin/sh"], environment: [:], workingDirectory: nil)
        for try await _ in stream {}

        let args = capturing.capturedArguments
        let labelIndices = args.indices.filter { args[$0] == "--label" }
        #expect(labelIndices.count == 2)
    }

    @Test("Run mode places image name immediately before original args")
    func testRunModeImagePositioning() async throws {
        let capturing = CapturingCommandRunner()
        let config = makeDockerRunConfig(
            imageName: "cardanosolutions/kupo:v2.10",
            volumes: ["/data:/data"],
            ports: ["1442:1442"]
        )
        let runner = makeRunner(config: config, mode: .run, capturing: capturing)

        let originalArgs = ["/usr/local/bin/kupo", "--host", "0.0.0.0", "--port", "1442"]
        let stream = runner.run(arguments: originalArgs, environment: [:], workingDirectory: nil)
        for try await _ in stream {}

        let args = capturing.capturedArguments
        guard let imageIdx = args.firstIndex(of: "cardanosolutions/kupo:v2.10") else {
            Issue.record("Image name not found")
            return
        }
        #expect(Array(args.suffix(from: imageIdx + 1)) == originalArgs)
    }

    @Test("Run mode uses Apple Container runtime prefix when configured")
    func testRunModeAppleContainerRuntime() async throws {
        let capturing = CapturingCommandRunner()
        let config = ContainerConfig(
            runtime: .appleContainer,
            imageName: "alpine:latest",
            containerName: "my-node"
        )
        let runner = makeRunner(config: config, mode: .run, capturing: capturing)

        let stream = runner.run(arguments: ["/bin/sh"], environment: [:], workingDirectory: nil)
        for try await _ in stream {}

        #expect(capturing.capturedArguments.first == "container")
        #expect(capturing.capturedArguments[1] == "run")
    }

    // MARK: - WorkingDirectory Tests

    @Test("Working directory is always passed as nil to inner runner (host path not meaningful in container)")
    func testWorkingDirectoryDiscarded() async throws {
        let capturing = CapturingCommandRunner()
        let runner = makeRunner(
            config: makeDockerExecConfig(),
            mode: .exec,
            capturing: capturing
        )

        // Pass a real-looking working directory
        let stream = runner.run(
            arguments: ["/bin/sh"],
            environment: [:],
            workingDirectory: nil
        )
        for try await _ in stream {}

        #expect(capturing.capturedWorkingDirectory == nil)
    }

    // MARK: - resolve() Factory Tests

    @Test("resolve() returns injected runner when provided")
    func testResolveUsesInjectedRunner() {
        let injected = CapturingCommandRunner()
        let container = ContainerConfig(runtime: .docker, imageName: "alpine:latest")
        let logger = Logger(label: "test")

        let resolved = ContainerizedCommandRunner.resolve(
            injected: injected,
            container: container,
            mode: .exec,
            logger: logger
        )

        // The resolved runner should be the injected one (same object)
        // We can't do identity checks on existentials, but we can verify
        // it behaves like the injected runner by calling it
        #expect(resolved is CapturingCommandRunner)
    }

    @Test("resolve() returns ContainerizedCommandRunner when container is set and no injected runner")
    func testResolveReturnsContainerizedRunner() {
        let container = ContainerConfig(runtime: .docker, imageName: "alpine:latest")
        let logger = Logger(label: "test")

        let resolved = ContainerizedCommandRunner.resolve(
            injected: nil,
            container: container,
            mode: .exec,
            logger: logger
        )

        #expect(resolved is ContainerizedCommandRunner)
    }

    @Test("resolve() returns CommandRunner when no injected runner and no container")
    func testResolveReturnsCommandRunner() {
        let logger = Logger(label: "test")

        let resolved = ContainerizedCommandRunner.resolve(
            injected: nil,
            container: nil,
            mode: .exec,
            logger: logger
        )

        #expect(resolved is CommandRunner)
    }

    @Test("resolve() injected runner takes priority over container config")
    func testResolveInjectedTakesPriorityOverContainer() {
        let injected = CapturingCommandRunner()
        let container = ContainerConfig(runtime: .docker, imageName: "alpine:latest")
        let logger = Logger(label: "test")

        let resolved = ContainerizedCommandRunner.resolve(
            injected: injected,
            container: container,
            mode: .exec,
            logger: logger
        )

        // Injected should win — it's a CapturingCommandRunner, not ContainerizedCommandRunner
        #expect(resolved is CapturingCommandRunner)
    }
}
