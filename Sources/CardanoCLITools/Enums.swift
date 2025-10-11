import Foundation
import Configuration
import SwiftCardanoCore
import SystemPackage


// MARK: - Network Type Enum

/// Supported Cardano networks
public enum Network: CaseIterable, Sendable, Equatable, ExpressibleByConfigString {
    case mainnet
    case preprod
    case preview
    case guildnet
    case sanchonet
    case custom(Int)
    
    public static let allCases: [Network] = [
        .mainnet,
        .preprod,
        .preview,
        .guildnet,
        .sanchonet,
        .custom(0) // Placeholder for custom networks
    ]
    
    public init(configString from: String) {
        self.init(from: from)
    }
    
    init(from: String) {
        switch from.lowercased() {
            case "mainnet":
                self = .mainnet
            case "preprod":
                self = .preprod
            case "preview":
                self = .preview
            case "guildnet":
                self = .guildnet
            case "sanchonet":
                self = .sanchonet
            default:
                if let magic = Int(from) {
                    self = .custom(magic)
                } else {
                    self = .mainnet
                }
        }
    }
    
    
    /// Returns the testnet magic for the network
    public var testnetMagic: Int? {
        switch self {
            case .mainnet:
                return nil
            case .preprod:
                return 1
            case .preview:
                return 2
            case .guildnet:
                return 141
            case .sanchonet:
                return 4
            case .custom(let magic):
                return magic
        }
    }
    
    /// Returns the description for the network
    public var description: String {
        switch self {
            case .mainnet:
                return "mainnet"
            case .preprod:
                return "preprod"
            case .preview:
                return "preview"
            case .guildnet:
                return "guildnet"
            case .sanchonet:
                return "sanchonet"
            case .custom(let magic):
                return "custom(\(magic))"
        }
    }
    
    /// Returns the command line arguments for the network
    public var arguments: [String] {
        switch self {
            case .mainnet:
                return ["--mainnet"]
            case .preprod:
                return ["--testnet-magic", "\(testnetMagic!)"]
            case .preview:
                return ["--testnet-magic", "\(testnetMagic!)"]
            case .guildnet:
                return ["--testnet-magic", "\(testnetMagic!)"]
            case .sanchonet:
                return ["--testnet-magic", "\(testnetMagic!)"]
            case .custom(let magic):
                return ["--testnet-magic", "\(magic)"]
        }
    }
    
    /// Returns the SwiftCardanoCore.Network for the network
    public var network: SwiftCardanoCore.Network {
        switch self {
            case .mainnet:
                return .mainnet
            default:
                return .testnet
        }
    }
}

// MARK: - Network Codable Implementation

extension Network: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self) {
            self.init(from: stringValue)
        } else if let intValue = try? container.decode(Int.self) {
            self = .custom(intValue)
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid network value"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .mainnet:
            try container.encode("mainnet")
        case .preprod:
            try container.encode("preprod")
        case .preview:
            try container.encode("preview")
        case .guildnet:
            try container.encode("guildnet")
        case .sanchonet:
            try container.encode("sanchonet")
        case .custom(let magic):
            try container.encode(magic)
        }
    }
}


// MARK: - Hardware Wallet Types

/// Enumeration of supported hardware wallet types
public enum HardwareWalletType: String, CaseIterable, Codable {
    case ledger = "LEDGER"
    case trezor = "TREZOR"
    
    public var displayName: String {
        switch self {
            case .ledger:
                return "Ledger"
            case .trezor:
                return "Trezor"
        }
    }
}

// MARK: - Derivation Type

/// Enumeration of supported derivation types for hardware wallets
public enum DerivationType: String, CaseIterable, Codable {
    case ledger = "LEDGER"
    case icarus = "ICARUS"
    case icarusTrezor = "ICARUS_TREZOR"
    
    public var displayName: String {
        switch self {
            case .ledger:
                return "Ledger"
            case .icarus:
                return "Icarus"
            case .icarusTrezor:
                return "Icarus Trezor"
        }
    }
}


// MARK: - Vote Public Key Input Types

/// Enumeration of supported vote public key input formats
public enum VotePublicKeyInput {
    /// Vote public key from jcli format file (ed25519extended format)
    case jcli(FilePath)
    /// Bech32-encoded vote public key string
    case string(String)
    /// Vote public key from hardware wallet signing file format
    case hwsFile(FilePath)
    /// Vote public key from cardano-cli file format
    case file(FilePath)
}
