import Testing
import Foundation
import Logging
import SystemPackage
import SwiftCardanoCore
import Mockable
import Command
import Path
@testable import SwiftCardanoUtils

// MARK: - Protocol Parameters Path
let protocolParametersJSONFilePath = (
    forResource: "protocol-parameters",
    ofType: "json",
    inDirectory: "data"
)

// MARK: - Config Path
let configJSONFilePath = (
    forResource: "config",
    ofType: "json",
    inDirectory: "data"
)

func getFilePath(forResource: String, ofType: String, inDirectory: String) throws -> String? {
    guard let filePath = Bundle.module.path(
        forResource: forResource,
        ofType: ofType,
        inDirectory: inDirectory) else {
        Issue.record("File not found: \(forResource).\(ofType)")
        try #require(Bool(false))
        return nil
    }
    return filePath
}

var protocolParameters: ProtocolParameters? {
    do {
        let keyPath = try getFilePath(
            forResource: protocolParametersJSONFilePath.forResource,
            ofType: protocolParametersJSONFilePath.ofType,
            inDirectory: protocolParametersJSONFilePath.inDirectory
        )
        return try ProtocolParameters.load(from: keyPath!)
    } catch {
        return nil
    }
}

/// Creates a mock configuration for testing
func createTestConfiguration() -> Config {
    let cardanoConfig = CardanoConfig(
        cli: FilePath("/usr/bin/true"),
        node: FilePath("/usr/bin/true"),
        hwCli: FilePath("/usr/bin/true"),
        signer: nil,
        socket: FilePath("/tmp/test-socket"),
        config: FilePath("/tmp/test-config.json"),
        topology: nil,
        database: nil,
        port: nil,
        hostAddr: nil,
        network: Network.preview,
        era: Era.conway,
        ttlBuffer: 3600,
        workingDir: FilePath("/tmp/cardano-cli-tools"),
        showOutput: false
    )
    
    return Config(
        cardano: cardanoConfig,
        ogmios: nil,
        kupo: nil
    )
}


func createCardanoCLIMockCommandRunner(
    config: Config
) -> MockCommandRunning {
    let commandRunner = MockCommandRunning()
    given(commandRunner)
        .run(
            arguments: .value([config.cardano!.cli!.string, "--version"]),
            environment: .any,
            workingDirectory: .any
        )
        .willReturn(
            AsyncThrowingStream<CommandEvent, any Error> { continuation in
                continuation.yield(
                    .standardOutput([UInt8](CLIResponse.version.utf8))
                )
                continuation.finish()
            }
        )
    
    return commandRunner
}

struct CLICommands {
    static let queryTip = ["conway", "query", "tip", "--testnet-magic", "2"]
    
    static let addressBuild = ["conway", "address", "build", "--payment-verification-key-file", "test.vkey", "--testnet-magic", "2"]
    
    static let stakePoolId = ["conway", "stake-pool", "id", "--cold-verification-key-file", "cold.vkey"]
    
    static let governanceDRepId = ["conway", "governance", "drep", "id", "--drep-verification-key-file", "drep.vkey"]
    
    static let stakeAddressInfo = ["conway", "query", "stake-address-info", "--address", "stake1u9mzj7z0thvn4r3ylxpd6tgl8wzpfp5dsfswmd4qdjz856g5wz62x",  "--out-file", "/dev/stdout", "--testnet-magic", "2"]
    
    static let utxos = ["conway", "query", "utxo", "--address", "addr_test1qp4kux2v7xcg9urqssdffff5p0axz9e3hcc43zz7pcuyle0e20hkwsu2ndpd9dh9anm4jn76ljdz0evj22stzrw9egxqmza5y3", "--out-file",  "/dev/stdout", "--testnet-magic", "2"]
}

struct CLIResponse {
    static let version = """
    cardano-cli 10.8.0.0 - darwin-x86_64 - ghc-9.6
    git rev 420c94fbb075146c6ec7fba78c5b0482fafe72dd
    """
    
    static let tip75 = """
    {"block":123456,"epoch":450,"era":"conway","hash":"abcd1234","slot":123456789,"slotInEpoch":65579,"slotsToEpochEnd":20821,"syncProgress":"75.0"}
    """
    
    static let tip100 = """
    {"block":123456,"epoch":450,"era":"conway","hash":"abcd1234","slot":123456789,"slotInEpoch":65579,"slotsToEpochEnd":20821,"syncProgress":"100.0"}
    """
    
