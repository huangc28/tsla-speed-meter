import Foundation
import Testing
@testable import TeslaBLE

private let fast = TeslaVehicleClient.Configuration(
    connectTimeout: .milliseconds(300),
    handshakeTimeout: .milliseconds(300),
    requestTimeout: .milliseconds(300),
    enrollmentTimeout: .milliseconds(600),
    enrollmentPollInterval: .milliseconds(20)
)

private func makeClient(
    vehicle: FakeVehicle = FakeVehicle(),
    store: InMemoryKeyStore = InMemoryKeyStore(),
    configuration: TeslaVehicleClient.Configuration = fast
) -> (TeslaVehicleClient, MockLink, InMemoryKeyStore) {
    let link = MockLink(vehicle: vehicle)
    return (TeslaVehicleClient(link: link, keyStore: store, configuration: configuration), link, store)
}

private func connectedClient(
    vehicle: FakeVehicle = FakeVehicle(),
    store: InMemoryKeyStore = InMemoryKeyStore(),
    configuration: TeslaVehicleClient.Configuration = fast
) async throws -> (TeslaVehicleClient, MockLink, InMemoryKeyStore) {
    let (client, link, store) = makeClient(vehicle: vehicle, store: store, configuration: configuration)
    try await client.connect(vin: ProtocolDoc.vin)
    return (client, link, store)
}

@Suite("TeslaVehicleClient: connect, sessions, data")
struct ClientSessionTests {
    @Test("requests before connect fail with notConnected")
    func notConnected() async throws {
        let (client, _, _) = makeClient()
        await #expect(throws: TeslaClientError.notConnected) { try await client.fetchVehicleData() }
        await #expect(throws: TeslaClientError.notConnected) { try await client.startSessions() }
    }

    @Test("a failed scan surfaces the link error and a connectFailed event")
    func connectFails() async throws {
        let (client, link, _) = makeClient()
        await link.set(connectError: .scanTimedOut)
        await #expect(throws: TeslaClientError.link(.scanTimedOut)) { try await client.connect(vin: ProtocolDoc.vin) }
        let events = await client.drainEvents()
        #expect(events.contains(.connecting(localName: TeslaBLEConstants.localName(forVIN: ProtocolDoc.vin))))
        #expect(events.contains { if case .connectFailed(.link(.scanTimedOut), _) = $0 { true } else { false } })
    }

    @Test("handshakes both domains, then reads vehicle data over 20-byte writes and 7-byte notifications")
    func readsVehicleData() async throws {
        let (client, link, store) = try await connectedClient()
        try await client.startSessions()
        #expect(await client.hasSession(.vehicleSecurity))
        #expect(await client.hasSession(.infotainment))

        let reading = try await client.fetchVehicleData()
        #expect(reading.gear == .drive)
        #expect(reading.speedFloat == 60.5)

        let writes = await link.writes
        #expect(writes.count > 3)
        #expect(writes.allSatisfy { $0.count <= 20 })
        #expect(try store.pairedVIN() == ProtocolDoc.vin)

        let events = await client.drainEvents()
        #expect(events.contains { if case .connected(_, 20, _) = $0 { true } else { false } })
        #expect(events.contains { if case .handshakeSucceeded(.vehicleSecurity, _) = $0 { true } else { false } })
        #expect(events.contains { if case .handshakeSucceeded(.infotainment, _) = $0 { true } else { false } })
        #expect(events.contains { if case .requestSent(.infotainment, .getVehicleData, _) = $0 { true } else { false } })
        #expect(events.contains {
            if case .responseReceived(.infotainment, .getVehicleData, let bytes, let ms) = $0 { bytes > 0 && ms >= 0 } else { false }
        })
    }

    @Test("fetchVehicleData handshakes infotainment on its own when there is no session")
    func lazyHandshake() async throws {
        let (client, link, _) = try await connectedClient()
        _ = try await client.fetchVehicleData()
        let vehicle = await link.vehicle
        #expect(vehicle.sessionInfoRequests == [.infotainment: 1])
    }

    @Test("pins each domain's vehicle key and rejects a different one for the same VIN")
    func pinsVehicleKey() async throws {
        let store = InMemoryKeyStore()
        let (first, _, _) = try await connectedClient(store: store)
        try await first.startSessions()
        #expect(try store.vehiclePublicKey(vin: ProtocolDoc.vin, domain: .vehicleSecurity) != nil)
        #expect(try store.vehiclePublicKey(vin: ProtocolDoc.vin, domain: .infotainment) != nil)

        let (impostor, _, _) = try await connectedClient(vehicle: FakeVehicle(), store: store)
        await #expect(throws: TeslaClientError.vehiclePublicKeyMismatch(.vehicleSecurity)) {
            try await impostor.startSessions()
        }
        #expect(!(await impostor.hasSession(.vehicleSecurity)))
    }

    @Test("an unknown key is keyNotPaired")
    func keyNotPaired() async throws {
        var vehicle = FakeVehicle()
        vehicle.keyOnWhitelist = false
        let (client, _, store) = try await connectedClient(vehicle: vehicle)
        await #expect(throws: TeslaClientError.keyNotPaired) { try await client.startSessions() }
        #expect(try store.pairedVIN() == nil)
    }

    @Test("raw frames are emitted only when capture is on")
    func rawFrames() async throws {
        var capturing = fast
        capturing.captureRawFrames = true
        let (client, _, _) = try await connectedClient(configuration: capturing)
        _ = try await client.fetchVehicleData()
        let events = await client.drainEvents()
        #expect(events.filter { if case .frameSent = $0 { true } else { false } }.count == 2)
        #expect(events.filter { if case .frameReceived = $0 { true } else { false } }.count == 2)

        let (quiet, _, _) = try await connectedClient()
        _ = try await quiet.fetchVehicleData()
        let quietEvents = await quiet.drainEvents()
        #expect(!quietEvents.contains { if case .frameSent = $0 { true } else if case .frameReceived = $0 { true } else { false } })
    }
}

