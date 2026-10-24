import Foundation
import TeslaBLE

extension Data {
    /// Decodes a hex string; traps on malformed input (test fixtures only).
    public init(hex: String) {
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

    public var hex: String { map { String(format: "%02x", $0) }.joined() }
}

/// Field numbers of the top-level fields in serialized protobuf bytes, in
/// wire order (varint and length-delimited fields only; enough for the
/// GetVehicleData sub-messages). Nil when the bytes do not walk cleanly.
public func topLevelFieldNumbers(_ bytes: Data) -> [Int]? {
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

/// Values from teslamotors/vehicle-command pkg/protocol/protocol.md worked
/// examples (also the Dart port's vectors).
public enum ProtocolDoc {
    public static let vin = "5YJ30123456789ABC"
    public static let clientPrivateKey = Data(hex: "2538cdc29a97c19c1e99a637d6cf4f8c970c118b56ede1e6323e6d162c4b30db")
    public static let clientPublicKey = Data(hex:
        "04b2b6bc68c2da0665ce656815594996c62394edd8bea905fe781a754fe6a845"
        + "a714330902f225e9269d466e05b349981fda9d85cc23c6fb444aa73b629105dc6e")
    public static let vehiclePublicKey = Data(hex:
        "04c7a1f47138486aa4729971494878d33b1a24e39571f748a6e16c5955b3d877"
        + "d3a6aaa0e955166474af5d32c410f439a2234137ad1bb085fd4e8813c958f11d97")
    public static let sessionKey = Data(hex: "1b2fce19967b79db696f909cff89ea9a")
    public static let epoch = Data(hex: "4c463f9cc0d3d26906e982ed224adde6")

    /// "Response" example: session info reply to request uuid 1588d5a3...
    public static let sessionInfoRequestUUID = Data(hex: "1588d5a30eabc6f8fc9a951b11f6fd11")
    public static let sessionInfoRoutingAddress = Data(hex: "2c907bd76c640d360b3027dc7404efde")
    public static let encodedSessionInfo = Data(hex:
        "0806124104c7a1f47138486aa4729971494878d33b1a24e39571f748a6e16c5955b3d877"
        + "d3a6aaa0e955166474af5d32c410f439a2234137ad1bb085fd4e8813c958f11d97"
        + "1a104c463f9cc0d3d26906e982ed224adde6255a0a0000")
    public static let sessionInfoTag = Data(hex: "996c1fe38331be138f8039c194b14db2198846ed7d8251e6749284d7b32ea002")

    public static func clientKey() throws -> SoftwareKeyAgreementKey {
        try SoftwareKeyAgreementKey(rawRepresentation: clientPrivateKey)
    }

    public static func sessionInfoResponse() -> UniversalMessage_RoutableMessage {
        var response = UniversalMessage_RoutableMessage()
        response.toDestination.routingAddress = sessionInfoRoutingAddress
        response.fromDestination.domain = .infotainment
        response.signatureData.sessionInfoTag.tag = sessionInfoTag
        response.sessionInfo = encodedSessionInfo
        response.requestUuid = sessionInfoRequestUUID
        return response
    }
}

/// A request/response pair produced by teslamotors/vehicle-command's own
/// Signer and Verifier (internal/authentication, commit fc5a191): the client
/// key is the protocol.md client key, the vehicle scalar is the one from
/// TestGCMKnown. The request asks for drive, charge and tire-pressure state
/// in one GetVehicleData (the client now asks for one category per request)
/// with FLAG_ENCRYPT_RESPONSE; the vehicle's reply was sealed by
/// `Verifier.Encrypt(response, RequestID(request), 1)` and checked with
/// `Signer.Decrypt` before being captured. A second reply to the same request
/// carries flags = 2 and signed_message_fault = BUSY (counter 2). All values
/// come from one run of Tools/zz_emit_vector_test.go, except `emptyFaultResponse`,
/// which `TestZZEmitEmptyFaultVector` sealed later against the same request hash.
public enum UpstreamResponseVector {
    public static let vehiclePublicKey = Data(hex:
        "041431dc57c892b8dcc87ba59159031e12046b6febcdfb88f7b9c9e2a0fc2b7a1e323a4bd5a5696f103845bd1c4b9dd104d0fe87a3721314a03a75504064"
        + "45705b")
    public static let sessionInfo = Data(hex:
        "1241041431dc57c892b8dcc87ba59159031e12046b6febcdfb88f7b9c9e2a0fc2b7a1e323a4bd5a5696f103845bd1c4b9dd104d0fe87a3721314a03a7550"
        + "406445705b1a10fd913356a5f5ffaa5b43942191b56afc")
    public static let request = Data(hex:
        "320208033a121210a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a19a0310b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2a00302520a5e8d1ac6783033869b846a80010a"
        + "430a4104b2b6bc68c2da0665ce656815594996c62394edd8bea905fe781a754fe6a845a714330902f225e9269d466e05b349981fda9d85cc23c6fb444aa7"
        + "3b629105dc6e2a390a10fd913356a5f5ffaa5b43942191b56afc120cfb76afe5272f582bd90d3b4f1801253c0000002a1007406afa108eaeaebd57a37419"
        + "f6b2d9")
    public static let requestID = Data(hex:
        "0507406afa108eaeaebd57a37419f6b2d9")
    public static let response = Data(hex:
        "32121210a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a13a020803920310b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2526ecf4e039e198c88e033e90fbaffc87ea30b"
        + "d95c916cfd4df52915ba5e1db2ea34de4885a311babc69d356cbb8654753bbd0e93ed237241fca29434394308ddd8f9d56db734bf6590bfaadf35c5d4c95"
        + "a2717af0ccfca51f77389b1793e5a5b3d2c4da36491a08409abd962b0f2e936a244a220a0c36e8ef13e78673dd317107ae10011a1054a40625578232c063"
        + "ae3920118d1758")
    public static let responsePlaintext = Data(hex:
        "126c1a250a021200e202060880f2d6ca06fd06008053438507004034438d0700006643900748d007002a210a022a0022060880f2d6ca06b0063cb806f4ff"
        + "ffffffffffffff01d506000072429a011f0a060880f2d6ca06320608a8edd6ca06159a9939401d000038402500004040")

    /// Second reply to the same request: flags = 2 and fault BUSY, counter 2.
    public static let faultResponse = Data(hex:
        "32121210a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a13a02080362021001920310b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2a00302520cc5cd08b0e29a4d375ea9"
        + "3dbd6a244a220a0c25c66e5d6dc9eeeadf87e43a10021a10b5a4f558229f4fb003fbe256227940e5")
    public static let faultResponsePlaintext = Data(hex: "0a0a080112060a0462757379")

    /// Third reply to the same request, shaped like the real car's replies:
    /// operation status ERROR, fault RESPONSE_MTU_EXCEEDED, no flags, its own
    /// uuid, AES-GCM response data and no payload field (counter 3).
    public static let emptyFaultResponse = Data(hex:
        "32121210a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a13a020803620408021019920310b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b29a0310c3c3c3c3c3c3c3c3c3c3c3"
        + "c3c3c3c3c36a244a220a0cc89b58b064fd27e16b9d83b010031a105b4a50ab0c84a81a0103f45add1783a4")
}
