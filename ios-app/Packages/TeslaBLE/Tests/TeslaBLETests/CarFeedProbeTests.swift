import Foundation
import Testing
@testable import TeslaBLE
import TeslaBLETestSupport

// #92: the drive logger's probe. `CarFeedTests` keeps its rig private and knows only the
// five categories, so the probe has its own small rig here.

/// A clock that never waits: sleeping moves it forward to the deadline, and
/// the fake car moves it forward by each reply's round trip.
private final class ProbeClock: CarFeedClock, @unchecked Sendable {
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

/// Each GetVehicleData request the fake car got, by group, with the clock time it was sent.
private final class GroupLog: @unchecked Sendable {
    struct Request: Equatable {
        let group: VehicleDataGroup
        let at: Duration
    }

    private let lock = NSLock()
    private var all: [Request] = []
    private var seen = 0

    var requests: [Request] { lock.withLock { all } }

    /// Logs a new vehicle-data request; its group and how many of that group so far.
    @discardableResult
    func observe(_ vehicle: FakeVehicle, clock: ProbeClock, roundTrip: Duration) -> (VehicleDataGroup, Int)? {
        let fields = vehicle.vehicleDataRequests
        let logged: (VehicleDataGroup, Int)? = lock.withLock {
            guard fields.count > seen else { return nil }
            seen = fields.count
            let group = Self.group(fields.last!)
            all.append(Request(group: group, at: clock.elapsed))
            return (group, all.filter { $0.group == group }.count)
        }
        if logged != nil { clock.advance(by: roundTrip) }
        return logged
    }

    /// The `GetVehicleData` field numbers (car_server.proto).
    private static func group(_ fields: [Int]) -> VehicleDataGroup {
        switch fields {
        case [2]: .charge
        case [3]: .climate
        case [4]: .drive
        case [7]: .location
        case [8]: .closures
        case [10]: .chargeSchedule
        case [11]: .preconditioningSchedule
        case [14]: .tirePressure
        case [15]: .media
        case [16]: .mediaDetail
        case [17]: .softwareUpdate
        case [19]: .parentalControls
        default: fatalError("unexpected request \(fields)")
        }
    }
}

/// Polls a listener has received.
private final class PollBox: @unchecked Sendable {
    private let lock = NSLock()
    private var polls: [VehicleDataPoll] = []
    var all: [VehicleDataPoll] { lock.withLock { polls } }
    func append(_ poll: VehicleDataPoll) { lock.withLock { polls.append(poll) } }
}

/// State a fake-car script keeps between requests.
private final class Script: @unchecked Sendable {
    private let lock = NSLock()
    private var silenceEnds = false
    func set(silenceEnds value: Bool) { lock.withLock { silenceEnds = value } }
    /// True once, for the first request after `set(silenceEnds: true)`.
    func takeSilenceEnd() -> Bool { lock.withLock { defer { silenceEnds = false }; return silenceEnds } }
}

/// Probe replies a listener has received.
private final class ReplyBox: @unchecked Sendable {
    private let lock = NSLock()
    private var all: [ProbeReply] = []
    var replies: [ProbeReply] { lock.withLock { all } }
    func append(_ reply: ProbeReply) { lock.withLock { all.append(reply) } }
}

private struct ProbeRig {
    let feed: CarFeed
    let link: MockLink
    let clock: ProbeClock
    let log: GroupLog

