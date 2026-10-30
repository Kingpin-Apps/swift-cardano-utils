import BigInt
import Foundation
import SystemPackage
import SwiftCardanoCore
import Logging
import Command


// MARK: - Main CardanoCLI Interface

/// Main interface for interacting with Cardano CLI tools
public struct CardanoCLI: BinaryInterfaceable {
    public let binaryPath: FilePath
    public let workingDirectory: FilePath
    public let configuration: Config
    public let cardanoConfig: CardanoConfig
    public let logger: Logging.Logger
    
    public static let binaryName: String = "cardano-cli"
    public static let mininumSupportedVersion: String = "10.0.0"
    
    public let commandRunner: any CommandRunning
    
    /// Initialize with optional configuration
    public init(
        configuration: Config,
        logger: Logging.Logger? = nil,
        commandRunner: (any CommandRunning)? = nil
    ) async throws {
        guard let cardanoConfig = configuration.cardano else {
            throw SwiftCardanoUtilsError.configurationMissing(
                "Cardano configuration missing: \(configuration)"
            )
        }
        
        self.configuration = configuration
        self.cardanoConfig = cardanoConfig

        // Setup binary path and validate
        if let container = cardanoConfig.container {
            // Container mode.  The official IntersectMBO entrypoint script
            // routes on $1, supporting two sub-modes:
            //
            //   Exec mode  (containerName is set):
            //     `docker exec <name> cardano-cli <args>`
            //     Bypasses the entrypoint and invokes the binary directly
            //     inside an already-running node container.
            //
            //   Run mode  (no containerName):
            //     `docker run <image> cli <args>`
            //     Entrypoint routes $1=="cli" → run-client, which shifts the
            //     "cli" prefix and delegates to `cardano-cli <remaining args>`.
            //     Requires `detach: false` in ContainerConfig so that command
            //     output is returned to the caller rather than a container ID.
            if container.containerName != nil {
                // Exec mode: use the binary path directly (entrypoint bypassed).
                self.binaryPath = cardanoConfig.cli ?? FilePath(Self.binaryName)
            } else {
                // Run mode: "cli" is the entrypoint routing word, not a binary.
                guard container.detach == false else {
                    throw SwiftCardanoUtilsError.configurationMissing(
                        "CardanoCLI container run mode requires 'detach: false' in ContainerConfig " +
                        "so that command output is returned to the caller."
                    )
                }
                self.binaryPath = FilePath("cli")
            }
            try ContainerChecks.checkImage(config: container)
        } else {
            guard let cliPath = cardanoConfig.cli else {
                throw SwiftCardanoUtilsError.binaryNotFound("cardano-cli path not configured")
            }
            self.binaryPath = cliPath
            try Self.checkBinary(binary: self.binaryPath)
        }

        // Setup working directory
        self.workingDirectory = cardanoConfig.workingDir ?? FilePath(
            FileManager.default.currentDirectoryPath
        )
        try Self.checkWorkingDirectory(workingDirectory: self.workingDirectory)

        // Setup logger
        self.logger = logger ?? Logger(label: Self.binaryName)

        // Setup command runner.
        // - Exec mode  (containerName set, or no container): existing behaviour.
        // - Run mode   (container without containerName): launch a new ephemeral
        //   container per command using the entrypoint's "cli" routing mode.
        if let container = cardanoConfig.container, container.containerName == nil {
            self.commandRunner = ContainerizedCommandRunner.resolve(
                injected: commandRunner,
                container: container,
                mode: .run,
                logger: self.logger
            )
        } else {
            self.commandRunner = ContainerizedCommandRunner.resolve(
                injected: commandRunner,
                container: cardanoConfig.container,
                mode: .exec,
                logger: self.logger
            )
        }
        
        // Setup node socket environment variable
        if let socket = cardanoConfig.socket {
            Environment.set(.cardanoNodeSocketPath, value: socket.string)
        }
        
        // Check the CLI version compatibility on initialization
        try await checkVersion()
    }
    
    // MARK: - High-Level Utility Methods
    
    /// Get the cardano-cli version
    public func version() async throws -> String {
        let output = try await runCommand(["--version"])
        let components = output.components(separatedBy: " ")
        guard components.count >= 2 else {
            throw SwiftCardanoUtilsError.invalidOutput("Could not parse version from: \(output)")
        }
        return components[1]
    }
    
    /// Get the help text
    public func help() async throws -> String {
        let output = try await runCommand(["help"])
        return output
    }
    
