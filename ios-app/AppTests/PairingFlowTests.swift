import Foundation
import HUDCore
import Testing
import TeslaBLE
import TeslaBLETestSupport
@testable import SpeedHUD

/// The car feed's clock, injected: it runs ten times faster than real time, so a
/// quiet retry of seconds takes a fraction of one.
private final class FastFeedClock: CarFeedClock, @unchecked Sendable {
    private let start = ContinuousClock.now
    static let speedUp = 10.0

    var now: ContinuousClock.Instant {
        start + (ContinuousClock.now - start) * Self.speedUp
    }

    func sleep(until deadline: ContinuousClock.Instant) async throws {
        let left = deadline - now
        guard left > .zero else { return }
        try await Task.sleep(for: left / Self.speedUp)
    }
}

private let fast = TeslaVehicleClient.Configuration(
    connectTimeout: .seconds(2),
    handshakeTimeout: .seconds(2),
    requestTimeout: .seconds(2),
    enrollmentTimeout: .seconds(5),
    enrollmentPollInterval: .milliseconds(20),
    busyRetryDelay: .milliseconds(20)
)

/// A synthetic VIN (not a real car) whose 9th character checks out.
private func vin(_ pattern: String) -> String {
    var characters = Array(pattern)
    characters[8] = VIN.checkDigit(for: pattern)!
    return String(characters)
}

private let carVIN = vin("5YJ3E1EA0KF000001")
private let oldCarVIN = vin("LRW3E7FS0MC000003")

