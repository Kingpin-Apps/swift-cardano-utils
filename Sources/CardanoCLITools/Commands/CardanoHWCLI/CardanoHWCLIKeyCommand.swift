import Foundation
import SystemPackage

// MARK: - Cardano HW CLI Key Command Implementation

extension CardanoHWCLI {
    
    /// Implementation of key utility commands
    public struct KeyCommandImpl: CommandProtocol {
        var baseCLI: any BinaryInterfaceable
        
        var baseCommand: [String] {
            ["key"]
        }
        
        init(baseCLI: any BinaryInterfaceable) {
            self.baseCLI = baseCLI
        }
        
        /// Get the verification key from a hardware signing file
        /// - Parameters:
        ///   - hwSigningFile: The path to the hardware signing file
        ///   - outputFile: The path to write the verification key file
        /// - Returns: The command output
        @discardableResult
        public func verificationKey(
            hwSigningFile: FilePath,
            verificationKeyFile: FilePath
        ) async throws -> String {
            let args = [
                "--hw-signing-file", hwSigningFile.string,
                "--verification-key-file", verificationKeyFile.string
            ]
            
            return try await executeCommand("verification-key", arguments: args)
        }
    }
    
}
