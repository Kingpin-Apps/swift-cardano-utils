import Foundation
import SystemPackage

// MARK: - Cardano HW CLI Device Command Implementation

extension CardanoHWCLI {
    
    /// Implementation of key utility commands
    public struct DeviceCommandImpl: CommandProtocol {
        var baseCLI: any BinaryInterfaceable
        
        var baseCommand: [String] {
            ["device"]
        }
        
        init(baseCLI: any BinaryInterfaceable) {
            self.baseCLI = baseCLI
        }
        
        /// Get the version of the connected hardware wallet
        ///
        /// - Returns: The version string of the connected hardware wallet
        public func version() async throws -> String {
            return try await executeCommand("version")
        }
    }
    
}