/// A bare VCSEC reply to the add-key request.
private func whitelistStatus(
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

/// A car that does not know this phone's key and waits for the key card.
private func newCar(_ vin: String = carVIN) -> FakeVehicle {
    var vehicle = FakeVehicle(vin: vin)
    vehicle.keyOnWhitelist = false
    vehicle.whitelistReplies = [whitelistStatus(.operationstatusWait)]
    return vehicle
}

/// Waits up to about three seconds for `condition`.
@MainActor
private func eventually(_ condition: () async -> Bool, _ comment: Comment? = nil) async throws {
    for _ in 0..<300 {
        if await condition() { return }
        try await Task.sleep(for: .milliseconds(10))
    }
    Issue.record(comment ?? "condition never became true")
}

/// A cancel a test started, and whether it has returned.
@MainActor
private final class CancelBox {
    var task: Task<Void, Never>?
    var done = false
}

/// Every step the flow went through.
@MainActor
private final class StepLog {
    var steps: [PairingFlow.Step] = []
}

/// Events a feed subscriber has received.
private final class EventLog: @unchecked Sendable {
    private let lock = NSLock()
    private var all: [TeslaClientEvent.Kind] = []
    var kinds: [TeslaClientEvent.Kind] { lock.withLock { all } }
    func append(_ kind: TeslaClientEvent.Kind) { lock.withLock { all.append(kind) } }
}

/// An in-memory key store whose `setPairedVIN` waits at a gate until `open()`, once
/// `arm()` was called (so seeding a paired car in `Rig.init` never blocks).
private final class GatedKeyStore: TeslaKeyStore, @unchecked Sendable {
    private let inner = InMemoryKeyStore()
    private let lock = NSLock()
    private let gate = DispatchSemaphore(value: 0)
    private var arrived = false
    private var armed = false

    /// `setPairedVIN` is waiting at the gate (or went through it).
    var reached: Bool { lock.withLock { arrived } }
    func arm() { lock.withLock { armed = true } }
    func open() { gate.signal() }

    func clientKey() throws -> any KeyAgreementKey { try inner.clientKey() }
    func pairedVIN() throws -> String? { try inner.pairedVIN() }
    func setPairedVIN(_ vin: String) throws {
        guard lock.withLock({ armed }) else { return try inner.setPairedVIN(vin) }
        lock.withLock { arrived = true }
        gate.wait()
        try inner.setPairedVIN(vin)
    }
    func vehiclePublicKey(vin: String, domain: UniversalMessage_Domain) throws -> Data? {
        try inner.vehiclePublicKey(vin: vin, domain: domain)
    }
    func setVehiclePublicKey(_ key: Data, vin: String, domain: UniversalMessage_Domain) throws {
        try inner.setVehiclePublicKey(key, vin: vin, domain: domain)
    }
}

@MainActor
private struct Rig {
    let link: MockLink
    let keyStore: any TeslaKeyStore
    let feed: CarFeed
    let flow: PairingFlow

    init(vehicle: FakeVehicle = newCar(), pairedVIN: String? = nil, keyStore: any TeslaKeyStore = InMemoryKeyStore()) {
        link = MockLink(vehicle: vehicle)
        self.keyStore = keyStore
        if let pairedVIN { try! keyStore.setPairedVIN(pairedVIN) }
        feed = CarFeed(client: TeslaVehicleClient(link: link, keyStore: keyStore, configuration: fast), clock: FastFeedClock())
        flow = PairingFlow(feed: feed)
    }

    var storedVIN: String? { try! keyStore.pairedVIN() }

    /// S13 → S14 → S15 with `typed`.
    func submit(_ typed: String = carVIN) {
        flow.parkedConfirmed = true
        flow.begin()
        flow.type(typed)
        flow.submitVIN()
    }

    func record() -> (EventLog, Task<Void, Never>) {
        let log = EventLog()
        let events = feed.events()
        return (log, Task { for await event in events { log.append(event.kind) } })
    }
}

@Suite("Pairing on the fake car", .serialized, .timeLimit(.minutes(1)))
@MainActor
struct PairingFlowTests {
    // MARK: Happy path

    @Test("S13 → S14 → S15 match → S16 key card → S17 read: the paired VIN is stored only after the read")
    func happyPath() async throws {
        let rig = Rig()
        let flow = rig.flow
        #expect(flow.step == .start)
        // L67: 開始 needs 「車子已經停好(P 檔)」.
        flow.begin()
        #expect(flow.step == .start)
        flow.parkedConfirmed = true
        flow.begin()
        #expect(flow.step == .vin)

        flow.type(carVIN.lowercased())
        #expect(flow.entry.vin == carVIN)
        // Bluetooth is not touched on S13 or S14.
        #expect(await rig.link.connectCalls == 0)

        // Hold the car's replies: the match shows while the key check waits.
        await rig.link.set(holdReplies: true)
        flow.submitVIN()
        #expect(flow.step == .finding(matched: false))
        try await eventually({ flow.step == .finding(matched: true) }, "✓ 就是旁邊這台")
        #expect(await rig.link.connectCalls == 1)
        await rig.link.set(holdReplies: false)
        await rig.link.releaseHeld()

        try await eventually({ flow.step == .keyCard }, "S16")
        try await Task.sleep(for: .milliseconds(100))
        #expect(flow.step == .keyCard)
        #expect(rig.storedVIN == nil, "not stored at S16")

        // The key card is tapped and confirmed on the car.
        await rig.link.update { $0.keyOnWhitelist = true }
        try await eventually({ if case .paired = flow.step { true } else { false } }, "S17")
        #expect(rig.storedVIN == carVIN)
        #expect(await rig.feed.pairedVIN == carVIN)
        guard case .paired(let preview) = flow.step else { return }
        // The fake car reports 60.5 mph in D with 72 %.
        #expect(preview.speedKilometersPerHour.map { $0.rounded() } == 97)
        #expect(preview.gear == .drive)
        #expect(preview.batteryPercent == 72)
        flow.finish()
    }

    @Test("the match shows the moment the scan sees the car's name, before the link is up")
    func matchBeforeConnected() async throws {
        let rig = Rig()
        // Connecting takes 2 s more after the car's name was seen.
        await rig.link.set(foundDelay: .seconds(2))
        rig.submit()
        try await eventually({ rig.flow.step == .finding(matched: true) }, "✓ 就是旁邊這台")
        #expect(await !rig.link.isConnected, "shown from the scan, not from the finished connect")
        await rig.flow.cancel()
    }

    @Test("a deliberately broken check digit: S14 warns, and 仍要繼續 pairs anyway; the nearby match decides")
    func checkDigitWarningThenContinue() async throws {
        var broken = Array(carVIN)
        broken[8] = broken[8] == "1" ? "2" : "1"
        let typed = String(broken)
        var vehicle = FakeVehicle(vin: typed)
        vehicle.keyOnWhitelist = true
        let rig = Rig(vehicle: vehicle)
        rig.submit(typed)
        #expect(rig.flow.entry.problem == .checkDigit)
        #expect(rig.flow.step == .vin)

        rig.flow.submitVINAnyway()
        try await eventually({ if case .paired = rig.flow.step { true } else { false } })
        #expect(rig.storedVIN == typed)
        rig.flow.finish()
    }

    @Test("a typed Q or a short VIN never leaves S14")
    func incompleteVINStays() async throws {
        let rig = Rig()
        rig.submit("5YJ3E1EA0KF00000Q")
        #expect(rig.flow.entry.problem == .invalidCharacter)
        rig.flow.submitVINAnyway()
        #expect(rig.flow.step == .vin)
        rig.flow.type("5YJ3E1")
        rig.flow.submitVIN()
        #expect(rig.flow.step == .vin)
        rig.flow.back()
        #expect(rig.flow.step == .start)
        #expect(await rig.link.connectCalls == 0)
    }

    // MARK: The owner's phone

    @Test("(a) the typed VIN is the car the feed is already connected to: the match shows at once, no new scan")
    func alreadyConnectedCar() async throws {
        var vehicle = FakeVehicle(vin: carVIN)
        vehicle.keyOnWhitelist = true
        let rig = Rig(vehicle: vehicle, pairedVIN: carVIN)
        // The drive screen listens, so the feed is connected to the paired car.
        let polls = rig.feed.polls()
        let listener = Task { for await _ in polls {} }
        defer { listener.cancel() }
        try await eventually { await rig.feed.connectedVIN == carVIN }
        let (connects, disconnects) = await (rig.link.connectCalls, rig.link.disconnectCalls)

        await rig.link.set(holdReplies: true)
        rig.submit()
        // The match shows before any reply from the car: no wait for a scan.
        try await eventually { rig.flow.step == .finding(matched: true) }
        await rig.link.set(holdReplies: false)
        await rig.link.releaseHeld()
        try await eventually({ if case .paired = rig.flow.step { true } else { false } })
        #expect(await rig.link.connectCalls == connects)
        #expect(await rig.link.disconnectCalls == disconnects)
        rig.flow.finish()
    }

    @Test("(b) the car already holds this app key: enrolled at once, straight to S17, never stuck at S16")
    func alreadyEnrolledKey() async throws {
        var vehicle = FakeVehicle(vin: carVIN)
        vehicle.keyOnWhitelist = true
        let rig = Rig(vehicle: vehicle)
        let seen = StepLog()
        rig.flow.onStepChange = { seen.steps.append($0) }
        rig.submit()
        try await eventually { if case .paired = rig.flow.step { true } else { false } }
        #expect(!seen.steps.contains(.keyCard), "\(seen.steps)")
        #expect(Array(seen.steps.prefix(4)) == [.vin, .finding(matched: false), .finding(matched: true), .reading])
        #expect(await rig.link.vehicle.addKeyRequests.isEmpty)
        #expect(rig.storedVIN == carVIN)
        rig.flow.finish()
    }

    @Test("(b) the car answers the add-key request with \"already on the whitelist\": enrolled, then S17")
    func alreadyOnTheWhitelistReply() async throws {
        var vehicle = FakeVehicle(vin: carVIN)
        vehicle.vcsecKnowsKey = false
        vehicle.infotainmentKnowsKey = true
        vehicle.whitelistReplies = [
            whitelistStatus(.rror, .whitelistoperationInformationAttemptingToAddKeyThatIsAlreadyOnTheWhitelist),
        ]
        let rig = Rig(vehicle: vehicle)
        rig.submit()
        try await eventually({ if case .paired = rig.flow.step { true } else { false } })
        #expect(rig.storedVIN == carVIN)
        rig.flow.finish()
    }

    // MARK: Cancel, failure, one car

    @Test("cancel at S16 leaves no paired car and no link, and the car was never stored")
    func cancelAtKeyCard() async throws {
        let rig = Rig()
        rig.submit()
        try await eventually { rig.flow.step == .keyCard }
        await rig.flow.cancel()
        #expect(rig.storedVIN == nil)
        #expect(await rig.feed.connectedVIN == nil)
        #expect(await !rig.link.isConnected)
        // The car takes the key later: still nothing is paired on the phone.
        await rig.link.update { $0.keyOnWhitelist = true }
        try await Task.sleep(for: .milliseconds(100))
        #expect(rig.storedVIN == nil)
    }

    @Test("cancel while searching ends the scan at once; the car is never connected")
    func cancelWhileSearching() async throws {
        let rig = Rig()
        let (events, recorder) = rig.record()
        defer { recorder.cancel() }
        await rig.link.set(connectDelay: .seconds(10))
        rig.submit()
        try await eventually { await rig.link.connectCalls == 1 }
        let start = ContinuousClock.now
        await rig.flow.cancel()
        #expect(ContinuousClock.now - start < .seconds(1), "cancel waited for the scan")
        #expect(rig.storedVIN == nil)
        #expect(await !rig.link.isConnected)
        try await Task.sleep(for: .milliseconds(100))
        #expect(!events.kinds.contains { if case .connected = $0 { true } else { false } })
    }

    @Test("a failure is one failed state with the error; 重試 pairs from S15 again")
    func failureThenRetry() async throws {
        let rig = Rig()
        await rig.link.set(connectError: .scanTimedOut)
        rig.submit()
        try await eventually { rig.flow.step == .failed(.link(.scanTimedOut)) }
        #expect(rig.storedVIN == nil)

        await rig.link.set(connectError: nil)
        await rig.link.update { $0.keyOnWhitelist = true }
        rig.flow.retry()
        #expect(rig.flow.step == .finding(matched: false))
        try await eventually({ if case .paired = rig.flow.step { true } else { false } })
        #expect(rig.storedVIN == carVIN)
        rig.flow.finish()
    }

    @Test("a read with no drive state is not pairing: failed, nothing stored")
    func readMustComeBack() async throws {
        var vehicle = FakeVehicle(vin: carVIN)
        vehicle.categoryFaults = [.drive: .init(fault: .rrorDecoding)]
        let rig = Rig(vehicle: vehicle)
        rig.submit()
        try await eventually { if case .failed = rig.flow.step { true } else { false } }
        #expect(rig.storedVIN == nil)
        await rig.flow.cancel()
        #expect(await !rig.link.isConnected)
        #expect(rig.storedVIN == nil, "稍後再說 stores nothing")
    }

    @Test("cancel while the paired VIN is being stored: the car stays paired, the screen closes, no preview")
    func cancelDuringStore() async throws {
        let store = GatedKeyStore()
        // A test that ends early never leaves a thread stuck at the gate (an extra signal is harmless).
        defer { store.open() }
        var vehicle = FakeVehicle(vin: carVIN)
        vehicle.keyOnWhitelist = true
        let rig = Rig(vehicle: vehicle, keyStore: store)
        store.arm()
        rig.submit()
        try await eventually({ store.reached }, "the store started")
        #expect(rig.flow.step == .reading)

        let cancelling = Task { await rig.flow.cancel() }
        try await Task.sleep(for: .milliseconds(50))
        store.open()
        await cancelling.value
        // Storing is the commit point: the new car is paired and nothing is reverted.
        #expect(rig.storedVIN == carVIN)
        #expect(await rig.feed.pairedVIN == carVIN)
        #expect(await rig.feed.connectedVIN == carVIN)
        // No S17 and no preview: with nobody listening, the feed sends nothing more.
        #expect(rig.flow.step == .reading)
        let writes = await rig.link.writes.count
        try await Task.sleep(for: .milliseconds(300))
        #expect(await rig.link.writes.count == writes, "a preview is still polling")
    }

    @Test("cancel before the store starts (during the S17 read): nothing is stored")
    func cancelBeforeStore() async throws {
        var vehicle = FakeVehicle(vin: carVIN)
        vehicle.keyOnWhitelist = true
        let rig = Rig(vehicle: vehicle)
        let cancelling = CancelBox()
        rig.flow.onStepChange = { [flow = rig.flow] step in
            if step == .reading, cancelling.task == nil { cancelling.task = Task { await flow.cancel() } }
        }
        rig.submit()
        try await eventually { cancelling.task != nil }
        await cancelling.task?.value
        #expect(rig.storedVIN == nil)
        #expect(rig.flow.step == .reading)
        #expect(await !rig.link.isConnected)
    }

    @Test("a car the test page connected, paired and cancelled at S16: the feed goes back to the paired car")
    func cancelReturnsFromTestPageCar() async throws {
        let rig = Rig(pairedVIN: oldCarVIN)
        let (events, recorder) = rig.record()
        let polls = rig.feed.polls()
        let listener = Task { for await _ in polls {} }
        defer {
            listener.cancel()
            recorder.cancel()
        }
        // The test page's override has the feed on the new car.
        try await rig.feed.connect(vin: carVIN)
        let connects = await rig.link.connectCalls
        rig.submit()
        try await eventually { rig.flow.step == .keyCard }
        #expect(await rig.link.connectCalls == connects, "case (a): no new connect")
        await rig.flow.cancel()
        #expect(rig.storedVIN == oldCarVIN)
        #expect(await rig.feed.targetVIN == oldCarVIN)
        #expect(await !rig.link.isConnected)

        let oldName = TeslaBLEConstants.localName(forVIN: oldCarVIN)
        func lookups() -> Int { events.kinds.filter { $0 == .connecting(localName: oldName) }.count }
        try await eventually { lookups() > 0 }
        // A drop, then background and front again: still the old car, never the new one.
        await rig.link.drop(reconnecting: false)
        try await Task.sleep(for: .milliseconds(100))
        let beforeResume = lookups()
        await rig.feed.suspend()
        await rig.feed.resume()
        try await eventually { lookups() > beforeResume }
        #expect(await rig.feed.targetVIN == oldCarVIN)
        #expect(await !rig.link.isConnected)
        #expect(await rig.feed.connectedVIN == nil)
    }

    @Test("稍後再說, then 重試 while the screen closes: nothing starts again, nothing is stored")
    func noRetryAfterClosing() async throws {
        let rig = Rig()
        await rig.link.set(connectError: .scanTimedOut)
        rig.submit()
        try await eventually { rig.flow.step == .failed(.link(.scanTimedOut)) }
        // The car is reachable and knows the key by now: a run would pair it.
        await rig.link.set(connectError: nil)
        await rig.link.update { $0.keyOnWhitelist = true }
        let connects = await rig.link.connectCalls

        // 稍後再說 starts closing; 重試 comes while that cancel is still running, and again after.
        let closed = CancelBox()
        let cancelling = Task {
            await rig.flow.cancel()
            closed.done = true
        }
        await Task.yield()
        #expect(!closed.done, "the cancel is still in flight")
        rig.flow.retry()
        rig.flow.submitVIN()
        rig.flow.begin()
        await cancelling.value
        rig.flow.retry()
        try await Task.sleep(for: .milliseconds(200))
        #expect(await rig.link.connectCalls == connects)
        #expect(rig.storedVIN == nil)
        #expect(rig.flow.step == .failed(.link(.scanTimedOut)))
    }

    @Test("one car: a new car replaces the paired one only after S17; cancelled, the feed goes back to the old one")
    func replacesOnlyAfterSuccess() async throws {
        let rig = Rig(pairedVIN: oldCarVIN)
        let (events, recorder) = rig.record()
        let polls = rig.feed.polls()
        let listener = Task { for await _ in polls {} }
        defer {
            listener.cancel()
            recorder.cancel()
        }
        rig.submit()
        try await eventually { rig.flow.step == .keyCard }
        await rig.flow.cancel()
        #expect(rig.storedVIN == oldCarVIN)
        // The feed looks for the old car again (it is not here).
        let oldName = TeslaBLEConstants.localName(forVIN: oldCarVIN)
        let before = events.kinds.filter { $0 == .connecting(localName: oldName) }.count
        try await eventually { events.kinds.filter { $0 == .connecting(localName: oldName) }.count > before }

        let again = PairingFlow(feed: rig.feed)
        again.parkedConfirmed = true
        again.begin()
        again.type(carVIN)
        again.submitVIN()
        try await eventually { again.step == .keyCard }
        #expect(rig.storedVIN == oldCarVIN)
        await rig.link.update { $0.keyOnWhitelist = true }
        try await eventually({ if case .paired = again.step { true } else { false } })
        #expect(rig.storedVIN == carVIN)
        again.finish()
    }

    // MARK: Afterwards

    @Test("after pairing the drive screen shows the car and the feed reconnects to it after a drop, with no restart")
    func feedUsesThePairedCarAfterwards() async throws {
        let rig = Rig()
        let model = HUDViewModel()
        model.handle(.authorization(.authorized))
        let run = Task { await model.run(car: rig.feed.carEvents()) }
        defer { run.cancel() }
        try await Task.sleep(for: .milliseconds(100))
        #expect(await rig.link.connectCalls == 0)
        #expect(model.state.source != .valid(.carBluetooth))

        rig.submit()
        try await eventually { rig.flow.step == .keyCard }
        await rig.link.update { $0.keyOnWhitelist = true }
        try await eventually({ if case .paired = rig.flow.step { true } else { false } })
        rig.flow.finish()
        try await eventually({ model.state.source == .valid(.carBluetooth) }, "● 車輛藍牙")

        // The link drops; the feed reconnects to the newly paired car by itself.
        let connects = await rig.link.connectCalls
        await rig.link.drop(reconnecting: false)
        try await eventually {
            let (calls, connected) = await (rig.link.connectCalls, rig.link.isConnected)
            return calls > connects && connected
        }
        #expect(await rig.feed.connectedVIN == carVIN)
        // The app goes to the background and back: still the paired car.
        await rig.feed.suspend()
        await rig.feed.resume()
        try await eventually { await rig.feed.connectedVIN == carVIN }
    }
}
