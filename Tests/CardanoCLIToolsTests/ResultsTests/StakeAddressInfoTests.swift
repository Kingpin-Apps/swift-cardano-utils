import Testing
import Foundation
import SwiftCardanoCore
@testable import CardanoCLITools

@Suite("StakeAddressInfo Tests")
struct StakeAddressInfoTests {
    
    // MARK: - Initialization Tests
    
    @Test("StakeAddressInfo initializes correctly with all parameters")
    func testInitializationWithAllParameters() {
        let govActionDeposits = ["action1": UInt64(1000)]
        
        let info = StakeAddressInfo(
            address: "stake_test1234567890abcdef",
            govActionDeposits: govActionDeposits,
            rewardAccountBalance: 5000000,
            stakeDelegation: nil,
            stakeRegistrationDeposit: 2000000,
            voteDelegation: nil
        )
        
        #expect(info.address == "stake_test1234567890abcdef")
        #expect(info.govActionDeposits == govActionDeposits)
        #expect(info.rewardAccountBalance == 5000000)
        #expect(info.stakeDelegation == nil)
        #expect(info.stakeRegistrationDeposit == 2000000)
        #expect(info.voteDelegation == nil)
    }
    
    @Test("StakeAddressInfo initializes correctly with minimal parameters")
    func testInitializationWithMinimalParameters() {
        let info = StakeAddressInfo(
            address: "stake_test1234567890abcdef",
            rewardAccountBalance: 1000000
        )
        
        #expect(info.address == "stake_test1234567890abcdef")
        #expect(info.govActionDeposits == nil)
        #expect(info.rewardAccountBalance == 1000000)
        #expect(info.stakeDelegation == nil)
        #expect(info.stakeRegistrationDeposit == nil)
        #expect(info.voteDelegation == nil)
    }
    
    // MARK: - Codable Tests
    
    @Test("StakeAddressInfo encodes and decodes correctly with all fields")
    func testFullCodableRoundTrip() throws {
        let govActionDeposits = ["action1": UInt64(1000), "action2": UInt64(2000)]
        
        let original = StakeAddressInfo(
            address: "stake_test1234567890abcdef",
            govActionDeposits: govActionDeposits,
            rewardAccountBalance: 5000000,
            stakeDelegation: nil,
            stakeRegistrationDeposit: 2000000,
            voteDelegation: nil
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(StakeAddressInfo.self, from: data)
        
        #expect(decoded == original)
    }
    
    @Test("StakeAddressInfo encodes and decodes correctly with minimal fields")
    func testMinimalCodableRoundTrip() throws {
        let original = StakeAddressInfo(
            address: "stake_test1234567890abcdef",
            rewardAccountBalance: 1000000
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(StakeAddressInfo.self, from: data)
        
        #expect(decoded == original)
    }
    
    @Test("StakeAddressInfo decodes from JSON with missing optional fields")
    func testDecodingWithMissingOptionalFields() throws {
        let json = """
        {
            "address": "stake_test1234567890abcdef",
            "rewardAccountBalance": 1500000
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(StakeAddressInfo.self, from: data)
        
        #expect(decoded.address == "stake_test1234567890abcdef")
        #expect(decoded.rewardAccountBalance == 1500000)
        #expect(decoded.govActionDeposits == nil)
        #expect(decoded.stakeDelegation == nil)
        #expect(decoded.stakeRegistrationDeposit == nil)
        #expect(decoded.voteDelegation == nil)
    }
    
    @Test("StakeAddressInfo decoding handles default values correctly")
    func testDecodingWithDefaultValues() throws {
        let json = """
        {
            "address": "stake_test1234567890abcdef"
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(StakeAddressInfo.self, from: data)
        
        #expect(decoded.address == "stake_test1234567890abcdef")
        #expect(decoded.rewardAccountBalance == 0) // Default value
        #expect(decoded.govActionDeposits == nil)
        #expect(decoded.stakeDelegation == nil)
        #expect(decoded.stakeRegistrationDeposit == nil)
        #expect(decoded.voteDelegation == nil)
    }
    
    @Test("StakeAddressInfo encodes null values correctly for optional fields")
    func testEncodingHandlesNullOptionalFields() throws {
        let info = StakeAddressInfo(
            address: "stake_test1234567890abcdef",
            rewardAccountBalance: 1000000
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(info)
        let jsonString = String(data: data, encoding: .utf8)!
        
        // Should contain the required fields and null optional fields
        #expect(jsonString.contains("\"address\":\"stake_test1234567890abcdef\""))
        #expect(jsonString.contains("\"rewardAccountBalance\":1000000"))
        #expect(jsonString.contains("\"govActionDeposits\":null"))
        #expect(jsonString.contains("\"stakeRegistrationDeposit\":null"))
    }
    
    // MARK: - Equatable Tests
    
    @Test("StakeAddressInfo equality works correctly for identical instances")
    func testEqualityForIdenticalInstances() {
        let info1 = StakeAddressInfo(
            address: "stake_test1234567890abcdef",
            rewardAccountBalance: 1000000,
            stakeRegistrationDeposit: 2000000
        )
        
        let info2 = StakeAddressInfo(
            address: "stake_test1234567890abcdef",
            rewardAccountBalance: 1000000,
            stakeRegistrationDeposit: 2000000
        )
        
        #expect(info1 == info2)
    }
    
    @Test("StakeAddressInfo inequality works correctly for different instances")
    func testInequalityForDifferentInstances() {
        let info1 = StakeAddressInfo(
            address: "stake_test1234567890abcdef",
            rewardAccountBalance: 1000000
        )
        
        let info2 = StakeAddressInfo(
            address: "stake_test1234567890abcdef",
            rewardAccountBalance: 2000000 // Different balance
        )
        
        #expect(info1 != info2)
    }
    
    @Test("StakeAddressInfo inequality works for different addresses")
    func testInequalityForDifferentAddresses() {
        let info1 = StakeAddressInfo(
            address: "stake_test1234567890abcdef",
            rewardAccountBalance: 1000000
        )
        
        let info2 = StakeAddressInfo(
            address: "stake_test9876543210fedcba", // Different address
            rewardAccountBalance: 1000000
        )
        
        #expect(info1 != info2)
    }
    
    // MARK: - Edge Cases
    
    @Test("StakeAddressInfo handles zero reward balance")
    func testZeroRewardBalance() {
        let info = StakeAddressInfo(
            address: "stake_test1234567890abcdef",
            rewardAccountBalance: 0
        )
        
        #expect(info.rewardAccountBalance == 0)
    }
    
    @Test("StakeAddressInfo handles negative reward balance")
    func testNegativeRewardBalance() {
        let info = StakeAddressInfo(
            address: "stake_test1234567890abcdef",
            rewardAccountBalance: -1000000
        )
        
        #expect(info.rewardAccountBalance == -1000000)
    }
    
    @Test("StakeAddressInfo handles empty gov action deposits dictionary")
    func testEmptyGovActionDeposits() {
        let info = StakeAddressInfo(
            address: "stake_test1234567890abcdef",
            govActionDeposits: [:],
            rewardAccountBalance: 1000000
        )
        
        #expect(info.govActionDeposits?.isEmpty == true)
    }
    
    @Test("StakeAddressInfo handles large gov action deposits values")
    func testLargeGovActionDeposits() {
        let largeDeposits = ["action1": UInt64.max]
        
        let info = StakeAddressInfo(
            address: "stake_test1234567890abcdef",
            govActionDeposits: largeDeposits,
            rewardAccountBalance: 1000000
        )
        
        #expect(info.govActionDeposits?["action1"] == UInt64.max)
    }
}
