import Configuration
import SwiftCardanoCore

extension Era: @retroactive ExpressibleByConfigString {
    public init(configString from: String) {
        self.init(from: from)
    }
}
