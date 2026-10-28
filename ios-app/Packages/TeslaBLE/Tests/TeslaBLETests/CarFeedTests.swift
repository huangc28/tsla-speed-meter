import Foundation
import Testing
@testable import TeslaBLE
import TeslaBLETestSupport

/// A clock that never waits: sleeping moves it forward to the deadline.
/// The fake car moves it forward by each reply's round trip. While closed,
/// a sleep first waits for `open()`, standing in for an await in flight.
private final class TestClock: CarFeedClock, @unchecked Sendable {
    private let lock = NSLock()
    private let start = ContinuousClock.now
    private var offset: Duration = .zero
    private var closed = false
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private var requested: [Duration] = []

    var elapsed: Duration { lock.withLock { offset } }
    /// How long each sleep asked to wait (deadline minus now), in order.
    var sleeps: [Duration] { lock.withLock { requested } }
    var now: ContinuousClock.Instant { start + elapsed }
    /// Sleeps waiting for `open()`.
    var blocked: Int { lock.withLock { waiters.count } }

    func advance(by duration: Duration) {
        lock.withLock { offset += duration }
    }

    func close() {
        lock.withLock { closed = true }
    }

    func open() {
        let waiting = lock.withLock {
            closed = false
            defer { waiters = [] }
            return waiters
        }
        waiting.forEach { $0.resume() }
    }

    func sleep(until deadline: ContinuousClock.Instant) async throws {
        lock.withLock { requested.append(deadline - (start + offset)) }
        await withCheckedContinuation { continuation in
            let wait = lock.withLock {
                if closed { waiters.append(continuation) }
                return closed
            }
            if !wait { continuation.resume() }
        }
        try Task.checkCancellation()
        lock.withLock { offset = max(offset, deadline - start) }
        await Task.yield()
    }
}

/// Each GetVehicleData request the fake car got, with the clock time it was sent.
private final class RequestLog: @unchecked Sendable {
    struct Request: Equatable {
        let category: VehicleDataCategory
        let at: Duration
    }

    private let lock = NSLock()
    private var all: [Request] = []
    private var seen = 0
    private var handshakesSeen = 0

    var requests: [Request] { lock.withLock { all } }
    var count: Int { lock.withLock { all.count } }

    /// Logs a new vehicle-data request, then lets `roundTrip` pass before
    /// its reply (`handshakeRoundTrip` for an Infotainment handshake). The
    /// request's category, nil for other messages.
    @discardableResult
    func observe(_ vehicle: FakeVehicle, clock: TestClock, roundTrip: Duration,
                 handshakeRoundTrip: Duration = .zero) -> VehicleDataCategory? {
        let handshakes = vehicle.sessionInfoRequests[.infotainment] ?? 0
        if lock.withLock({ defer { handshakesSeen = handshakes }; return handshakes > handshakesSeen }) {
            clock.advance(by: handshakeRoundTrip)
        }
        let fields = vehicle.vehicleDataRequests
        let category: VehicleDataCategory? = lock.withLock {
            guard fields.count > seen else { return nil }
            seen = fields.count
            let category = Self.category(fields.last!)
            all.append(Request(category: category, at: clock.elapsed))
            return category
        }
        if category != nil { clock.advance(by: roundTrip) }
        return category
    }

    private static func category(_ fields: [Int]) -> VehicleDataCategory {
        // getDriveState 4, getChargeState 2, getTirePressureState 14, getClosuresState 8, getClimateState 3.
        switch fields {
        case [4]: .drive
        case [2]: .charge
        case [14]: .tirePressure
        case [8]: .closures
        case [3]: .climate
        default: fatalError("unexpected request \(fields)")
        }
    }
}

/// Polls a listener has received.
private final class PollBox: @unchecked Sendable {
    private let lock = NSLock()
    private var all: [VehicleDataPoll] = []
    var polls: [VehicleDataPoll] { lock.withLock { all } }
    var count: Int { lock.withLock { all.count } }
    func append(_ poll: VehicleDataPoll) { lock.withLock { all.append(poll) } }
}

private let configuration = TeslaVehicleClient.Configuration(
    connectTimeout: .seconds(2),
    handshakeTimeout: .seconds(2),
    requestTimeout: .seconds(2),
    enrollmentTimeout: .seconds(3),
    enrollmentPollInterval: .milliseconds(20),
    busyRetryDelay: .milliseconds(20)
)

private struct Rig {
    let feed: CarFeed
    let link: MockLink
    let clock: TestClock
    let log: RequestLog

