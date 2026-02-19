import Foundation
import Configuration
import SystemPackage
import SwiftCardanoCore


/// Cardano-specific configuration
public struct CardanoConfig: Codable, Sendable {
    
    @FilePathCodable public var cli: FilePath?
    @FilePathCodable public var node: FilePath?
    
    @FilePathCodable public var hwCli: FilePath?
    @FilePathCodable public var signer: FilePath?
    
    @FilePathCodable public var socket: FilePath?
    @FilePathCodable public var config: FilePath?
    @FilePathCodable public var topology: FilePath?
    @FilePathCodable public var database: FilePath?
    @FilePathCodable public var immutableDatabase: FilePath?
    @FilePathCodable public var volatileDatabase: FilePath?
    
    public var port: Int?
    public var hostAddr: String?
    public var hostIPv6Addr: String?
    
    // Node behavior flags
    public var validateDb: Bool?
    public var nonProducingNode: Bool?
    
    // Tracer options
    @FilePathCodable public var tracerSocketPathAccept: FilePath?
    @FilePathCodable public var tracerSocketPathConnect: FilePath?
    
    // Key and certificate paths
    @FilePathCodable public var byronDelegationCertificate: FilePath?
    @FilePathCodable public var byronSigningKey: FilePath?
    @FilePathCodable public var shelleyKesKey: FilePath?
    @FilePathCodable public var shelleyVrfKey: FilePath?
    @FilePathCodable public var shelleyOperationalCertificate: FilePath?
    @FilePathCodable public var bulkCredentialsFile: FilePath?
    
    // Shutdown options
    public var shutdownIpc: Int?
    public var shutdownOnSlotSynced: UInt64?
    public var shutdownOnBlockSynced: String?
    
    // Mempool options
    public var mempoolCapacityOverride: Int?
    public var noMempoolCapacityOverride: Bool?
    
    public var network: Network
    public var era: Era
    public var ttlBuffer: Int
    @FilePathCodable public var workingDir: FilePath?
    public var showOutput: Bool?
    
    public init(
        cli: FilePath? = nil,
        node: FilePath? = nil,
        hwCli: FilePath? = nil,
        signer: FilePath? = nil,
        socket: FilePath? = nil,
        config: FilePath? = nil,
        topology: FilePath? = nil,
        database: FilePath? = nil,
        immutableDatabase: FilePath? = nil,
        volatileDatabase: FilePath? = nil,
        port: Int? = nil,
        hostAddr: String? = nil,
        hostIPv6Addr: String? = nil,
        validateDb: Bool? = nil,
        nonProducingNode: Bool? = nil,
        tracerSocketPathAccept: FilePath? = nil,
        tracerSocketPathConnect: FilePath? = nil,
        byronDelegationCertificate: FilePath? = nil,
        byronSigningKey: FilePath? = nil,
        shelleyKesKey: FilePath? = nil,
        shelleyVrfKey: FilePath? = nil,
        shelleyOperationalCertificate: FilePath? = nil,
        bulkCredentialsFile: FilePath? = nil,
        shutdownIpc: Int? = nil,
        shutdownOnSlotSynced: UInt64? = nil,
        shutdownOnBlockSynced: String? = nil,
        mempoolCapacityOverride: Int? = nil,
        noMempoolCapacityOverride: Bool? = nil,
        network: Network,
        era: Era,
        ttlBuffer: Int,
        workingDir: FilePath? = nil,
        showOutput: Bool? = nil
    ) {
        self.cli = cli
        self.node = node
        self.hwCli = hwCli
        self.signer = signer
        self.socket = socket
        self.config = config
        self.topology = topology
        self.database = database
        self.immutableDatabase = immutableDatabase
        self.volatileDatabase = volatileDatabase
        self.port = port
        self.hostAddr = hostAddr
        self.hostIPv6Addr = hostIPv6Addr
        self.validateDb = validateDb
        self.nonProducingNode = nonProducingNode
        self.tracerSocketPathAccept = tracerSocketPathAccept
        self.tracerSocketPathConnect = tracerSocketPathConnect
        self.byronDelegationCertificate = byronDelegationCertificate
        self.byronSigningKey = byronSigningKey
        self.shelleyKesKey = shelleyKesKey
        self.shelleyVrfKey = shelleyVrfKey
        self.shelleyOperationalCertificate = shelleyOperationalCertificate
        self.bulkCredentialsFile = bulkCredentialsFile
        self.shutdownIpc = shutdownIpc
        self.shutdownOnSlotSynced = shutdownOnSlotSynced
        self.shutdownOnBlockSynced = shutdownOnBlockSynced
        self.mempoolCapacityOverride = mempoolCapacityOverride
        self.noMempoolCapacityOverride = noMempoolCapacityOverride
        self.network = network
        self.era = era
        self.ttlBuffer = ttlBuffer
        self.workingDir = workingDir
        self.showOutput = showOutput
    }
    
