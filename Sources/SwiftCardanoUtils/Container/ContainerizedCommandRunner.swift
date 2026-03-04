import Foundation
import Command
import Logging
import Path

// MARK: - Container Execution Mode

/// Determines how `ContainerizedCommandRunner` intercepts command invocations.
///
/// - ``exec``: Prepends `docker exec <containerName>` to every call.
///   Used for one-shot interactive tools (`CardanoCLI`, `CardanoHWCLI`, `CardanoSigner`)
///   that exec into an already-running container.
///
/// - ``run``: Builds a full `docker run` invocation, using the original
///   binary + args as the container CMD.
///   Used for long-running daemon tools (`CardanoNode`, `Kupo`, `Ogmios`, `MithrilClient`)
///   that launch a new container.
public enum ContainerExecutionMode: Sendable {
    case exec
    case run
}

// MARK: - ContainerizedCommandRunner

/// A `CommandRunning` implementation that transparently wraps another runner,
/// prepending container exec/run prefixes to every invocation.
///
/// ## Exec Mode
///
/// The `arguments` array received by `run()` starts with the binary path as
/// `arguments[0]` (set by `BinaryInterfaceable.runCommand`). In exec mode the
/// transformation is:
///
/// ```
/// Original: ["/usr/local/bin/cardano-cli", "query", "tip", "--mainnet"]
/// Result:   ["docker", "exec", "my-node", "/usr/local/bin/cardano-cli",
///            "query", "tip", "--mainnet"]
/// ```
///
/// ## Run Mode
///
/// In run mode, a full `docker run` invocation is built from `ContainerConfig`
/// and the original binary + args become the container CMD:
///
/// ```
/// Original: ["/usr/local/bin/kupo", "--host", "0.0.0.0", "--port", "1442"]
/// Result:   ["docker", "run", "--detach", "--name", "my-kupo",
///            "--volume", "/data:/data", "--publish", "1442:1442",
///            "cardano-kupo:latest",
///            "/usr/local/bin/kupo", "--host", "0.0.0.0", "--port", "1442"]
/// ```
public struct ContainerizedCommandRunner: CommandRunning {

    // MARK: - Properties

    private let config: ContainerConfig
    private let mode: ContainerExecutionMode
    private let inner: any CommandRunning
    private let logger: Logger

    // MARK: - Init

    /// - Parameters:
    ///   - config: The container configuration (runtime, image, volumes, etc.).
    ///   - mode: Whether to exec into an existing container or launch a new one.
    ///   - inner: The underlying runner to delegate to after argument transformation.
    ///            Defaults to a fresh `CommandRunner`.
    ///   - logger: Logger for diagnostic output.
    public init(
        config: ContainerConfig,
        mode: ContainerExecutionMode,
        inner: (any CommandRunning)? = nil,
        logger: Logger = Logger(label: "ContainerizedCommandRunner")
    ) {
        self.config = config
        self.mode = mode
        self.logger = logger
        self.inner = inner ?? CommandRunner(logger: logger)
    }

    // MARK: - CommandRunning