    /// Check that the mode is set to Online and node is synced
    public func checkOnline() async throws {
        let syncProgress = try await getSyncProgress()
        if syncProgress < 100.0 {
            throw SwiftCardanoUtilsError.nodeNotSynced(syncProgress)
        }
    }
    
    /// Get the node's current sync progress
    public func getSyncProgress() async throws -> Double {
        do {
            let chainTip = try await query.tip()
            
            // Convert string syncProgress to Double (already in percentage format)
            guard let syncProgress = chainTip.syncProgress,
                  let syncProgressDouble = Double(syncProgress) else {
                throw SwiftCardanoUtilsError
                    .invalidOutput(
                        "Could not parse syncProgress as Double: \(String(describing: chainTip.syncProgress))"
                    )
            }
            return syncProgressDouble
        } catch {
            logger.warning("Unable to check sync progress. Node may not be online yet. \(error)")
            return 0.0
        }
    }
    
    /// Get the current era from the node
    public func getEra() async throws -> Era? {
        do {
            let chainTip = try await query.tip()
            
            guard let syncProgress = chainTip.syncProgress,
                  let syncProgressDouble = Double(syncProgress) else {
                throw SwiftCardanoUtilsError
                    .invalidOutput(
                        "Could not parse syncProgress as Double: \(String(describing: chainTip.syncProgress))"
                    )
            }
            
            guard let era = chainTip.era else {
                throw SwiftCardanoUtilsError
                    .invalidOutput(
                        "Could not parse era: \(String(describing: chainTip.era))"
                    )
            }
            
            if syncProgressDouble < 100.0 {
                logger.warning("Node not fully synced!")
            }
            
            return Era(rawValue: era.lowercased())
        } catch {
            logger.info("Unable to check era. Node may not be fully synced. \(error)")
            return nil
        }
    }
    
    /// Get the current epoch from the node
    public func getEpoch() async throws -> EpochNumber {
        do {
            let chainTip = try await query.tip()
            
            guard let syncProgress = chainTip.syncProgress,
                  let syncProgressDouble = Double(syncProgress) else {
                throw SwiftCardanoUtilsError
                    .invalidOutput(
                        "Could not parse syncProgress as Double: \(String(describing: chainTip.syncProgress))"
                    )
            }
            
            if syncProgressDouble < 100.0 {
                throw SwiftCardanoUtilsError.nodeNotSynced(syncProgressDouble)
            }
            
            guard let epoch = chainTip.epoch else {
                throw SwiftCardanoUtilsError
                    .invalidOutput(
                        "Could not parse epoch: \(String(describing: chainTip.epoch))"
                    )
            }
            
            return epoch
        } catch let error as SwiftCardanoUtilsError {
            throw error
        } catch {
            throw SwiftCardanoUtilsError.invalidOutput("Could not get epoch from node: \(error)")
        }
    }
    
    /// Calculate current epoch from genesis.json offline
    public func calculateEpochOffline() async throws -> UInt32 {
        guard let configPath = cardanoConfig.config else {
            throw SwiftCardanoUtilsError.valueError("Cardano node config path is required for offline epoch calculation")
        }
        
        let nodeConfig = try NodeConfig.load(
            from: configPath.string
        )
        
        // Get parent directory
        let parentDir = configPath.removingLastComponent()
        let shelleyGenesisFile = parentDir.appending(nodeConfig.shelleyGenesisFile)
        
        let shelleyGenesis = try ShelleyGenesis.load(
            from: shelleyGenesisFile.string
        )
        
        let systemStartStr = shelleyGenesis.systemStart
        let epochLength = shelleyGenesis.epochLength
        
        let formatter = ISO8601DateFormatter()
        guard let startDate = formatter.date(from: systemStartStr) else {
            throw SwiftCardanoUtilsError.invalidOutput("Could not parse systemStart date")
        }
        
        let currentTime = Date()
        let timeDiff = currentTime.timeIntervalSince(startDate)
        guard timeDiff >= 0, epochLength > 0,
              let currentEpoch = UInt32(exactly: UInt64(timeDiff) / epochLength)
        else {
            throw SwiftCardanoUtilsError.invalidOutput("Could not calculate epoch from genesis")
        }
        
        return currentEpoch
    }
    
