import Foundation
import System
import Logging


protocol BinaryExecutable: Sendable {
    static var binaryName: String { get }
    static var mininumSupportedVersion: String { get }
    
    var configuration: Configuration { get }
    var logger: Logger { get }
    
    func version() async throws -> String
}

extension BinaryExecutable {
    
    /// Get the path to the binary using `which ${binary}`
    /// - Returns: URL to the  binary or nil if not found
    /// - Note: This method relies on the system's PATH environment variable
    public static func getBinaryPath() throws -> FilePath {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [Self.binaryName]
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        process.environment = ProcessInfo.processInfo.environment
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                if let outputString = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !outputString.isEmpty {
                    return FilePath(outputString)
                } else {
                    throw CardanoCLIToolsError.binaryNotFound(Self.binaryName)
                }
            } else {
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                throw CardanoCLIToolsError.commandFailed([Self.binaryName], "Failed to run command: \(errorMessage)")
            }
        } catch {
            throw CardanoCLIToolsError.commandFailed([Self.binaryName], "Failed to run command: \(error.localizedDescription)")
        }
    }
    
    /// Create working directory if it doesn't exist
    public static func checkWorkingDirectory(workingDirectory: FilePath) throws -> Void {
        if !FileManager.default.fileExists(atPath: workingDirectory.string) {
            try FileManager.default.createDirectory(atPath: workingDirectory.string, withIntermediateDirectories: true)
        }
    }
    
    /// Check if the binary exists and is executable
    public static func checkBinary(binary: FilePath) throws -> Void {
        var isDirectory: ObjCBool = false
        if !FileManager.default.fileExists(atPath: binary.string, isDirectory: &isDirectory)
            || isDirectory.boolValue
        {
            throw CardanoCLIToolsError.binaryNotFound("\(Self.binaryName) binary file not found: \(binary.string)")
        }
        
        // Check if is executable
        if !FileManager.default.isExecutableFile(atPath: binary.string) {
            throw CardanoCLIToolsError.binaryNotFound("\(Self.binaryName) binary file is not executable: \(binary.string)")
        }
    }
    
    /// Check if the node version is compatible with minimum requirements
    public func checkVersion() async throws {        
        let currentVersion = try await version()
        logger.debug("CardanoCLI version: \(currentVersion)")
        logger.debug("Minimum required version: \(Self.mininumSupportedVersion)")
        
        // Simple version comparison (could be enhanced with proper semantic versioning)
        if currentVersion.compare(Self.mininumSupportedVersion, options: .numeric) == .orderedAscending {
            logger.warning("Unsupported \(Self.binaryName) version.")
            logger.warning("Current version: \(currentVersion)")
            logger.warning("Minimum supported version: \(Self.mininumSupportedVersion)")
            throw CardanoCLIToolsError.unsupportedVersion(currentVersion, Self.mininumSupportedVersion)
        }
    }
}
