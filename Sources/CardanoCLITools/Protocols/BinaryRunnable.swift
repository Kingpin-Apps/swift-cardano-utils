import Foundation
import SystemPackage
import Logging
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

/// Protocol for binary runners
protocol BinaryRunnable: BinaryInterfaceable {
    var binaryPath: FilePath { get }
    var workingDirectory: FilePath { get }
    var showOutput: Bool { get }
    var process: Process? { get set }
    var processTerminated: Bool { get set }
    
    init(configuration: CardanoCLIToolsConfig, logger: Logger?) async throws
}

extension BinaryRunnable {
    
    mutating func start(_ arguments: [String] = []) throws {
        guard process == nil || !process!.isRunning else {
            throw CardanoCLIToolsError.processAlreadyRunning
        }
        
        process = Process()
        processTerminated = false
        guard let process = process else { return }
        
        process.executableURL = URL(fileURLWithPath: binaryPath.string)
        process.arguments = arguments
        
        if !showOutput {
            process.standardOutput = Pipe()
            process.standardError = Pipe()
        }
        
        logger.info("Starting process: \(binaryPath) \(arguments.joined(separator: " "))")
        
        // Handle process termination
        process.terminationHandler = { [self] terminatedProcess in
            self.logger.info(
                "Process terminated with exit code: \(terminatedProcess.terminationStatus)"
            )
//            self.process = nil
        }
        
        try process.run()
        
        // If showing output, wait for the process to complete
        if showOutput {
            process.waitUntilExit()
        }
    }
    
    mutating func stop() async throws {
        guard let process = process, process.isRunning else { return }
        
        logger.info("Stopping process...")
        process.interrupt()
        
        try await Task.sleep(for: .seconds(10))
        
        if let process = self.process, process.isRunning {
            self.logger.warning(
                "Process did not terminate gracefully, forcing termination"
            )
            process.terminate()
            processTerminated = true
        }
        
        // Give it a moment to terminate gracefully
//        DispatchQueue.global().asyncAfter(deadline: .now() + 10) { [self] in
//            if let process = self.process, process.isRunning {
//                self.logger.warning(
//                    "Process did not terminate gracefully, forcing termination"
//                )
//                process.terminate()
//            }
//        }
    }
    
    func version() async throws -> String {
        let versionProcess = Process()
        let pipe = Pipe()
        
        versionProcess.executableURL = URL(fileURLWithPath: binaryPath.string)
        versionProcess.arguments = ["--version"]
        versionProcess.standardOutput = pipe
        
        try versionProcess.run()
        versionProcess.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    
    var isRunning: Bool {
        guard let process = process else { return false }
        
        // If we've explicitly marked the process as terminated, return false
        // This handles Linux timing issues where Process.isRunning may be stale
        if processTerminated {
            return false
        }
        
        // Standard check - if this reports false, we can trust it
        if !process.isRunning {
            return false
        }
        
        // On Linux, Process.isRunning might be stale after natural termination
        // Use kill(pid, 0) to verify the process actually exists
        let pid = process.processIdentifier
        if pid > 0 {
            #if canImport(Glibc)
            // Use kill(pid, 0) to test if process exists without sending a signal
            let result = kill(pid, 0)
            if result == -1 {
                let error = errno
                if error == ESRCH {
                    // Process doesn't exist - it has terminated
                    return false
                } else if error == EPERM {
                    // Process exists but we don't have permission - it's still running
                    return true
                }
                // Other errors - fall back to Process.isRunning
            } else {
                // kill succeeded - process exists and is running
                return true
            }
            #elseif canImport(Darwin)
            // Use kill(pid, 0) on macOS too for consistency
            let result = kill(pid, 0)
            if result == -1 && errno == ESRCH {
                // Process doesn't exist - it has terminated
                return false
            }
            #endif
        }
        
        // Fall back to Process.isRunning if kill check is inconclusive
        return process.isRunning
    }
}

