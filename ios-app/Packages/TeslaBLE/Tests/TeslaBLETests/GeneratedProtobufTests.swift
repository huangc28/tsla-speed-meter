import Foundation
import Testing
@testable import TeslaBLE

// Port of test/ble/routable_message_test.dart (feature/goal-2-ble): the generated
// bindings round-trip the BLE transport envelope (RoutableMessage).
@Suite("RoutableMessage (generated protobuf)")
struct GeneratedProtobufTests {
    @Test("round-trips a session-info-request envelope")
    func roundTripsSessionInfoRequestEnvelope() throws {
        var sent = UniversalMessage_RoutableMessage()
        sent.toDestination.domain = .vehicleSecurity
        sent.fromDestination.routingAddress = Data([1, 2, 3, 4])
        sent.sessionInfoRequest.publicKey = Data([4, 9, 9, 9])
        sent.sessionInfoRequest.challenge = Data([7, 7])
        sent.uuid = Data([0xAB, 0xCD])

        let wire = try sent.serializedData()
        let got = try UniversalMessage_RoutableMessage(serializedBytes: wire)

        guard case .sessionInfoRequest(let request)? = got.payload else {
            Issue.record("payload is not sessionInfoRequest: \(String(describing: got.payload))")
            return
        }
        #expect(got.toDestination.domain == .vehicleSecurity)
        guard case .routingAddress(let address)? = got.fromDestination.subDestination else {
            Issue.record("fromDestination is not a routing address")
            return
        }
        #expect(address == Data([1, 2, 3, 4]))
        #expect(request.publicKey == Data([4, 9, 9, 9]))
        #expect(request.challenge == Data([7, 7]))
        #expect(got.uuid == Data([0xAB, 0xCD]))
    }
}
