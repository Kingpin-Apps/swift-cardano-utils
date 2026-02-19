import Foundation
import Configuration
import SystemPackage
import SwiftCardanoCore

/// Mithril client configuration
public struct MithrilConfig: Codable, Sendable {
    @FilePathCodable public var binary: FilePath?
    public var aggregatorEndpoint: String?
    public var genesisVerificationKey: String?
    public var ancillaryVerificationKey: String?
    @FilePathCodable public var downloadDir: FilePath?
    @FilePathCodable public var workingDir: FilePath?
    public var showOutput: Bool?
    
    enum CodingKeys: String, CodingKey {
        case binary
        case aggregatorEndpoint = "aggregator_endpoint"
        case genesisVerificationKey = "genesis_verification_key"
        case ancillaryVerificationKey = "ancillary_verification_key"
        case downloadDir = "download_dir"
        case workingDir = "working_dir"
        case showOutput = "show_output"
    }
    
    public init(
        binary: FilePath? = nil,
        aggregatorEndpoint: String? = nil,
        genesisVerificationKey: String? = nil,
        ancillaryVerificationKey: String? = nil,
        downloadDir: FilePath? = nil,
        workingDir: FilePath? = nil,
        showOutput: Bool? = nil
    ) {
        self.binary = binary
        self.aggregatorEndpoint = aggregatorEndpoint
        self.genesisVerificationKey = genesisVerificationKey
        self.ancillaryVerificationKey = ancillaryVerificationKey
        self.downloadDir = downloadDir
        self.workingDir = workingDir
        self.showOutput = showOutput
    }
    
    /// Creates a new MithrilConfig using values from the provided reader.
    ///
    /// - Parameter config: The config reader to read configuration values from.
    public init(config: ConfigReader) throws {
        func key(_ codingKey: CodingKeys) -> String {
            return "mithril.\(codingKey.rawValue)"
        }
        
        self.binary = config.string(
            forKey: key(.binary),
            as: FilePath.self
        )
        self.aggregatorEndpoint = config.string(forKey: key(.aggregatorEndpoint))
        self.genesisVerificationKey = config.string(forKey: key(.genesisVerificationKey))
        self.ancillaryVerificationKey = config.string(forKey: key(.ancillaryVerificationKey))
        self.downloadDir = config.string(forKey: key(.downloadDir), as: FilePath.self)
        self.workingDir = config.string(forKey: key(.workingDir), as: FilePath.self)
        self.showOutput = config.bool(forKey: key(.showOutput))
    }
    
    public static func `default`() throws -> MithrilConfig {
        return MithrilConfig(
            binary: try? MithrilClient.getBinaryPath(),
            aggregatorEndpoint: Environment.get(.aggregatorEndpoint),
            genesisVerificationKey: Environment.get(.genesisVerificationKey),
            ancillaryVerificationKey: Environment.get(.ancillaryVerificationKey),
            downloadDir: nil,
            workingDir: FilePath(FileManager.default.currentDirectoryPath),
            showOutput: true
        )
    }
}
