import Foundation
import Testing
@testable import TeslaBLE

private let fast = TeslaVehicleClient.Configuration(
    connectTimeout: .milliseconds(300),
    handshakeTimeout: .milliseconds(300),
    requestTimeout: .milliseconds(300),
    enrollmentTimeout: .milliseconds(800),
    enrollmentPollInterval: .milliseconds(20),
    busyRetryDelay: .milliseconds(20)
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

    @Test("fetchVehicleDataResponse reports encryption, round trip and retry")
    func responseDetails() async throws {
        let (client, link, _) = try await connectedClient()
        let first = try await client.fetchVehicleDataResponse()
        #expect(first.isEncrypted)
        #expect(first.roundTripMs >= 0)
        #expect(!first.retried)
        #expect(first.reading.gear == .drive)
        await link.update { $0.rotateEpoch(.infotainment) }
        #expect(try await client.fetchVehicleDataResponse().retried)
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

    @Test("BUSY waits and resends on the same session, without a handshake")
    func busyRetriesSameSession() async throws {
        let (client, link, _) = try await connectedClient()
        try await client.startSessions([.infotainment])
        await link.update { $0.scriptedFaults = [.init(fault: .rrorBusy)] }
        let start = ContinuousClock.now
        _ = try await client.fetchVehicleData()
        #expect(ContinuousClock.now - start >= .milliseconds(20))
        let vehicle = await link.vehicle
        #expect(vehicle.signedRequests == 2)
        #expect(vehicle.sessionInfoRequests[.infotainment] == 1)
    }

    @Test("a stale-session fault without session info re-handshakes, then retries")
    func rehandshake() async throws {
        let (client, link, _) = try await connectedClient()
        try await client.startSessions([.infotainment])
        await link.update { $0.scriptedFaults = [.init(fault: .rrorInvalidSignature)] }
        _ = try await client.fetchVehicleData()
        let vehicle = await link.vehicle
        #expect(vehicle.signedRequests == 2)
        #expect(vehicle.sessionInfoRequests[.infotainment] == 2)
    }

    @Test("a re-handshake whose session info has an older counter never rolls the counter back")
    func counterNeverRollsBack() async throws {
        var vehicle = FakeVehicle()
        vehicle.staleSessionCounter = true
        let (client, link, _) = try await connectedClient(vehicle: vehicle)
        _ = try await client.fetchVehicleData()
        _ = try await client.fetchVehicleData()
        await link.update { $0.scriptedFaults = [.init(fault: .rrorInvalidSignature)] }
        _ = try await client.fetchVehicleData()
        let after = await link.vehicle
        #expect(after.sessionInfoRequests[.infotainment] == 2)
        #expect(after.domains[.infotainment]?.counter == 4)
    }

    @Test("an encrypted fault is authenticated before it is acted on: a bad tag is not retried")
    func encryptedFaultBadTag() async throws {
        let (client, link, _) = try await connectedClient()
        try await client.startSessions([.infotainment])
        await link.update { $0.scriptedFaults = [.init(fault: .rrorBusy, encrypted: true, corruptTag: true)] }
        await #expect(throws: TeslaClientError.session(.invalidResponseTag)) { try await client.fetchVehicleData() }
        #expect(await link.vehicle.signedRequests == 1)
    }

    @Test("an authenticated encrypted BUSY is retried on the same session")
    func encryptedFaultValid() async throws {
        let (client, link, _) = try await connectedClient()
        try await client.startSessions([.infotainment])
        await link.update { $0.scriptedFaults = [.init(fault: .rrorBusy, encrypted: true)] }
        _ = try await client.fetchVehicleData()
        let vehicle = await link.vehicle
        #expect(vehicle.signedRequests == 2)
        #expect(vehicle.sessionInfoRequests[.infotainment] == 1)
    }

    @Test("a second retriable fault in a row is surfaced")
    func retriesOnlyOnce() async throws {
        let (client, link, _) = try await connectedClient()
        try await client.startSessions([.infotainment])
        await link.update {
            $0.scriptedFaults = [.init(fault: .rrorBusy, attachSessionInfo: true), .init(fault: .rrorBusy, attachSessionInfo: true)]
        }
        await #expect(throws: TeslaClientError.vehicleFault(.rrorBusy)) { try await client.fetchVehicleData() }
        #expect(await link.vehicle.signedRequests == 2)
    }

    @Test("a non-retriable fault is surfaced without a retry")
    func nonRetriable() async throws {
        let (client, link, _) = try await connectedClient()
        try await client.startSessions([.infotainment])
        await link.update { $0.scriptedFaults = [.init(fault: .rrorInsufficientPrivileges)] }
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

@Suite("TeslaVehicleClient: concurrency, cancellation, locked phone")
struct ClientConcurrencyTests {
    @Test("concurrent first requests share one handshake")
    func sharedHandshake() async throws {
        let (client, link, _) = try await connectedClient()
        async let first = client.fetchVehicleData()
        async let second = client.fetchVehicleData()
        async let third = client.fetchVehicleData()
        _ = try await [first, second, third]
        let vehicle = await link.vehicle
        #expect(vehicle.sessionInfoRequests[.infotainment] == 1)
        #expect(vehicle.signedRequests == 3)
    }

    @Test("cancelling a request waiting for its reply ends it at once")
    func cancelPendingRequest() async throws {
        let (client, link, _) = try await connectedClient()
        try await client.startSessions([.infotainment])
        await link.set(holdReplies: true)
        let request = Task { try await client.fetchVehicleData() }
        try await eventually { await link.held.count == 1 }
        let start = ContinuousClock.now
        request.cancel()
        await #expect(throws: TeslaClientError.cancelled) { try await request.value }
        #expect(ContinuousClock.now - start < .milliseconds(150))
    }

    @Test("cancelling a request waiting for a handshake ends it at once")
    func cancelDuringHandshake() async throws {
        var vehicle = FakeVehicle()
        vehicle.silentDomains = [.infotainment]
        let (client, link, _) = try await connectedClient(vehicle: vehicle)
        let request = Task { try await client.fetchVehicleData() }
        try await eventually { await link.writes.count > 0 }
        let start = ContinuousClock.now
        request.cancel()
        await #expect(throws: TeslaClientError.cancelled) { try await request.value }
        #expect(ContinuousClock.now - start < .milliseconds(150))
    }

    @Test("after the first read, a re-handshake works while the key store is locked")
    func lockedKeyStore() async throws {
        let (client, link, store) = try await connectedClient()
        try await client.startSessions()
        store.isLocked = true
        await link.drop(reconnecting: true)
        try await eventually { await !client.isConnected }
        await link.reconnect()
        try await eventually { await client.isConnected }
        _ = try await client.fetchVehicleData()
        #expect(await link.vehicle.sessionInfoRequests[.infotainment] == 2)
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

    private static func status(
        _ operation: VCSEC_OperationStatus_E,
        _ information: VCSEC_WhitelistOperation_information_E? = nil
    ) -> VCSEC_FromVCSECMessage {
        var reply = VCSEC_FromVCSECMessage()
        reply.commandStatus.operationStatus = operation
        if let information {
            reply.commandStatus.whitelistOperationStatus.operationStatus = operation
            reply.commandStatus.whitelistOperationStatus.whitelistOperationInformation = information
        }
        return reply
    }

    private static func unpaired() -> FakeVehicle {
        var vehicle = FakeVehicle()
        vehicle.keyOnWhitelist = false
        return vehicle
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

    @Test("no answer from VCSEC is vehicleUnreachable, with no key-card prompt")
    func unreachable() async throws {
        var vehicle = Self.unpaired()
        vehicle.silentDomains = [.vehicleSecurity]
        let (client, link, _) = try await connectedClient(vehicle: vehicle)
        let states = States()
        await #expect(throws: TeslaClientError.vehicleUnreachable) { try await client.enrollKey { states.append($0) } }
        #expect(states.all == [.checking])
        #expect(await link.vehicle.addKeyRequests.isEmpty)
    }

    @Test("sends the add-key request, waits for the card tap, then confirms over VCSEC and Infotainment")
    func enrollsAfterTap() async throws {
        var vehicle = Self.unpaired()
        vehicle.whitelistReplies = [Self.status(.operationstatusWait)]
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
        #expect(await client.hasSession(.infotainment))
        let events = await client.drainEvents()
        #expect(events.contains(.whitelistStatus(.operationstatusWait, information: .whitelistoperationInformationNone)))
        #expect(events.contains { if case .requestSent(.vehicleSecurity, .addKeyToWhitelist, _) = $0 { true } else { false } })
    }

    @Test("waits for Infotainment to learn the key before reporting enrolled and storing the VIN")
    func waitsForInfotainmentSync() async throws {
        let (client, link, store) = try await connectedClient(vehicle: Self.unpaired())
        let states = States()
        async let enrollment: Void = client.enrollKey { states.append($0) }
        try await eventually { await !link.vehicle.addKeyRequests.isEmpty }
        await link.update { $0.vcsecKnowsKey = true }
        try await eventually { states.all.contains(.waitingForSync) }
        #expect(try store.pairedVIN() == nil)
        await link.update { $0.infotainmentKnowsKey = true }
        try await enrollment
        #expect(states.all == [.checking, .awaitingKeyCardTap, .waitingForSync, .enrolled])
        #expect(try store.pairedVIN() == ProtocolDoc.vin)
    }

    @Test("WAIT, BUSY and replies without session info while polling mean not yet")
    func temporaryOutcomes() async throws {
        var vehicle = Self.unpaired()
        vehicle.handshakeHiccups = [.vehicleSecurity: 2]
        vehicle.whitelistReplies = [Self.status(.operationstatusWait)]
        let (client, link, _) = try await connectedClient(vehicle: vehicle)
        let states = States()
        async let enrollment: Void = client.enrollKey { states.append($0) }
        try await eventually { await !link.vehicle.addKeyRequests.isEmpty }
        await link.update {
            $0.handshakeHiccups = [.vehicleSecurity: 2, .infotainment: 2]
            $0.keyOnWhitelist = true
        }
        try await enrollment
        #expect(states.all.first == .checking)
        #expect(states.all.last == .enrolled)
        #expect(!states.all.contains { if case .rejected = $0 { true } else { false } })
    }

    @Test("a generic VCSEC ERROR without whitelist information is ignored")
    func genericErrorIgnored() async throws {
        var vehicle = Self.unpaired()
        vehicle.whitelistReplies = [Self.status(.rror)]
        let (client, link, _) = try await connectedClient(vehicle: vehicle)
        let states = States()
        async let enrollment: Void = client.enrollKey { states.append($0) }
        try await eventually { await !link.vehicle.addKeyRequests.isEmpty }
        try await Task.sleep(for: .milliseconds(60))
        await link.update { $0.keyOnWhitelist = true }
        try await enrollment
        #expect(states.all == [.checking, .awaitingKeyCardTap, .enrolled])
    }

    @Test("\"already on the whitelist\" counts as VCSEC success")
    func alreadyOnWhitelist() async throws {
        var vehicle = Self.unpaired()
        vehicle.infotainmentKnowsKey = true
        vehicle.whitelistReplies = [Self.status(.rror, .whitelistoperationInformationAttemptingToAddKeyThatIsAlreadyOnTheWhitelist)]
        let (client, _, store) = try await connectedClient(vehicle: vehicle)
        let states = States()
        try await client.enrollKey { states.append($0) }
        #expect(states.all == [.checking, .awaitingKeyCardTap, .enrolled])
        #expect(try store.pairedVIN() == ProtocolDoc.vin)
    }

    @Test("no tap before the deadline is enrollmentTimedOut")
    func timesOut() async throws {
        let (client, _, store) = try await connectedClient(vehicle: Self.unpaired())
        let states = States()
        let start = ContinuousClock.now
        await #expect(throws: TeslaClientError.enrollmentTimedOut) { try await client.enrollKey { states.append($0) } }
        #expect(ContinuousClock.now - start < .seconds(3))
        #expect(states.all == [.checking, .awaitingKeyCardTap, .timedOut])
        #expect(try store.pairedVIN() == nil)
    }

    @Test("a specific whitelist rejection code is enrollmentRejected")
    func rejected() async throws {
        var vehicle = Self.unpaired()
        vehicle.whitelistReplies = [Self.status(.rror, .whitelistoperationInformationWhitelistFull)]
        let (client, _, _) = try await connectedClient(vehicle: vehicle)
        let states = States()
        await #expect(throws: TeslaClientError.enrollmentRejected("whitelistoperationInformationWhitelistFull")) {
            try await client.enrollKey { states.append($0) }
        }
        #expect(states.all.last == .rejected("whitelistoperationInformationWhitelistFull"))
    }
}
