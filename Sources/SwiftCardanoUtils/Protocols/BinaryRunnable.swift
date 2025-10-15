import Command
import Path
import SystemPackage

/// Protocol for binary runners
public protocol BinaryRunnable: BinaryInterfaceable {
    var showOutput: Bool { get }
}

extension BinaryRunnable {
    /// Start the binary process with the given arguments
    /// - Parameter arguments: Array of command line arguments
    /// - Returns: Void
    /// - Throws: SwiftCardanoUtilsError if the command fails
    public func start(_ arguments: [String] = []) async throws -> Void {
        let fullCommand = [binaryPath.string] + arguments
        
        let output = commandRunner.run(
            arguments: fullCommand,
            environment: Environment.getEnv(),
            workingDirectory: try AbsolutePath(validating: self.workingDirectory.string)
        )
        do {
            if showOutput {
                logger.info("Starting process with output shown...")
                return try await output.pipedStream().awaitCompletion()
            } else {
                logger.info("Starting process with output hidden...")
                
                return try await output.awaitCompletion()
            }
        } catch {
            logger.error("Process failed: \(error.localizedDescription)")
            throw SwiftCardanoUtilsError.commandFailed(fullCommand, error.localizedDescription)
        }
    }
}