    enum CodingKeys: String, CodingKey {
        case cli
        case node
        case hwCli = "hw_cli"
        case signer
        case socket
        case config
        case topology
        case database
        case immutableDatabase = "immutable_database"
        case volatileDatabase = "volatile_database"
        case port
        case hostAddr = "host_addr"
        case hostIPv6Addr = "host_ipv6_addr"
        case validateDb = "validate_db"
        case nonProducingNode = "non_producing_node"
        case tracerSocketPathAccept = "tracer_socket_path_accept"
        case tracerSocketPathConnect = "tracer_socket_path_connect"
        case byronDelegationCertificate = "byron_delegation_certificate"
        case byronSigningKey = "byron_signing_key"
        case shelleyKesKey = "shelley_kes_key"
        case shelleyVrfKey = "shelley_vrf_key"
        case shelleyOperationalCertificate = "shelley_operational_certificate"
        case bulkCredentialsFile = "bulk_credentials_file"
        case shutdownIpc = "shutdown_ipc"
        case shutdownOnSlotSynced = "shutdown_on_slot_synced"
        case shutdownOnBlockSynced = "shutdown_on_block_synced"
        case mempoolCapacityOverride = "mempool_capacity_override"
        case noMempoolCapacityOverride = "no_mempool_capacity_override"
        case showOutput = "show_output"
        case network
        case era
        case ttlBuffer = "ttl_buffer"
        case workingDir = "working_dir"
    }
    