    /// `closeAfterFirst`: close the clock once that category's first request
    /// is sent, so the slot waits before its drive request until `open()`.
    init(
        vehicle: FakeVehicle = FakeVehicle(),
        roundTrip: Duration = .milliseconds(150),
        handshakeRoundTrip: Duration = .zero,
        closeAfterFirst: VehicleDataCategory? = nil,
        pairedVIN: String? = nil
    ) async {
        let link = MockLink(vehicle: vehicle)
        let clock = TestClock()
        let log = RequestLog()
        await link.set(onMessage: { vehicle in
            if let category = log.observe(vehicle, clock: clock, roundTrip: roundTrip, handshakeRoundTrip: handshakeRoundTrip),
               category == closeAfterFirst,
               log.requests.filter({ $0.category == category }).count == 1 {
                clock.close()
            }
        })
        self.link = link
        self.clock = clock
        self.log = log
        let keyStore = InMemoryKeyStore()
        if let pairedVIN { try! keyStore.setPairedVIN(pairedVIN) }
        feed = CarFeed(client: TeslaVehicleClient(link: link, keyStore: keyStore, configuration: configuration), clock: clock)
    }

    /// A listener that keeps every poll until it is cancelled.
    func listen() -> (PollBox, Task<Void, Never>) {
        let box = PollBox()
        let stream = feed.polls()
        let task = Task {
            for await poll in stream { box.append(poll) }
        }
        return (box, task)
    }

    /// Listens until the clock passes `duration`; the polls received, and the
    /// requests they cover.
    func run(for duration: Duration) async -> ([VehicleDataPoll], [RequestLog.Request]) {
        var polls: [VehicleDataPoll] = []
        for await poll in feed.polls() {
            polls.append(poll)
            if clock.elapsed >= duration { break }
        }
        let covered = polls.reduce(0) { $0 + $1.entries.count }
        return (polls, Array(log.requests.prefix(covered)))
    }
}

/// Waits about 50 ms of real time, enough for a feed that should be idle to send something.
private func settle() async throws {
    try await Task.sleep(for: .milliseconds(50))
}

@Suite("Car feed", .serialized, .timeLimit(.minutes(1)))
struct CarFeedTests {
    @Test("drive state is asked again as soon as allowed: 200 ms after the previous drive request, never sooner")
    func driveCadence() async throws {
        let rig = await Rig(roundTrip: .milliseconds(150))
        try await rig.feed.connect(vin: ProtocolDoc.vin)
        let (polls, requests) = await rig.run(for: .seconds(12))

        #expect(polls.allSatisfy { $0.firstError == nil })
        let drives = requests.filter { $0.category == .drive }.map(\.at)
        let gaps = zip(drives, drives.dropFirst()).map { $1 - $0 }
        #expect(gaps.count > 40)
        #expect(gaps.allSatisfy { $0 >= .milliseconds(200) })
        // Drive after drive: the 200 ms floor. With charge or tire pressure in
        // between: as soon as that reply came back (150 + 150 ms).
        #expect(Set(gaps) == [.milliseconds(200), .milliseconds(300)])
    }

    @Test("a slow reply: the next drive request goes as soon as it arrives")
    func slowReplies() async throws {
        let rig = await Rig(roundTrip: .milliseconds(300))
        try await rig.feed.connect(vin: ProtocolDoc.vin)
        let (_, requests) = await rig.run(for: .seconds(12))

        let pairs = zip(requests, requests.dropFirst())
        let driveToDrive = pairs.filter { $0.category == .drive && $1.category == .drive }.map { $1.at - $0.at }
        #expect(!driveToDrive.isEmpty)
        #expect(driveToDrive.allSatisfy { $0 == .milliseconds(300) })
    }

    @Test("one request in flight: the next is sent only after the reply")
    func oneInFlight() async throws {
        let rig = await Rig()
        try await rig.feed.connect(vin: ProtocolDoc.vin)
        try await rig.feed.startSessions()
        await rig.link.set(holdReplies: true)
        let (_, listener) = rig.listen()
        defer { listener.cancel() }

        for sent in 1...3 {
            try await eventually { rig.log.count == sent }
            try await settle()
            #expect(rig.log.count == sent)
            await rig.link.releaseHeld()
        }
    }