    /// Get the current tip (slot number) of the blockchain
    public func getTip() async throws -> SlotNumber {
        let chainTip = try await query.tip()
        
        guard let syncProgress = chainTip.syncProgress,
              let syncProgressDouble = Double(syncProgress) else {
            throw SwiftCardanoUtilsError
                .invalidOutput(
                    "Could not parse syncProgress as Double: \(String(describing: chainTip.syncProgress))"
                )
        }
        
        if syncProgressDouble < 100.0 {
            logger.info("Node not fully synced!")
        }
        
        guard let slot = chainTip.slot else {
            throw SwiftCardanoUtilsError
                .invalidOutput(
                    "Could not parse slot: \(String(describing: chainTip.slot))"
                )
        }
        
        return slot
    }
    
    /// Calculate the current TTL (Time To Live) for transactions
    public func getCurrentTTL() async throws -> SlotNumber {
        return try await getTip() + SlotNumber(cardanoConfig.ttlBuffer)
    }
    
    /// Get protocol parameters from the Cardano node or offline file
    public func getProtocolParameters(paramsFile: FilePath? = nil) async throws -> ProtocolParameters {
        let outFile: String
        if paramsFile != nil {
            outFile = paramsFile!.string
        } else {
            outFile = "/dev/stdout"
        }
        
        let results = try await query
            .protocolParameters(
                arguments: ["--out-file", outFile]
            )
        
        
        let params: ProtocolParameters
        if paramsFile != nil {
            params = try ProtocolParameters.load(
                from: paramsFile!.string
            )
        } else {
            params = try JSONDecoder().decode(
                ProtocolParameters.self,
                from: results.toData
            )
        }
        
        return params
    }
    
    /// A script object from a UTxO's `referenceScript` entry.
    ///
    /// - Throws: ``SwiftCardanoUtilsError/valueError(_:)`` if the script type is not supported
    static func getScript(from referenceScript: CLIJSON) throws -> ScriptType {
        guard let script = referenceScript["script"], let scriptType = script["type"]?.string else {
            throw SwiftCardanoUtilsError.valueError("Invalid reference script")
        }
        func cbor(_ name: String) throws -> Data {
            guard let hex = script["cborHex"]?.string, let data = Data(hexString: hex) else {
                throw SwiftCardanoUtilsError.valueError("Invalid \(name) CBOR")
            }
            return data
        }
        switch scriptType {
        case "PlutusScriptV1":
            return .plutusV1Script(PlutusV1Script(data: try cbor("PlutusScriptV1")))
        case "PlutusScriptV2":
            return .plutusV2Script(PlutusV2Script(data: try cbor("PlutusScriptV2")))
        default:
            // A native script in cardano-cli's JSON form.
            return .nativeScript(try JSONDecoder().decode(NativeScript.self, from: JSONEncoder().encode(script)))
        }
    }

    /// Get all UTxOs associated with an address
    ///
    /// - Parameter address: An address encoded with bech32
    /// - Returns: A list of UTxOs
    /// - Throws: CardanoChainError if the query fails
    public func utxos(address: Address) async throws -> [UTxO] {
        // Query the UTxOs
        let result = try await query.utxo(arguments: [
            "--address", address.toBech32(), "--out-file", "/dev/stdout"
        ])
        
        guard let data = result.data(using: .utf8) else {
            throw SwiftCardanoUtilsError.valueError("Failed to parse UTxOs JSON")
        }
        return try Self.parseUTxOs(data)
    }

