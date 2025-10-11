import Foundation
import SystemPackage

// MARK: - Cardano CLI Address Command Implementation
extension CardanoCLI {
    /// Implementation of address utility commands
    public struct AddressCommandImpl: CommandProtocol {
        var baseCLI: any BinaryInterfaceable
        
        var baseCommand: [String] {
            [era.rawValue, "address"]
        }
        
        init(baseCLI: any BinaryInterfaceable) {
            self.baseCLI = baseCLI
        }
        
        /// Print information about an address - returns JSON
        public func info(arguments: [String]) async throws -> String {
            return try await executeCommand("info", arguments: arguments)
        }
        
        /// Create an address key pair
        public func keyGen(arguments: [String]) async throws -> String {
            return try await executeCommand("key-gen", arguments: arguments)
        }
        
        /// Print the hash of an address key
        public func keyHash(arguments: [String]) async throws -> String {
            return try await executeCommand("key-hash", arguments: arguments)
        }
        
        /// Build a Shelley payment address, with optional delegation to a stake address
        public func build(arguments: [String]) async throws -> String {
            let networkArgs = baseCLI.configuration.cardano.network.arguments
            return try await executeCommand("build", arguments: arguments + networkArgs)
        }
        
        /// Build a Shelley script address (deprecated; use 'build' instead with '--payment-script-file')
        @available(*, deprecated, message: "use 'build' instead with '--payment-script-file'", renamed: "build")
        public func buildScript(arguments: [String]) async throws -> String {
            baseCLI.logger.warning("build-script is deprecated; use 'build' instead with '--payment-script-file'")
            return try await executeCommand("build-script", arguments: arguments)
        }
    }
}
