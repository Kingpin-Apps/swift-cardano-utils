import Foundation
import System
import SwiftCardanoCore

// MARK: - Configuration Models

/// Main configuration structure for Cardano CLI tools
public struct Configuration: Codable, Sendable {
    let cardano: CardanoConfig
    let ogmios: OgmiosConfig?
    let kupo: KupoConfig?
}

/// Cardano-specific configuration
public struct CardanoConfig: Codable, Sendable {
    public let cli: FilePath
    public let node: FilePath
    
    public let hwCli: FilePath?
    public let signer: FilePath?
    
    public let socket: FilePath
    public let config: FilePath
    public let topology: FilePath?
    public let database: FilePath?
    
    public let port: Int?
    public let hostAddr: String?
    
    public let network: Network
    public let era: Era
    public let ttlBuffer: Int
    public let workingDir: FilePath
    public let showOutput: Bool?
    
    enum CodingKeys: String, CodingKey {
        case cli
        case node
        case hwCli = "hw_cli"
        case signer
        case socket
        case config
        case topology
        case database
        case port
        case hostAddr = "host_addr"
        case showOutput = "show_output"
        case network
        case era
        case ttlBuffer = "ttl_buffer"
        case workingDir = "working_dir"
    }
    
    static func `default`() throws -> CardanoConfig {
        return CardanoConfig(
            cli: try CardanoCLI.getBinaryPath(),
            node: try CardanoNode.getBinaryPath(),
            hwCli: try CardanoHWCLI.getBinaryPath(),
            signer: try CardanoSigner.getBinaryPath(),
            socket: Environment.getFilePath(.cardanoSocketPath)!,
            config: Environment.getFilePath(.cardanoConfig)!,
            topology: Environment.getFilePath(.cardanoTopology)!,
            database: Environment.getFilePath(.cardanoDatabasePath)!,
            port: Int(Environment.get(.cardanoPort)!),
            hostAddr: Environment.get(.cardanoBindAddr)!,
            network: Network(
                from: Environment.get(.network) ?? "mainnet"
            ),
            era: .conway,
            ttlBuffer: 3600,
            workingDir: FilePath(FileManager.default.currentDirectoryPath),
            showOutput: true,
        )
    }
}

/// Ogmios configuration
public struct OgmiosConfig: Codable, Sendable {
    let binary: FilePath
    let host: String?
    let port: Int?
    let timeout: Int?
    let maxInFlight: Int?
    let logLevel: String?
    let logLevelHealth: String?
    let logLevelMetrics: String?
    let logLevelWebsocket: String?
    let logLevelServer: String?
    let logLevelOptions: String?
    let workingDir: FilePath?
    let showOutput: Bool?
    
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
    
    static func `default`() throws -> OgmiosConfig {
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

/// Kupo configuration
public struct KupoConfig: Codable, Sendable {
    let binary: FilePath
    let host: String?
    let port: Int?
    let since: String?
    let matches: [String]?
    let deferDbIndexes: Bool?
    let pruneUTxO: Bool?
    let gcInterval: Int?
    let maxConcurrency: Int?
    let logLevel: String?
    let logLevelHttpServer: String?
    let logLevelDatabase: String?
    let logLevelConsumer: String?
    let logLevelGarbageCollector: String?
    let logLevelConfiguration: String?
    let workingDir: FilePath?
    let showOutput: Bool?
    
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
        case logLevel = "log_level"
        case logLevelHttpServer = "log_level_http_server"
        case logLevelDatabase = "log_level_database"
        case logLevelConsumer = "log_level_consumer"
        case logLevelGarbageCollector = "log_level_garbage_collector"
        case logLevelConfiguration = "log_level_configuration"
        case workingDir = "working_dir"
        case showOutput = "show_output"
    }
    
    static func `default`() throws -> KupoConfig {
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

