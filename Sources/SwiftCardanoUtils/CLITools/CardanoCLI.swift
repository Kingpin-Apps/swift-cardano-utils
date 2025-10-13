import Foundation
import SystemPackage
import SwiftCardanoCore
import Logging
import PotentCodables
import PotentCBOR


// MARK: - Main CardanoCLI Interface

/// Main interface for interacting with Cardano CLI tools
public struct CardanoCLI: BinaryInterfaceable {
    public let binaryPath: FilePath
    public let workingDirectory: FilePath
    public let configuration: Config
    public let logger: Logging.Logger
    
    public static let binaryName: String = "cardano-cli"
    public static let mininumSupportedVersion: String = "8.0.0"

    
    /// Initialize with optional configuration
    public init(configuration: Config, logger: Logger? = nil) async throws {
        // Assign all let properties directly
        self.configuration = configuration
        
        // Setup binary path
        guard let cliPath = configuration.cardano.cli else {
            throw SwiftCardanoUtilsError.binaryNotFound("cardano-cli path not configured")
        }
        self.binaryPath = cliPath
        try Self.checkBinary(binary: self.binaryPath)
        
        // Setup working directory
        self.workingDirectory = configuration.cardano.workingDir ?? FilePath(
            FileManager.default.currentDirectoryPath
        )
        try Self.checkWorkingDirectory(workingDirectory: self.workingDirectory)
        
        // Setup logger
        self.logger = logger ?? Logger(label: Self.binaryName)
        
        // Setup node socket environment variable
        if let socket = configuration.cardano.socket {
            Environment.set(.cardanoSocketPath, value: socket.string)
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
            guard let syncProgressDouble = Double(chainTip.syncProgress) else {
                throw SwiftCardanoUtilsError.invalidOutput("Could not parse syncProgress as Double: \(chainTip.syncProgress)")
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
            
            guard let syncProgressDouble = Double(chainTip.syncProgress) else {
                logger.warning("Could not parse syncProgress as Double: \(chainTip.syncProgress)")
                return Era(rawValue: chainTip.era)
            }
            let syncProgress = syncProgressDouble
            if syncProgress < 100.0 {
                logger.info("Node not fully synced!")
            }
            return Era(rawValue: chainTip.era)
        } catch {
            logger.info("Unable to check era. Node may not be fully synced. \(error)")
            return nil
        }
    }
    
    /// Get the current epoch from the node
    public func getEpoch() async throws -> Int {
        do {
            let chainTip = try await query.tip()
            
            guard let syncProgressDouble = Double(chainTip.syncProgress) else {
                throw SwiftCardanoUtilsError.invalidOutput("Could not parse syncProgress as Double: \(chainTip.syncProgress)")
            }
            let syncProgress = syncProgressDouble
            if syncProgress < 100.0 {
                throw SwiftCardanoUtilsError.nodeNotSynced(syncProgress)
            }
            
            return chainTip.epoch
        } catch let error as SwiftCardanoUtilsError {
            throw error
        } catch {
            throw SwiftCardanoUtilsError.invalidOutput("Could not get epoch from node: \(error)")
        }
    }
    
    /// Calculate current epoch from genesis.json offline
    public func calculateEpochOffline() async throws -> UInt32 {
        guard let configPath = configuration.cardano.config else {
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
        let currentEpoch = UInt32(timeDiff) / epochLength
        
        return currentEpoch
    }
    
    /// Get the current tip (slot number) of the blockchain
    public func getTip() async throws -> Int {
        let chainTip = try await query.tip()
        
        guard let syncProgressDouble = Double(chainTip.syncProgress) else {
            logger.warning("Could not parse syncProgress as Double: \(chainTip.syncProgress), proceeding anyway")
            return chainTip.slot
        }
        let syncProgress = syncProgressDouble // Already a percentage
        if syncProgress < 100.0 {
            logger.info("Node not fully synced!")
        }
        
        return chainTip.slot
    }
    
    /// Calculate the current TTL (Time To Live) for transactions
    public func getCurrentTTL() async throws -> Int {
        return try await getTip() + configuration.cardano.ttlBuffer
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
    
    /// Get a script object from a reference script dictionary
    ///
    /// - Parameter referenceScript: The reference script dictionary
    /// - Returns: A script object
    /// - Throws: CardanoChainError if the script type is not supported
    private func getScript(from referenceScript: [String: Any]) async throws -> ScriptType {
        guard let script = referenceScript["script"] as? [String: Any],
              let scriptType = script["type"] as? String
        else {
            throw SwiftCardanoUtilsError.valueError("Invalid reference script")
        }
        
        if scriptType == "PlutusScriptV1" {
            guard let cborHex = script["cborHex"] as? String,
                  let cborData = Data(hexString: cborHex)
            else {
                throw SwiftCardanoUtilsError.valueError("Invalid PlutusScriptV1 CBOR")
            }
            
            // Create PlutusV1Script from CBOR
            let v1script = PlutusV1Script(data: cborData)
            return .plutusV1Script(v1script)
        } else if scriptType == "PlutusScriptV2" {
            guard let cborHex = script["cborHex"] as? String,
                  let cborData = Data(hexString: cborHex)
            else {
                throw SwiftCardanoUtilsError.valueError("Invalid PlutusScriptV2 CBOR")
            }
            
            // Create PlutusV2Script from CBOR
            let v2script = PlutusV2Script(data: cborData)
            return .plutusV2Script(v2script)
        } else {
            // Create NativeScript from dictionary
            // Convert the dictionary to JSON data
            guard let jsonData = try? JSONSerialization.data(withJSONObject: script, options: [])
            else {
                throw SwiftCardanoUtilsError.valueError("Failed to serialize NativeScript JSON")
            }
            
            // Decode the JSON data to a NativeScript object
            let nativeScript = try JSONDecoder().decode(NativeScript.self, from: jsonData)
            return .nativeScript(nativeScript)
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
        
        guard let data = result.data(using: .utf8),
              let rawUtxos = try? JSONSerialization.jsonObject(with: data, options: [])
                as? [String: [String: Any]]
        else {
            throw SwiftCardanoUtilsError.valueError("Failed to parse UTxOs JSON")
        }
        
        var utxos: [UTxO] = []
        
        for (txHash, utxo) in rawUtxos {
            let parts = txHash.split(separator: "#")
            guard parts.count == 2,
                  let txIdx = Int(parts[1])
            else {
                continue
            }
            
            let txId = String(parts[0])
            let txIn = TransactionInput(
                transactionId: try TransactionId(from: .string(txId)),
                index: UInt16(txIdx)
            )
            
            guard let utxoValue = utxo["value"] as? [String: Any] else {
                continue
            }
            
            var value = Value(coin: 0)
            var multiAsset = MultiAsset([:])
            
            for (asset, amount) in utxoValue {
                if asset == "lovelace" {
                    if let lovelace = amount as? Int {
                        value.coin = Int(lovelace)
                    }
                } else {
                    let policyId = asset
                    
                    guard let assets = amount as? [String: Int] else {
                        continue
                    }
                    
                    for (assetHexName, assetAmount) in assets {
                        // Create Asset and add to MultiAsset
                        let policy = try ScriptHash(from: .string(policyId))
                        let assetName = AssetName(from: assetHexName)
                        
                        // Initialize the Asset for this policy if it doesn't exist
                        if multiAsset[policy] == nil {
                            multiAsset[policy] = Asset([:])
                        }
                        // Add the asset to the policy
                        multiAsset[policy]?[assetName] = assetAmount
                    }
                }
            }
            
            // Set the multi-asset on the value
            value.multiAsset = multiAsset
            
            // Handle datum hash
            var datumHash: DatumHash? = nil
            if let datumHashStr = utxo["datumhash"] as? String {
                datumHash = try DatumHash(from: .string(datumHashStr))
            }
            
            // Handle datum
            var datum: Datum? = nil
            if let datumStr = utxo["datum"] as? String, let datumData = Data(hexString: datumStr) {
                datum = .cbor(CBOR(datumData))
            } else if let inlineDatum = utxo["inlineDatum"] as? [AnyValue: AnyValue] {
                // Convert inline datum dictionary to RawPlutusData
                // This would require proper implementation of RawPlutusData.fromDict
                datum = .dict(inlineDatum)
            }
            
            // Handle reference script
            var script: ScriptType? = nil
            if let referenceScript = utxo["referenceScript"] as? [String: Any] {
                script = try await getScript(from: referenceScript)
            }
            
            let address = try Address(
                from: .string(utxo["address"] as! String)
            )
            let txOut = TransactionOutput(
                address: address,
                amount: value,
                datumHash: datumHash,
                datum: datum,
                script: script
            )
            
            utxos.append(UTxO(input: txIn, output: txOut))
        }
        
        return utxos
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
        
        let stakeAddressInfo = try JSONDecoder().decode(
            [StakeAddressInfo].self,
            from: results.toData
        )
        
        return stakeAddressInfo
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
            args.append(contentsOf: configuration.cardano.network.arguments)
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
