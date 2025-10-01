import Testing
import Foundation
import System
@testable import CardanoCLITools

@Suite("Environment Tests", .serialized)
struct EnvironmentTests {
    
    // MARK: - Test Setup & Teardown
    
    /// Helper to backup and restore environment variables
    private func withTestEnvironment<T>(_ body: () throws -> T) rethrows -> T {
        // Backup original values for Environment variables we'll be testing
        let testEnvVars: [Environment] = [
            .debug, .network, .cardanoBindAddr, .cardanoBlockProducer,
            .cardanoConfig, .cardanoConfigBase, .cardanoDatabasePath,
            .cardanoLogDir, .cardanoPort, .cardanoSocketPath, .cardanoTopology,
            .cardanoShelleyKESKey, .cardanoShelleyVRFKey, .cardanoShelleyOperationalCertificate
        ]
        
        let originalValues: [Environment: String?] = testEnvVars.reduce(into: [:]) { result, env in
            result[env] = Environment.get(env)
        }
        
        defer {
            // Restore original environment
            for (env, originalValue) in originalValues {
                Environment.set(env, value: originalValue)
            }
        }
        
        // Clear all test variables first
        for env in testEnvVars {
            Environment.set(env, value: nil)
        }
        
        return try body()
    }
    
    // MARK: - Raw Value Tests
    
    @Test("Environment enum has correct raw values")
    func testEnvironmentRawValues() {
        #expect(Environment.debug.rawValue == "DEBUG")
        #expect(Environment.network.rawValue == "NETWORK")
        #expect(Environment.cardanoBindAddr.rawValue == "CARDANO_BIND_ADDR")
        #expect(Environment.cardanoBlockProducer.rawValue == "CARDANO_BLOCK_PRODUCER")
        #expect(Environment.cardanoConfig.rawValue == "CARDANO_CONFIG")
        #expect(Environment.cardanoConfigBase.rawValue == "CARDANO_CONFIG_BASE")
        #expect(Environment.cardanoDatabasePath.rawValue == "CARDANO_DATABASE_PATH")
        #expect(Environment.cardanoLogDir.rawValue == "CARDANO_LOG_DIR")
        #expect(Environment.cardanoPort.rawValue == "CARDANO_PORT")
        #expect(Environment.cardanoSocketPath.rawValue == "CARDANO_SOCKET_PATH")
        #expect(Environment.cardanoTopology.rawValue == "CARDANO_TOPOLOGY")
        #expect(Environment.cardanoShelleyKESKey.rawValue == "CARDANO_SHELLEY_KES_KEY")
        #expect(Environment.cardanoShelleyVRFKey.rawValue == "CARDANO_SHELLEY_VRF_KEY")
        #expect(Environment.cardanoShelleyOperationalCertificate.rawValue == "CARDANO_SHELLEY_OPERATIONAL_CERTIFICATE")
    }
    
    // MARK: - get(_:) Method Tests
    
    @Test("get returns existing environment variable")
    func testGetExistingVariable() {
        withTestEnvironment {
            Environment.set(.debug, value: "true")
            let result = Environment.get(.debug)
            #expect(result == "true")
        }
    }
    
    @Test("get returns nil for non-existing environment variable")
    func testGetNonExistingVariable() {
        withTestEnvironment {
            Environment.set(.debug, value: nil) // Ensure it's unset
            let result = Environment.get(.debug)
            #expect(result == nil)
        }
    }
    
    @Test("get returns empty string for empty environment variable")
    func testGetEmptyVariable() {
        withTestEnvironment {
            Environment.set(.debug, value: "")
            let result = Environment.get(.debug)
            #expect(result == "")
        }
    }
    
    @Test("get works with different environment variables")
    func testGetDifferentVariables() {
        withTestEnvironment {
            Environment.set(.network, value: "mainnet")
            Environment.set(.cardanoSocketPath, value: "/tmp/socket1")  // Use different variable
            Environment.set(.cardanoBindAddr, value: "0.0.0.0")
            
            #expect(Environment.get(.network) == "mainnet")
            #expect(Environment.get(.cardanoSocketPath) == "/tmp/socket1")
            #expect(Environment.get(.cardanoBindAddr) == "0.0.0.0")
        }
    }
    
    // MARK: - getFilePath(_:) Method Tests
    
    @Test("getFilePath returns FilePath for existing variable")
    func testGetFilePathExistingVariable() {
        withTestEnvironment {
            let testPath = "/tmp/test/path"
            Environment.set(.cardanoConfig, value: testPath)
            
            let result = Environment.getFilePath(.cardanoConfig)
            #expect(result == FilePath(testPath))
        }
    }
    
    @Test("getFilePath returns nil for non-existing variable")
    func testGetFilePathNonExistingVariable() {
        withTestEnvironment {
            Environment.set(.cardanoConfig, value: nil) // Ensure it's unset
            let result = Environment.getFilePath(.cardanoConfig)
            #expect(result == nil)
        }
    }
    
    @Test("getFilePath handles relative paths")
    func testGetFilePathRelativePath() {
        withTestEnvironment {
            let relativePath = "./config/cardano.json"
            Environment.set(.cardanoConfig, value: relativePath)
            
            let result = Environment.getFilePath(.cardanoConfig)
            #expect(result == FilePath(relativePath))
        }
    }
    
    @Test("getFilePath handles paths with spaces")
    func testGetFilePathWithSpaces() {
        withTestEnvironment {
            let pathWithSpaces = "/path/with spaces/config.json"
            Environment.set(.cardanoConfig, value: pathWithSpaces)
            
            let result = Environment.getFilePath(.cardanoConfig)
            #expect(result == FilePath(pathWithSpaces))
        }
    }
    
