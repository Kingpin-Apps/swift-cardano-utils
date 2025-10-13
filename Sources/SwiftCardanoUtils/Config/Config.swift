import Foundation
import Configuration
import SystemPackage
import SwiftCardanoCore

// MARK: - Configuration Models

/// Main configuration structure for SwiftCardanoUtils
public struct Config: Codable, Sendable {
    public let cardano: CardanoConfig
    public let ogmios: OgmiosConfig?
    public let kupo: KupoConfig?
    
    public init(
        cardano: CardanoConfig,
        ogmios: OgmiosConfig? = nil,
        kupo: KupoConfig? = nil
    ) {
        self.cardano = cardano
        self.ogmios = ogmios
        self.kupo = kupo
    }
    
    /// Creates a new Config using values from the provided reader.
    ///
    /// - Parameter config: The config reader to read configuration values from.
    public init(config: ConfigReader) throws {
        self.cardano = CardanoConfig(config: config)
        self.ogmios = try OgmiosConfig(config: config)
        self.kupo = try KupoConfig(config: config)
    }
    
    public static func `default`() throws -> Config {
        return Config(
            cardano: try CardanoConfig.default(),
            ogmios: try? OgmiosConfig.default(),
            kupo: try? KupoConfig.default()
        )
    }
    
    /// Save the JSON representation to a file.
    /// - Parameter path: The file path.
    public func save(to path: FilePath) throws {
        if FileManager.default.fileExists(atPath: path.string) {
            throw SwiftCardanoUtilsError.fileAlreadyExists("File already exists: \(path)")
        }
        
        let data = try JSONEncoder().encode(self)
        try data.write(to: URL(fileURLWithPath: path.string), options: .atomic)
    }
    
    public static func load(path: FilePath) async throws -> Config {
        let config = ConfigReader(providers: [
            EnvironmentVariablesProvider(),
            try await JSONProvider(filePath: .init(path.string))
        ])
        return try Config(config: config)
    }
}
