import CryptoKit
import Foundation
@testable import TeslaBLE

extension Data {
    /// Decodes a hex string; traps on malformed input (test fixtures only).
    init(hex: String) {
        precondition(hex.count.isMultiple(of: 2), "odd-length hex")
        var bytes: [UInt8] = []
        var index = hex.startIndex
        while index < hex.endIndex {
            let next = hex.index(index, offsetBy: 2)
            bytes.append(UInt8(hex[index..<next], radix: 16)!)
            index = next
        }
        self.init(bytes)
    }

    var hex: String { map { String(format: "%02x", $0) }.joined() }
}

/// Field numbers of the top-level fields in serialized protobuf bytes, in
/// wire order (varint and length-delimited fields only; enough for the
/// GetVehicleData sub-messages). Nil when the bytes do not walk cleanly.
func topLevelFieldNumbers(_ bytes: Data) -> [Int]? {
    let bytes = [UInt8](bytes)
    var index = 0
    func varint() -> UInt64? {
        var value: UInt64 = 0
        var shift: UInt64 = 0
        while index < bytes.count, shift < 64 {
            let byte = bytes[index]
            index += 1
            value |= UInt64(byte & 0x7f) << shift
            if byte & 0x80 == 0 { return value }
            shift += 7
        }
        return nil
    }
    var fields: [Int] = []
    while index < bytes.count {
        guard let key = varint() else { return nil }
        switch key & 0x7 {
        case 0:
            guard varint() != nil else { return nil }
        case 2:
            guard let length = varint(), index + Int(length) <= bytes.count else { return nil }
            index += Int(length)
        default:
            return nil
        }
        fields.append(Int(key >> 3))
    }
    return fields
}

extension SymmetricKey {
    var data: Data { withUnsafeBytes { Data($0) } }
}

/// Values from teslamotors/vehicle-command pkg/protocol/protocol.md worked
/// examples (also the Dart port's vectors).
enum ProtocolDoc {
    static let vin = "5YJ30123456789ABC"
    static let clientPrivateKey = Data(hex: "2538cdc29a97c19c1e99a637d6cf4f8c970c118b56ede1e6323e6d162c4b30db")
    static let clientPublicKey = Data(hex:
        "04b2b6bc68c2da0665ce656815594996c62394edd8bea905fe781a754fe6a845"
        + "a714330902f225e9269d466e05b349981fda9d85cc23c6fb444aa73b629105dc6e")
    static let vehiclePublicKey = Data(hex:
        "04c7a1f47138486aa4729971494878d33b1a24e39571f748a6e16c5955b3d877"
        + "d3a6aaa0e955166474af5d32c410f439a2234137ad1bb085fd4e8813c958f11d97")
    static let sessionKey = Data(hex: "1b2fce19967b79db696f909cff89ea9a")
    static let epoch = Data(hex: "4c463f9cc0d3d26906e982ed224adde6")

    /// "Response" example: session info reply to request uuid 1588d5a3...
    static let sessionInfoRequestUUID = Data(hex: "1588d5a30eabc6f8fc9a951b11f6fd11")
    static let sessionInfoRoutingAddress = Data(hex: "2c907bd76c640d360b3027dc7404efde")
    static let encodedSessionInfo = Data(hex:
        "0806124104c7a1f47138486aa4729971494878d33b1a24e39571f748a6e16c5955b3d877"
        + "d3a6aaa0e955166474af5d32c410f439a2234137ad1bb085fd4e8813c958f11d97"
        + "1a104c463f9cc0d3d26906e982ed224adde6255a0a0000")
    static let sessionInfoTag = Data(hex: "996c1fe38331be138f8039c194b14db2198846ed7d8251e6749284d7b32ea002")

    static func clientKey() throws -> SoftwareKeyAgreementKey {
        try SoftwareKeyAgreementKey(rawRepresentation: clientPrivateKey)
    }

    static func sessionInfoResponse() -> UniversalMessage_RoutableMessage {
        var response = UniversalMessage_RoutableMessage()
        response.toDestination.routingAddress = sessionInfoRoutingAddress
        response.fromDestination.domain = .infotainment
        response.signatureData.sessionInfoTag.tag = sessionInfoTag
        response.sessionInfo = encodedSessionInfo
        response.requestUuid = sessionInfoRequestUUID
        return response
    }
}