    /// The UTxOs in `query utxo --output-json` output, read exactly: amounts
    /// through `JSONDecoder` as exact numbers, datums from their CBOR.
    static func parseUTxOs(_ data: Data) throws -> [UTxO] {
        let rawUtxos: [String: CLIJSON]
        do {
            rawUtxos = try JSONDecoder().decode([String: CLIJSON].self, from: data)
        } catch {
            throw SwiftCardanoUtilsError.valueError("Failed to parse UTxOs JSON: \(error)")
        }

        var utxos: [UTxO] = []

        for (txHash, utxo) in rawUtxos {
            let parts = txHash.split(separator: "#")
            guard parts.count == 2,
                  let txIdx = UInt16(parts[1])
            else {
                throw SwiftCardanoUtilsError.valueError("Invalid UTxO reference: \(txHash)")
            }

            let txIn = TransactionInput(
                transactionId: try TransactionId(from: .string(String(parts[0]))),
                index: txIdx
            )

            guard let utxoValue = utxo["value"]?.object else {
                throw SwiftCardanoUtilsError.valueError("UTxO \(txHash) has no value")
            }

            var value = Value(coin: 0)
            var multiAsset = MultiAsset([:])

            for (asset, amount) in utxoValue {
                if asset == "lovelace" {
                    guard let lovelace = amount.integer else {
                        throw SwiftCardanoUtilsError.valueError("Invalid lovelace amount: \(amount)")
                    }
                    value.coin = lovelace
                } else {
                    let policyId = asset
                    guard let rawAssets = amount.object else {
                        throw SwiftCardanoUtilsError.valueError("Invalid assets for policy \(policyId): \(amount)")
                    }
                    let policy = try ScriptHash(from: .string(policyId))
                    for (assetHexName, rawAmount) in rawAssets {
                        guard let assetAmount = rawAmount.integer else {
                            throw SwiftCardanoUtilsError.valueError(
                                "Invalid quantity for asset \(policyId).\(assetHexName): \(rawAmount)"
                            )
                        }
                        let assetName = AssetName(from: assetHexName)
                        if multiAsset[policy] == nil {
                            multiAsset[policy] = Asset([:])
                        }
                        multiAsset[policy]?[assetName] = assetAmount
                    }
                }
            }
            value.multiAsset = multiAsset

            var datumHash: DatumHash? = nil
            if let datumHashStr = utxo["datumhash"]?.string {
                datumHash = try DatumHash(from: .string(datumHashStr))
            }

            let datumOption = try datumOption(utxo, txHash)

            var script: ScriptType? = nil
            if let referenceScript = utxo["referenceScript"], !referenceScript.isNull {
                script = try getScript(from: referenceScript)
            }

            guard let addressText = utxo["address"]?.string else {
                throw SwiftCardanoUtilsError.valueError("UTxO \(txHash) has no address")
            }
            let txOut = TransactionOutput(
                address: try Address(from: .string(addressText)),
                amount: value,
                datumHash: datumHash,
                datumOption: datumOption,
                script: script
            )

            utxos.append(UTxO(input: txIn, output: txOut))
        }

        return utxos
    }

    /// A UTxO entry's datum, read from its CBOR: `datum` (a datum option) or
    /// `inlineDatumRaw` (the inline datum's Plutus data). `nil` when it has neither.
    ///
    /// The JSON `inlineDatum` is never read: a datum integer is unbounded and a
    /// JSON number does not hold it exactly. An entry with an inline datum but
    /// no CBOR for it throws.
    static func datumOption(_ entry: CLIJSON, _ txHash: String) throws -> DatumOption? {
        if let datum = entry["datum"]?.string {
            guard let data = Data(hexString: datum) else {
                throw SwiftCardanoUtilsError.valueError("UTxO \(txHash) datum is not hex")
            }
            return try DatumOption.fromCBOR(data: data)
        }
        if let raw = entry["inlineDatumRaw"]?.string {
            guard let data = Data(hexString: raw) else {
                throw SwiftCardanoUtilsError.valueError("UTxO \(txHash) inlineDatumRaw is not hex")
            }
            return DatumOption(datum: try PlutusData.fromCBOR(data: data))
        }
        if let inline = entry["inlineDatum"], !inline.isNull {
            throw SwiftCardanoUtilsError.valueError(
                "UTxO \(txHash) has an inline datum only as JSON (no inlineDatumRaw), whose integers cannot be read exactly"
            )
        }
        return nil
    }

    /// Get the stake address information
    ///
    /// - Parameter address: The stake address
    /// - Returns: List of StakeAddressInfo objects
    /// - Throws: CardanoChainError if the query fails
    public func stakeAddressInfo(address: Address) async throws -> [StakeAddressInfo] {
        let results = try await query.stakeAddressInfo(arguments: [
            "--address", address.toBech32(), "--out-file", "/dev/stdout"
        ])
        
        do {
            let stakeAddressInfo = try JSONDecoder().decode(
                [CLIStakeAddressInfo].self,
                from: results.toData
            )

            return stakeAddressInfo.map(\.stakeAddressInfo)
        } catch {
            throw SwiftCardanoUtilsError
                .invalidOutput(
                    "Could not decode stake address info: \(error)"
                )
        }
    }
    
    /// Sign a transaction with witness files (for multi-signature transactions)
    public func witnessTransaction(txFile: FilePath, witnesses: [FilePath]) async throws -> FilePath {
        // Generate witness arguments
        var witnessArgs: [String] = []
        for witness in witnesses {
            witnessArgs.append(contentsOf: ["--witness-file", witness.string])
        }
        
        // Generate signed transaction file name
        let txName = txFile.lastComponent
        let parentDir = txFile.removingLastComponent()
        let signedTxFile = parentDir.appending("\(txName!.string).signed")
        
        // Assemble the transaction with witnesses
        var args = ["--tx-body-file", txFile.string]
        args.append(contentsOf: witnessArgs)
        args.append(contentsOf: ["--out-file", signedTxFile.string])
        
        _ = try await transaction.assemble(arguments: args)
        
        logger.debug("Transaction assembled with witnesses: \(signedTxFile.string)")
        return signedTxFile
    }
    
