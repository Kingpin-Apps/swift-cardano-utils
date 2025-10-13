import Foundation
import Configuration
import SystemPackage
import SwiftCardanoCore

/// Ogmios configuration
public struct OgmiosConfig: Codable, Sendable {
    @FilePathCodable public var binary: FilePath?
    public let host: String?
    public let port: Int?
    public let timeout: Int?
    public let maxInFlight: Int?
    public let logLevel: String?
    public let logLevelHealth: String?
    public let logLevelMetrics: String?
    public let logLevelWebsocket: String?
    public let logLevelServer: String?
    public let logLevelOptions: String?
    @FilePathCodable public var workingDir: FilePath?
    public let showOutput: Bool?
    
    enum CodingKeys: String, CodingKey {
        case binary
        case host
        case port
        case timeout
        case maxInFlight = "max_in_flight"
        case logLevel = "log_level"
        case logLevelHealth = "log_level_health"
        case logLevelMetrics = "log_level_metrics"
        case logLevelWebsocket = "log_level_websocket"
        case logLevelServer = "log_level_server"
        case logLevelOptions = "log_level_options"
        case workingDir = "working_dir"
        case showOutput = "show_output"
    }
    
    public init(
        binary: FilePath,
        host: String? = nil,
        port: Int? = nil,
        timeout: Int? = nil,
        maxInFlight: Int? = nil,
        logLevel: String? = nil,
        logLevelHealth: String? = nil,
        logLevelMetrics: String? = nil,
        logLevelWebsocket: String? = nil,
        logLevelServer: String? = nil,
        logLevelOptions: String? = nil,
        workingDir: FilePath? = nil,
        showOutput: Bool? = nil
    ) {
        self.binary = binary
        self.host = host
        self.port = port
        self.timeout = timeout
        self.maxInFlight = maxInFlight
        self.logLevel = logLevel
        self.logLevelHealth = logLevelHealth
        self.logLevelMetrics = logLevelMetrics
        self.logLevelWebsocket = logLevelWebsocket
        self.logLevelServer = logLevelServer
        self.logLevelOptions = logLevelOptions
        self.workingDir = workingDir
        self.showOutput = showOutput
    }
    
    /// Creates a new OgmiosConfig using values from the provided reader.
    ///
    /// - Parameter config: The config reader to read configuration values from.
    public init(config: ConfigReader) throws {
        func key(_ codingKey: CodingKeys) -> String {
            return "ogmios.\(codingKey.rawValue)"
        }
        
        self.binary = try config.requiredString(
            forKey: key(.binary),
            as: FilePath.self
        )
        self.host = config.string(forKey: key(.host))
        self.port = config.int(forKey: key(.port))
        self.timeout = config.int(forKey: key(.timeout))
        self.maxInFlight = config.int(forKey: key(.maxInFlight))
        self.logLevel = config.string(forKey: key(.logLevel))
        self.logLevelHealth = config.string(forKey: key(.logLevelHealth))
        self.logLevelMetrics = config.string(forKey: key(.logLevelMetrics))
        self.logLevelWebsocket = config.string(forKey: key(.logLevelWebsocket))
        self.logLevelServer = config.string(forKey: key(.logLevelServer))
        self.logLevelOptions = config.string(forKey: key(.logLevelOptions))
        self.workingDir = config.string(forKey: key(.workingDir), as: FilePath.self)
        self.showOutput = config.bool(forKey: key(.showOutput))
    }
    
    public static func `default`() throws -> OgmiosConfig {
        return OgmiosConfig(
            binary: try Ogmios.getBinaryPath(),
            host: "0.0.0.0",
            port: 1337,
            timeout: 30,
            maxInFlight: 100,
            logLevel: "info",
            logLevelHealth: "info",
            logLevelMetrics: "info",
            logLevelWebsocket: "info",
            logLevelServer: "info",
            logLevelOptions: "info",
            workingDir: FilePath(FileManager.default.currentDirectoryPath),
            showOutput: true,
        )
    }
}