@Suite("TeslaVehicleClient: routing and timeouts")
struct ClientRoutingTests {
    @Test("concurrent requests get their own replies when the vehicle answers out of order")
    func outOfOrderReplies() async throws {
        let (client, link, _) = try await connectedClient()
        try await client.startSessions([.infotainment])
        await link.set(holdReplies: true)
        async let first = client.fetchVehicleData()
        async let second = client.fetchVehicleData()
        try await eventually { await link.held.count == 2 }
        await link.releaseHeld(reversed: true)
        let readings = try await [first, second]
        #expect(readings.allSatisfy { $0.gear == .drive })
    }

    @Test("a reply to an unknown routing address is dropped and logged")
    func strayReply() async throws {
        let (client, link, _) = try await connectedClient()
        var stray = UniversalMessage_RoutableMessage()
        stray.toDestination.routingAddress = .random(count: 16)
        stray.fromDestination.domain = .infotainment
        await link.deliver(try stray.serializedData())
        _ = try await client.fetchVehicleData()
        let events = await client.drainEvents()
        #expect(events.contains(.messageDropped(reason: "no pending request for routing address")))
    }

    @Test("an infotainment reply with the wrong request uuid is dropped, so the request times out")
    func requestUUIDMismatch() async throws {
        let (client, link, _) = try await connectedClient()
        try await client.startSessions([.infotainment])
        await link.update { $0.corruptRequestUUID = true }
        await #expect(throws: TeslaClientError.timeout(.getVehicleData)) { try await client.fetchVehicleData() }
        let events = await client.drainEvents()
        #expect(events.contains(.messageDropped(reason: "request uuid mismatch")))
        #expect(events.contains { if case .timeout(.infotainment, .getVehicleData, let ms) = $0 { ms >= 250 } else { false } })
    }

    @Test("a silent domain times out the handshake instead of hanging")
    func handshakeTimeout() async throws {
        var vehicle = FakeVehicle()
        vehicle.silentDomains = [.infotainment]
        let (client, _, _) = try await connectedClient(vehicle: vehicle)
        let start = ContinuousClock.now
        await #expect(throws: TeslaClientError.timeout(.sessionInfo)) { try await client.startSessions([.infotainment]) }
        #expect(ContinuousClock.now - start < .seconds(2))
        let events = await client.drainEvents()
        #expect(events.contains { if case .timeout(.infotainment, .sessionInfo, _) = $0 { true } else { false } })
        #expect(events.contains { if case .handshakeFailed(.infotainment, .timeout(.sessionInfo), _) = $0 { true } else { false } })
    }

    @Test("a write failure fails the request at once")
    func writeFailure() async throws {
        let (client, link, _) = try await connectedClient()
        await link.set(writeError: .writeFailed("gatt"))
        let start = ContinuousClock.now
        await #expect(throws: TeslaClientError.link(.writeFailed("gatt"))) { try await client.fetchVehicleData() }
        #expect(ContinuousClock.now - start < .milliseconds(250))
    }

