import Foundation
import SystemPackage

// MARK: - Cardano HW CLI Node Command Implementation

extension CardanoHWCLI {
    
    /// Implementation of node utility commands
    public struct NodeCommandImpl: CommandProtocol {
        var baseCLI: any BinaryInterfaceable
        
        var baseCommand: [String] {
            ["node"]
        }
        
        init(baseCLI: any BinaryInterfaceable) {
            self.baseCLI = baseCLI
        }
        
        /// Issue operational certificate using hardware wallet
        /// - Parameters:
        ///   - kesVerificationKeyFile: Input file path for KES verification key
        ///   - kesPeriod: KES period number
        ///   - operationalCertificateIssueCounterFile: Input file path for issue counter file
        ///   - hwSigningFile: Input file path for hardware signing file
        ///   - outFile: Output file path for the operational certificate
        /// - Returns: Command output as a String
        /// - Throws: CardanoCLIToolsError if command execution fails
        public func issueOpCert(
            kesVerificationKeyFile: FilePath,
            kesPeriod: UInt64,
            operationalCertificateIssueCounterFile: FilePath,
            hwSigningFile: FilePath,
            outFile: FilePath
        ) async throws -> String {
            let args = [
                "--kes-verification-key-file", kesVerificationKeyFile.string,
                "--kes-period", String(kesPeriod),
                "--operational-certificate-issue-counter-file", operationalCertificateIssueCounterFile.string,
                "--hw-signing-file", hwSigningFile.string,
                "--out-file", outFile.string
            ]
            
            return try await executeCommand("issue-op-cert", arguments: args)
        }
        
        /// Generate node keys using hardware wallet
        /// - Parameters:
        ///   - path: Derivation path for the node key
        ///   - hwSigningFile: Output file path for hardware signing file
        ///   - coldVerificationKeyFile: Output file path for cold verification key file
        ///   - operationalCertificateIssueCounterFile: Output file path for the issue counter file
        /// - Returns: Command output as a String
        /// - Throws: CardanoCLIToolsError if command execution fails
        public func keyGen(
            path: String,
            hwSigningFile: FilePath,
            coldVerificationKeyFile: FilePath,
            operationalCertificateIssueCounterFile: FilePath
        ) async throws -> String {
            let args = [
                "--path", path,
                "--hw-signing-file", hwSigningFile.string,
                "--cold-verification-key-file", coldVerificationKeyFile.string,
                "--operational-certificate-issue-counter-file", operationalCertificateIssueCounterFile.string
            ]
            
            return try await executeCommand("key-gen", arguments: args)
        }
        
        /// Issue operational certificate using deprecated counter parameter (for backwards compatibility)
        /// - Parameters:
        ///   - kesVerificationKeyFile: Input file path for KES verification key
        ///   - kesPeriod: KES period number
        ///   - operationalCertificateIssueCounter: Input file path for issue counter file (deprecated parameter)
        ///   - hwSigningFile: Input file path for hardware signing file
        ///   - outFile: Output file path for the operational certificate
        /// - Returns: Command output as a String
        /// - Throws: CardanoCLIToolsError if command execution fails
        @available(*, deprecated, message: "Use issueOpCert with operationalCertificateIssueCounterFile parameter instead")
        public func issueOpCertDeprecated(
            kesVerificationKeyFile: FilePath,
            kesPeriod: UInt64,
            operationalCertificateIssueCounter: FilePath,
            hwSigningFile: FilePath,
            outFile: FilePath
        ) async throws -> String {
            let args = [
                "--kes-verification-key-file", kesVerificationKeyFile.string,
                "--kes-period", String(kesPeriod),
                "--operational-certificate-issue-counter", operationalCertificateIssueCounter.string,
                "--hw-signing-file", hwSigningFile.string,
                "--out-file", outFile.string
            ]
            
            return try await executeCommand("issue-op-cert", arguments: args)
        }
    }
}
