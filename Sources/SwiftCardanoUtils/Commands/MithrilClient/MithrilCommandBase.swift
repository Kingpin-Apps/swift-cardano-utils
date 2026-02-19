import Foundation
import SwiftCardanoCore
import Logging

// MARK: - Mithril Command Base Infrastructure

/// Protocol for Mithril command implementations
protocol MithrilCommandProtocol {
    var baseCLI: any BinaryInterfaceable { get }
    var mithrilConfig: MithrilConfig { get }
    var baseCommand: [String] { get }
    func executeCommand(_ subcommand: String, arguments: [String]) async throws -> String
}

/// Base implementation for Mithril command protocol
extension MithrilCommandProtocol {    
    /// Get the aggregator endpoint arguments if configured
    var aggregatorArgs: [String] {
        if let endpoint = mithrilConfig.aggregatorEndpoint {
            return ["--aggregator-endpoint", endpoint]
        } else if let endpoint = Environment.get(.aggregatorEndpoint) {
            return ["--aggregator-endpoint", endpoint]
        } else {
            switch baseCLI.cardanoConfig.network {
                case .mainnet:
                    return ["--aggregator-endpoint", "https://aggregator.release-mainnet.api.mithril.network/aggregator"]
                case .preprod:
                    return ["--aggregator-endpoint", "https://aggregator.release-preprod.api.mithril.network/aggregator"]
                case .preview:
                    return ["--aggregator-endpoint", "https://aggregator.pre-release-preview.api.mithril.network/aggregator"]
                default:
                        return []
            }
        }
    }
    
    /// Get the genesis verification key arguments if configured
    var genesisVerificationKeyArgs: [String] {
        get async throws {
            if let key = mithrilConfig.genesisVerificationKey {
                return ["--genesis-verification-key", key]
            } else if let key = Environment.get(.genesisVerificationKey) {
                return ["--genesis-verification-key", key]
            } else {
                let genesisKeyURL: URL
                switch baseCLI.cardanoConfig.network {
                    case .mainnet:
                        genesisKeyURL = URL(
                            string: "https://raw.githubusercontent.com/input-output-hk/mithril/main/mithril-infra/configuration/release-mainnet/genesis.vkey"
                        )!
                    case .preprod:
                        genesisKeyURL = URL(
                            string: "https://raw.githubusercontent.com/input-output-hk/mithril/main/mithril-infra/configuration/release-preprod/genesis.vkey"
                        )!
                    case .preview:
                        genesisKeyURL = URL(
                            string: "https://raw.githubusercontent.com/input-output-hk/mithril/main/mithril-infra/configuration/pre-release-preview/genesis.vkey"
                        )!
                    default:
                        return []
                }
                
                let (key, response) = try await URLSession.shared.data(from: genesisKeyURL)
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode)
                else {
                    throw SwiftCardanoUtilsError.networkError("Failed to fetch genesis verification key from URL: \(genesisKeyURL)")
                }
                return ["--genesis-verification-key", key.toString]
            }
        }
    }
    
    /// Execute a command with aggregator endpoint included
    func executeCommand(_ subcommand: String, arguments: [String] = []) async throws -> String {
        let fullCommand = baseCommand + [subcommand] + aggregatorArgs + arguments
        return try await baseCLI.runCommand(fullCommand)
    }
    
    /// Execute a command without additional processing
    func executeRawCommand(_ subcommand: String, arguments: [String] = []) async throws -> String {
        let fullCommand = baseCommand + [subcommand] + arguments
        return try await baseCLI.runCommand(fullCommand)
    }
}