    /// `onRequest` runs for each whole message after the fake car has answered
    /// it (or not): for a vehicle-data request, its group and the how-many-th
    /// of that group it is; nil and 0 for any other message, or one sent to a
    /// silent domain (the fake car does not log those).
    init(
        vehicle: FakeVehicle = FakeVehicle(),
        roundTrip: Duration = .milliseconds(150),
        requestTimeout: Duration = .seconds(2),
        onRequest: (@Sendable (VehicleDataGroup?, Int, MockLink) -> Void)? = nil
    ) async {
        let link = MockLink(vehicle: vehicle)
        let clock = ProbeClock()
        let log = GroupLog()
        await link.set(onMessage: { vehicle in
            let logged = log.observe(vehicle, clock: clock, roundTrip: roundTrip)
            onRequest?(logged?.0, logged?.1 ?? 0, link)
        })
        self.link = link
        self.clock = clock
        self.log = log
        let configuration = TeslaVehicleClient.Configuration(
            connectTimeout: .seconds(2), handshakeTimeout: .seconds(2), requestTimeout: requestTimeout,
            enrollmentTimeout: .seconds(3), enrollmentPollInterval: .milliseconds(20), busyRetryDelay: .milliseconds(20)
        )
        feed = CarFeed(client: TeslaVehicleClient(link: link, keyStore: InMemoryKeyStore(), configuration: configuration), clock: clock)
    }

    /// Keeps every probe reply until the task is cancelled.
    func listenToProbe() -> (ReplyBox, Task<Void, Never>) {
        let box = ReplyBox()
        let stream = feed.probeReplies()
        let task = Task {
            for await reply in stream { box.append(reply) }
        }
        return (box, task)
    }

    /// Listens to polls until the clock passes `end`; the polls received.
    func run(until end: Duration) async -> [VehicleDataPoll] {
        var polls: [VehicleDataPoll] = []
        for await poll in feed.polls() {
            polls.append(poll)
            if clock.elapsed >= end { break }
        }
        return polls
    }

    func requests(from start: Duration, to end: Duration) -> [GroupLog.Request] {
        log.requests.filter { $0.at >= start && $0.at < end }
    }
}

@Suite("Car feed probe", .serialized, .timeLimit(.minutes(1)))
struct CarFeedProbeTests {
    @Test("probe off: only the five categories are asked and nothing reaches the probe; after switching it off, no probe group again")
    func offAsksNothingNew() async throws {
        let rig = await ProbeRig()
        let (box, listener) = rig.listenToProbe()
        defer { listener.cancel() }
        try await rig.feed.connect(vin: ProtocolDoc.vin)
        _ = await rig.run(until: .seconds(35))
        let fiveCategories = Set(VehicleDataCategory.allCases.map(VehicleDataGroup.init))
        #expect(rig.log.requests.allSatisfy { fiveCategories.contains($0.group) && $0.group != .climate })
        #expect(box.replies.isEmpty)

        await rig.feed.setProbing(true)
        let on = rig.clock.elapsed
        _ = await rig.run(until: on + .seconds(5))
        #expect(rig.requests(from: on, to: on + .seconds(5)).contains { VehicleDataGroup.probeOnly.contains($0.group) })

        await rig.feed.setProbing(false)
        let off = rig.clock.elapsed
        let seenWhileOn = box.replies.count
        _ = await rig.run(until: off + .seconds(40))
        let after = rig.log.requests.filter { $0.at > off }
        #expect(!after.isEmpty)
        #expect(after.allSatisfy { fiveCategories.contains($0.group) && $0.group != .climate })
        try await Task.sleep(for: .milliseconds(50))
        #expect(box.replies.count == seenWhileOn)
    }