    /// Sign a transaction with signing keys
    public func signTransaction(txFile: FilePath, signingKeys: [FilePath]) async throws -> FilePath {
        do {
            // Generate signing key arguments
            var signingKeyArgs: [String] = []
            for keyPath in signingKeys {
                signingKeyArgs.append(contentsOf: ["--signing-key-file", keyPath.string])
            }
            
            // Generate signed transaction file name
            let txName = txFile.lastComponent
            let parentDir = txFile.removingLastComponent()
            let signedTxFile = parentDir.appending("\(txName!.string).signed")
            
            // Sign the transaction
            var args = ["--tx-body-file", txFile.string]
            args.append(contentsOf: signingKeyArgs)
            args.append(contentsOf: cardanoConfig.network.arguments)
            args.append(contentsOf: ["--out-file", signedTxFile.string])
            
            _ = try await transaction.sign(arguments: args)
            
            logger.debug("Transaction signed: \(signedTxFile.string)")
            return signedTxFile
        } catch {
            throw SwiftCardanoUtilsError.commandFailed(["transaction", "sign"], "Unable to sign transaction: \(error)")
        }
    }
    
    /// Submit a transaction to the blockchain
    public func submitTransaction(signedTxFile: FilePath, cleanup: Bool = false) async throws -> String {
        // Submit the transaction
        do {
            _ = try await transaction.submit(arguments: ["--tx-file", signedTxFile.string])
        } catch {
            throw SwiftCardanoUtilsError.commandFailed(["transaction", "submit"], "Unable to submit transaction: \(error)")
        }
        
        // Get the transaction ID
        let txId: String
        do {
            txId = try await transaction.txId(arguments: ["--tx-file", signedTxFile.string])
        } catch {
            throw SwiftCardanoUtilsError.commandFailed(["transaction", "txid"], "Unable to get transaction id: \(error)")
        }
        
        // Clean up transaction files if requested
        if cleanup {
            try? FileManager.default.removeItem(atPath: signedTxFile.string)
            logger.debug("Cleaned up transaction file: \(signedTxFile.string)")
        }
        
        logger.debug("✅ Transaction submitted successfully")
        logger.debug("Transaction ID: \(txId)")
        
        return txId
    }
}

extension CardanoCLI {
    // MARK: - Command Accessors
    
    /// Access to address commands
    public var address: AddressCommandImpl {
        return AddressCommandImpl(baseCLI: self)
    }
    
    /// Access to key commands
    public var key: KeyCommandImpl {
        return KeyCommandImpl(baseCLI: self)
    }
    
    /// Access to node commands
    public var node: NodeCommandImpl {
        return NodeCommandImpl(baseCLI: self)
    }
    
    /// Access to hash commands
    public var hash: HashCommandImpl {
        return HashCommandImpl(baseCLI: self)
    }
    
    /// Access to query commands
    public var query: QueryCommandImpl {
        return QueryCommandImpl(baseCLI: self)
    }
    
    /// Access to legacy commands
    public var legacy: LegacyCommandImpl {
        return LegacyCommandImpl(baseCLI: self)
    }
    
    /// Access to transaction commands
    public var transaction: TransactionCommandImpl {
        return TransactionCommandImpl(baseCLI: self)
    }
    
    /// Access to stake address commands
    public var stakeAddress: StakeAddressCommandImpl {
        return StakeAddressCommandImpl(baseCLI: self)
    }
    
    /// Access to stake pool commands
    public var stakePool: StakePoolCommandImpl {
        return StakePoolCommandImpl(baseCLI: self)
    }
    
    /// Access to governance commands
    public var governance: GovernanceCommandImpl {
        return GovernanceCommandImpl(baseCLI: self)
    }
    
    /// Access to genesis commands
    public var genesis: GenesisCommandImpl {
        return GenesisCommandImpl(baseCLI: self)
    }
    
    /// Access to text view commands
    public var textView: TextViewCommandImpl {
        return TextViewCommandImpl(baseCLI: self)
    }
    
    /// Access to debug commands
    public var debug: DebugCommandImpl {
        return DebugCommandImpl(baseCLI: self)
    }
    
}
