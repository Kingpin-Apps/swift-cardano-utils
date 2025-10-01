import Foundation
import System

/// Environment variables
enum Environment: String {
    case debug = "DEBUG"
    case network = "NETWORK"
    case cardanoBindAddr = "CARDANO_BIND_ADDR"
    case cardanoBlockProducer = "CARDANO_BLOCK_PRODUCER"
    case cardanoConfig = "CARDANO_CONFIG"
    case cardanoConfigBase = "CARDANO_CONFIG_BASE"
    case cardanoDatabasePath = "CARDANO_DATABASE_PATH"
    case cardanoLogDir = "CARDANO_LOG_DIR"
    case cardanoPort = "CARDANO_PORT"
    case cardanoSocketPath = "CARDANO_SOCKET_PATH"
    case cardanoTopology = "CARDANO_TOPOLOGY"
    case cardanoShelleyKESKey = "CARDANO_SHELLEY_KES_KEY"
    case cardanoShelleyVRFKey = "CARDANO_SHELLEY_VRF_KEY"
    case cardanoShelleyOperationalCertificate = "CARDANO_SHELLEY_OPERATIONAL_CERTIFICATE"
    
    static func get(_ name: Environment) -> String? {
        guard let cString = getenv(name.rawValue) else {
            return nil
        }
        return String(cString: cString)
    }
    
    static func getFilePath(_ name: Environment) -> FilePath? {
        if let path = get(name) {
            return FilePath(path)
        }
        return nil
    }
    
    static func set(_ name: Environment, value: String?) {
        if value == nil {
            _ = unsetenv(name.rawValue)
        } else {
            setenv(name.rawValue, value!, 1)
        }
    }
}
