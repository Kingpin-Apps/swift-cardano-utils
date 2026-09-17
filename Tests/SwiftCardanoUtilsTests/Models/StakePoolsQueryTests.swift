import Testing
import Foundation
import SwiftCardanoCore
import Command
import Mockable
@testable import SwiftCardanoUtils

@Suite("query stake-pools parsing")
struct StakePoolsQueryTests {
    static let pool1 = "pool1pu5jlj4q9w9jlxeu370a3c9myx47md5j5m2str0naunn2q3lkdy"
    static let pool2 = "pool1z5uqdk7dzdxaae5633fqfcu2eqzy3a3rgtuvy087fdld7yws0xt"

    @Test("parses the default JSON array output")
    func parsesJSON() {
        let output = """
        [
            "\(Self.pool1)",
            "\(Self.pool2)"
        ]
        """
        #expect(QueryCommandImpl.parseStakePoolIds(output) == [Self.pool1, Self.pool2])
    }

    @Test("parses one pool ID per line (older versions or --output-text)")
    func parsesText() {
        let output = "\(Self.pool1)\n\(Self.pool2)\n"
        #expect(QueryCommandImpl.parseStakePoolIds(output) == [Self.pool1, Self.pool2])
    }

    @Test("parses empty output")
    func parsesEmpty() {
        #expect(QueryCommandImpl.parseStakePoolIds("[]").isEmpty)
        #expect(QueryCommandImpl.parseStakePoolIds("\n").isEmpty)
    }

    @Test("query.stakePools() decodes the JSON array into pool operators")
    func queryStakePoolsJSON() async throws {
        let config = createTestConfiguration()
        let runner = createCardanoCLIMockCommandRunner(config: config)

        given(runner)
            .run(
                arguments: .value([
                    config.cardano!.cli!.string,
                    "conway", "query", "stake-pools",
                    "--testnet-magic", "2"
                ]),
                environment: .any,
                workingDirectory: .any
            )
            .willReturn(
                AsyncThrowingStream<CommandEvent, any Error> { continuation in
                    continuation.yield(.standardOutput([UInt8]("[\n  \"\(Self.pool1)\",\n  \"\(Self.pool2)\"\n]\n".utf8)))
                    continuation.finish()
                }
            )

        let cli = try await CardanoCLI(configuration: config, commandRunner: runner)
        let pools = try await cli.query.stakePools()

        #expect(pools.count == 2)
        #expect(try pools.first?.toBech32() == Self.pool1)
    }
}