    @Test("charge state, tire pressure and closures: each once per 10 s, between drive requests, never back to back")
    func slowCategories() async throws {
        let rig = await Rig(roundTrip: .milliseconds(150))
        try await rig.feed.connect(vin: ProtocolDoc.vin)
        let (polls, requests) = await rig.run(for: .seconds(35))
        let categories = requests.map(\.category)

        #expect(categories.first == .drive)
        for (current, next) in zip(categories, categories.dropFirst()) where current != .drive {
            #expect(next == .drive)
        }
        for slow in [VehicleDataCategory.charge, .tirePressure, .closures] {
            let times = requests.filter { $0.category == slow }.map(\.at)
            #expect(times.count == 4)
            #expect(times.first.map { $0 < .seconds(1) } == true)
            let gaps = zip(times, times.dropFirst()).map { $1 - $0 }
            #expect(gaps.allSatisfy { $0 >= .seconds(10) && $0 < .milliseconds(10_600) })
        }

        // One poll per drive request: the slot's charge or tire pressure, then drive.
        #expect(polls.flatMap { $0.entries.map(\.category) } == categories)
        #expect(polls.allSatisfy { $0.entries.last?.category == .drive && $0.entries.count <= 2 })
        let withCharge = try #require(polls.first { $0.entries.first?.category == .charge })
        #expect(withCharge.reading?.batteryLevel != nil)
        #expect(withCharge.reading?.speedFloat != nil)
    }

    // #78: closures joined the 10 s batch. Each slow slot costs one round trip more than the
    // 200 ms floor, so with 150 ms round trips drive state still comes back about 5 times a second.
    @Test("with closures in the slow batch, drive state still comes back about 5 times a second")
    func driveRateWithClosures() async throws {
        let rig = await Rig(roundTrip: .milliseconds(150))
        try await rig.feed.connect(vin: ProtocolDoc.vin)
        let (polls, requests) = await rig.run(for: .seconds(60))

        #expect(polls.allSatisfy { $0.firstError == nil })
        let drives = requests.filter { $0.category == .drive }.map(\.at)
        let span = try #require(drives.last) - drives[0]
        let perSecond = Double(drives.count - 1) / (Double(span.components.seconds) + Double(span.components.attoseconds) / 1e18)
        print("drive replies per second with closures: \(perSecond)")
        #expect(perSecond >= 4.8 && perSecond <= 5)
        #expect(requests.filter { $0.category == .closures }.count == 6)
    }

    // #79: the parked screen turns climate polling on: climate state joins the slow batch, once per
    // 30 s, between drive requests like the others; off, it is not asked.
    @Test("climate state: only while climate polling is on, once per 30 s, never back to back")
    func climateWhileParked() async throws {
        let rig = await Rig(roundTrip: .milliseconds(150))
        try await rig.feed.connect(vin: ProtocolDoc.vin)
        let (_, before) = await rig.run(for: .seconds(15))
        #expect(!before.contains { $0.category == .climate })

        await rig.feed.setClimatePolling(true)
        let start = rig.clock.elapsed
        let (polls, _) = await rig.run(for: start + .seconds(65))
        // This run's requests (`run(for:)` counts from the first).
        let requests = rig.log.requests.filter { $0.at >= start && $0.at < start + .seconds(65) }
        let categories = requests.map(\.category)
        for (current, next) in zip(categories, categories.dropFirst()) where current != .drive {
            #expect(next == .drive)
        }
        let times = requests.filter { $0.category == .climate }.map(\.at)
        #expect(times.count == 3)
        // Asked at the next slot, then every 30 s.
        #expect(times.first.map { $0 - start < .seconds(1) } == true)
        let gaps = zip(times, times.dropFirst()).map { $1 - $0 }
        #expect(gaps.allSatisfy { $0 >= .seconds(30) && $0 < .milliseconds(30_600) })
        #expect(polls.allSatisfy { $0.entries.count <= 2 })

        await rig.feed.setClimatePolling(false)
        let off = rig.clock.elapsed
        _ = await rig.run(for: off + .seconds(40))
        #expect(!rig.log.requests.contains { $0.at > off && $0.category == .climate })
    }

    // #79: measured on the fake car (150 ms round trips): with climate in the batch while parked,
    // drive state still comes back about 5 times a second. The car's own figure is a car-run item.
    @Test("with climate polled while parked, drive state still comes back about 5 times a second")
    func driveRateWithClimate() async throws {
        let rig = await Rig(roundTrip: .milliseconds(150))
        try await rig.feed.connect(vin: ProtocolDoc.vin)
        await rig.feed.setClimatePolling(true)
        let (polls, requests) = await rig.run(for: .seconds(60))

        #expect(polls.allSatisfy { $0.firstError == nil })
        let drives = requests.filter { $0.category == .drive }.map(\.at)
        let span = try #require(drives.last) - drives[0]
        let perSecond = Double(drives.count - 1) / (Double(span.components.seconds) + Double(span.components.attoseconds) / 1e18)
        print("drive replies per second with closures and climate: \(perSecond)")
        #expect(perSecond >= 4.8 && perSecond <= 5)
        #expect(requests.filter { $0.category == .climate }.count == 2)
    }

