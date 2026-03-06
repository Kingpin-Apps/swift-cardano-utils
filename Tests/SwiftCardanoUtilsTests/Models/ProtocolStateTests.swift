import Testing
import Foundation
import SwiftCardanoCore
import Command
import Mockable
@testable import SwiftCardanoUtils

// MARK: - Test Fixtures

private extension CLIResponse {
    static let protocolState = """
    {
        "candidateNonce": "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
        "epochNonce": "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
        "evolvingNonce": "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef",
        "labNonce": "cafebabecafebabecafebabecafebabecafebabecafebabecafebabecafebabe0",
        "lastEpochBlockNonce": "f00df00df00df00df00df00df00df00df00df00df00df00df00df00df00df00d",
        "lastSlot": 12345678,
        "oCertCounters": {}
    }
    """

    static let protocolStateWithCounters = """
    {
        "candidateNonce": "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
        "epochNonce": "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
        "evolvingNonce": "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef",
        "labNonce": "cafebabecafebabecafebabecafebabecafebabecafebabecafebabecafebabe0",
        "lastEpochBlockNonce": "f00df00df00df00df00df00df00df00df00df00df00df00df00df00df00df00d",
        "lastSlot": 12345678,
        "oCertCounters": {
            "d8d46a3e430fab5dc8c5a0a7fc82abbf4339a89034a8c804bb7e6012": 5
        }
    }
    """
}

private let queryProtocolState = ["conway", "query", "protocol-state", "--testnet-magic", "2"]

// MARK: - ProtocolState Model Tests

@Suite("ProtocolState Model Tests")
struct ProtocolStateModelTests {

    // MARK: - Initialization

    @Test("Basic initialization stores all properties")
    func testBasicInitialization() {
        let state = ProtocolState(
            candidateNonce: "aaa",
            epochNonce: "bbb",
            evolvingNonce: "ccc",
            labNonce: "ddd",
            lastEpochBlockNonce: "eee",
            lastSlot: 99_000_000,
            oCertCounters: [:]
        )

        #expect(state.candidateNonce == "aaa")
        #expect(state.epochNonce == "bbb")
        #expect(state.evolvingNonce == "ccc")
        #expect(state.labNonce == "ddd")
        #expect(state.lastEpochBlockNonce == "eee")
        #expect(state.lastSlot == 99_000_000)
        #expect(state.oCertCounters.isEmpty)
    }

    // MARK: - JSON Decoding

    @Test("Decodes from JSON with empty oCertCounters")
    func testDecodeEmptyCounters() throws {
        let data = try #require(CLIResponse.protocolState.data(using: .utf8))
        let state = try JSONDecoder().decode(ProtocolState.self, from: data)

        #expect(state.candidateNonce == "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890")
        #expect(state.epochNonce == "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef")
        #expect(state.evolvingNonce == "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef")
        #expect(state.labNonce == "cafebabecafebabecafebabecafebabecafebabecafebabecafebabecafebabe0")
        #expect(state.lastEpochBlockNonce == "f00df00df00df00df00df00df00df00df00df00df00df00df00df00df00df00d")
        #expect(state.lastSlot == 12_345_678)
        #expect(state.oCertCounters.isEmpty)
    }

    @Test("Decodes from JSON with pool operator counters")
    func testDecodeWithCounters() throws {
        let data = try #require(CLIResponse.protocolStateWithCounters.data(using: .utf8))
        let state = try JSONDecoder().decode(ProtocolState.self, from: data)

        #expect(state.oCertCounters.count == 1)
        #expect(state.oCertCounters.values.first == 5)
    }

