import BigInt
import Foundation

/// JSON as cardano-cli prints it, with every number held as the exact `Decimal`
/// its text spells, decoded with `JSONDecoder` rather than `JSONSerialization`.
///
/// A `Decimal` holds 38 significant digits: every ledger amount and token
/// quantity fits, but not a Plutus datum's unbounded integers, so datums are
/// read from their CBOR, never through this type.
indirect enum CLIJSON: Codable, Sendable, Hashable {
    case object([String: CLIJSON])
    case array([CLIJSON])
    case string(String)
    case number(Decimal)
    case bool(Bool)
    case null

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Decimal.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([CLIJSON].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: CLIJSON].self) {
            self = .object(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Not a JSON value")
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .object(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }

    subscript(key: String) -> CLIJSON? {
        if case .object(let members) = self { return members[key] }
        return nil
    }

    var object: [String: CLIJSON]? {
        if case .object(let members) = self { return members }
        return nil
    }

    var string: String? {
        if case .string(let text) = self { return text }
        return nil
    }

    var isNull: Bool {
        if case .null = self { return true }
        return false
    }

    /// A whole number exactly, at any size the JSON holds; `nil` for anything else.
    var integer: BigInt? {
        guard case .number(var value) = self, value.isFinite, !value.isNaN else { return nil }
        var whole = Decimal()
        NSDecimalRound(&whole, &value, 0, .plain)
        guard whole == value else { return nil }
        return BigInt(whole.description)
    }
}
