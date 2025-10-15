import Foundation
import SystemPackage
import Logging
import Path

// MARK: - Base CLI Protocol

public protocol BinaryInterfaceable: BinaryExecutable {
    var binaryPath: FilePath { get }
    var workingDirectory: FilePath { get }
}

// MARK: - Base CLI Implementation

/// Default implementations for CLI tool protocol
extension BinaryInterfaceable {

    /// Run a CLI command with the given arguments
    /// - Parameter arguments: Array of command line arguments
    /// - Returns: Standard output from the command
    /// - Throws: CLIError if the command fails
    /// - Note: This method is thread-safe and uses a serial queue to prevent concurrent executions
    public func runCommand(_ arguments: [String]) async throws -> String {
        let fullCommand = [binaryPath.string] + arguments
        
        do {
            return try await commandRunner.run(
                arguments: fullCommand,
                environment: Environment.getEnv(),
                workingDirectory: try AbsolutePath(validating: self.workingDirectory.string)
            ).concatenatedString()
        } catch {
            throw SwiftCardanoUtilsError
                .commandFailed(
                    fullCommand,
                    error.localizedDescription
                )
        }
    }
}