    static let protocolParams = """
    {"collateralPercentage":150,"committeeMaxTermLength":146,"committeeMinSize":7,"costModels":{"PlutusV1":[100788,420,1,1,1000,173,0,1,1000,59957,4,1,11183,32,201305,8356,4,16000,100,16000,100,16000,100,16000,100,16000,100,16000,100,100,100,16000,100,94375,32,132994,32,61462,4,72010,178,0,1,22151,32,91189,769,4,2,85848,228465,122,0,1,1,1000,42921,4,2,24548,29498,38,1,898148,27279,1,51775,558,1,39184,1000,60594,1,141895,32,83150,32,15299,32,76049,1,13169,4,22100,10,28999,74,1,28999,74,1,43285,552,1,44749,541,1,33852,32,68246,32,72362,32,7243,32,7391,32,11546,32,85848,228465,122,0,1,1,90434,519,0,1,74433,32,85848,228465,122,0,1,1,85848,228465,122,0,1,1,270652,22588,4,1457325,64566,4,20467,1,4,0,141992,32,100788,420,1,1,81663,32,59498,32,20142,32,24588,32,20744,32,25933,32,24623,32,53384111,14333,10],"PlutusV2":[100788,420,1,1,1000,173,0,1,1000,59957,4,1,11183,32,201305,8356,4,16000,100,16000,100,16000,100,16000,100,16000,100,16000,100,100,100,16000,100,94375,32,132994,32,61462,4,72010,178,0,1,22151,32,91189,769,4,2,85848,228465,122,0,1,1,1000,42921,4,2,24548,29498,38,1,898148,27279,1,51775,558,1,39184,1000,60594,1,141895,32,83150,32,15299,32,76049,1,13169,4,22100,10,28999,74,1,28999,74,1,43285,552,1,44749,541,1,33852,32,68246,32,72362,32,7243,32,7391,32,11546,32,85848,228465,122,0,1,1,90434,519,0,1,74433,32,85848,228465,122,0,1,1,85848,228465,122,0,1,1,955506,213312,0,2,270652,22588,4,1457325,64566,4,20467,1,4,0,141992,32,100788,420,1,1,81663,32,59498,32,20142,32,24588,32,20744,32,25933,32,24623,32,43053543,10,53384111,14333,10,43574283,26308,10],"PlutusV3":[100788,420,1,1,1000,173,0,1,1000,59957,4,1,11183,32,201305,8356,4,16000,100,16000,100,16000,100,16000,100,16000,100,16000,100,100,100,16000,100,94375,32,132994,32,61462,4,72010,178,0,1,22151,32,91189,769,4,2,85848,123203,7305,-900,1716,549,57,85848,0,1,1,1000,42921,4,2,24548,29498,38,1,898148,27279,1,51775,558,1,39184,1000,60594,1,141895,32,83150,32,15299,32,76049,1,13169,4,22100,10,28999,74,1,28999,74,1,43285,552,1,44749,541,1,33852,32,68246,32,72362,32,7243,32,7391,32,11546,32,85848,123203,7305,-900,1716,549,57,85848,0,1,90434,519,0,1,74433,32,85848,123203,7305,-900,1716,549,57,85848,0,1,1,85848,123203,7305,-900,1716,549,57,85848,0,1,955506,213312,0,2,270652,22588,4,1457325,64566,4,20467,1,4,0,141992,32,100788,420,1,1,81663,32,59498,32,20142,32,24588,32,20744,32,25933,32,24623,32,43053543,10,53384111,14333,10,43574283,26308,10,16000,100,16000,100,962335,18,2780678,6,442008,1,52538055,3756,18,267929,18,76433006,8868,18,52948122,18,1995836,36,3227919,12,901022,1,166917843,4307,36,284546,36,158221314,26549,36,74698472,36,333849714,1,254006273,72,2174038,72,2261318,64571,4,207616,8310,4,1293828,28716,63,0,1,1006041,43623,251,0,1,100181,726,719,0,1,100181,726,719,0,1,100181,726,719,0,1,107878,680,0,1,95336,1,281145,18848,0,1,180194,159,1,1,158519,8942,0,1,159378,8813,0,1,107490,3298,1,106057,655,1,1964219,24520,3]},"dRepActivity":20,"dRepDeposit":500000000,"dRepVotingThresholds":{"committeeNoConfidence":0.6,"committeeNormal":0.67,"hardForkInitiation":0.6,"motionNoConfidence":0.67,"ppEconomicGroup":0.67,"ppGovGroup":0.75,"ppNetworkGroup":0.67,"ppTechnicalGroup":0.67,"treasuryWithdrawal":0.67,"updateToConstitution":0.75},"executionUnitPrices":{"priceMemory":0.0577,"priceSteps":0.0000721},"govActionDeposit":100000000000,"govActionLifetime":6,"maxBlockBodySize":90112,"maxBlockExecutionUnits":{"memory":62000000,"steps":20000000000},"maxBlockHeaderSize":1100,"maxCollateralInputs":3,"maxTxExecutionUnits":{"memory":14000000,"steps":10000000000},"maxTxSize":16384,"maxValueSize":5000,"minFeeRefScriptCostPerByte":15,"minPoolCost":170000000,"monetaryExpansion":0.003,"poolPledgeInfluence":0.3,"poolRetireMaxEpoch":18,"poolVotingThresholds":{"committeeNoConfidence":0.51,"committeeNormal":0.51,"hardForkInitiation":0.51,"motionNoConfidence":0.51,"ppSecurityGroup":0.51},"protocolVersion":{"major":10,"minor":0},"stakeAddressDeposit":2000000,"stakePoolDeposit":500000000,"stakePoolTargetNum":500,"treasuryCut":0.2,"txFeeFixed":155381,"txFeePerByte":44,"utxoCostPerByte":4310}
    """
    
