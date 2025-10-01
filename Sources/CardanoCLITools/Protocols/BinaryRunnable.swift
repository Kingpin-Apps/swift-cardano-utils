import Foundation
import System
import Logging

/// Protocol for binary runners
protocol BinaryRunnable: BinaryInterfaceable {
    var binaryPath: FilePath { get }
    var workingDirectory: FilePath { get }
    var showOutput: Bool { get }
    var process: Process? { get set }
    
    init(configuration: Configuration, logger: Logger?) async throws
}

extension BinaryRunnable {
    
    mutating func start(_ arguments: [String] = []) throws {
        guard process == nil else {
            throw CardanoCLIToolsError.processAlreadyRunning
        }
        
        process = Process()
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
    
    func stop() {
        guard let process = process, process.isRunning else { return }
        
        logger.info("Stopping process...")
        process.interrupt()
        
        // Give it a moment to terminate gracefully
        DispatchQueue.global().asyncAfter(deadline: .now() + 10) { [self] in
            if let process = self.process, process.isRunning {
                self.logger.warning(
                    "Process did not terminate gracefully, forcing termination"
                )
                process.terminate()
            }
        }
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
        return process?.isRunning ?? false
    }
}