    @Test("getFilePath handles different path types")
    func testGetFilePathDifferentTypes() {
        withTestEnvironment {
            let socketPath = "/tmp/cardano.socket"
            let databasePath = "/var/lib/cardano/db"
            let logDir = "/var/log/cardano"
            
            Environment.set(.cardanoSocketPath, value: socketPath)
            Environment.set(.cardanoDatabasePath, value: databasePath)
            Environment.set(.cardanoLogDir, value: logDir)
            
            #expect(Environment.getFilePath(.cardanoSocketPath) == FilePath(socketPath))
            #expect(Environment.getFilePath(.cardanoDatabasePath) == FilePath(databasePath))
            #expect(Environment.getFilePath(.cardanoLogDir) == FilePath(logDir))
        }
    }
    
    // MARK: - set(_:value:) Method Tests
    
    @Test("set sets environment variable with string value")
    func testSetWithStringValue() {
        withTestEnvironment {
            Environment.set(.network, value: "testnet")
            
            let result = Environment.get(.network)
            #expect(result == "testnet")
        }
    }
    
    @Test("set unsets environment variable with nil value")
    func testSetWithNilValue() {
        withTestEnvironment {
            // First set a value
            Environment.set(.network, value: "testnet")
            #expect(Environment.get(.network) == "testnet")
            
            // Then unset it
            Environment.set(.network, value: nil)
            #expect(Environment.get(.network) == nil)
        }
    }
    
    @Test("set overwrites existing environment variable")
    func testSetOverwritesExistingValue() {
        withTestEnvironment {
            // Use a unique variable for this test
            Environment.set(.cardanoLogDir, value: "3000")
            #expect(Environment.get(.cardanoLogDir) == "3000")
            
            Environment.set(.cardanoLogDir, value: "3001")
            #expect(Environment.get(.cardanoLogDir) == "3001")
        }
    }
    
    @Test("set handles empty string value")
    func testSetWithEmptyString() {
        withTestEnvironment {
            Environment.set(.debug, value: "")
            
            let result = Environment.get(.debug)
            #expect(result == "")
        }
    }
    
    @Test("set handles special characters in values")
    func testSetWithSpecialCharacters() {
        withTestEnvironment {
            let specialValue = "test@#$%^&*()_+{}|:<>?[]\\;'\",./"
            Environment.set(.debug, value: specialValue)
            
            let result = Environment.get(.debug)
            #expect(result == specialValue)
        }
    }
    
    // MARK: - Integration Tests
    
    @Test("Environment variables work together")
    func testEnvironmentVariablesWorkTogether() {
        withTestEnvironment {
            Environment.set(.network, value: "mainnet")
            Environment.set(.cardanoPort, value: "3001")
            Environment.set(.cardanoBindAddr, value: "127.0.0.1")
            Environment.set(.cardanoConfig, value: "/etc/cardano/mainnet.json")
            
            #expect(Environment.get(.network) == "mainnet")
            #expect(Environment.get(.cardanoPort) == "3001")
            #expect(Environment.get(.cardanoBindAddr) == "127.0.0.1")
            #expect(Environment.getFilePath(.cardanoConfig) == FilePath("/etc/cardano/mainnet.json"))
        }
    }
    
    @Test("Setting and unsetting multiple variables")
    func testMultipleVariableSetUnset() {
        withTestEnvironment {
            let variables: [(Environment, String)] = [
                (.network, "testnet"),
                (.cardanoPort, "3002"),
                (.cardanoBindAddr, "0.0.0.0"),
                (.cardanoConfig, "/tmp/config.json"),
                (.cardanoDatabasePath, "/tmp/db"),
                (.cardanoLogDir, "/tmp/logs")
            ]
            
            // Set all variables
            for (env, value) in variables {
                Environment.set(env, value: value)
            }
            
            // Verify all variables are set
            for (env, expected) in variables {
                #expect(Environment.get(env) == expected)
            }
            
            // Unset all variables
            for (env, _) in variables {
                Environment.set(env, value: nil)
            }
            
            // Verify all variables are unset
            for (env, _) in variables {
                #expect(Environment.get(env) == nil)
            }
        }
    }
    
    // MARK: - Edge Cases
    
    @Test("Environment handles unicode characters")
    func testUnicodeCharacters() {
        withTestEnvironment {
            let unicodeValue = "配置文件路径/config.json"
            Environment.set(.cardanoConfig, value: unicodeValue)
            
            let result = Environment.get(.cardanoConfig)
            #expect(result == unicodeValue)
            
            let filePath = Environment.getFilePath(.cardanoConfig)
            #expect(filePath == FilePath(unicodeValue))
        }
    }
    
    @Test("Environment handles very long paths")
    func testVeryLongPaths() {
        withTestEnvironment {
            let longPath = String(repeating: "a", count: 4096) + "/config.json"
            Environment.set(.cardanoConfig, value: longPath)
            
            let result = Environment.get(.cardanoConfig)
            #expect(result == longPath)
            
            let filePath = Environment.getFilePath(.cardanoConfig)
            #expect(filePath == FilePath(longPath))
        }
    }
    
    @Test("Environment variables are case sensitive")
    func testCaseSensitiveVariables() {
        withTestEnvironment {
            Environment.set(.debug, value: "true")
            
            // The enum should match exactly
            #expect(Environment.get(.debug) == "true")
            
            // Manually check that case matters in underlying system
            let processEnv = ProcessInfo.processInfo.environment
            #expect(processEnv["DEBUG"] == "true")
            #expect(processEnv["debug"] == nil) // Different case should not exist
        }
    }
}