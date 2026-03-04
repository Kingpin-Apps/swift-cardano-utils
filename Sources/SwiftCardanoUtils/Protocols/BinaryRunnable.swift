import Foundation
import Command
import Path
import SystemPackage
import Dispatch

/// Protocol for binary runners
public protocol BinaryRunnable: BinaryInterfaceable {
    var showOutput: Bool { get }
}

extension BinaryRunnable {
    /// Start the binary process with the given arguments.
    ///
    /// **Non-container mode** uses the `Command` library runner with `runWithSignalForwarding`,
    /// which cancels the child via `SIGTERM` on Ctrl+C.
    ///
    /// **Container mode** uses `Foundation.Process` directly so that we hold the
    /// `processIdentifier` and can forward `SIGINT` (not `SIGTERM`) to the runtime.
    /// The runtime then proxies `SIGINT` to the container's PID 1 via `--sig-proxy=true`
    /// and waits for the container to exit before terminating itself.  Swift waits for
    /// the `terminationHandler` to fire, so the app only exits after the container has
    /// fully shut down.
    ///
    /// - Parameter arguments: Array of command line arguments
    /// - Throws: SwiftCardanoUtilsError if the command fails
    public func start(_ arguments: [String] = []) async throws -> Void {

        if let container = cardanoConfig.container {
            // ── Container mode ──────────────────────────────────────────────────────
            // Build a foreground (non-detached) ContainerizedCommandRunner just to
            // get the fully assembled argument array, then hand it to
            // startContainerProcess which uses Foundation.Process directly.
            var foregroundConfig = container
            foregroundConfig.detach = false

            let inner: (any CommandRunning)? =
                commandRunner is ContainerizedCommandRunner ? nil : commandRunner
            let containerRunner = ContainerizedCommandRunner(
                config: foregroundConfig,
                mode: .run,
                inner: inner,
                logger: self.logger
            )

            let runtimeArgs = containerRunner.runArguments(for: arguments)
            try await startContainerProcess(runtimeArgs: runtimeArgs)

        } else {
            // ── Binary mode ──────────────────────────────────────────────────────────
            let fullCommand = [binaryPath.string] + arguments
            let output = commandRunner.run(
                arguments: fullCommand,
                environment: Environment.getEnv(),
                workingDirectory: try AbsolutePath(validating: self.workingDirectory.string)
            )

            do {
                if showOutput {
                    logger.info("Starting process with output shown...")
                    try await runWithSignalForwarding { try await output.pipedStream().awaitCompletion() }
                } else {
                    logger.info("Starting process with output hidden...")
                    try await runWithSignalForwarding { try await output.awaitCompletion() }
                }
            } catch {
                logger.error("Process failed: \(error)")
                throw SwiftCardanoUtilsError.commandFailed(fullCommand, error.localizedDescription)
            }
        }
    }

    // MARK: - Container mode process runner

    /// Spawns the container runtime (`docker run` / `container run`) via
    /// `Foundation.Process`, then:
    ///
    /// - Intercepts `SIGINT` and forwards it as `kill(pid, SIGINT)` so the runtime's
    ///   `--sig-proxy=true` can pass it to the container's PID 1 for a graceful shutdown.
    /// - Intercepts `SIGTERM` and forwards it as `kill(pid, SIGTERM)`.
    /// - Connects stdout/stderr directly to the terminal (or `/dev/null` when
    ///   `showOutput` is `false`) so that the runtime sees the correct file-descriptor
    ///   types and can proxy signals properly.
    /// - Waits via `terminationHandler` (without blocking the cooperative thread pool)
    ///   until the runtime process exits — which happens only after the container has
    ///   stopped — so the Swift process does not exit while the container is still running.
    private func startContainerProcess(runtimeArgs: [String]) async throws {
        guard let executableName = runtimeArgs.first else {
            throw SwiftCardanoUtilsError.commandFailed(
                runtimeArgs, "Empty container runtime argument list"
            )
        }

        // Resolve the runtime executable (e.g. /usr/local/bin/docker).
        let execURL = try resolveExecutableURL(executableName)

        let process = Process()
        process.executableURL = execURL
        process.arguments    = Array(runtimeArgs.dropFirst())
        process.standardInput  = FileHandle.standardInput
        process.standardOutput = showOutput ? FileHandle.standardOutput : FileHandle.nullDevice
        process.standardError  = showOutput ? FileHandle.standardError  : FileHandle.nullDevice
        process.environment    = Environment.getEnv()

        // Suppress default signal disposition so Swift doesn't die on Ctrl+C.
        signal(SIGINT,  SIG_IGN)
        signal(SIGTERM, SIG_IGN)

        let sigintSource  = DispatchSource.makeSignalSource(signal: SIGINT,  queue: .global())
        let sigtermSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .global())