    @Test("probe on: all twelve groups are asked, first asks 5 s apart, then each probe group once per 30 s, one per slot and always followed by drive state; every decrypted reply reaches the probe")
    func onAsksAllTwelve() async throws {
        let rig = await ProbeRig()
        let (box, listener) = rig.listenToProbe()
        defer { listener.cancel() }
        try await rig.feed.connect(vin: ProtocolDoc.vin)
        await rig.feed.setProbing(true)
        let polls = await rig.run(until: .seconds(100))
        let requests = rig.requests(from: .zero, to: .seconds(100))

        #expect(Set(requests.map(\.group)) == Set(VehicleDataGroup.allCases))
        let groups = requests.map(\.group)
        for (current, next) in zip(groups, groups.dropFirst()) where current != .drive {
            #expect(next == .drive)
        }
        let probeGroups = VehicleDataGroup.probeOnly + [.climate]
        let firstAsks = probeGroups.compactMap { group in requests.first { $0.group == group }?.at }.sorted()
        #expect(firstAsks.count == 8)
        let firstGaps = zip(firstAsks, firstAsks.dropFirst()).map { $1 - $0 }
        #expect(firstGaps.allSatisfy { $0 >= .seconds(5) && $0 < .milliseconds(5_600) })
        for group in probeGroups {
            let times = requests.filter { $0.group == group }.map(\.at)
            // Every 30 s from its first ask, which is up to 35 s in.
            #expect(times.count == (times.first.map { $0 < .seconds(10) } == true ? 4 : 3), "\(group)")
            let gaps = zip(times, times.dropFirst()).map { $1 - $0 }
            #expect(gaps.allSatisfy { $0 >= .seconds(30) && $0 < .milliseconds(31_000) }, "\(group)")
        }
        // The probe stays out of the polls: their rows and readings are what they were.
        #expect(polls.allSatisfy { $0.entries.allSatisfy { $0.category != .climate } && $0.entries.count <= 2 })
        #expect(polls.allSatisfy { $0.firstError == nil && $0.skipped.isEmpty })

        try await Task.sleep(for: .milliseconds(50))
        let replies = box.replies
        #expect(Set(replies.map(\.group)) == Set(VehicleDataGroup.allCases))
        #expect(replies.allSatisfy { $0.isAnswer && !$0.retired })
        // One reply per request sent (the run may end with a request in flight).
        #expect(abs(replies.count - rig.log.requests.count) <= 1)
    }

    @Test("a refused group is retired at once, one unanswered twice in a row after its second miss; the rotation and drive state go on")
    func refusedGroupsRetire() async throws {
        var vehicle = FakeVehicle()
        vehicle.refusedGroups = [.location]
        vehicle.silentGroups = [.media]
        let rig = await ProbeRig(vehicle: vehicle, requestTimeout: .milliseconds(300))
        let (box, listener) = rig.listenToProbe()
        defer { listener.cancel() }
        try await rig.feed.connect(vin: ProtocolDoc.vin)
        await rig.feed.setProbing(true)
        let polls = await rig.run(until: .seconds(95))
        let requests = rig.requests(from: .zero, to: .seconds(95))

        #expect(requests.filter { $0.group == .location }.count == 1)
        #expect(requests.filter { $0.group == .media }.count == 2)
        for group in VehicleDataGroup.probeOnly where group != .location && group != .media {
            #expect(requests.filter { $0.group == group }.count >= 3, "\(group)")
        }
        #expect(polls.allSatisfy { $0.response(for: .drive) != nil })

        try await Task.sleep(for: .milliseconds(50))
        let location = box.replies.filter { $0.group == .location }
        #expect(location.count == 1)
        #expect(location.first?.isRefusal == true && location.first?.retired == true)
        #expect(location.first?.text?.contains("not supported") == true)
        let media = box.replies.filter { $0.group == .media }
        #expect(media.map(\.result) == [.failure(.timeout(.getVehicleData)), .failure(.timeout(.getVehicleData))])
        #expect(media.map(\.retired) == [false, true])

        // Switching the probe on again starts a new session: both are asked again.
        await rig.feed.setProbing(false)
        await rig.feed.setProbing(true)
        let again = rig.clock.elapsed
        _ = await rig.run(until: again + .seconds(40))
        let later = rig.requests(from: again, to: again + .seconds(40)).map(\.group)
        #expect(later.contains(.location) && later.contains(.media))
    }