    @Test("an oversized length prefix is discarded and logged")
    func oversizedFrame() async throws {
        let (client, link, _) = try await connectedClient()
        await link.inject(Data([0xff, 0xff, 0x00]))
        _ = try await client.fetchVehicleData()
        let events = await client.drainEvents()
        #expect(events.contains { if case .messageDropped(let reason) = $0 { reason.hasPrefix("frame discarded") } else { false } })
    }
}

@Suite("TeslaVehicleClient: faults and resync")
struct ClientFaultTests {
    @Test("INCORRECT_EPOCH with session info attached: resync from the fault, retry once, no new handshake")
    func resyncFromFault() async throws {
        let (client, link, _) = try await connectedClient()
        try await client.startSessions([.infotainment])
        await link.update { $0.rotateEpoch(.infotainment) }

        let reading = try await client.fetchVehicleData()
        #expect(reading.gear == .drive)
        let vehicle = await link.vehicle
        #expect(vehicle.signedRequests == 2)
        #expect(vehicle.sessionInfoRequests[.infotainment] == 1)
        let events = await client.drainEvents()
        #expect(events.contains(.fault(.infotainment, .rrorIncorrectEpoch)))
        #expect(events.contains(.sessionResynced(.infotainment)))
    }

    @Test("a retriable fault without session info re-handshakes, then retries")
    func rehandshake() async throws {
        let (client, link, _) = try await connectedClient()
        try await client.startSessions([.infotainment])
        await link.update { $0.scriptedFaults = [(.rrorBusy, false)] }
        _ = try await client.fetchVehicleData()
        let vehicle = await link.vehicle
        #expect(vehicle.signedRequests == 2)
        #expect(vehicle.sessionInfoRequests[.infotainment] == 2)
    }

    @Test("a second retriable fault in a row is surfaced")
    func retriesOnlyOnce() async throws {
        let (client, link, _) = try await connectedClient()
        try await client.startSessions([.infotainment])
        await link.update { $0.scriptedFaults = [(.rrorBusy, true), (.rrorBusy, true)] }
        await #expect(throws: TeslaClientError.vehicleFault(.rrorBusy)) { try await client.fetchVehicleData() }
        #expect(await link.vehicle.signedRequests == 2)
    }

    @Test("a non-retriable fault is surfaced without a retry")
    func nonRetriable() async throws {
        let (client, link, _) = try await connectedClient()
        try await client.startSessions([.infotainment])
        await link.update { $0.scriptedFaults = [(.rrorInsufficientPrivileges, false)] }
        await #expect(throws: TeslaClientError.vehicleFault(.rrorInsufficientPrivileges)) {
            try await client.fetchVehicleData()
        }
        #expect(await link.vehicle.signedRequests == 1)
    }

    @Test("UNKNOWN_KEY_ID on a signed request is keyNotPaired")
    func unknownKey() async throws {
        let (client, link, _) = try await connectedClient()
        try await client.startSessions([.infotainment])
        await link.update { $0.keyOnWhitelist = false }
        await #expect(throws: TeslaClientError.keyNotPaired) { try await client.fetchVehicleData() }
        #expect(!(await client.hasSession(.infotainment)))
    }
}

@Suite("TeslaVehicleClient: disconnect and reconnect")
struct ClientReconnectTests {
    @Test("a dropped link fails the pending request; after the reconnect the next request re-handshakes")
    func autoReconnect() async throws {
        let (client, link, _) = try await connectedClient()
        try await client.startSessions([.infotainment])
        await link.set(holdReplies: true)
        let pending = Task { try await client.fetchVehicleData() }
        try await eventually { await link.held.count == 1 }
        await link.drop(reconnecting: true)
        await #expect(throws: TeslaClientError.disconnected) { try await pending.value }
        #expect(!(await client.hasSession(.infotainment)))
        await #expect(throws: TeslaClientError.notConnected) { try await client.fetchVehicleData() }

        await link.set(holdReplies: false)
        await link.reconnect()
        try await eventually { await client.isConnected }
        _ = try await client.fetchVehicleData()
        #expect(await link.vehicle.sessionInfoRequests[.infotainment] == 2)
        let events = await client.drainEvents()
        #expect(events.contains(.disconnected(reconnecting: true, reason: "test")))
        #expect(events.contains(.reconnected(maxWriteLength: 20)))
    }

