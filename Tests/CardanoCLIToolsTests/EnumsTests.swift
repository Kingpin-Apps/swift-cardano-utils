import Testing
import Foundation
@testable import CardanoCLITools


@Suite("Network Tests")
struct NetworkTests {
    @Test func testNetworkTestnetMagic() {
        // Test mainnet (should be nil)
        #expect(Network.mainnet.testnetMagic == nil)
        
        // Test testnet networks (should have specific magic numbers)
        #expect(Network.preprod.testnetMagic == 1)
        #expect(Network.preview.testnetMagic == 2)
        #expect(Network.guildnet.testnetMagic == 141)
        #expect(Network.sanchonet.testnetMagic == 4)
        
        // Test custom network
        let customMagic = 999
        #expect(Network.custom(customMagic).testnetMagic == customMagic)
    }
    
    @Test func testNetworkDescription() {
        // Test descriptions for predefined networks
        #expect(Network.mainnet.description == "mainnet")
        #expect(Network.preprod.description == "preprod")
        #expect(Network.preview.description == "preview")
        #expect(Network.guildnet.description == "guildnet")
        #expect(Network.sanchonet.description == "sanchonet")
        
        // Test description for custom network
        let customMagic = 999
        #expect(Network.custom(customMagic).description == "custom(\(customMagic))")
    }
    
    @Test func testNetworkArguments() {
        // Test mainnet arguments
        #expect(Network.mainnet.arguments == ["--mainnet"])
        
        // Test testnet network arguments
        #expect(Network.preprod.arguments == ["--testnet-magic", "1"])
        #expect(Network.preview.arguments == ["--testnet-magic", "2"])
        #expect(Network.guildnet.arguments == ["--testnet-magic", "141"])
        #expect(Network.sanchonet.arguments == ["--testnet-magic", "4"])
        
        // Test custom network arguments
        let customMagic = 999
        #expect(Network.custom(customMagic).arguments == ["--testnet-magic", "\(customMagic)"])
    }
    
    @Test func testNetworkEquality() async {
        // Create two instances of the same network type
        let mainnet1 = Network.mainnet
        let mainnet2 = Network.mainnet
        
        // Test equality using description as Network doesn't conform to Equatable
        #expect(mainnet1.description == mainnet2.description)
        
        // Test custom networks with same magic number
        let customMagic = 999
        let custom1 = Network.custom(customMagic)
        let custom2 = Network.custom(customMagic)
        
        #expect(custom1.description == custom2.description)
        #expect(custom1.testnetMagic == custom2.testnetMagic)
        #expect(custom1.arguments == custom2.arguments)
    }
    
    @Test func testNetworkArgumentsFormat() async {
        // Test that arguments are properly formatted for CLI use
        for network in [Network.preprod, Network.preview, Network.guildnet, Network.sanchonet] {
            let args = network.arguments
            #expect(args.count == 2)
            #expect(args[0] == "--testnet-magic")
            #expect(args[1] == "\(network.testnetMagic!)")
        }
        
        // Test mainnet separately as it has a different format
        let mainnetArgs = Network.mainnet.arguments
        #expect(mainnetArgs.count == 1)
        #expect(mainnetArgs[0] == "--mainnet")
    }
}


@Suite("Enums Tests")
struct EnumsTests {
    
    // MARK: - HardwareWalletType Tests
    
    @Test("HardwareWalletType enum has all expected cases")
    func testHardwareWalletTypeAllCases() {
        let expectedCases: Set<HardwareWalletType> = [.ledger, .trezor]
        let actualCases = Set(HardwareWalletType.allCases)
        
        #expect(actualCases == expectedCases)
        #expect(HardwareWalletType.allCases.count == 2)
    }
    
    @Test("HardwareWalletType raw values are correct")
    func testHardwareWalletTypeRawValues() {
        #expect(HardwareWalletType.ledger.rawValue == "LEDGER")
        #expect(HardwareWalletType.trezor.rawValue == "TREZOR")
    }
    
    @Test("HardwareWalletType display names are correct")
    func testHardwareWalletTypeDisplayNames() {
        #expect(HardwareWalletType.ledger.displayName == "Ledger")
        #expect(HardwareWalletType.trezor.displayName == "Trezor")
    }
    
