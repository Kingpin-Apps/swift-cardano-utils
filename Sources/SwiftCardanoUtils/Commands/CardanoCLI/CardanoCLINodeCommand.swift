import Foundation

// MARK: - Node Command Implementation

/// Implementation of Cardano node commands
public struct NodeCommandImpl: CommandProtocol {
    var baseCLI: any BinaryInterfaceable
    
    var baseCommand: [String] {
        [era.rawValue, "node"]
    }
    
    init(baseCLI: any BinaryInterfaceable) {
        self.baseCLI = baseCLI
    }
    
    /// Generate node operator's offline key pair and certificate issue counter
    public func keyGen(verificationKeyFile: String, signingKeyFile: String, operationalCertificateIssueCounterFile: String) async throws -> String {
        return try await executeCommand("key-gen", arguments: [
            "--verification-key-file", verificationKeyFile,
            "--signing-key-file", signingKeyFile,
            "--operational-certificate-issue-counter-file", operationalCertificateIssueCounterFile
        ])
    }
    
    /// Generate KES operational key pair
    public func keyGenKES(verificationKeyFile: String, signingKeyFile: String) async throws -> String {
        return try await executeCommand("key-gen-KES", arguments: [
            "--verification-key-file", verificationKeyFile,
            "--signing-key-file", signingKeyFile
        ])
    }
    
    /// Generate VRF operational key pair
    public func keyGenVRF(verificationKeyFile: String, signingKeyFile: String) async throws -> String {
        return try await executeCommand("key-gen-VRF", arguments: [
            "--verification-key-file", verificationKeyFile,
            "--signing-key-file", signingKeyFile
        ])
    }
    
    /// Get hash of VRF verification key
    public func keyHashVRF(verificationKeyFile: String) async throws -> String {
        return try await executeCommand("key-hash-VRF", arguments: [
            "--verification-key-file", verificationKeyFile
        ])
    }
    
    /// Issue operational certificate
    public func issueOpCert(kesVerificationKeyFile: String, coldSigningKeyFile: String, operationalCertificateIssueCounterFile: String, kesPeriod: Int, outFile: String) async throws -> String {
        return try await executeCommand("issue-op-cert", arguments: [
            "--kes-verification-key-file", kesVerificationKeyFile,
            "--cold-signing-key-file", coldSigningKeyFile,
            "--operational-certificate-issue-counter-file", operationalCertificateIssueCounterFile,
            "--kes-period", String(kesPeriod),
            "--out-file", outFile
        ])
    }
    
    /// Create new certificate issue counter
    public func newCounter(coldVerificationKeyFile: String, counterValue: Int, operationalCertificateIssueCounterFile: String) async throws -> String {
        return try await executeCommand("new-counter", arguments: [
            "--cold-verification-key-file", coldVerificationKeyFile,
            "--counter-value", String(counterValue),
            "--operational-certificate-issue-counter-file", operationalCertificateIssueCounterFile
        ])
    }
}
