import Foundation
import Testing
@testable import TeslaBLE

/// A clock that never waits: sleeping moves it forward to the deadline.
/// The fake car moves it forward by each reply's round trip.
private final class TestClock: CarFeedClock, @unchecked Sendable {
    private let lock = NSLock()
    private let start = ContinuousClock.now
    private var offset: Duration = .zero

    var elapsed: Duration { lock.withLock { offset } }
    var now: ContinuousClock.Instant { start + elapsed }

    func advance(by duration: Duration) {
        lock.withLock { offset += duration }
    }

    func sleep(until deadline: ContinuousClock.Instant) async throws {
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

    var requests: [Request] { lock.withLock { all } }
    var count: Int { lock.withLock { all.count } }

    /// Logs a new vehicle-data request, then lets `roundTrip` pass before its reply.
    func observe(_ vehicle: FakeVehicle, clock: TestClock, roundTrip: Duration) {
        let fields = vehicle.vehicleDataRequests
        let isNew = lock.withLock {
            guard fields.count > seen else { return false }
            seen = fields.count
            all.append(Request(category: Self.category(fields.last!), at: clock.elapsed))
            return true
        }
        if isNew { clock.advance(by: roundTrip) }
    }

    private static func category(_ fields: [Int]) -> VehicleDataCategory {
        // getDriveState 4, getChargeState 2, getTirePressureState 14.
        switch fields {
        case [4]: .drive
        case [2]: .charge
        case [14]: .tirePressure
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

    init(vehicle: FakeVehicle = FakeVehicle(), roundTrip: Duration = .milliseconds(150)) async {
        let link = MockLink(vehicle: vehicle)
        let clock = TestClock()
        let log = RequestLog()
        await link.set(onMessage: { vehicle in log.observe(vehicle, clock: clock, roundTrip: roundTrip) })
        self.link = link
        self.clock = clock
        self.log = log
        feed = CarFeed(client: TeslaVehicleClient(link: link, keyStore: InMemoryKeyStore(), configuration: configuration), clock: clock)
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

    @Test("charge state and tire pressure: each once per 10 s, between drive requests, never back to back")
    func slowCategories() async throws {
        let rig = await Rig(roundTrip: .milliseconds(150))
        try await rig.feed.connect(vin: ProtocolDoc.vin)
        let (polls, requests) = await rig.run(for: .seconds(35))
        let categories = requests.map(\.category)

        #expect(categories.first == .drive)
        for (current, next) in zip(categories, categories.dropFirst()) where current != .drive {
            #expect(next == .drive)
        }
        for slow in [VehicleDataCategory.charge, .tirePressure] {
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
        await rig.link.drop(reconnecting: true)
        try await settle()
        let pollsWhileDown = box.count
        let sentWhileDown = rig.log.count
        try await settle()
        #expect(box.count == pollsWhileDown)

        await rig.link.reconnect()
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

    @Test("讀一次 asks all three, drive state last, with polling paused")
    func readOnce() async throws {
        let rig = await Rig()
        try await rig.feed.connect(vin: ProtocolDoc.vin)
        let alone = await rig.feed.readOnce()
        #expect(alone.entries.map(\.category) == [.charge, .tirePressure, .drive])
        #expect(alone.firstError == nil)
        #expect(rig.log.requests.map(\.category) == [.charge, .tirePressure, .drive])

        let (box, listener) = rig.listen()
        defer { listener.cancel() }
        try await eventually { box.count >= 3 }
        let read = await rig.feed.readOnce()
        #expect(read.entries.map(\.category) == [.charge, .tirePressure, .drive])
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
}