    @Test("HardwareWalletType can be initialized from raw value")
    func testHardwareWalletTypeInitializationFromRawValue() {
        #expect(HardwareWalletType(rawValue: "LEDGER") == .ledger)
        #expect(HardwareWalletType(rawValue: "TREZOR") == .trezor)
        #expect(HardwareWalletType(rawValue: "ledger") == nil) // Case sensitive
        #expect(HardwareWalletType(rawValue: "trezor") == nil) // Case sensitive
        #expect(HardwareWalletType(rawValue: "invalid") == nil)
        #expect(HardwareWalletType(rawValue: "") == nil)
    }
    
    @Test("HardwareWalletType display name formatting")
    func testHardwareWalletTypeDisplayNameFormatting() {
        for walletType in HardwareWalletType.allCases {
            let displayName = walletType.displayName
            
            // Display name should be properly capitalized
            #expect(displayName.first?.isUppercase == true, "Display name should start with uppercase letter")
            
            // Display name should not be empty
            #expect(!displayName.isEmpty, "Display name should not be empty")
            
            // Display name should be different from raw value (more user-friendly)
            #expect(displayName != walletType.rawValue, "Display name should be different from raw value")
        }
    }
    
    // MARK: - Codable Tests for HardwareWalletType
    
    @Test("HardwareWalletType can be encoded to JSON")
    func testHardwareWalletTypeJSONEncoding() async throws {
        let encoder = JSONEncoder()
        
        let ledgerData = try encoder.encode(HardwareWalletType.ledger)
        let ledgerString = String(data: ledgerData, encoding: .utf8)
        #expect(ledgerString == "\"LEDGER\"")
        
        let trezorData = try encoder.encode(HardwareWalletType.trezor)
        let trezorString = String(data: trezorData, encoding: .utf8)
        #expect(trezorString == "\"TREZOR\"")
    }
    
    @Test("HardwareWalletType can be decoded from JSON")
    func testHardwareWalletTypeJSONDecoding() async throws {
        let decoder = JSONDecoder()
        
        let ledgerData = "\"LEDGER\"".data(using: .utf8)!
        let decodedLedger = try decoder.decode(HardwareWalletType.self, from: ledgerData)
        #expect(decodedLedger == .ledger)
        
        let trezorData = "\"TREZOR\"".data(using: .utf8)!
        let decodedTrezor = try decoder.decode(HardwareWalletType.self, from: trezorData)
        #expect(decodedTrezor == .trezor)
    }
    
    @Test("HardwareWalletType JSON decoding fails for invalid values")
    func testHardwareWalletTypeJSONDecodingFailure() {
        let decoder = JSONDecoder()
        
        let invalidData = "\"INVALID\"".data(using: .utf8)!
        
        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(HardwareWalletType.self, from: invalidData)
        }
        
        let lowercaseData = "\"ledger\"".data(using: .utf8)!
        
        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(HardwareWalletType.self, from: lowercaseData)
        }
    }
    
    // MARK: - Cross-Enum Integration Tests
    
    @Test("All enums conform to expected protocols")
    func testEnumProtocolConformance() {
        // Test that all enums conform to CaseIterable
        #expect(HardwareWalletType.allCases.count > 0)
        
        // Test that string-based enums have consistent behavior
        for walletType in HardwareWalletType.allCases {
            #expect(HardwareWalletType(rawValue: walletType.rawValue) == walletType)
        }
    }
    
    @Test("Enum raw values are unique within each enum")
    func testEnumRawValueUniqueness() {
        // HardwareWalletType raw values should be unique
        let walletRawValues = HardwareWalletType.allCases.map { $0.rawValue }
        let uniqueWalletRawValues = Set(walletRawValues)
        #expect(walletRawValues.count == uniqueWalletRawValues.count)
    }
    
    @Test("Enum case names follow Swift naming conventions")
    func testEnumNamingConventions() {        
        for walletType in HardwareWalletType.allCases {
            let caseName = String(describing: walletType)
            #expect(caseName.first?.isLowercase == true, "HardwareWalletType case '\(caseName)' should start with lowercase")
        }
    }
}
