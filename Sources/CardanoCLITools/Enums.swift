import Foundation
import SwiftCardanoCore


// MARK: - Network Type Enum

/// Supported Cardano networks
public enum Network: Codable, Sendable, Equatable {
    case mainnet
    case preprod
    case preview
    case guildnet
    case sanchonet
    case custom(Int)
    
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