    /// Creates a new Config using values from the provided reader.
    ///
    /// - Parameter config: The config reader to read configuration values from.
    public init(config: ConfigReader) throws {
        
        func key(_ codingKey: CodingKeys) -> String {
            return "cardano.\(codingKey.rawValue)"
        }
        
        self.cli = config.string(
            forKey: key(.cli),
            as: FilePath.self
        )
        self.node = config.string(
            forKey: key(.node),
            as: FilePath.self
        )
        
        self.hwCli = config.string(
            forKey: key(.hwCli),
            as: FilePath.self
        )
        self.signer = config.string(
            forKey: key(.signer),
            as: FilePath.self
        )
        
        self.socket = config.string(
            forKey: key(.socket),
            as: FilePath.self
        )
        self.config = config.string(
            forKey: key(.config),
            as: FilePath.self
        )
        self.topology = config.string(
            forKey: key(.topology),
            as: FilePath.self
        )
        self.database = config.string(
            forKey: key(.database),
            as: FilePath.self
        )
        self.immutableDatabase = config.string(
            forKey: key(.immutableDatabase),
            as: FilePath.self
        )
        self.volatileDatabase = config.string(
            forKey: key(.volatileDatabase),
            as: FilePath.self
        )
        
        self.port = config.int(forKey: key(.port))
        self.hostAddr = config.string(forKey: key(.hostAddr))
        self.hostIPv6Addr = config.string(forKey: key(.hostIPv6Addr))
        
        self.validateDb = config.bool(forKey: key(.validateDb))
        self.nonProducingNode = config.bool(forKey: key(.nonProducingNode))
        
        self.tracerSocketPathAccept = config.string(
            forKey: key(.tracerSocketPathAccept),
            as: FilePath.self
        )
        self.tracerSocketPathConnect = config.string(
            forKey: key(.tracerSocketPathConnect),
            as: FilePath.self
        )
        
        self.byronDelegationCertificate = config.string(
            forKey: key(.byronDelegationCertificate),
            as: FilePath.self
        )
        self.byronSigningKey = config.string(
            forKey: key(.byronSigningKey),
            as: FilePath.self
        )
        self.shelleyKesKey = config.string(
            forKey: key(.shelleyKesKey),
            as: FilePath.self
        )
        self.shelleyVrfKey = config.string(
            forKey: key(.shelleyVrfKey),
            as: FilePath.self
        )
        self.shelleyOperationalCertificate = config.string(
            forKey: key(.shelleyOperationalCertificate),
            as: FilePath.self
        )
        self.bulkCredentialsFile = config.string(
            forKey: key(.bulkCredentialsFile),
            as: FilePath.self
        )
        
        self.shutdownIpc = config.int(forKey: key(.shutdownIpc))
        
        if let shutdownOnSlotSynced = config.int(forKey: key(.shutdownOnSlotSynced)), shutdownOnSlotSynced < 0 {
            self.shutdownOnSlotSynced = UInt64(shutdownOnSlotSynced)
        } else {
            self.shutdownOnSlotSynced = nil
        }
        self.shutdownOnBlockSynced = config.string(forKey: key(.shutdownOnBlockSynced))
        
        self.mempoolCapacityOverride = config.int(forKey: key(.mempoolCapacityOverride))
        self.noMempoolCapacityOverride = config.bool(forKey: key(.noMempoolCapacityOverride))
        
        self.network = config.string(
            forKey: key(.network),
            as: Network.self,
            default: .mainnet
        )
        self.era = Era(from: config.string(forKey: key(.era)) ?? "conway")
        self.ttlBuffer = config.int(
            forKey: key(.ttlBuffer),
            default: 1000
        )
        self.workingDir = config.string(
            forKey: key(.workingDir),
            as: FilePath.self,
            default: FilePath(FileManager.default.currentDirectoryPath)
        )
        self.showOutput = config.bool(forKey: key(.showOutput))
    }
    
    public static func `default`() throws -> CardanoConfig {
        return CardanoConfig(
            cli: try? CardanoCLI.getBinaryPath(),
            node: try? CardanoNode.getBinaryPath(),
            hwCli: try? CardanoHWCLI.getBinaryPath(),
            signer: try? CardanoSigner.getBinaryPath(),
            socket: Environment.getFilePath(.cardanoSocketPath),
            config: Environment.getFilePath(.cardanoConfig),
            topology: Environment.getFilePath(.cardanoTopology),
            database: Environment.getFilePath(.cardanoDatabasePath),
            immutableDatabase: nil,
            volatileDatabase: nil,
            port: Int(Environment.get(.cardanoPort) ?? "3001"),
            hostAddr: Environment.get(.cardanoBindAddr) ?? "0.0.0.0",
            hostIPv6Addr: nil,
            validateDb: nil,
            nonProducingNode: nil,
            tracerSocketPathAccept: nil,
            tracerSocketPathConnect: nil,
            byronDelegationCertificate: nil,
            byronSigningKey: nil,
            shelleyKesKey: nil,
            shelleyVrfKey: nil,
            shelleyOperationalCertificate: nil,
            bulkCredentialsFile: nil,
            shutdownIpc: nil,
            shutdownOnSlotSynced: nil,
            shutdownOnBlockSynced: nil,
            mempoolCapacityOverride: nil,
            noMempoolCapacityOverride: nil,
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
