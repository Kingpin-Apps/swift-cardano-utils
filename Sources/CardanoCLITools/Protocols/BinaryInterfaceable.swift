import Foundation
import System
import Logging

// MARK: - Base CLI Protocol

protocol BinaryInterfaceable: BinaryExecutable {
    var binaryPath: FilePath { get }
    var workingDirectory: FilePath { get }
    
    init(configuration: Configuration, logger: Logger?) async throws
}

// MARK: - Base CLI Implementation

/// Default implementations for CLI tool protocol
extension BinaryInterfaceable {

    /// Run a CLI command with the given arguments
    /// - Parameter arguments: Array of command line arguments
    /// - Returns: Standard output from the command
    /// - Throws: CLIError if the command fails
    /// - Note: This method is thread-safe and uses a serial queue to prevent concurrent executions
    func runCommand(_ arguments: [String]) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: self.binaryPath.string)
            process.arguments = arguments
            
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe
            
            process.terminationHandler = { process in
                if process.terminationStatus == 0 {
                    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: outputData, encoding: .utf8)?.trimmingCharacters(
                        in: .whitespacesAndNewlines) ?? ""
                    
                    logger.debug("CLI command output: \(output)")
                    continuation.resume(returning: output)
                } else {
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                    logger.error("CLI command failed with exit code \(process.terminationStatus)")
                    logger.error("Error output: \(errorMessage)")
                    continuation.resume(throwing: CardanoCLIToolsError.commandFailed(arguments, errorMessage))
                }
            }
            
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}