    public func run(
        arguments: [String],
        environment: [String: String],
        workingDirectory: Path.AbsolutePath?
    ) -> AsyncThrowingStream<CommandEvent, any Error> {
        let transformed: [String]
        do {
            transformed = try buildArguments(original: arguments)
        } catch {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: error)
            }
        }
        logger.debug(
            "ContainerizedCommandRunner [\(mode)] → \(transformed.joined(separator: " "))"
        )
        // The host workingDirectory has no meaning inside a container.
        // The container's working directory is expressed via ContainerConfig.workingDir
        // and included as --workdir in the generated arguments.
        return inner.run(
            arguments: transformed,
            environment: environment,
            workingDirectory: nil
        )
    }
    
    public func runCommand(_ arguments: [String]) async throws -> String {
        do {
            return try await self.run(
                arguments: arguments,
                environment: Environment.getEnv()
            ).concatenatedString()
        } catch CommandError.terminated(let status, let stderr) {
            throw SwiftCardanoUtilsError
                .commandFailed(
                    arguments,
                    "The command terminated with the code \(status). \n\(stderr)"
                )
        } catch {
            throw SwiftCardanoUtilsError
                .commandFailed(
                    arguments,
                    "\(error)"
                )
        }
        
    }

    // MARK: - Argument Transformation

    private func buildArguments(original: [String]) throws -> [String] {
        switch mode {
        case .exec: return try buildExecArguments(original: original)
        case .run:  return buildRunArguments(original: original)
        }
    }

    /// `<runtime> exec [--workdir <dir>] [--user <user>] [--env K=V ...] <containerName> <original...>`
    private func buildExecArguments(original: [String]) throws -> [String] {
        guard let containerName = config.containerName else {
            throw SwiftCardanoUtilsError.configurationMissing(
                "container_name is required for exec mode"
            )
        }

        var args: [String] = [config.runtime.executable, "exec"]

        if let workingDir = config.workingDir {
            args += ["--workdir", workingDir]
        }
        if let user = config.user {
            args += ["--user", user]
        }
        for envVar in config.environment ?? [] {
            args += ["--env", envVar]
        }

        args.append(containerName)
        args += original
        return args
    }

    /// `<runtime> run [flags...] <imageName> <original...>`
    private func buildRunArguments(original: [String]) -> [String] {
        var args: [String] = [config.runtime.executable, "run"]

        if config.detach ?? true {
            args.append("--detach")
        }
        if config.removeOnExit == true {
            args.append("--rm")
        }
        if let name = config.containerName {
            args += ["--name", name]
        }
        for vol in config.volumes ?? [] {
            args += ["--volume", vol]
        }
        for envVar in config.environment ?? [] {
            args += ["--env", envVar]
        }
        for port in config.ports ?? [] {
            args += ["--publish", port]
        }
        if let network = config.network       { args += ["--network", network] }
        if let workingDir = config.workingDir { args += ["--workdir", workingDir] }
        if let user = config.user             { args += ["--user", user] }
        if let hostname = config.hostname     { args += ["--hostname", hostname] }
        if let restart = config.restart       { args += ["--restart", restart] }
        if config.privileged == true          { args.append("--privileged") }
        if let entrypoint = config.entrypoint { args += ["--entrypoint", entrypoint] }
        if let platform = config.platform     { args += ["--platform", platform] }
        if let memory = config.memory         { args += ["--memory", memory] }
        if let cpus = config.cpus             { args += ["--cpus", cpus] }
        for cap in config.capAdd ?? []        { args += ["--cap-add", cap] }
        for cap in config.capDrop ?? []       { args += ["--cap-drop", cap] }
        if config.readOnly == true            { args.append("--read-only") }
        if let logDriver = config.logDriver   { args += ["--log-driver", logDriver] }
        for opt in config.logOptions ?? []    { args += ["--log-opt", opt] }
        for label in config.labels ?? []      { args += ["--label", label] }

        args.append(config.imageName)
        args += original
        return args
    }

    // MARK: - Argument Building (Public)

    /// Returns the full `<runtime> run [flags] <image> <original>` argument array
    /// without spawning a process.  The first element is the runtime executable name
    /// (e.g. `"docker"`); use it as the executable and pass the rest as `arguments`.
    ///
    /// Only valid when this instance was created with `.run` mode.
    public func runArguments(for original: [String]) -> [String] {
        buildRunArguments(original: original)
    }

    // MARK: - Factory

    /// Resolves the appropriate `CommandRunning` implementation.
    ///
    /// - Returns the injected runner when one is provided.
    /// - Returns a `ContainerizedCommandRunner` when a `ContainerConfig` is present.
    /// - Falls back to a plain `CommandRunner` otherwise.
    public static func resolve(
        injected: (any CommandRunning)?,
        container: ContainerConfig?,
        mode: ContainerExecutionMode,
        logger: Logger
    ) -> any CommandRunning {
        if let injected { return injected }
        if let container { return ContainerizedCommandRunner(config: container, mode: mode, logger: logger) }
        return CommandRunner(logger: logger)
    }
}