    @Test("polls only while someone listens and the link is up")
    func pollsWhileListenedAndConnected() async throws {
        let rig = await Rig()
        let (early, earlyListener) = rig.listen()
        try await settle()
        #expect(rig.log.count == 0)
        #expect(early.count == 0)

        try await rig.feed.connect(vin: ProtocolDoc.vin)
        try await eventually { early.count >= 3 }
        earlyListener.cancel()
        try await settle()
        let afterStop = rig.log.count
        try await settle()
        #expect(rig.log.count == afterStop)

        let (box, listener) = rig.listen()
        defer { listener.cancel() }
        try await eventually { box.count >= 3 }
        // The feed waits out CoreBluetooth's own reconnect on the clock; a
        // closed clock keeps that wait (and the outage) going.
        rig.clock.close()
        await rig.link.drop(reconnecting: true)
        try await settle()
        let pollsWhileDown = box.count
        let sentWhileDown = rig.log.count
        try await settle()
        #expect(box.count == pollsWhileDown)

        await rig.link.reconnect()
        try await eventually { await rig.feed.linkStatus == .connected }
        rig.clock.open()
        try await eventually { rig.log.count > sentWhileDown + 3 }
    }

    @Test("two listeners get the same polls, and every events() subscriber gets every event")
    func twoListeners() async throws {
        let rig = await Rig()
        let first = rig.feed.events()
        let second = rig.feed.events()
        try await rig.feed.connect(vin: ProtocolDoc.vin)
        for stream in [first, second] {
            var iterator = stream.makeAsyncIterator()
            var sawConnected = false
            while !sawConnected, let event = await iterator.next() {
                if case .connected = event.kind { sawConnected = true }
            }
            #expect(sawConnected)
        }

        let (a, listenerA) = rig.listen()
        let (b, listenerB) = rig.listen()
        defer {
            listenerA.cancel()
            listenerB.cancel()
        }
        try await eventually { a.count >= 5 && b.count >= 5 }
        listenerA.cancel()
        let (countA, countB) = (a.count, b.count)
        #expect(abs(countA - countB) <= 1)
        // One listener left: polling goes on.
        try await eventually { b.count > countB + 3 }
    }

    @Test("adding a key pauses polling, which resumes afterwards")
    func pausesForEnrollment() async throws {
        var vehicle = FakeVehicle()
        vehicle.vcsecKnowsKey = false
        var wait = VCSEC_FromVCSECMessage()
        wait.commandStatus.operationStatus = .operationstatusWait
        vehicle.whitelistReplies = [wait]
        let rig = await Rig(vehicle: vehicle)
        try await rig.feed.connect(vin: ProtocolDoc.vin)
        let (box, listener) = rig.listen()
        defer { listener.cancel() }
        try await eventually { box.count >= 3 }

        let enrollment = Task { try await rig.feed.enrollKey() }
        try await eventually { await !rig.link.vehicle.addKeyRequests.isEmpty }
        let duringEnrollment = rig.log.count
        try await Task.sleep(for: .milliseconds(150))
        #expect(rig.log.count == duringEnrollment)

        await rig.link.update { $0.vcsecKnowsKey = true }
        try await enrollment.value
        try await eventually { rig.log.count > duringEnrollment + 3 }
    }

    @Test("讀一次 asks every category (climate too), drive state last, with polling paused")
    func readOnce() async throws {
        let rig = await Rig()
        try await rig.feed.connect(vin: ProtocolDoc.vin)
        let alone = await rig.feed.readOnce()
        #expect(alone.entries.map(\.category) == [.charge, .tirePressure, .closures, .climate, .drive])
        #expect(alone.firstError == nil)
        #expect(rig.log.requests.map(\.category) == [.charge, .tirePressure, .closures, .climate, .drive])

        let (box, listener) = rig.listen()
        defer { listener.cancel() }
        try await eventually { box.count >= 3 }
        let read = await rig.feed.readOnce()
        #expect(read.entries.map(\.category) == [.charge, .tirePressure, .closures, .climate, .drive])
        #expect(read.firstError == nil)
        let count = box.count
        try await eventually { box.count > count + 3 }
    }

