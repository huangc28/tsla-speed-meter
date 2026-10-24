import Foundation

/// Time for `CarFeed`'s cadence, injected so tests need no real waiting.
public protocol CarFeedClock: Sendable {
    var now: ContinuousClock.Instant { get }
    /// Throws when the task is cancelled.
    func sleep(until deadline: ContinuousClock.Instant) async throws
}

/// The real clock.
public struct SystemCarFeedClock: CarFeedClock {
    public init() {}

    public var now: ContinuousClock.Instant { .now }

    public func sleep(until deadline: ContinuousClock.Instant) async throws {
        try await ContinuousClock().sleep(until: deadline, tolerance: nil)
    }
}

/// The app's one car feed: it owns the single `TeslaVehicleClient` (the one
/// Car Bluetooth connection) and is the only thing that polls the car.
///
/// It polls while the link is up and at least one `polls()` stream is
/// listening, one request in flight (L61):
/// - Drive state is asked as soon as the previous reply arrives, but never
///   sooner than `Cadence.driveInterval` after the previous drive request.
/// - Charge state and tire pressure are each asked once per
///   `Cadence.slowInterval`, one at a time, right after a drive reply, so
///   every one of them is followed by a drive request and two of them are
///   never sent back to back.
///
/// Each drive request ends one `VehicleDataPoll`: the charge or tire
/// pressure result asked just before it (if any), then drive state. A link
/// or handshake failure on that earlier category marks drive state skipped,
/// as `TeslaVehicleClient.pollVehicleData(_:)` does.
///
/// 連線, 加入鑰匙 and 讀一次 go through the feed too; adding a key and
/// reading once pause the polling (the request in flight is cancelled)
/// and resume it afterwards.
public actor CarFeed {
    public struct Cadence: Sendable {
        /// The shortest time from one drive request to the next.
        public var driveInterval: Duration
        /// How often charge state and tire pressure are each asked.
        public var slowInterval: Duration

        public init(driveInterval: Duration = .milliseconds(200), slowInterval: Duration = .seconds(10)) {
            self.driveInterval = driveInterval
            self.slowInterval = slowInterval
        }
    }

    /// Asked for once per `Cadence.slowInterval`, between drive requests.
    public static let slowCategories: [VehicleDataCategory] = [.charge, .tirePressure]
    /// What 讀一次 asks for: every category, drive state last.
    public static let allCategories: [VehicleDataCategory] = [.charge, .tirePressure, .drive]

    public nonisolated let client: TeslaVehicleClient
    public nonisolated let cadence: Cadence
    private let clock: any CarFeedClock
    private nonisolated let clientEvents = Broadcast<TeslaClientEvent>()
    private nonisolated let pollResults = Broadcast<VehicleDataPoll>()

    private var pump: Task<Void, Never>?
    private var loop: Task<Void, Never>?
    /// Set by every change that may start polling; lets a loop that is
    /// ending notice one that arrived meanwhile.
    private var kicked = false
    /// Running 加入鑰匙 / 讀一次 calls.
    private var pauses = 0
    private var lastDriveSentAt: ContinuousClock.Instant?
    /// Whether the last request this feed sent was drive state.
    private var lastSentWasDrive = false
    private var slowAskedAt: [VehicleDataCategory: ContinuousClock.Instant] = [:]

    public init(client: TeslaVehicleClient, cadence: Cadence = Cadence(), clock: any CarFeedClock = SystemCarFeedClock()) {
        self.client = client
        self.cadence = cadence
        self.clock = clock
    }

    deinit {
        pump?.cancel()
        loop?.cancel()
    }

    // MARK: Listening

    /// Every client event (connects, requests, frames …), for any number of
    /// subscribers. Keeps the newest 1,000 per subscriber while it is not read.
    public nonisolated func events() -> AsyncStream<TeslaClientEvent> {
        clientEvents.subscribe()
    }

    /// One poll per drive request while the stream is alive. The feed polls
    /// while at least one of these streams is alive and the link is up.
    public nonisolated func polls() -> AsyncStream<VehicleDataPoll> {
        pollResults.subscribe { [weak self] in
            Task { await self?.updatePolling() }
        }
    }

    // MARK: Connection

    public var isConnected: Bool {
        get async { await client.isConnected }
    }

    public func connect(vin: String) async throws {
        startPumpIfNeeded()
        try await client.connect(vin: vin)
        updatePolling()
    }

    public func disconnect() async {
        startPumpIfNeeded()
        await client.disconnect()
    }

    public func startSessions() async throws {
        startPumpIfNeeded()
        try await client.startSessions()
    }

    /// `TeslaVehicleClient.enrollKey(onStateChange:)`, with polling paused
    /// until it ends.
    public func enrollKey(onStateChange: @Sendable (EnrollmentState) -> Void = { _ in }) async throws {
        await pausePolling()
        defer { resumePolling() }
        try await client.enrollKey(onStateChange: onStateChange)
    }

    /// Asks every category once, drive state last, with polling paused. The
    /// result goes to the caller only.
    public func readOnce() async -> VehicleDataPoll {
        await pausePolling()
        defer { resumePolling() }
        let poll = await client.pollVehicleData(Self.allCategories)
        // Its drive request was sent before now: the next one waits from here.
        lastDriveSentAt = clock.now
        lastSentWasDrive = true
        return poll
    }

    // MARK: Polling

    private var wantsPolling: Bool {
        pauses == 0 && pollResults.count > 0
    }

    /// Starts the loop when it is wanted and not running; stops it when it
    /// is no longer wanted.
    private func updatePolling() {
        startPumpIfNeeded()
        kicked = true
        guard wantsPolling else {
            loop?.cancel()
            return
        }
        guard loop == nil else { return }
        loop = Task { await self.run() }
    }

    private func run() async {
        while true {
            kicked = false
            let connected = await client.isConnected
            guard !Task.isCancelled, wantsPolling, connected else { break }
            pollResults.yield(await cycle())
        }
        loop = nil
        // A connect or a new listener arrived while this loop was ending.
        if kicked, wantsPolling { updatePolling() }
    }

    /// One slot: charge state or tire pressure when due (only right after a
    /// drive request), then drive state.
    private func cycle() async -> VehicleDataPoll {
        var entries: [VehicleDataPoll.Entry] = []
        if lastSentWasDrive, let slow = dueSlowCategory() {
            slowAskedAt[slow] = clock.now
            lastSentWasDrive = false
            let result = await fetch(slow)
            entries.append(.init(category: slow, result: result))
            if case .failure(let failure) = result {
                if failure == .cancelled || Task.isCancelled { return VehicleDataPoll(entries: entries) }
                if TeslaVehicleClient.endsPoll(failure) { return VehicleDataPoll(entries: entries, skipped: [.drive]) }
            }
        }
        if let lastDriveSentAt {
            do {
                try await clock.sleep(until: lastDriveSentAt + cadence.driveInterval)
            } catch {
                entries.append(.init(category: .drive, result: .failure(.cancelled)))
                return VehicleDataPoll(entries: entries)
            }
        }
        lastDriveSentAt = clock.now
        lastSentWasDrive = true
        entries.append(.init(category: .drive, result: await fetch(.drive)))
        return VehicleDataPoll(entries: entries)
    }

    /// The slow category asked longest ago (never asked first, charge state
    /// before tire pressure), if `slowInterval` has passed since.
    private func dueSlowCategory() -> VehicleDataCategory? {
        let now = clock.now
        for category in Self.slowCategories where slowAskedAt[category] == nil {
            return category
        }
        let oldest = Self.slowCategories.min { slowAskedAt[$0]! < slowAskedAt[$1]! }!
        return now - slowAskedAt[oldest]! >= cadence.slowInterval ? oldest : nil
    }

    private func fetch(_ category: VehicleDataCategory) async -> Result<VehicleDataResponse, TeslaClientError> {
        do {
            return .success(try await client.fetchVehicleDataResponse(category))
        } catch {
            return .failure(TeslaVehicleClient.clientError(error))
        }
    }

    /// Stops the loop (cancelling the request in flight) and waits until it
    /// has ended.
    private func pausePolling() async {
        startPumpIfNeeded()
        pauses += 1
        guard let loop else { return }
        loop.cancel()
        await loop.value
    }

    private func resumePolling() {
        pauses -= 1
        updatePolling()
    }

    // MARK: Client events

    private func startPumpIfNeeded() {
        guard pump == nil else { return }
        let events = client.events
        pump = Task { [weak self] in
            for await event in events {
                guard let self else { return }
                await self.handle(event)
            }
        }
    }

    private func handle(_ event: TeslaClientEvent) {
        clientEvents.yield(event)
        switch event.kind {
        case .connected, .reconnected: updatePolling()
        default: break
        }
    }
}

/// Fans one stream of values out to any number of `AsyncStream`s.
final class Broadcast<Element: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuations: [UUID: AsyncStream<Element>.Continuation] = [:]

    var count: Int { lock.withLock { continuations.count } }

    /// A new stream; `onChange` runs after it is added and after it ends.
    func subscribe(onChange: @escaping @Sendable () -> Void = {}) -> AsyncStream<Element> {
        let id = UUID()
        let (stream, continuation) = AsyncStream.makeStream(of: Element.self, bufferingPolicy: .bufferingNewest(1000))
        continuation.onTermination = { [weak self] _ in
            self?.remove(id)
            onChange()
        }
        lock.withLock { continuations[id] = continuation }
        onChange()
        return stream
    }

    private func remove(_ id: UUID) {
        lock.withLock { _ = continuations.removeValue(forKey: id) }
    }

    func yield(_ element: Element) {
        for continuation in lock.withLock({ Array(continuations.values) }) {
            continuation.yield(element)
        }
    }
}
