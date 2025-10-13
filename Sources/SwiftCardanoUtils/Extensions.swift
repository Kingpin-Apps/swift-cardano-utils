import Configuration
import SystemPackage
import SwiftCardanoCore

extension Era: @retroactive ExpressibleByConfigString {
    public init(configString from: String) {
        self.init(from: from)
    }
}

@propertyWrapper
public struct FilePathCodable: Codable, Sendable {
    public var wrappedValue: FilePath?
    
    public init(wrappedValue: FilePath?) {
        self.wrappedValue = wrappedValue
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String?.self)
        wrappedValue = string != nil ? FilePath(string!) : nil
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue?.string)
    }
}