    @Test("disconnect, then connect again")
    func manualReconnect() async throws {
        let (client, link, _) = try await connectedClient()
        _ = try await client.fetchVehicleData()
        await client.disconnect()
        #expect(await link.disconnectCalls == 1)
        await #expect(throws: TeslaClientError.notConnected) { try await client.fetchVehicleData() }
        try await client.connect(vin: ProtocolDoc.vin)
        _ = try await client.fetchVehicleData()
        #expect(await link.vehicle.sessionInfoRequests[.infotainment] == 2)
    }
}

@Suite("TeslaVehicleClient: key enrollment")
struct ClientEnrollmentTests {
    private final class States: @unchecked Sendable {
        private let lock = NSLock()
        private var values: [EnrollmentState] = []
        func append(_ state: EnrollmentState) { lock.withLock { values.append(state) } }
        var all: [EnrollmentState] { lock.withLock { values } }
    }

    private static func waitingReply(_ status: VCSEC_OperationStatus_E, _ info: VCSEC_WhitelistOperation_information_E) -> VCSEC_FromVCSECMessage {
        var reply = VCSEC_FromVCSECMessage()
        reply.commandStatus.operationStatus = status
        reply.commandStatus.whitelistOperationStatus.operationStatus = status
        reply.commandStatus.whitelistOperationStatus.whitelistOperationInformation = info
        return reply
    }

    @Test("an enrolled key returns at once without an add-key request")
    func alreadyEnrolled() async throws {
        let (client, link, store) = try await connectedClient()
        let states = States()
        try await client.enrollKey { states.append($0) }
        #expect(states.all == [.checking, .enrolled])
        #expect(await link.vehicle.addKeyRequests.isEmpty)
        #expect(try store.pairedVIN() == ProtocolDoc.vin)
    }

    @Test("sends the add-key request, waits for the card tap, then confirms over VCSEC")
    func enrollsAfterTap() async throws {
        var vehicle = FakeVehicle()
        vehicle.keyOnWhitelist = false
        vehicle.whitelistReply = Self.waitingReply(.operationstatusWait, .whitelistoperationInformationNone)
        let (client, link, store) = try await connectedClient(vehicle: vehicle)
        let states = States()

        async let enrollment: Void = client.enrollKey { states.append($0) }
        try await eventually { await !link.vehicle.addKeyRequests.isEmpty }
        await link.update { $0.keyOnWhitelist = true }
        try await enrollment

        #expect(states.all == [.checking, .awaitingKeyCardTap, .enrolled])
        #expect(await link.vehicle.addKeyRequests == [try store.clientKey().publicKeyX963])
        #expect(try store.pairedVIN() == ProtocolDoc.vin)
        #expect(await client.hasSession(.vehicleSecurity))
        let events = await client.drainEvents()
        #expect(events.contains(.whitelistStatus(.operationstatusWait, information: .whitelistoperationInformationNone)))
        #expect(events.contains { if case .requestSent(.vehicleSecurity, .addKeyToWhitelist, _) = $0 { true } else { false } })
    }

    @Test("no tap before the deadline is enrollmentTimedOut")
    func timesOut() async throws {
        var vehicle = FakeVehicle()
        vehicle.keyOnWhitelist = false
        let (client, _, store) = try await connectedClient(vehicle: vehicle)
        let states = States()
        let start = ContinuousClock.now
        await #expect(throws: TeslaClientError.enrollmentTimedOut) { try await client.enrollKey { states.append($0) } }
        #expect(ContinuousClock.now - start < .seconds(3))
        #expect(states.all == [.checking, .awaitingKeyCardTap, .timedOut])
        #expect(try store.pairedVIN() == nil)
    }

    @Test("a VCSEC whitelist error is enrollmentRejected")
    func rejected() async throws {
        var vehicle = FakeVehicle()
        vehicle.keyOnWhitelist = false
        vehicle.whitelistReply = Self.waitingReply(.rror, .whitelistoperationInformationWhitelistFull)
        let (client, _, _) = try await connectedClient(vehicle: vehicle)
        let states = States()
        await #expect(throws: TeslaClientError.enrollmentRejected("whitelistoperationInformationWhitelistFull")) {
            try await client.enrollKey { states.append($0) }
        }
        #expect(states.all.last == .rejected("whitelistoperationInformationWhitelistFull"))
    }
}