    @Test("a link failure on charge state skips that slot's drive request, and drive state is asked next")
    func linkFailureSkipsDrive() async throws {
        let rig = await Rig()
        try await rig.feed.connect(vin: ProtocolDoc.vin)
        try await rig.feed.startSessions()
        await rig.link.set(writeError: .notConnected)
        var polls: [VehicleDataPoll] = []
        for await poll in rig.feed.polls() {
            polls.append(poll)
            if polls.count >= 2, polls[polls.count - 2].entries.first?.category != .drive { break }
        }
        let slot = polls[polls.count - 2]
        #expect(slot.entries.map(\.category) == [.charge])
        #expect(slot.skipped == [.drive])
        #expect(polls.last?.entries.map(\.category) == [.drive])
    }
    @Test("a listener that arrives while the stopped loop is still finishing its slot gets polls")
    func listenerDuringStop() async throws {
        let rig = await Rig()
        try await rig.feed.connect(vin: ProtocolDoc.vin)
        let (first, firstListener) = rig.listen()
        try await eventually { first.count >= 2 }
        rig.clock.close()
        try await eventually { rig.clock.blocked == 1 }
        // The last listener leaves: the loop is cancelled, but is still waiting.
        firstListener.cancel()
        try await settle()
        let (second, secondListener) = rig.listen()
        defer { secondListener.cancel() }
        try await settle()
        rig.clock.open()
        try await eventually { second.polls.filter { $0.response(for: .drive) != nil }.count > 3 }
    }

    @Test("the first request after polling resumes is drive state, even with charge state due")
    func driveFirstAfterReconnect() async throws {
        let rig = await Rig()
        try await rig.feed.connect(vin: ProtocolDoc.vin)
        try await rig.feed.startSessions()
        await rig.link.set(holdReplies: true)
        let (box, listener) = rig.listen()
        defer { listener.cancel() }
        try await eventually { rig.log.count == 1 }
        // The link drops with that drive request in flight; charge state is due.
        // A closed clock keeps the feed waiting out the system reconnect.
        rig.clock.close()
        await rig.link.drop(reconnecting: true)
        try await eventually { box.count == 1 }
        try await settle()
        await rig.link.set(holdReplies: false)
        await rig.link.reconnect()
        try await eventually { await rig.feed.linkStatus == .connected }
        rig.clock.open()
        try await eventually { rig.log.count >= 4 }
        #expect(rig.log.requests.map(\.category).prefix(4) == [.drive, .drive, .charge, .drive])
    }

    @Test("讀一次 counts as asking charge state and tire pressure")
    func readOnceCountsAsAsked() async throws {
        let rig = await Rig()
        try await rig.feed.connect(vin: ProtocolDoc.vin)
        _ = await rig.feed.readOnce()
        let (polls, _) = await rig.run(for: .seconds(9))
        #expect(polls.count > 30)
        #expect(polls.allSatisfy { $0.entries.map(\.category) == [.drive] })
    }

    @Test("a pause that cuts a slot short leaves its charge state due again")
    func pausedSlotStaysDue() async throws {
        let rig = await Rig(closeAfterFirst: .charge)
        try await rig.feed.connect(vin: ProtocolDoc.vin)
        let (box, listener) = rig.listen()
        defer { listener.cancel() }
        // Charge state came back; the slot waits before its drive request.
        try await eventually { rig.clock.blocked == 1 }
        let enrollment = Task { try await rig.feed.enrollKey() }
        try await settle()
        rig.clock.open()
        try await enrollment.value
        #expect(!box.polls.contains { $0.response(for: .charge) != nil && $0.response(for: .drive) != nil })

        try await eventually { rig.log.requests.filter { $0.category == .charge }.count == 2 }
        let charges = rig.log.requests.filter { $0.category == .charge }.map(\.at)
        #expect(charges[1] - charges[0] < .seconds(2))
    }
}

/// Events a subscriber has received.
private final class EventBox: @unchecked Sendable {
    private let lock = NSLock()
    private var all: [TeslaClientEvent.Kind] = []
    var kinds: [TeslaClientEvent.Kind] { lock.withLock { all } }
    func append(_ kind: TeslaClientEvent.Kind) { lock.withLock { all.append(kind) } }

    var autoReconnectAttempts: [Int] {
        kinds.compactMap { if case .autoReconnect(let attempt) = $0 { attempt } else { nil } }
    }
}

extension Rig {
    /// Every event from now on, until the task is cancelled.
    func record() -> (EventBox, Task<Void, Never>) {
        let box = EventBox()
        let stream = feed.events()
        let task = Task {
            for await event in stream { box.append(event.kind) }
        }
        return (box, task)
    }

    /// The quiet-retry waits: sleeps of a second or more (drive floor waits are shorter).
    var retryWaits: [Duration] { clock.sleeps.filter { $0 >= .seconds(1) } }
}

private func seconds(_ values: Int...) -> [Duration] { values.map { .seconds($0) } }

