# CardanoSigner

Advanced offline signing tool supporting CIP-8, CIP-30, CIP-36 standards for secure Cardano operations.

## Overview

``CardanoSigner`` provides advanced cryptographic signing capabilities for Cardano, supporting modern web3 standards and secure offline workflows. It's designed for applications requiring sophisticated signature operations beyond basic transaction signing.

### Key Features

- **CIP Standards Support** - CIP-8, CIP-30, CIP-36 compliance
- **Offline Signing** - Secure air-gapped signature operations
- **Multi-Signature** - Support for complex signing scenarios
- **Key Generation** - Advanced key derivation and management
- **Data Verification** - Signature verification and validation
- **Catalyst Integration** - Voting registration and delegation (CIP-36)
- **Governance Support** - JSON-LD metadata hashing (CIP-100)

### Supported Standards

| Standard | Purpose | Supported |
|----------|---------|-----------|
| CIP-8 | Message signing | ✅ |
| CIP-30 | DApp connector standard | ✅ |
| CIP-36 | Catalyst voting registration | ✅ |
| CIP-100 | Governance metadata | ✅ |

### Requirements

- macOS 14.0+
- Swift 6.0+
- cardano-signer 1.17.0+ (installed separately)

## Installation

### Installing cardano-signer

Download the latest cardano-signer from the [official releases](https://github.com/gitmachtl/cardano-signer/releases):

```bash
# Download and install cardano-signer
curl -L https://github.com/gitmachtl/cardano-signer/releases/latest/download/cardano-signer-macos -o cardano-signer
chmod +x cardano-signer
sudo mv cardano-signer /usr/local/bin/
```

## Configuration

CardanoSigner requires the signer binary path to be configured:

```swift
import CardanoCLITools
import System

let cardanoConfig = CardanoConfig(
    cli: FilePath("/usr/local/bin/cardano-cli"),
    node: FilePath("/usr/local/bin/cardano-node"),
    hwCli: nil,
    signer: FilePath("/usr/local/bin/cardano-signer"), // Required
    socket: FilePath("/tmp/cardano-node.socket"),
    config: FilePath("/path/to/config.json"),
    topology: nil,
    database: nil,
    port: nil,
    hostAddr: nil,
    network: .preview,
    era: .conway,
    ttlBuffer: 3600,
    workingDir: FilePath("/tmp"),
    showOutput: false
)

let configuration = Configuration(
    cardano: cardanoConfig,
    ogmios: nil,
    kupo: nil
)

let signer = try await CardanoSigner(configuration: configuration)
```

## Basic Signing Operations

### Message Signing

```swift
// Sign a text message
let signature = try await signer.sign(
    dataText: "Hello, Cardano!",
    secretKey: "ed25519_sk1...", // Extended signing key
    outputFormat: .hex
)
print("Signature: \(signature)")

// Sign hex data
let hexSignature = try await signer.sign(
    dataHex: "48656c6c6f2c20576f726c6421",
    secretKey: "ed25519_sk1...",
    outputFormat: .json
)

// Sign file content
let fileSignature = try await signer.sign(
    dataFile: "/path/to/message.txt",
    secretKey: "ed25519_sk1...",
    outputFormat: .bech
)
```

### Signature Verification

```swift
// Verify a signature
let isValid = try await signer.verify(
    dataText: "Hello, Cardano!",
    signature: "84584001234567890abcdef...",
    publicKey: "ed25519_pk1...",
    outputFormat: .json
)
print("Signature valid: \(isValid)")

// Verify with address check
let isValidWithAddress = try await signer.verify(
    dataHex: "48656c6c6f2c20576f726c6421",
    signature: "84584001234567890abcdef...",
    publicKey: "ed25519_pk1...",
    address: "addr_test1...", // Optional address verification
    outputFormat: .hex
)
```

## Advanced Signing Standards

### CIP-8 Message Signing

CIP-8 provides standardized message signing for Cardano DApps:

```swift
// Sign message with CIP-8 standard
let cip8Signature = try await signer.signCIP8(
    dataText: "Sign in to MyDApp",
    secretKey: "ed25519_sk1...",
    address: "addr_test1...",
    testnetMagic: 2,
    outputFormat: .json
)
print("CIP-8 signature: \(cip8Signature)")

// Sign hashed data (already hashed)
let hashedSignature = try await signer.signCIP8(
    dataHex: "a665a45920422f9d417e4867e...", // Pre-hashed data
    secretKey: "ed25519_sk1...",
    address: "addr_test1...",
    hashed: true,
    outputFormat: .json
)
```

### CIP-30 Connector Standard

CIP-30 signing for wallet connector compatibility:

```swift
// Sign for CIP-30 wallet connector
let cip30Signature = try await signer.signCIP30(
    dataHex: "a665a45920422f9d417e4867e...",
    secretKey: "ed25519_sk1...",
    address: "addr_test1...",
    noHashCheck: false,
    testnetMagic: 2,
    outputFormat: .json
)

// Verify CIP-30 signature
let cip30Valid = try await signer.verifyCIP30(
    coseSign1: "845840a20126...", // COSE_Sign1 structure
    coseKey: "a401012004215820...", // COSE_Key structure
    dataHex: "a665a45920422f9d417e4867e...",
    outputFormat: .json
)
print("CIP-30 signature valid: \(cip30Valid)")
```

### CIP-36 Catalyst Voting

CIP-36 provides voting registration and delegation for Catalyst:

```swift
// Register for Catalyst voting
let catalystRegistration = try await signer.signCIP36(
    votePublicKeys: ["ed25519_pk1abc...", "ed25519_pk1def..."],
    voteWeights: [60, 40], // Percentage weights
    secretKey: "ed25519_sk1...", // Stake key
    paymentAddress: "addr_test1...",
    nonce: 12345678,
    votePurpose: 0, // Catalyst voting
    testnetMagic: 2,
    outputFormat: .json,
    outCbor: "/tmp/catalyst-reg.cbor"
)

// Deregister from Catalyst
let deregistration = try await signer.signCIP36(
    secretKey: "ed25519_sk1...",
    nonce: 12345679,
    deregister: true,
    testnetMagic: 2,
    outputFormat: .json
)
```

## Key Generation

### Standard Key Generation

```swift
// Generate payment keys
let paymentKeys = try await signer.keygen(
    path: .payment.pathString,
    outputFormat: .json,
    outSkey: "payment.skey",
    outVkey: "payment.vkey"
)

// Generate stake keys
let stakeKeys = try await signer.keygen(
    path: .stake.pathString,
    outputFormat: .json,
    outSkey: "stake.skey",
    outVkey: "stake.vkey"
)

// Generate keys from mnemonic
let mnemonicKeys = try await signer.keygen(
    path: "1852'/1815'/0'/0/0",
    mnemonics: "word1 word2 word3 ... word24",
    outputFormat: .json,
    outFile: "keys.json"
)
```

### CIP-36 Voting Keys

```swift
// Generate Catalyst voting keys
let votingKeys = try await signer.keygen(
    path: .cip36.pathString,
    cip36: true,
    votePurpose: 0,
    vkeyExtended: true,
    outputFormat: .json,
    outSkey: "vote.skey",
    outVkey: "vote.vkey"
)
```

### Committee and DRep Keys

```swift
// Generate committee cold keys
let committeeColdKeys = try await signer.keygen(
    path: .ccCold.pathString,
    outputFormat: .json,
    outSkey: "cc-cold.skey",
    outVkey: "cc-cold.vkey"
)

// Generate committee hot keys
let committeeHotKeys = try await signer.keygen(
    path: .ccHot.pathString,
    outputFormat: .json,
    outSkey: "cc-hot.skey",
    outVkey: "cc-hot.vkey"
)

// Generate DRep keys
let drepKeys = try await signer.keygen(
    path: .drep.pathString,
    outputFormat: .json,
    outSkey: "drep.skey",
    outVkey: "drep.vkey"
)
```

## Governance Operations

### CIP-100 Metadata Hashing

CIP-100 provides standardized hashing for governance metadata:

```swift
// Hash governance metadata
let metadataHash = try await signer.hashCIP100(
    dataFile: "/path/to/governance-metadata.jsonld",
    outputFormat: .json,
    outCanonized: "canonized-metadata.json",
    outFile: "metadata-hash.json"
)

// Hash JSON-LD text directly
let textHash = try await signer.hashCIP100(
    dataText: """
    {
      "@context": "https://schema.org",
      "@type": "GovernanceAction",
      "title": "Treasury Withdrawal Proposal"
    }
    """,
    outputFormat: .hex
)
```

## Offline Workflows

### Air-Gapped Signing

CardanoSigner excels in offline, air-gapped environments:

```swift
class OfflineSigningService {
    private let signer: CardanoSigner
    
    init() async throws {
        // Configure for offline use (no node connection needed)
        let config = Configuration(
            cardano: CardanoConfig(
                cli: FilePath("/usr/local/bin/cardano-cli"),
                node: FilePath("/usr/local/bin/cardano-node"),
                hwCli: nil,
                signer: FilePath("/usr/local/bin/cardano-signer"),
                socket: FilePath("/tmp/dummy.socket"), // Not used offline
                config: FilePath("/tmp/dummy.json"), // Not used offline
                topology: nil,
                database: nil,
                port: nil,
                hostAddr: nil,
                network: .mainnet,
                era: .conway,
                ttlBuffer: 3600,
                workingDir: FilePath("/tmp"),
                showOutput: false
            ),
            ogmios: nil,
            kupo: nil
        )
        
        self.signer = try await CardanoSigner(configuration: config)
    }
    
    func signTransactionOffline(
        txBodyHex: String,
        signingKey: String
    ) async throws -> String {
        // Sign transaction body hash
        return try await signer.sign(
            dataHex: txBodyHex,
            secretKey: signingKey,
            outputFormat: .hex
        )
    }
    
    func signDAppMessage(
        message: String,
        signingKey: String,
        userAddress: String
    ) async throws -> String {
        // CIP-8 signing for DApp authentication
        return try await signer.signCIP8(
            dataText: message,
            secretKey: signingKey,
            address: userAddress,
            outputFormat: .json
        )
    }
    
    func registerCatalystVoting(
        votePublicKeys: [String],
        stakeSigningKey: String,
        rewardsAddress: String,
        nonce: UInt
    ) async throws -> String {
        // CIP-36 voting registration
        return try await signer.signCIP36(
            votePublicKeys: votePublicKeys,
            voteWeights: [100], // Single delegate
            secretKey: stakeSigningKey,
            paymentAddress: rewardsAddress,
            nonce: nonce,
            votePurpose: 0,
            outputFormat: .json,
            outCbor: "catalyst-registration.cbor"
        )
    }
}
```

### Multi-Signature Coordination

```swift
class MultiSignatureCoordinator {
    private let signer: CardanoSigner
    
    init(configuration: Configuration) async throws {
        self.signer = try await CardanoSigner(configuration: configuration)
    }
    
    func createPartialSignature(
        transactionHash: String,
        signingKey: String,
        signerIndex: Int
    ) async throws -> PartialSignature {
        let signature = try await signer.sign(
            dataHex: transactionHash,
            secretKey: signingKey,
            outputFormat: .hex
        )
        
        return PartialSignature(
            index: signerIndex,
            signature: signature,
            publicKey: extractPublicKey(from: signingKey)
        )
    }
    
    func verifyPartialSignature(
        _ partial: PartialSignature,
        transactionHash: String
    ) async throws -> Bool {
        return try await signer.verify(
            dataHex: transactionHash,
            signature: partial.signature,
            publicKey: partial.publicKey,
            outputFormat: .json
        )
    }
    
    private func extractPublicKey(from signingKey: String) -> String {
        // Extract public key from signing key
        // This would use CardanoCLI key operations
        return "ed25519_pk1..."
    }
}

struct PartialSignature {
    let index: Int
    let signature: String
    let publicKey: String
}
```

## Integration with CardanoCLI

CardanoSigner complements <doc:CardanoCLI> for complete transaction workflows:

```swift
class SigningService {
    let cli: CardanoCLI
    let signer: CardanoSigner
    
    init(configuration: Configuration) async throws {
        self.cli = try await CardanoCLI(configuration: configuration)
        self.signer = try await CardanoSigner(configuration: configuration)
    }
    
    func signAndSubmitTransaction(
        txBodyFile: String,
        signingKeys: [String]
    ) async throws -> String {
        // 1. Calculate transaction hash using CardanoCLI
        let txId = try await cli.transaction.txId(arguments: [
            "--tx-body-file", txBodyFile
        ])
        
        // 2. Sign with CardanoSigner
        var witnesses: [String] = []
        for (index, key) in signingKeys.enumerated() {
            let signature = try await signer.sign(
                dataHex: txId,
                secretKey: key,
                outputFormat: .hex
            )
            
            // Create witness file
            let witnessFile = "witness-\(index).json"
            // ... create witness structure
            witnesses.append(witnessFile)
        }
        
        // 3. Assemble transaction with CardanoCLI
        var assembleArgs = ["--tx-body-file", txBodyFile]
        for witness in witnesses {
            assembleArgs.append(contentsOf: ["--witness-file", witness])
        }
        assembleArgs.append(contentsOf: ["--out-file", "signed-tx.json"])
        
        let _ = try await cli.transaction.assemble(arguments: assembleArgs)
        
        // 4. Submit with CardanoCLI
        return try await cli.submitTransaction(signedTxFile: FilePath("signed-tx.json"))
    }
}
```

## Security Best Practices

### Key Management

1. **Secure Storage** - Store signing keys encrypted at rest
2. **Memory Protection** - Clear sensitive data from memory
3. **Access Control** - Limit key access to authorized operations
4. **Audit Logging** - Log all signing operations for security audits

### Offline Security

```swift
class SecureOfflineSigner {
    private let signer: CardanoSigner
    private let keyStore: SecureKeyStore
    
    init() async throws {
        // Air-gapped configuration
        let config = createOfflineConfiguration()
        self.signer = try await CardanoSigner(configuration: config)
        self.keyStore = SecureKeyStore()
    }
    
    func secureSign(
        data: String,
        keyId: String,
        purpose: SigningPurpose
    ) async throws -> String {
        // 1. Retrieve key securely
        let signingKey = try keyStore.getKey(id: keyId, purpose: purpose)
        defer { signingKey.zeroize() } // Clear from memory
        
        // 2. Validate signing context
        guard purpose.isValid(for: data) else {
            throw SigningError.invalidContext
        }
        
        // 3. Sign with appropriate method
        let signature: String
        switch purpose {
        case .transaction:
            signature = try await signer.sign(
                dataHex: data,
                secretKey: signingKey.value,
                outputFormat: .hex
            )
        case .cip8Message:
            signature = try await signer.signCIP8(
                dataHex: data,
                secretKey: signingKey.value,
                address: keyStore.getAddress(for: keyId),
                outputFormat: .json
            )
        case .catalystVoting:
            signature = try await signer.signCIP36(
                votePublicKeys: keyStore.getVotingKeys(),
                secretKey: signingKey.value,
                paymentAddress: keyStore.getAddress(for: keyId),
                nonce: generateSecureNonce(),
                outputFormat: .json
            )
        }
        
        // 4. Audit log
        auditLog.record(SigningEvent(
            keyId: keyId,
            purpose: purpose,
            timestamp: Date()
        ))
        
        return signature
    }
}

enum SigningPurpose {
    case transaction
    case cip8Message
    case catalystVoting
    
    func isValid(for data: String) -> Bool {
        // Validate data format for purpose
        switch self {
        case .transaction:
            return data.isValidTransactionHash
        case .cip8Message:
            return data.isValidMessageData
        case .catalystVoting:
            return data.isValidVotingData
        }
    }
}
```

### Production Considerations

1. **Environment Separation** - Use different keys for mainnet vs testnet
2. **Rate Limiting** - Implement signing operation rate limits
3. **Monitoring** - Monitor for unusual signing patterns
4. **Recovery** - Maintain secure backup and recovery procedures
5. **Compliance** - Follow applicable security standards and regulations

## Error Handling

```swift
do {
    let signature = try await signer.signCIP8(
        dataText: "Hello, Cardano!",
        secretKey: signingKey,
        address: userAddress,
        outputFormat: .json
    )
} catch CardanoCLIToolsError.binaryNotFound(let path) {
    print("cardano-signer not found at: \(path)")
    // Installation guidance
} catch CardanoCLIToolsError.commandFailed(let command, let message) {
    print("Signing failed: \(message)")
    if message.contains("invalid key") {
        print("Check signing key format")
    } else if message.contains("address mismatch") {
        print("Address doesn't match signing key")
    }
} catch CardanoCLIToolsError.invalidOutput(let message) {
    print("Invalid signing parameters: \(message)")
} catch {
    print("Unexpected signing error: \(error)")
}
```

## Advanced Use Cases

### DApp Backend Integration

```swift
class DAppAuthenticationService {
    private let signer: CardanoSigner
    
    func authenticateUser(
        message: String,
        signature: String,
        publicKey: String,
        address: String
    ) async throws -> Bool {
        // Verify CIP-8 signature for DApp authentication
        return try await signer.verifyCIP8(
            coseSign1: signature,
            coseKey: publicKey,
            dataText: message,
            address: address,
            outputFormat: .json
        )
    }
    
    func validateGovernanceProposal(
        metadataJson: String
    ) async throws -> String {
        // Hash governance metadata per CIP-100
        return try await signer.hashCIP100(
            dataText: metadataJson,
            outputFormat: .hex
        )
    }
}
```

### Wallet Backend Services

```swift
class WalletSigningService {
    func prepareTransactionSignature(
        txBodyHex: String,
        userSigningKey: String
    ) async throws -> TransactionSignature {
        let signature = try await signer.sign(
            dataHex: txBodyHex,
            secretKey: userSigningKey,
            outputFormat: .hex
        )
        
        return TransactionSignature(
            signature: signature,
            algorithm: "Ed25519",
            format: "hex"
        )
    }
}
```

CardanoSigner provides the cryptographic foundation for secure Cardano applications. For basic blockchain operations, see <doc:CardanoCLI>. For hardware wallet integration, see <doc:CardanoHWCLI>.