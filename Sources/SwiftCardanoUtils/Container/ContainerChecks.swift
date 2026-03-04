import Foundation
import Logging

// MARK: - Container Pre-flight Checks

/// Pre-flight validation helpers for container-mode CLITools.
///
/// These replace the host-filesystem checks in `BinaryExecutable.checkBinary`
/// when a `ContainerConfig` is present on the service config.
public enum ContainerChecks {

    // MARK: - Image Check

    /// Verifies that a container image exists locally.
    ///
    /// Runs `docker images --quiet --filter reference=<imageName>` (or the Apple Container equivalent).
    /// A non-empty stdout confirms the image is present on the local daemon.
    ///
    /// - Parameters:
    ///   - config: The container configuration specifying the runtime and image name.
    ///   - logger: Optional logger for diagnostic messages.
    /// - Throws: `SwiftCardanoUtilsError.binaryNotFound` if the image is not found locally,
    ///           or `SwiftCardanoUtilsError.commandFailed` if the runtime CLI cannot be invoked.
    public static func checkImage(
        config: ContainerConfig,
        logger: Logger = Logger(label: "ContainerChecks")
    ) throws {
        let runtime = config.runtime.executable
        let image = config.imageName

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [runtime, "images", "--quiet", "--filter", "reference=\(image)"]
        process.environment = ProcessInfo.processInfo.environment
        process.currentDirectoryURL = URL(
            fileURLWithPath: FileManager.default.currentDirectoryPath
        )

        let outputPipe = Pipe()
        let errorPipe  = Pipe()
        process.standardOutput = outputPipe
        process.standardError  = errorPipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            throw SwiftCardanoUtilsError.commandFailed(
                [runtime, "images", "--quiet", "--filter", "reference=\(image)"],
                "Failed to query container image. " +
                "Ensure '\(runtime)' is installed and the daemon is running. " +
                "Error: \(error.localizedDescription)"
            )
        }

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outputData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !output.isEmpty else {
            throw SwiftCardanoUtilsError.binaryNotFound(
                "Container image '\(image)' not found locally. " +
                "Pull it first with: \(runtime) pull \(image)"
            )
        }

        logger.debug("Container image '\(image)' found locally (id: \(output))")
    }
}