extension CarFeedTests {
    // MARK: The 200 ms floor counts from the real previous drive request

    @Test("after a BUSY resend inside a fetch, the next drive request waits 200 ms from the resend")
    func floorAfterBusyResend() async throws {
        let rig = await Rig(roundTrip: .milliseconds(150))
        try await rig.feed.connect(vin: ProtocolDoc.vin)
        // Counts as asking the slow categories: the next slots ask drive state only.
        _ = await rig.feed.readOnce()
        await rig.link.update { $0.scriptedFaults = [.init(fault: .rrorBusy)] }
        _ = await rig.run(for: .seconds(3))

        let drives = rig.log.requests.dropFirst(CarFeed.allCategories.count).filter { $0.category == .drive }.map(\.at)
        let gaps = zip(drives, drives.dropFirst()).map { $1 - $0 }
        // The resend went out as soon as the BUSY fault came back …
        #expect(gaps.first == .milliseconds(150))
        // … and every drive request after it is 200 ms after the one before.
        #expect(gaps.count > 5)
        #expect(gaps.dropFirst().allSatisfy { $0 == .milliseconds(200) })
    }

    @Test("after a handshake and a resend inside a fetch, the next drive request waits 200 ms from the resend")
    func floorAfterHandshake() async throws {
        let rig = await Rig(roundTrip: .milliseconds(150), handshakeRoundTrip: .milliseconds(150))
        try await rig.feed.connect(vin: ProtocolDoc.vin)
        _ = await rig.feed.readOnce()
        // A fault that drops the session: the client handshakes again, then resends.
        await rig.link.update { $0.scriptedFaults = [.init(fault: .rrorInvalidSignature)] }
        let handshakesBefore = await rig.link.vehicle.sessionInfoRequests[.infotainment] ?? 0
        _ = await rig.run(for: .seconds(3))

        #expect(await rig.link.vehicle.sessionInfoRequests[.infotainment] == handshakesBefore + 1)
        let drives = rig.log.requests.dropFirst(CarFeed.allCategories.count).filter { $0.category == .drive }.map(\.at)
        let gaps = zip(drives, drives.dropFirst()).map { $1 - $0 }
        // Fault reply, then the handshake, then the resend.
        #expect(gaps.first == .milliseconds(300))
        #expect(gaps.count > 5)
        #expect(gaps.dropFirst().allSatisfy { $0 == .milliseconds(200) })
    }

    // MARK: Quiet retry

    @Test("a car that does not know the key: quiet retries 1, 2, 4, 8, 10, 10 s; the next verified reply resets them")
    func quietRetryWhenKeyNotPaired() async throws {
        var vehicle = FakeVehicle()
        vehicle.infotainmentKnowsKey = false
        let rig = await Rig(vehicle: vehicle)
        try await rig.feed.connect(vin: ProtocolDoc.vin)
        let (box, listener) = rig.listen()
        defer {
            listener.cancel()
            rig.clock.open()
        }
        try await eventually { rig.retryWaits.count >= 7 }
        rig.clock.close()
        #expect(Array(rig.retryWaits.prefix(7)) == seconds(1, 2, 4, 8, 10, 10, 10))
        #expect(rig.log.count == 0)
        #expect(box.count > 0)
        #expect(box.polls.allSatisfy { $0.error(for: .drive) == .keyNotPaired })

        // The car learns the key: polling goes back to the drive cadence.
        await rig.link.update { $0.infotainmentKnowsKey = true }
        rig.clock.open()
        try await eventually { rig.log.requests.filter { $0.category == .drive }.count >= 6 }
        let reset = rig.retryWaits.count
        let drives = rig.log.requests.filter { $0.category == .drive }.map(\.at)
        #expect(zip(drives, drives.dropFirst()).allSatisfy { $1 - $0 >= .milliseconds(200) && $1 - $0 <= .milliseconds(300) })

        // It forgets the key again: the retries start over at 1 s.
        await rig.link.update { $0.infotainmentKnowsKey = false }
        try await eventually { rig.retryWaits.count >= reset + 2 }
        rig.clock.close()
        #expect(Array(rig.retryWaits[reset..<reset + 2]) == seconds(1, 2))
    }

