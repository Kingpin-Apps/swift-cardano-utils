import Foundation

// MARK: - Errors

enum SwiftCardanoUtilsError: Error, LocalizedError {
    case binaryNotFound(String)
    case commandFailed([String], String)
    case processAlreadyRunning
    case configurationMissing(Config)
    case deviceError(String)
    case invalidOutput(String)
    case invalidParameters(String)
    case nodeNotSynced(Double)
    case unsupportedVersion(String, String)
    case invalidMultiSigConfig(String)
    case fileAlreadyExists(String)
    case fileNotFound(String)
    case valueError(String)
    case versionMismatch(String)
    
    var errorDescription: String? {
        switch self {
            case .binaryNotFound(let path):
                return "Binary not found at: \(path)"
            case .commandFailed(let command, let error):
                return "Command failed: \(command.joined(separator: " ")). Error: \(error)"
            case .processAlreadyRunning:
                return "Process is already running"
            case .configurationMissing(let config):
                return "Configuration is missing or invalid: \(config)"
            case .deviceError(let message):
                return "Hardware wallet device error: \(message)"
            case .invalidOutput(let message):
                return "Invalid CLI output: \(message)"
            case .invalidParameters(let message):
                return "Invalid parameters: \(message)"
            case .nodeNotSynced(let progress):
                return "Node is not fully synced. Current sync progress: \(progress)%"
            case .unsupportedVersion(let current, let minimum):
                return "Unsupported version: \(current). Minimum required: \(minimum)"
            case .invalidMultiSigConfig(let message):
                return "Invalid multi-signature configuration: \(message)"
            case .fileAlreadyExists(let path):
                return "File already exists: \(path)"
            case .fileNotFound(let path):
                return "File not found: \(path)"
            case .valueError(let message):
                return "Value error: \(message)"
            case .versionMismatch(let message):
                return "Version mismatch for binary at path: \(message)"
        }
    }
}