    static let addressBuild = "addr1v84rja0gwv0c8aexdlchaglrtwnjfxn946zs52uxtrxy5mqjr4vwn"
    
    static let stakePoolId = "pool1m5947rydk4n0ywe6ctlav0ztt632lcwjef7fsy93sflz7ctcx6z"
    
    static let governanceDRepId = "drep1kqhhkv66a0egfw7uyz7u8dv7fcvr4ck0c3ad9k9urx3yzhefup0"
    
    static let stakeAddressInfo = """
        [
            {
                "address": "stake1u9mzj7z0thvn4r3ylxpd6tgl8wzpfp5dsfswmd4qdjz856g5wz62x",
                "govActionDeposits": {
                    "c832f194684d672316212e01efc6d28177e8965b7cd6956981fe37cc6715963e#0": 100000000000
                },
                "rewardAccountBalance": 100000000000,
                "stakeDelegation": "pool1m5947rydk4n0ywe6ctlav0ztt632lcwjef7fsy93sflz7ctcx6z",
                "stakeRegistrationDeposit": 2000000,
                "voteDelegation": "keyHash-b02f7b335aebf284bbdc20bdc3b59e4e183ae2cfc47ad2d8bc19a241"
            }
        ]
        """
    
    static var utxos: String {
        let dictionary = [
            "39a7a284c2a0948189dc45dec670211cd4d72f7b66c5726c08d9b3df11e44d58#0": [
                "address": "addr_test1qp4kux2v7xcg9urqssdffff5p0axz9e3hcc43zz7pcuyle0e20hkwsu2ndpd9dh9anm4jn76ljdz0evj22stzrw9egxqmza5y3",
                "datum": nil,
                "inlineDatum": [
                    "constructor": 0,
                    "fields": [
                        [
                            "constructor": 0,
                            "fields": [
                                ["bytes": "2e11e7313e00ccd086cfc4f1c3ebed4962d31b481b6a153c23601c0f"],
                                ["bytes": "636861726c69335f6164615f6e6674"]
                            ]
                        ],
                        [
                            "constructor": 0,
                            "fields": [
                                ["bytes": ""],
                                ["bytes": ""]
                            ]
                        ],
                        [
                            "constructor": 0,
                            "fields": [
                                ["bytes": "8e51398904a5d3fc129fbf4f1589701de23c7824d5c90fdb9490e15a"],
                                ["bytes": "434841524c4933"]
                            ]
                        ],
                        [
                            "constructor": 0,
                            "fields": [
                                ["bytes": "d8d46a3e430fab5dc8c5a0a7fc82abbf4339a89034a8c804bb7e6012"],
                                ["bytes": "636861726c69335f6164615f6c71"]
                            ]
                        ],
                        ["int": 997],
                        [
                            "list": [
                                ["bytes": "4dd98a2ef34bc7ac3858bbcfdf94aaa116bb28ca7e01756140ba4d19"]
                            ]
                        ],
                        ["int": 10000000000]
                    ]
                ],
                "inlineDatumhash": "c56003cba9cfcf2f73cf6a5f4d6354d03c281bcd2bbd7a873d7475faa10a7123",
                "referenceScript": nil,
                "value": [
                    "2e11e7313e00ccd086cfc4f1c3ebed4962d31b481b6a153c23601c0f": [
                        "636861726c69335f6164615f6e6674": 1
                    ],
                    "8e51398904a5d3fc129fbf4f1589701de23c7824d5c90fdb9490e15a": [
                        "434841524c4933": 1367726755
                    ],
                    "d8d46a3e430fab5dc8c5a0a7fc82abbf4339a89034a8c804bb7e6012": [
                        "636861726c69335f6164615f6c71": 9223372035870126880
                    ],
                    "lovelace": 708864940
                ]
            ]
        ]
        
        let jsonData = try! JSONSerialization.data(withJSONObject: dictionary, options: [])
        return String(data: jsonData, encoding: .utf8)!
    }
}

// MARK: - Helper Test Handler

struct TestLogHandler: LogHandler {
    var logLevel: Logger.Level = .debug
    var metadata: Logger.Metadata = [:]
    
    subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }
    
    func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, source: String, file: String, function: String, line: UInt) {
        // Test implementation - could capture log messages if needed
    }
}
