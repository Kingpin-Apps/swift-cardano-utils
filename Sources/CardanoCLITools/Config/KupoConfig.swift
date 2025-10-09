import Foundation
import Configuration
import SystemPackage
import SwiftCardanoCore


/// Kupo configuration
public struct KupoConfig: Codable, Sendable {
    @FilePathCodable public var binary: FilePath?
    public let host: String?
    public let port: Int?
    public let since: String?
    public let matches: [String]?
    public let deferDbIndexes: Bool?
    public let pruneUTxO: Bool?
    public let gcInterval: Int?
    public let maxConcurrency: Int?
    public let inMemory: Bool?
    public let logLevel: String?
    public let logLevelHttpServer: String?
    public let logLevelDatabase: String?
    public let logLevelConsumer: String?
    public let logLevelGarbageCollector: String?
    public let logLevelConfiguration: String?
    @FilePathCodable public var workingDir: FilePath?
    public let showOutput: Bool?
    
    public init(
        binary: FilePath,
        host: String? = nil,
        port: Int? = nil,
        since: String? = nil,
        matches: [String]? = nil,
        deferDbIndexes: Bool? = nil,
        pruneUTxO: Bool? = nil,
        gcInterval: Int? = nil,
        maxConcurrency: Int? = nil,
        inMemory: Bool? = nil,
        logLevel: String? = nil,
        logLevelHttpServer: String? = nil,
        logLevelDatabase: String? = nil,
        logLevelConsumer: String? = nil,
        logLevelGarbageCollector: String? = nil,
        logLevelConfiguration: String? = nil,
        workingDir: FilePath? = nil,
        showOutput: Bool? = nil
    ) {
        self.binary = binary
        self.host = host
        self.port = port
        self.since = since
        self.matches = matches
        self.deferDbIndexes = deferDbIndexes
        self.pruneUTxO = pruneUTxO
        self.gcInterval = gcInterval
        self.maxConcurrency = maxConcurrency
        self.inMemory = inMemory
        self.logLevel = logLevel
        self.logLevelHttpServer = logLevelHttpServer
        self.logLevelDatabase = logLevelDatabase
        self.logLevelConsumer = logLevelConsumer
        self.logLevelGarbageCollector = logLevelGarbageCollector
        self.logLevelConfiguration = logLevelConfiguration
        self.workingDir = workingDir
        self.showOutput = showOutput
    }
    
    enum CodingKeys: String, CodingKey {
        case binary
        case host
        case port
        case since
        case matches
        case deferDbIndexes = "defer_db_indexes"
        case pruneUTxO = "prune_utxo"
        case gcInterval = "gc_interval"
        case maxConcurrency = "max_concurrency"
        case inMemory = "in_memory"
        case logLevel = "log_level"
        case logLevelHttpServer = "log_level_http_server"
        case logLevelDatabase = "log_level_database"
        case logLevelConsumer = "log_level_consumer"
        case logLevelGarbageCollector = "log_level_garbage_collector"
        case logLevelConfiguration = "log_level_configuration"
        case workingDir = "working_dir"
        case showOutput = "show_output"
    }
    
    /// Creates a new KupoConfig using values from the provided reader.
    ///
    /// - Parameter config: The config reader to read configuration values from.
    public init(config: ConfigReader) throws {
        func key(_ codingKey: CodingKeys) -> String {
            return "kupo.\(codingKey.rawValue)"
        }
        
        self.binary = try config.requiredString(
            forKey: key(.binary),
            as: FilePath.self
        )
        self.host = config.string(forKey: key(.host))
        self.port = config.int(forKey: key(.port))
        self.since = config.string(forKey: key(.since))
        self.matches = config.stringArray(forKey: key(.matches))
        self.deferDbIndexes = config.bool(forKey: key(.deferDbIndexes))
        self.pruneUTxO = config.bool(forKey: key(.pruneUTxO))
        self.gcInterval = config.int(forKey: key(.gcInterval))
        self.maxConcurrency = config.int(forKey: key(.maxConcurrency))
        self.inMemory = config.bool(forKey: key(.inMemory))
        self.logLevel = config.string(forKey: key(.logLevel))
        self.logLevelHttpServer = config.string(forKey: key(.logLevelHttpServer))
        self.logLevelDatabase = config.string(forKey: key(.logLevelDatabase))
        self.logLevelConsumer = config.string(forKey: key(.logLevelConsumer))
        self.logLevelGarbageCollector = config.string(forKey: key(.logLevelGarbageCollector))
        self.logLevelConfiguration = config.string(forKey: key(.logLevelConfiguration))
        self.workingDir = config.string(forKey: key(.workingDir), as: FilePath.self)
        self.showOutput = config.bool(forKey: key(.showOutput))
    }
    
    public static func `default`() throws -> KupoConfig {
        return KupoConfig(
            binary: try Kupo.getBinaryPath(),
            host: "0.0.0.0",
            port: 1442,
            since: "origin",
            matches: ["*"],
            deferDbIndexes: false,
            pruneUTxO: false,
            gcInterval: 300,
            maxConcurrency: 10,
            inMemory: false,
            logLevel: "info",
            logLevelHttpServer: "info",
            logLevelDatabase: "info",
            logLevelConsumer: "info",
            logLevelGarbageCollector: "info",
            logLevelConfiguration: "info",
            workingDir: FilePath(FileManager.default.currentDirectoryPath),
            showOutput: true,
        )
    }
}