    @Test("a paired car that cannot be reached: quiet connect retries 1, 2, 4, 8, 10 s, then it connects")
    func quietRetryWhenConnectFails() async throws {
        let rig = await Rig(pairedVIN: ProtocolDoc.vin)
        await rig.link.set(connectError: .scanTimedOut)
        let (events, recorder) = rig.record()
        let (box, listener) = rig.listen()
        defer {
            listener.cancel()
            recorder.cancel()
            rig.clock.open()
        }
        try await eventually { rig.retryWaits.count >= 5 }
        rig.clock.close()
        #expect(Array(rig.retryWaits.prefix(5)) == seconds(1, 2, 4, 8, 10))
        #expect(box.count == 0)
        #expect(events.kinds.contains(.autoReconnectFailed(attempt: 1, .link(.scanTimedOut))))

        await rig.link.set(connectError: nil)
        rig.clock.open()
        try await eventually { box.polls.contains { $0.response(for: .drive) != nil } }
        #expect(await rig.feed.linkStatus == .connected)
    }

    // MARK: Connecting on its own

    @Test("with a paired car, a listener alone connects the feed, and it reconnects after a drop")
    func autoConnectsWhenPaired() async throws {
        let rig = await Rig(pairedVIN: ProtocolDoc.vin)
        let (events, recorder) = rig.record()
        let (box, listener) = rig.listen()
        defer {
            listener.cancel()
            recorder.cancel()
        }
        try await eventually { box.polls.filter { $0.response(for: .drive) != nil }.count >= 3 }
        #expect(await rig.link.isConnected)
        #expect(await rig.feed.linkStatus == .connected)

        let before = box.count
        await rig.link.drop(reconnecting: false)
        try await eventually { box.count > before + 3 }
        #expect(await rig.link.isConnected)
        #expect(events.autoReconnectAttempts == [1, 1])
    }

    @Test("with no paired car the feed never connects, never prompts, even with listeners")
    func neverConnectsWhenNotPaired() async throws {
        let rig = await Rig()
        let (events, recorder) = rig.record()
        let (box, listener) = rig.listen()
        defer {
            listener.cancel()
            recorder.cancel()
        }
        await rig.feed.resume()
        try await settle()
        try await settle()
        #expect(box.count == 0)
        #expect(await !rig.link.isConnected)
        #expect(await rig.feed.linkStatus == .idle)
        #expect(events.kinds.isEmpty)
    }

    @Test("CoreBluetooth's own reconnect gets 15 s; then the feed disconnects and connects itself")
    func systemReconnectStalls() async throws {
        let rig = await Rig()
        try await rig.feed.connect(vin: ProtocolDoc.vin)
        let (events, recorder) = rig.record()
        let (box, listener) = rig.listen()
        defer {
            listener.cancel()
            recorder.cancel()
        }
        try await eventually { box.count >= 3 }
        await rig.link.drop(reconnecting: true)
        let before = rig.log.count
        try await eventually { rig.log.count > before + 3 }
        #expect(rig.clock.sleeps.contains(.seconds(15)))
        #expect(events.kinds.contains(.systemReconnectStalled(graceMs: 15_000)))
        #expect(events.autoReconnectAttempts == [1])
        #expect(await rig.link.disconnectCalls == 1)
    }

    // MARK: Background and foreground

    @Test("suspend stops polling and disconnects; listeners change nothing until resume, which connects again")
    func suspendAndResume() async throws {
        let rig = await Rig(pairedVIN: ProtocolDoc.vin)
        let (box, listener) = rig.listen()
        defer { listener.cancel() }
        try await eventually { box.count >= 3 }

        await rig.feed.suspend()
        #expect(await !rig.link.isConnected)
        #expect(await rig.link.disconnectCalls == 1)
        let sent = rig.log.count
        let (_, other) = rig.listen()
        try await settle()
        other.cancel()
        try await settle()
        #expect(rig.log.count == sent)
        #expect(await !rig.link.isConnected)
        #expect(await rig.feed.linkStatus == .idle)

        await rig.feed.resume()
        try await eventually { rig.log.count > sent + 3 }
        #expect(await rig.link.isConnected)
    }

    // MARK: Surface

    @Test("a late status subscriber gets the current link status first, then changes")
    func lateStatusSubscriber() async throws {
        let rig = await Rig()
        try await rig.feed.connect(vin: ProtocolDoc.vin)
        try await eventually { await rig.feed.linkStatus == .connected }
        var statuses = rig.feed.linkStatusUpdates().makeAsyncIterator()
        #expect(await statuses.next() == .connected)
        await rig.link.drop(reconnecting: false)
        #expect(await statuses.next() == .lost)
    }

