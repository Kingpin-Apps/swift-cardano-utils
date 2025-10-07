import Foundation
import Configuration
import SystemPackage
import SwiftCardanoCore

// MARK: - Configuration Models

/// Main configuration structure for Cardano CLI tools
public struct CardanoCLIToolsConfig: Codable, Sendable {
    let cardano: CardanoConfig
    let ogmios: OgmiosConfig?
    let kupo: KupoConfig?
    
    init(
        cardano: CardanoConfig,
        ogmios: OgmiosConfig? = nil,
        kupo: KupoConfig? = nil
    ) {
        self.cardano = cardano
        self.ogmios = ogmios
        self.kupo = kupo
    }
    
    /// Creates a new CardanoCLIToolsConfig using values from the provided reader.
    ///
    /// - Parameter config: The config reader to read configuration values from.
    public init(config: ConfigReader) throws {
        self.cardano = CardanoConfig(config: config)
        self.ogmios = try OgmiosConfig(config: config)
        self.kupo = try KupoConfig(config: config)
    }
    
    static func `default`() throws -> CardanoCLIToolsConfig {
        return CardanoCLIToolsConfig(
            cardano: try CardanoConfig.default(),
            ogmios: try? OgmiosConfig.default(),
            kupo: try? KupoConfig.default()
        )
    }
    
    /// Save the JSON representation to a file.
    /// - Parameter path: The file path.
    func save(to path: FilePath) throws {
        if FileManager.default.fileExists(atPath: path.string) {
            throw CardanoCLIToolsError.fileAlreadyExists("File already exists: \(path)")
        }
        
        let data = try JSONEncoder().encode(self)
        try data.write(to: URL(fileURLWithPath: path.string), options: .atomic)
    }
    
    static func load(path: FilePath) async throws -> CardanoCLIToolsConfig {
        let config = ConfigReader(providers: [
            EnvironmentVariablesProvider(),
            try await JSONProvider(filePath: .init(path.string))
        ])
        return try CardanoCLIToolsConfig(config: config)
    }
}