    @Test("one timeout, then an answer: the group stays in the rotation")
    func timeoutThenAnswerKeepsTheGroup() async throws {
        var vehicle = FakeVehicle()
        vehicle.silentGroups = [.location]
        let rig = await ProbeRig(vehicle: vehicle, requestTimeout: .milliseconds(300)) { group, count, link in
            if group == .location, count == 1 { Task { await link.update { $0.silentGroups = [] } } }
        }
        let (box, listener) = rig.listenToProbe()
        defer { listener.cancel() }
        try await rig.feed.connect(vin: ProtocolDoc.vin)
        await rig.feed.setProbing(true)
        _ = await rig.run(until: .seconds(95))

        #expect(rig.log.requests.filter { $0.group == .location }.count == 4)
        try await Task.sleep(for: .milliseconds(50))
        let location = box.replies.filter { $0.group == .location }
        #expect(location.map(\.isAnswer) == [false, true, true, true])
        #expect(location.allSatisfy { !$0.retired })
    }

    @Test("a timeout while drive state fails too (the whole car silent) does not count toward two in a row")
    func carWideSilenceDoesNotCount() async throws {
        var vehicle = FakeVehicle()
        vehicle.silentGroups = [.location]
        let script = Script()
        let rig = await ProbeRig(vehicle: vehicle, requestTimeout: .milliseconds(300)) { group, count, link in
            switch (group, count) {
            case (.location, 1):
                // The drive request after it goes unanswered too.
                script.set(silenceEnds: true)
                Task { await link.update { $0.silentDomains = [.infotainment] } }
            case (nil, _) where script.takeSilenceEnd():
                Task { await link.update { $0.silentDomains = [] } }
            case (.location, 2):
                // Missed again, with drive state answered: one in a row so far.
                Task { await link.update { $0.silentGroups = [] } }
            default:
                break
            }
        }
        let (box, listener) = rig.listenToProbe()
        defer { listener.cancel() }
        let polls = PollBox()
        let screen = Task { for await poll in rig.feed.polls() { polls.append(poll) } }
        defer { screen.cancel() }
        try await rig.feed.connect(vin: ProtocolDoc.vin)
        await rig.feed.setProbing(true)
        try await eventually { rig.log.requests.filter { $0.group == .location }.count >= 3 }
        try await eventually { box.replies.filter { $0.group == .location }.count >= 3 }

        #expect(polls.all.contains { $0.error(for: .drive) == .timeout(.getVehicleData) })
        let location = box.replies.filter { $0.group == .location }.prefix(3)
        #expect(location.map(\.isAnswer) == [false, false, true])
        #expect(location.allSatisfy { !$0.retired })
    }

    @Test("misses that never come two in a row still retire the group at the fourth: the time it costs is bounded")
    func missesInAllAreBounded() async throws {
        var vehicle = FakeVehicle()
        vehicle.silentGroups = [.location]
        let rig = await ProbeRig(vehicle: vehicle, requestTimeout: .milliseconds(300)) { group, count, link in
            // Silent on asks 1, 3, 5, 7; answered on 2, 4, 6.
            guard group == .location else { return }
            Task { await link.update { $0.silentGroups = count.isMultiple(of: 2) ? [.location] : [] } }
        }
        let (box, listener) = rig.listenToProbe()
        defer { listener.cancel() }
        try await rig.feed.connect(vin: ProtocolDoc.vin)
        await rig.feed.setProbing(true)
        _ = await rig.run(until: .seconds(300))

        #expect(rig.log.requests.filter { $0.group == .location }.count == CarFeed.probeMaxMisses * 2 - 1)
        try await Task.sleep(for: .milliseconds(50))
        let location = box.replies.filter { $0.group == .location }
        #expect(location.map(\.isAnswer) == [false, true, false, true, false, true, false])
        #expect(location.map(\.retired) == [false, false, false, false, false, false, true])
    }