    @Test("Throws on missing required fields")
    func testThrowsOnMissingFields() {
        let incomplete = """
        {
            "candidateNonce": "abc",
            "epochNonce": "def"
        }
        """
        let data = incomplete.data(using: .utf8)!
        #expect(throws: Error.self) {
            _ = try JSONDecoder().decode(ProtocolState.self, from: data)
        }
    }

    @Test("Throws on wrong type for lastSlot")
    func testThrowsOnWrongType() {
        let json = """
        {
            "candidateNonce": "abc",
            "epochNonce": "def",
            "evolvingNonce": "ghi",
            "labNonce": "jkl",
            "lastEpochBlockNonce": "mno",
            "lastSlot": "not-a-number",
            "oCertCounters": {}
        }
        """
        let data = json.data(using: .utf8)!
        #expect(throws: Error.self) {
            _ = try JSONDecoder().decode(ProtocolState.self, from: data)
        }
    }

    // MARK: - JSON Round-Trip

    @Test("Round-trip encode/decode preserves all fields with empty counters")
    func testRoundTripEmptyCounters() throws {
        let data = try #require(CLIResponse.protocolState.data(using: .utf8))
        let original = try JSONDecoder().decode(ProtocolState.self, from: data)

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ProtocolState.self, from: encoded)

        #expect(decoded.candidateNonce == original.candidateNonce)
        #expect(decoded.epochNonce == original.epochNonce)
        #expect(decoded.evolvingNonce == original.evolvingNonce)
        #expect(decoded.labNonce == original.labNonce)
        #expect(decoded.lastEpochBlockNonce == original.lastEpochBlockNonce)
        #expect(decoded.lastSlot == original.lastSlot)
        #expect(decoded.oCertCounters.isEmpty)
    }

    @Test("Round-trip encode/decode preserves pool operator counters")
    func testRoundTripWithCounters() throws {
        let data = try #require(CLIResponse.protocolStateWithCounters.data(using: .utf8))
        let original = try JSONDecoder().decode(ProtocolState.self, from: data)

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ProtocolState.self, from: encoded)

        #expect(decoded.candidateNonce == original.candidateNonce)
        #expect(decoded.lastSlot == original.lastSlot)
        #expect(decoded.oCertCounters.count == original.oCertCounters.count)

        // Verify counter values match by key
        for (key, value) in original.oCertCounters {
            #expect(decoded.oCertCounters[key] == value)
        }
    }
}

// MARK: - ProtocolState CLI Query Tests

@Suite("ProtocolState CLI Query Tests")
struct ProtocolStateCLITests {

    @Test("query.protocolState() decodes response")
    func testQueryProtocolState() async throws {
        let config = createTestConfiguration()
        let runner = createCardanoCLIMockCommandRunner(config: config)

        given(runner)
            .run(
                arguments: .value([config.cardano!.cli!.string] + queryProtocolState),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(
                        .standardOutput([UInt8](CLIResponse.protocolState.utf8))
                    )
                    continuation.finish()
                }
            )

        let cli = try await CardanoCLI(configuration: config, commandRunner: runner)
        let state = try await cli.query.protocolState()

        #expect(state.lastSlot == 12_345_678)
        #expect(state.oCertCounters.isEmpty)
        #expect(!state.candidateNonce.isEmpty)
        #expect(!state.epochNonce.isEmpty)
    }

    @Test("query.protocolState() with pool operator counters")
    func testQueryProtocolStateWithCounters() async throws {
        let config = createTestConfiguration()
        let runner = createCardanoCLIMockCommandRunner(config: config)

        given(runner)
            .run(
                arguments: .value([config.cardano!.cli!.string] + queryProtocolState),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(
                        .standardOutput([UInt8](CLIResponse.protocolStateWithCounters.utf8))
                    )
                    continuation.finish()
                }
            )

        let cli = try await CardanoCLI(configuration: config, commandRunner: runner)
        let state = try await cli.query.protocolState()

        #expect(state.oCertCounters.count == 1)
        #expect(state.oCertCounters.values.first == 5)
    }

    @Test("query.protocolState() throws on invalid JSON response")
    func testQueryProtocolStateThrowsOnInvalidJSON() async throws {
        let config = createTestConfiguration()
        let runner = createCardanoCLIMockCommandRunner(config: config)

        given(runner)
            .run(
                arguments: .value([config.cardano!.cli!.string] + queryProtocolState),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(
                        .standardOutput([UInt8]("not valid json".utf8))
                    )
                    continuation.finish()
                }
            )

        let cli = try await CardanoCLI(configuration: config, commandRunner: runner)

        await #expect(throws: Error.self) {
            _ = try await cli.query.protocolState()
        }
    }
}