        // Track whether we triggered the shutdown so we can treat the exit as normal.
        var shutdownTriggered = false
        var runError: Error?

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            // Set terminationHandler before process.run() to avoid a race where the
            // process exits before the handler is registered.
            process.terminationHandler = { _ in
                continuation.resume()
            }

            do {
                try process.run()

                // Capture PID as Int32 (Sendable) — avoids capturing non-Sendable Process
                // in the @Sendable DispatchSource event handlers.
                let pid = process.processIdentifier

                sigintSource.setEventHandler {
                    shutdownTriggered = true
                    _ = kill(pid, SIGINT)
                }
                sigtermSource.setEventHandler {
                    shutdownTriggered = true
                    _ = kill(pid, SIGTERM)
                }
                sigintSource.resume()
                sigtermSource.resume()

                logger.info("\(Self.binaryName): container process started (pid \(pid))")

            } catch {
                // process.run() failed before the process started; terminationHandler
                // will never fire, so we resume the continuation ourselves.
                runError = error
                continuation.resume()
            }
        }

        // Restore signal handling and clean up sources.
        sigintSource.cancel()
        sigtermSource.cancel()
        signal(SIGINT,  SIG_DFL)
        signal(SIGTERM, SIG_DFL)

        if let error = runError {
            throw SwiftCardanoUtilsError.commandFailed(
                runtimeArgs, "Failed to start container process: \(error.localizedDescription)"
            )
        }

        logger.info("\(Self.binaryName): container process exited\(shutdownTriggered ? " (signal forwarded)" : "")")
    }

    /// Resolves a bare executable name (e.g. `"docker"`) to its full path using
    /// `/usr/bin/which`, mirroring the lookup performed by the `Command` library.
    /// Absolute paths are returned as-is.
    private func resolveExecutableURL(_ name: String) throws -> URL {
        if name.hasPrefix("/") {
            return URL(fileURLWithPath: name)
        }
        let which = Process()
        which.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        which.arguments = [name]
        let pipe = Pipe()
        which.standardOutput = pipe
        which.standardError  = Pipe()   // discard stderr
        try which.run()
        which.waitUntilExit()
        guard which.terminationStatus == 0 else {
            throw SwiftCardanoUtilsError.binaryNotFound(name)
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let path = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !path.isEmpty else {
            throw SwiftCardanoUtilsError.binaryNotFound(name)
        }
        return URL(fileURLWithPath: path)
    }

    // MARK: - Non-container signal forwarding

    /// Runs an async throwing closure while intercepting SIGINT and SIGTERM.
    ///
    /// When either signal arrives the inner Task is cancelled.  The `Command`
    /// runner's `onTermination(.cancelled)` handler then calls
    /// `process.terminate()`, sending SIGTERM to the child process so it can
    /// perform a graceful shutdown rather than being orphaned.
    private func runWithSignalForwarding(
        _ body: @escaping @Sendable () async throws -> Void
    ) async throws {
        // Unstructured task so we can cancel it from a DispatchSource handler.
        let task = Task(operation: body)

        // Suppress the default signal disposition so the Swift process is not
        // killed outright before the child has a chance to shut down.
        signal(SIGINT,  SIG_IGN)
        signal(SIGTERM, SIG_IGN)

        let sigintSource  = DispatchSource.makeSignalSource(signal: SIGINT,  queue: .global())
        let sigtermSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .global())

        sigintSource.setEventHandler  { task.cancel() }
        sigtermSource.setEventHandler { task.cancel() }
        sigintSource.resume()
        sigtermSource.resume()

        try await withTaskCancellationHandler {
            defer {
                sigintSource.cancel()
                sigtermSource.cancel()
                signal(SIGINT,  SIG_DFL)
                signal(SIGTERM, SIG_DFL)
            }
            do {
                try await task.value
            } catch is CancellationError {
                logger.info("\(Self.binaryName): shutdown signal received, child process terminating gracefully")
            }
        } onCancel: {
            // Also forward structured cancellation (e.g. parent task cancelled).
            task.cancel()
        }
    }
}