    @Test("dropping the feed ends every stream it handed out")
    func deinitFinishesStreams() async throws {
        var feed: CarFeed? = CarFeed(client: TeslaVehicleClient(link: MockLink(), keyStore: InMemoryKeyStore()))
        let streams = (feed!.events(), feed!.linkStatusUpdates(), feed!.polls())
        weak let dropped = feed
        let ended = PollBox()
        let tasks = [
            Task { for await _ in streams.0 {}; ended.append(VehicleDataPoll(entries: [])) },
            Task { for await _ in streams.1 {}; ended.append(VehicleDataPoll(entries: [])) },
            Task { for await _ in streams.2 {}; ended.append(VehicleDataPoll(entries: [])) },
        ]
        defer { tasks.forEach { $0.cancel() } }
        feed = nil
        try await eventually { dropped == nil }
        try await eventually { ended.count == 3 }
    }
}

extension CarFeedTests {
    // MARK: Review fixes

    @Test("the phone locks during a test-page 連線: the connect ends, the link stays down, and resume reconnects")
    func suspendDuringAConnect() async throws {
        let rig = await Rig()
        let (_, listener) = rig.listen()
        defer { listener.cancel() }
        await rig.link.set(connectDelay: .milliseconds(200))
        let connecting = Task { try await rig.feed.connect(vin: ProtocolDoc.vin) }
        try await Task.sleep(for: .milliseconds(50))
        await rig.feed.suspend()
        let result = await connecting.result
        #expect(throws: TeslaClientError.cancelled) { try result.get() }
        try await Task.sleep(for: .milliseconds(250))
        #expect(await !rig.link.isConnected)
        #expect(rig.log.count == 0)
        #expect(await rig.feed.linkStatus == .idle)

        await rig.link.set(connectDelay: .zero)
        await rig.feed.resume()
        try await eventually { rig.log.count >= 3 }
    }

    @Test("連線's startSessions while the drive screen polls: the loop's request ends before a handshake goes out")
    func startSessionsPausesPolling() async throws {
        let rig = await Rig()
        let (events, recorder) = rig.record()
        let (_, listener) = rig.listen()
        defer {
            listener.cancel()
            recorder.cancel()
        }
        await rig.link.set(holdReplies: true)
        try await rig.feed.connect(vin: ProtocolDoc.vin)
        // The loop's first request, the Infotainment handshake, waits for its reply.
        try await eventually { await rig.link.vehicle.sessionInfoRequests[.infotainment] == 1 }
        let sessions = Task { try await rig.feed.startSessions() }
        try await eventually { await rig.link.vehicle.sessionInfoRequests[.vehicleSecurity] == 1 }
        try await settle()
        // Both held replies come back in order: the loop's, then the VCSEC one.
        await rig.link.set(holdReplies: false)
        await rig.link.releaseHeld()
        try await sessions.value
        // The loop's request had already ended when the VCSEC handshake went out, so its
        // reply matches nothing: never two requests in flight.
        try await eventually { events.kinds.contains(.messageDropped(reason: "no pending request for routing address")) }
        try await eventually { rig.log.count >= 3 }
    }
}

// MARK: Pairing (#55)

extension CarFeedTests {
    @Test("returnToPairedCar forgets the last connected car: the feed goes back to the paired one")
    func returnToPairedCar() async throws {
        let paired = "5YJ3E1EA0KF000001"
        let rig = await Rig(pairedVIN: paired)
        // The paired car is not near: only the one this test connects to is.
        let (events, recorder) = rig.record()
        let (box, listener) = rig.listen()
        defer {
            listener.cancel()
            recorder.cancel()
        }
        try await rig.feed.connect(vin: ProtocolDoc.vin)
        try await eventually { box.polls.contains { $0.response(for: .drive) != nil } }
        #expect(await rig.feed.connectedVIN == ProtocolDoc.vin)

        await rig.feed.returnToPairedCar()
        #expect(await rig.feed.connectedVIN == nil)
        let pairedName = TeslaBLEConstants.localName(forVIN: paired)
        try await eventually { events.kinds.contains(.connecting(localName: pairedName)) }
        #expect(await !rig.link.isConnected)
    }

    @Test("storePairedVIN: the feed connects to the new paired car from then on, with no restart")
    func newPairedCarIsTheTarget() async throws {
        let rig = await Rig()
        let (box, listener) = rig.listen()
        defer { listener.cancel() }
        try await rig.feed.connect(vin: ProtocolDoc.vin)
        try await rig.feed.storePairedVIN(ProtocolDoc.vin)
        #expect(await rig.feed.pairedVIN == ProtocolDoc.vin)

        // Forgetting the last connected car leaves the paired one as the only target.
        await rig.feed.returnToPairedCar()
        let before = box.count
        try await eventually { box.polls.dropFirst(before).contains { $0.response(for: .drive) != nil } }
        #expect(await rig.feed.connectedVIN == ProtocolDoc.vin)
    }
}
