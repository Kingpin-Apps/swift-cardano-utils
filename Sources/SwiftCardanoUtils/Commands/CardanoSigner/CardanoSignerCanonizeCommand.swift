import Foundation
import SystemPackage

extension CardanoSigner {
    
    /// Implementation of canonize utility commands
    public struct CanonizeCommandImpl: CommandProtocol {
        var baseCLI: any BinaryInterfaceable
        
        var baseCommand: [String] {
            ["canonize"]
        }
        
        init(baseCLI: any BinaryInterfaceable) {
            self.baseCLI = baseCLI
        }
        
        /// Canonize and hash governance JSON-LD body metadata for author-signatures (CIP-100)
        /// - Parameters:
        ///   - data: Input data for canonization (mutually exclusive with dataFile)
        ///   - dataFile: Path to file containing JSON-LD data (mutually exclusive with data)
        ///   - disableSafeMode: Disable the safe-mode for JSON-LD canonization
        ///   - outputFormat: Output format (hex, json, json-extended)
        ///   - outCanonized: Path to output file for canonized data
        ///   - outFile: Path to general output file
        /// - Returns: Hash of canonized body (NOT the anchor-url-hash)
        /// - Throws: SwiftCardanoUtilsError if validation fails or command execution fails
        public func callAsFunction(
            data: String? = nil,
            dataFile: FilePath? = nil,
            disableSafeMode: Bool = false,
            outputFormat: SignOutputFormat = .hex,
            outCanonized: FilePath? = nil,
            outFile: FilePath? = nil
        ) async throws -> String {
            // Validate that exactly one data input is provided
            let hasData = data != nil
            let hasDataFile = dataFile != nil
            
            guard hasData != hasDataFile else {
                throw SwiftCardanoUtilsError.invalidParameters("Either data OR dataFile must be specified, but not both")
            }
            
            var args = ["--cip100"]
            
            // Add data parameter
            if let text = data {
                args.append(contentsOf: ["--data", text])
            } else if let file = dataFile {
                args.append(contentsOf: ["--data-file", file.string])
            }
            
            // Add disable safe mode flag
            if disableSafeMode {
                args.append("--disable-safemode")
            }
            
            // Add output format
            switch outputFormat {
                case .json:
                    args.append("--json")
                case .jsonExtended:
                    args.append("--json-extended")
                case .hex, .jcli, .bech:
                    break // Default format
            }
            
            // Add output files if specified
            if let canonized = outCanonized {
                args.append(contentsOf: ["--out-canonized", canonized.string])
            }
            
            if let file = outFile {
                args.append(contentsOf: ["--out-file", file.string])
            }
            
            return try await executeCommand("canonize", arguments: args)
        }
    }
}