    @Test("a probe request cut short by a dropped link or a suspend is not a refusal: the group is asked again and nothing is reported")
    func linkDownAndCancelDoNotRetire() async throws {
        var vehicle = FakeVehicle()
        vehicle.silentGroups = [.location]
        let rig = await ProbeRig(vehicle: vehicle, requestTimeout: .seconds(20))
        let (box, listener) = rig.listenToProbe()
        defer { listener.cancel() }
        let polls = PollBox()
        let screen = Task { for await poll in rig.feed.polls() { polls.append(poll) } }
        defer { screen.cancel() }
        try await rig.feed.connect(vin: ProtocolDoc.vin)
        await rig.feed.setProbing(true)
        let asked = { rig.log.requests.filter { $0.group == .location }.count }

        // Dropped while location is in flight: the slot ends, its drive request skipped with
        // the cause; the feed reconnects, location comes due again.
        try await eventually { asked() == 1 }
        await rig.link.drop(reconnecting: false)
        try await eventually { asked() == 2 }
        let skip = try #require(polls.all.first { $0.skipped == [.drive] })
        #expect(skip.entries.isEmpty)
        #expect(skip.skipCause != nil)
        #expect(skip.firstError == skip.skipCause)

        // Suspended while location is in flight: cancelled, so it is asked first again after resume.
        await rig.feed.suspend()
        await rig.link.update { $0.silentGroups = [] }
        await rig.feed.resume()
        try await eventually { asked() == 3 }
        try await eventually { box.replies.contains { $0.group == .location } }
        let location = box.replies.filter { $0.group == .location }
        #expect(location.count == 1)
        #expect(location.allSatisfy { $0.isAnswer && !$0.retired })
    }

    // Measured on the fake car (150 ms round trips): the figure is printed for the ticket.
    @Test("with the probe on, drive state still comes back about 4.7 times a second")
    func driveRateWithProbe() async throws {
        let rig = await ProbeRig()
        try await rig.feed.connect(vin: ProtocolDoc.vin)
        await rig.feed.setProbing(true)
        _ = await rig.run(until: .seconds(120))

        let drives = rig.requests(from: .seconds(60), to: .seconds(120)).filter { $0.group == .drive }.map(\.at)
        let span = try #require(drives.last) - drives[0]
        let perSecond = Double(drives.count - 1) / (Double(span.components.seconds) + Double(span.components.attoseconds) / 1e18)
        print("drive replies per second with the probe on: \(perSecond)")
        #expect(perSecond >= 4.65 && perSecond <= 5)
    }

    @Test("the probe gets the decrypted reply in full: known fields by name, unknown fields at every nested level by number")
    func fullReplyWithUnknownFields() async throws {
        var vehicle = FakeVehicle()
        vehicle.responsePlaintext = try ProbeFixture.replyWithUnknownFields()
        let rig = await ProbeRig(vehicle: vehicle)
        let (box, listener) = rig.listenToProbe()
        defer { listener.cancel() }
        try await rig.feed.connect(vin: ProtocolDoc.vin)
        await rig.feed.setProbing(true)
        _ = await rig.run(until: .seconds(3))
        try await Task.sleep(for: .milliseconds(50))

        let drive = try #require(box.replies.first { $0.group == .drive }?.text)
        print(drive)
        #expect(drive.contains("drive_state {"))
        #expect(drive.contains("speed_float: 60.5"))
        #expect(drive.contains("999: 7"))
        let location = try #require(box.replies.first { $0.group == .location }?.text)
        print(location)
        #expect(location.contains("location_state {"))
        #expect(location.contains("heading: 90"))
        #expect(location.contains("200 {"))
        #expect(location.contains("1: 5"))
        #expect(location.contains("2: 0x04030201"))
        // The decrypted bytes themselves keep every field too.
        guard case .success(let plaintext)? = box.replies.first(where: { $0.group == .location })?.result else {
            Issue.record("no location reply")
            return
        }
        let decoded = try CarServer_Response(serializedBytes: plaintext)
        #expect(!decoded.vehicleData.locationState.unknownFields.data.isEmpty)
    }
}
