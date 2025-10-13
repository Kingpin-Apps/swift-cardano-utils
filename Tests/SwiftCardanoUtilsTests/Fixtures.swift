import Testing
import Foundation
import Logging
import SystemPackage
import SwiftCardanoCore
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

func createMockConfig() -> Config {
    let cardanoConfig = CardanoConfig(
        cli: FilePath(createMockCardanoCLI()),
        node: FilePath("/tmp/mock-cardano-node"),
        hwCli: nil,
        signer: nil,
        socket: FilePath("/tmp/test-socket"),
        config: FilePath("/tmp/mock-config.json"),
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

func createMockConfiguration() -> Config {
    let mockCardanoConfig = CardanoConfig(
        cli: FilePath(createMockCardanoCLI()),
        node: FilePath("/usr/bin/true"),
        hwCli: nil,
        signer: nil,
        socket: FilePath("/tmp/test-socket"),
        config: FilePath("/tmp/test.json"),
        topology: nil,
        database: nil,
        port: nil,
        hostAddr: nil,
        network: Network.preview,
        era: Era.conway,
        ttlBuffer: 3600,
        workingDir: FilePath("/tmp"),
        showOutput: false
    )
    
    return Config(
        cardano: mockCardanoConfig,
        ogmios: nil,
        kupo: nil
    )
}

func createMockBaseCLIConfiguration(
    tempDir: URL,
    cli: String? = nil,
    workingDir: String? = nil,
    mode: String = "online",
    hwCli: String? = nil,
    jcli: String? = nil
) throws -> Config {
    
    // Create mock CLI binaries
    let mockCardanoCliPath = cli ?? {
        return createMockCardanoCLI()
    }()
    
    let workDir = workingDir ?? tempDir.appendingPathComponent("working").path
    
    let cardanoConfig = CardanoConfig(
        cli: FilePath(mockCardanoCliPath),
        node: FilePath("/usr/bin/true"),
        hwCli: hwCli.map { FilePath($0) },
        signer: nil,
        socket: FilePath("/tmp/test-socket"),
        config: FilePath(tempDir.appendingPathComponent("config.json").path),
        topology: nil,
        database: nil,
        port: nil,
        hostAddr: nil,
        network: Network.preview,
        era: Era.conway,
        ttlBuffer: 3600,
        workingDir: FilePath(workDir),
        showOutput: false
    )
    
    return Config(
        cardano: cardanoConfig,
        ogmios: nil,
        kupo: nil
    )
}


/// Creates a temporary mock binary for testing
func createMockBinary(withContent content: String = "#!/bin/bash\necho 'mock binary v1.0.0'") -> String {
    let tempDir = FileManager.default.temporaryDirectory
    let binaryPath = tempDir.appendingPathComponent("mock-binary-\(UUID().uuidString)").path
    
    _ = FileManager.default.createFile(atPath: binaryPath, contents: content.data(using: .utf8))
    
    // Make it executable
    let permissions = [FileAttributeKey.posixPermissions: 0o755]
    try? FileManager.default.setAttributes(permissions, ofItemAtPath: binaryPath)
    
    return binaryPath
}

/// Creates a mock configuration for testing
func createTestConfiguration() -> Config {
    let cardanoConfig = CardanoConfig(
        cli: FilePath(createMockCardanoCLI()),
        node: FilePath("/usr/bin/true"),
        hwCli: nil,
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

/// Cleans up temporary files
func cleanupFile(at path: String) {
    try? FileManager.default.removeItem(atPath: path)
}

func createTempDirectory() throws -> URL {
    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("BaseCLITests-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    return tempDir
}

func createMockExecutable(at path: URL) async throws {
    // Create empty file
    try Data().write(to: path)
    
    // Make executable (chmod +x equivalent)
    var attributes = try FileManager.default.attributesOfItem(atPath: path.path)
    if let permissions = attributes[.posixPermissions] as? NSNumber {
        let newPermissions = NSNumber(value: permissions.uint16Value | 0o111)
        attributes[.posixPermissions] = newPermissions
        try FileManager.default.setAttributes(attributes, ofItemAtPath: path.path)
    }
}

/// Creates a mock executable that returns specific outputs based on arguments
func createMockCardanoCLI(withResponses responses: [String: String] = [:]) -> String {
    let tempDir = FileManager.default.temporaryDirectory
    let binaryPath = tempDir.appendingPathComponent("mock-cardano-cli-\(UUID().uuidString)").path
    
    // Create a comprehensive mock script that handles various CLI commands
    var mockScript = """
    #!/bin/bash
    
    # Debug: Log all arguments for debugging (disabled)
    # echo "DEBUG: Mock CLI called with args: '$*'" >&2
    # echo "DEBUG: Number of args: $#" >&2
    
    """
    
    // Add custom responses first, exact matches first
    for (command, response) in responses {
        mockScript += """
        
        # Exact match for: \(command)
        if [[ "$*" == "\(command)" ]]; then
            echo '\(response)'
            # Check if this should exit with error code
            if [[ "\(response)" == *"invalid"* ]] || [[ "\(response)" == *"command failed"* ]]; then
                exit 1
            fi
            exit 0
        fi
        """
    }
    
    // Add wildcard matches after exact matches
    for (command, response) in responses {
        mockScript += """
        
        # Wildcard match for: \(command)
        if [[ "$*" == *"\(command)"* ]]; then
            echo '\(response)'
            # Check if this should exit with error code
            if [[ "\(response)" == *"invalid"* ]] || [[ "\(response)" == *"command failed"* ]]; then
                exit 1
            fi
            exit 0
        fi
        """
    }
    
    mockScript += """
    
    # Handle version command (default)
    if [[ "$1" == "--version" ]]; then
        echo "cardano-cli 8.20.3 - macos-x86_64 - ghc-9.2"
        exit 0
    fi
    
    # Handle query tip command (default)
    if [[ "$1" == "conway" && "$2" == "query" && "$3" == "tip" ]]; then
        echo '{"block": 123456,"epoch": 450,"era": "conway","hash": "771179d7a58518ad48e72af2206e0db5e0efc4105a3cc0bdeb676567fbb39179","slot": 123456789,"slotInEpoch": 65579,"slotsToEpochEnd": 20821,"syncProgress": "100.00"}'
        exit 0
    fi
    
    # Handle query protocol-parameters command
    if [[ "$1" == "conway" && "$2" == "query" && "$3" == "protocol-parameters" ]]; then
        # Check for --out-file argument
        if [[ "$*" == *"--out-file"* ]]; then
            # Find the output file argument
            for ((i=1; i<=$#; i++)); do
                if [[ "${!i}" == "--out-file" && $((i+1)) -le $# ]]; then
                    next_index=$((i+1))
                    output_file="${!next_index}"
                    # Create the directory if it doesn't exist
                    mkdir -p "$(dirname "$output_file")"
                    # Write the complete protocol parameters JSON to the file
                    echo '{"collateralPercentage":150,"committeeMaxTermLength":146,"committeeMinSize":7,"costModels":{"PlutusV1":[100788,420,1,1,1000,173,0,1,1000,59957,4,1,11183,32,201305,8356,4,16000,100,16000,100,16000,100,16000,100,16000,100,16000,100,100,100,16000,100,94375,32,132994,32,61462,4,72010,178,0,1,22151,32,91189,769,4,2,85848,228465,122,0,1,1,1000,42921,4,2,24548,29498,38,1,898148,27279,1,51775,558,1,39184,1000,60594,1,141895,32,83150,32,15299,32,76049,1,13169,4,22100,10,28999,74,1,28999,74,1,43285,552,1,44749,541,1,33852,32,68246,32,72362,32,7243,32,7391,32,11546,32,85848,228465,122,0,1,1,90434,519,0,1,74433,32,85848,228465,122,0,1,1,85848,228465,122,0,1,1,270652,22588,4,1457325,64566,4,20467,1,4,0,141992,32,100788,420,1,1,81663,32,59498,32,20142,32,24588,32,20744,32,25933,32,24623,32,53384111,14333,10],"PlutusV2":[100788,420,1,1,1000,173,0,1,1000,59957,4,1,11183,32,201305,8356,4,16000,100,16000,100,16000,100,16000,100,16000,100,16000,100,100,100,16000,100,94375,32,132994,32,61462,4,72010,178,0,1,22151,32,91189,769,4,2,85848,228465,122,0,1,1,1000,42921,4,2,24548,29498,38,1,898148,27279,1,51775,558,1,39184,1000,60594,1,141895,32,83150,32,15299,32,76049,1,13169,4,22100,10,28999,74,1,28999,74,1,43285,552,1,44749,541,1,33852,32,68246,32,72362,32,7243,32,7391,32,11546,32,85848,228465,122,0,1,1,90434,519,0,1,74433,32,85848,228465,122,0,1,1,85848,228465,122,0,1,1,955506,213312,0,2,270652,22588,4,1457325,64566,4,20467,1,4,0,141992,32,100788,420,1,1,81663,32,59498,32,20142,32,24588,32,20744,32,25933,32,24623,32,43053543,10,53384111,14333,10,43574283,26308,10],"PlutusV3":[100788,420,1,1,1000,173,0,1,1000,59957,4,1,11183,32,201305,8356,4,16000,100,16000,100,16000,100,16000,100,16000,100,16000,100,100,100,16000,100,94375,32,132994,32,61462,4,72010,178,0,1,22151,32,91189,769,4,2,85848,123203,7305,-900,1716,549,57,85848,0,1,1,1000,42921,4,2,24548,29498,38,1,898148,27279,1,51775,558,1,39184,1000,60594,1,141895,32,83150,32,15299,32,76049,1,13169,4,22100,10,28999,74,1,28999,74,1,43285,552,1,44749,541,1,33852,32,68246,32,72362,32,7243,32,7391,32,11546,32,85848,123203,7305,-900,1716,549,57,85848,0,1,90434,519,0,1,74433,32,85848,123203,7305,-900,1716,549,57,85848,0,1,1,85848,123203,7305,-900,1716,549,57,85848,0,1,955506,213312,0,2,270652,22588,4,1457325,64566,4,20467,1,4,0,141992,32,100788,420,1,1,81663,32,59498,32,20142,32,24588,32,20744,32,25933,32,24623,32,43053543,10,53384111,14333,10,43574283,26308,10,16000,100,16000,100,962335,18,2780678,6,442008,1,52538055,3756,18,267929,18,76433006,8868,18,52948122,18,1995836,36,3227919,12,901022,1,166917843,4307,36,284546,36,158221314,26549,36,74698472,36,333849714,1,254006273,72,2174038,72,2261318,64571,4,207616,8310,4,1293828,28716,63,0,1,1006041,43623,251,0,1,100181,726,719,0,1,100181,726,719,0,1,100181,726,719,0,1,107878,680,0,1,95336,1,281145,18848,0,1,180194,159,1,1,158519,8942,0,1,159378,8813,0,1,107490,3298,1,106057,655,1,1964219,24520,3]},"dRepActivity":20,"dRepDeposit":500000000,"dRepVotingThresholds":{"committeeNoConfidence":0.6,"committeeNormal":0.67,"hardForkInitiation":0.6,"motionNoConfidence":0.67,"ppEconomicGroup":0.67,"ppGovGroup":0.75,"ppNetworkGroup":0.67,"ppTechnicalGroup":0.67,"treasuryWithdrawal":0.67,"updateToConstitution":0.75},"executionUnitPrices":{"priceMemory":0.0577,"priceSteps":0.0000721},"govActionDeposit":100000000000,"govActionLifetime":6,"maxBlockBodySize":90112,"maxBlockExecutionUnits":{"memory":62000000,"steps":20000000000},"maxBlockHeaderSize":1100,"maxCollateralInputs":3,"maxTxExecutionUnits":{"memory":14000000,"steps":10000000000},"maxTxSize":16384,"maxValueSize":5000,"minFeeRefScriptCostPerByte":15,"minPoolCost":170000000,"monetaryExpansion":0.003,"poolPledgeInfluence":0.3,"poolRetireMaxEpoch":18,"poolVotingThresholds":{"committeeNoConfidence":0.51,"committeeNormal":0.51,"hardForkInitiation":0.51,"motionNoConfidence":0.51,"ppSecurityGroup":0.51},"protocolVersion":{"major":10,"minor":0},"stakeAddressDeposit":2000000,"stakePoolDeposit":500000000,"stakePoolTargetNum":500,"treasuryCut":0.2,"txFeeFixed":155381,"txFeePerByte":44,"utxoCostPerByte":4310}' > "$output_file"
                    echo "Protocol parameters written to $output_file" >&2
                    exit 0
                fi
            done
        fi
        echo '{"collateralPercentage":150,"committeeMaxTermLength":146,"committeeMinSize":7,"costModels":{"PlutusV1":[100788,420,1,1,1000,173,0,1,1000,59957,4,1,11183,32,201305,8356,4,16000,100,16000,100,16000,100,16000,100,16000,100,16000,100,100,100,16000,100,94375,32,132994,32,61462,4,72010,178,0,1,22151,32,91189,769,4,2,85848,228465,122,0,1,1,1000,42921,4,2,24548,29498,38,1,898148,27279,1,51775,558,1,39184,1000,60594,1,141895,32,83150,32,15299,32,76049,1,13169,4,22100,10,28999,74,1,28999,74,1,43285,552,1,44749,541,1,33852,32,68246,32,72362,32,7243,32,7391,32,11546,32,85848,228465,122,0,1,1,90434,519,0,1,74433,32,85848,228465,122,0,1,1,85848,228465,122,0,1,1,270652,22588,4,1457325,64566,4,20467,1,4,0,141992,32,100788,420,1,1,81663,32,59498,32,20142,32,24588,32,20744,32,25933,32,24623,32,53384111,14333,10],"PlutusV2":[100788,420,1,1,1000,173,0,1,1000,59957,4,1,11183,32,201305,8356,4,16000,100,16000,100,16000,100,16000,100,16000,100,16000,100,100,100,16000,100,94375,32,132994,32,61462,4,72010,178,0,1,22151,32,91189,769,4,2,85848,228465,122,0,1,1,1000,42921,4,2,24548,29498,38,1,898148,27279,1,51775,558,1,39184,1000,60594,1,141895,32,83150,32,15299,32,76049,1,13169,4,22100,10,28999,74,1,28999,74,1,43285,552,1,44749,541,1,33852,32,68246,32,72362,32,7243,32,7391,32,11546,32,85848,228465,122,0,1,1,90434,519,0,1,74433,32,85848,228465,122,0,1,1,85848,228465,122,0,1,1,955506,213312,0,2,270652,22588,4,1457325,64566,4,20467,1,4,0,141992,32,100788,420,1,1,81663,32,59498,32,20142,32,24588,32,20744,32,25933,32,24623,32,43053543,10,53384111,14333,10,43574283,26308,10],"PlutusV3":[100788,420,1,1,1000,173,0,1,1000,59957,4,1,11183,32,201305,8356,4,16000,100,16000,100,16000,100,16000,100,16000,100,16000,100,100,100,16000,100,94375,32,132994,32,61462,4,72010,178,0,1,22151,32,91189,769,4,2,85848,123203,7305,-900,1716,549,57,85848,0,1,1,1000,42921,4,2,24548,29498,38,1,898148,27279,1,51775,558,1,39184,1000,60594,1,141895,32,83150,32,15299,32,76049,1,13169,4,22100,10,28999,74,1,28999,74,1,43285,552,1,44749,541,1,33852,32,68246,32,72362,32,7243,32,7391,32,11546,32,85848,123203,7305,-900,1716,549,57,85848,0,1,90434,519,0,1,74433,32,85848,123203,7305,-900,1716,549,57,85848,0,1,1,85848,123203,7305,-900,1716,549,57,85848,0,1,955506,213312,0,2,270652,22588,4,1457325,64566,4,20467,1,4,0,141992,32,100788,420,1,1,81663,32,59498,32,20142,32,24588,32,20744,32,25933,32,24623,32,43053543,10,53384111,14333,10,43574283,26308,10,16000,100,16000,100,962335,18,2780678,6,442008,1,52538055,3756,18,267929,18,76433006,8868,18,52948122,18,1995836,36,3227919,12,901022,1,166917843,4307,36,284546,36,158221314,26549,36,74698472,36,333849714,1,254006273,72,2174038,72,2261318,64571,4,207616,8310,4,1293828,28716,63,0,1,1006041,43623,251,0,1,100181,726,719,0,1,100181,726,719,0,1,100181,726,719,0,1,107878,680,0,1,95336,1,281145,18848,0,1,180194,159,1,1,158519,8942,0,1,159378,8813,0,1,107490,3298,1,106057,655,1,1964219,24520,3]},"dRepActivity":20,"dRepDeposit":500000000,"dRepVotingThresholds":{"committeeNoConfidence":0.6,"committeeNormal":0.67,"hardForkInitiation":0.6,"motionNoConfidence":0.67,"ppEconomicGroup":0.67,"ppGovGroup":0.75,"ppNetworkGroup":0.67,"ppTechnicalGroup":0.67,"treasuryWithdrawal":0.67,"updateToConstitution":0.75},"executionUnitPrices":{"priceMemory":0.0577,"priceSteps":0.0000721},"govActionDeposit":100000000000,"govActionLifetime":6,"maxBlockBodySize":90112,"maxBlockExecutionUnits":{"memory":62000000,"steps":20000000000},"maxBlockHeaderSize":1100,"maxCollateralInputs":3,"maxTxExecutionUnits":{"memory":14000000,"steps":10000000000},"maxTxSize":16384,"maxValueSize":5000,"minFeeRefScriptCostPerByte":15,"minPoolCost":170000000,"monetaryExpansion":0.003,"poolPledgeInfluence":0.3,"poolRetireMaxEpoch":18,"poolVotingThresholds":{"committeeNoConfidence":0.51,"committeeNormal":0.51,"hardForkInitiation":0.51,"motionNoConfidence":0.51,"ppSecurityGroup":0.51},"protocolVersion":{"major":10,"minor":0},"stakeAddressDeposit":2000000,"stakePoolDeposit":500000000,"stakePoolTargetNum":500,"treasuryCut":0.2,"txFeeFixed":155381,"txFeePerByte":44,"utxoCostPerByte":4310}'
        exit 0
    fi
    
    # Handle address build command
    if [[ "$1" == "conway" && "$2" == "address" && "$3" == "build" ]]; then
        echo "addr_test1234567890abcdef"
        exit 0
    fi
    
    # Handle key verification-key command
    if [[ "$1" == "conway" && "$2" == "key" && "$3" == "verification-key" ]]; then
        echo "Key verification successful"
        exit 0
    fi
    
    # Handle transaction build command
    if [[ "$1" == "conway" && "$2" == "transaction" && "$3" == "build" ]]; then
        echo "Transaction build successful"
        exit 0
    fi
    
    # Handle stake-pool id command
    if [[ "$1" == "conway" && "$2" == "stake-pool" && "$3" == "id" ]]; then
        echo "pool1234567890abcdef"
        exit 0
    fi
    
    # Handle genesis hash command
    if [[ "$1" == "conway" && "$2" == "genesis" && "$3" == "hash" ]]; then
        echo "genesis_hash_1234567890abcdef"
        exit 0
    fi
    
    # Handle governance drep id command
    if [[ "$1" == "conway" && "$2" == "governance" && "$3" == "drep" && "$4" == "id" ]]; then
        echo "drep1234567890abcdef"
        exit 0
    fi
    
    # Handle debug commands (no era prefix)
    if [[ "$1" == "debug" ]]; then
        echo "Debug command executed: $*"
        exit 0
    fi
    
    # Default response for unhandled commands
    echo "Mock CLI executed with arguments: $*"
    exit 0
    """
    
    _ = FileManager.default.createFile(atPath: binaryPath, contents: mockScript.data(using: .utf8))
    
    // Make it executable
    let permissions = [FileAttributeKey.posixPermissions: 0o755]
    try? FileManager.default.setAttributes(permissions, ofItemAtPath: binaryPath)
    
    return binaryPath
}

/// Creates a comprehensive test configuration with all necessary paths
func createAdvancedTestConfiguration(cliPath: String? = nil) -> Config {
    let mockCliPath = cliPath ?? createMockCardanoCLI()
    
    let cardanoConfig = CardanoConfig(
        cli: FilePath(mockCliPath),
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

/// Creates a test configuration for offline mode
func createOfflineTestConfiguration(shelleyGenesisFile: String? = nil, offlineFile: String? = nil) -> Config {
    let mockCliPath = createMockCardanoCLI()
    
    let cardanoConfig = CardanoConfig(
        cli: FilePath(mockCliPath),
        node: FilePath("/usr/bin/true"),
        hwCli: nil,
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

/// Creates a mock genesis file for testing
func createMockGenesisFile() -> String {
    let tempDir = FileManager.default.temporaryDirectory
    let genesisPath = tempDir.appendingPathComponent("mock-genesis-\(UUID().uuidString).json").path
    
    let genesisData = """
    {
        "systemStart": "2024-01-01T00:00:00Z",
        "epochLength": 432000,
        "networkMagic": 1
    }
    """
    
    try? genesisData.write(toFile: genesisPath, atomically: true, encoding: .utf8)
    return genesisPath
}

/// Creates a mock offline file for testing
func createMockOfflineFile() -> String {
    let tempDir = FileManager.default.temporaryDirectory
    let offlinePath = tempDir.appendingPathComponent("mock-offline-\(UUID().uuidString).json").path
    
    let offlineData = """
    {
        "protocol": {
            "parameters": {
                "minFeeA": 44,
                "minFeeB": 155381,
                "maxTxSize": 16384,
                "coinsPerUTxOWord": 34482
            }
        }
    }
    """
    
    try? offlineData.write(toFile: offlinePath, atomically: true, encoding: .utf8)
    return offlinePath
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
