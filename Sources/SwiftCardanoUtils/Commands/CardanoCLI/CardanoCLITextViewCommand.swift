import Foundation

// MARK: - Text View Command Implementation

/// Implementation of text view commands
public struct TextViewCommandImpl: CommandProtocol {
    var baseCLI: any BinaryInterfaceable
    
    var baseCommand: [String] {
        [era.rawValue, "text-view"]
    }
    
    init(baseCLI: any BinaryInterfaceable) {
        self.baseCLI = baseCLI
    }
    
    /// Print a TextView file as decoded CBOR
    public func decodeCbor(arguments: [String]) async throws -> String {
        return try await executeCommand("decode-cbor", arguments: arguments)
    }
}
