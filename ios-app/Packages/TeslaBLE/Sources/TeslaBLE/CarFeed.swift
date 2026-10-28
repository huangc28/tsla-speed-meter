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
/// While at least one `polls()` stream is listening (and the feed is not
/// suspended), it keeps the link up and polls:
/// - Link: with the link down, it connects to the car of the last
///   `connect(vin:)`, else to the paired car; with neither it never
///   connects. `returnToPairedCar()` forgets the last `connect(vin:)`. After a drop it reconnects on its own; while CoreBluetooth
///   reconnects by itself it waits `Cadence.systemReconnectGrace` first.
/// - Polling, one request in flight (L61): drive state is asked as soon as
///   the previous reply arrives, but never sooner than
///   `Cadence.driveInterval` after the previous drive request was sent
///   (its last send, after a handshake or a resend). Charge state, tire
///   pressure and closures are each asked once per `Cadence.slowInterval`, one at a
///   time, right after a drive reply, so every one of them is followed by a
///   drive request and two of them are never sent back to back. The first
///   request after polling starts or resumes is drive state.
/// - Quiet retry: a connect attempt that fails, or a slot with no verified
///   reply (the car does not know the key, its key changed, it does not
///   answer …), waits `Cadence.retryDelay`, doubling up to
///   `Cadence.maxRetryDelay`; the next verified reply resets it. Nothing is
///   ever shown to the driver for it.
///
/// Each slot ends one `VehicleDataPoll`: the charge, tire pressure or closures result
/// asked in it (if any), then drive state. A link or handshake failure on
/// that earlier category skips the slot's drive request and marks it
/// skipped, as `TeslaVehicleClient.pollVehicleData(_:)` does. A slot cut
/// short by a pause or by the last listener leaving leaves its slow
/// category due again.
///
/// 連線, 加入鑰匙 and 讀一次 go through the feed too; starting sessions,
/// adding a key and reading once pause the polling (the request in flight
/// is cancelled) and resume it afterwards. `suspend()` (background, lock)
/// stops everything and disconnects, ending a connect in progress;
/// `resume()` starts again.
public actor CarFeed {
    public struct Cadence: Sendable {
        /// The shortest time from one drive request to the next.
        public var driveInterval: Duration
        /// How often charge state, tire pressure and closures are each asked.
        public var slowInterval: Duration
        /// The first quiet-retry wait; it doubles up to `maxRetryDelay`.
        public var retryDelay: Duration
        public var maxRetryDelay: Duration
        /// How long CoreBluetooth's own reconnect may take before the feed
        /// cancels it and connects again itself.
        public var systemReconnectGrace: Duration

        public init(
            driveInterval: Duration = .milliseconds(200),
            slowInterval: Duration = .seconds(10),
            retryDelay: Duration = .seconds(1),
            maxRetryDelay: Duration = .seconds(10),
            systemReconnectGrace: Duration = .seconds(15)
        ) {
            self.driveInterval = driveInterval
            self.slowInterval = slowInterval
            self.retryDelay = retryDelay
            self.maxRetryDelay = maxRetryDelay
            self.systemReconnectGrace = systemReconnectGrace
        }
    }

    /// The Car Bluetooth link, as the feed sees it.
    public enum LinkStatus: Sendable, Equatable {
        /// Down, and the feed is not trying (nothing to connect to, nobody
        /// listening, suspended, or disconnected on request).
        case idle
        /// Down, and the feed is connecting; it has not been up since.
        case connecting
        case connected
        /// It was up and dropped; the feed may be reconnecting.
        case lost
    }

    /// Asked for once per `Cadence.slowInterval`, between drive requests.
    public static let slowCategories: [VehicleDataCategory] = [.charge, .tirePressure, .closures]
    /// What 讀一次 asks for: every category, drive state last.
    public static let allCategories: [VehicleDataCategory] = [.charge, .tirePressure, .closures, .drive]

    public nonisolated let cadence: Cadence
    private nonisolated let client: TeslaVehicleClient
    private let clock: any CarFeedClock
    private nonisolated let clientEvents = Broadcast<TeslaClientEvent>()
    private nonisolated let pollResults = Broadcast<VehicleDataPoll>()
    private nonisolated let linkStatuses = Broadcast<LinkStatus>(latest: .idle)

    private var pump: Task<Void, Never>?
    private var loop: Task<Void, Never>?
    private var keeper: Task<Void, Never>?
    /// Set by every change that may start polling; lets a loop that is
    /// ending notice one that arrived meanwhile.
    private var kicked = false
    /// A cancelled keeper is still ending while the link is wanted again.
    private var relink = false
    /// Running 加入鑰匙 / 讀一次 calls.
    private var pauses = 0
    /// Background or locked: no polling, no connecting.
    private var suspended = false
    /// Disconnected on request: no connecting until `connect(vin:)` or `resume()`.
    private var holdDisconnected = false
    private var connectCalls = 0
    /// The link dropped and CoreBluetooth is reconnecting on its own.
    private var systemReconnecting = false
    private var status = LinkStatus.idle
    /// The next quiet-retry wait; nil means `cadence.retryDelay`.
    private var nextRetryDelay: Duration?
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
        keeper?.cancel()
        clientEvents.finish()
        pollResults.finish()
        linkStatuses.finish()
    }

    /// The client's timeouts and settings, for logs.
    public nonisolated var configuration: TeslaVehicleClient.Configuration {
        client.configuration
    }

    // MARK: Listening

    /// Every client event (connects, requests, frames …) and the feed's own
    /// reconnect events, for any number of subscribers. Keeps the newest
    /// 1,000 per subscriber while it is not read. Nothing is replayed: a late
    /// subscriber gets the current link from `linkStatusUpdates()`.
    public nonisolated func events() -> AsyncStream<TeslaClientEvent> {
        clientEvents.subscribe()
    }

    /// One poll per slot (drive request) while the stream is alive. The feed
    /// keeps the link up and polls while at least one of these is alive.
    public nonisolated func polls() -> AsyncStream<VehicleDataPoll> {
        pollResults.subscribe { [weak self] in
            Task { await self?.updatePolling() }
        }
    }

    /// The current link status first, then every change.
    public nonisolated func linkStatusUpdates() -> AsyncStream<LinkStatus> {
        linkStatuses.subscribe()
    }

    // MARK: Connection

    public var isConnected: Bool {
        get async { await client.isConnected }
    }

    public var linkStatus: LinkStatus { status }

    /// The paired car's VIN (`TeslaVehicleClient.storedPairedVIN`).
    public var pairedVIN: String? {
        get async { await client.storedPairedVIN }
    }

    /// The VIN of the car the link is up to; nil while it is down.
    public var connectedVIN: String? {
        get async { await client.connectedVIN }
    }

    /// The car the feed connects to while someone listens: the last `connect(vin:)`,
    /// else the paired car.
    public var targetVIN: String? {
        get async {
            if let vin = await client.vin { return vin }
            return await client.storedPairedVIN
        }
    }

    /// Makes `vin` the paired car (`TeslaVehicleClient.storePairedVIN(_:)`).
    /// From then on the feed connects to it whenever it has no other car.
    public func storePairedVIN(_ vin: String) async throws {
        try await client.storePairedVIN(vin)
    }

    /// Connects to `vin` now, ending a reconnect attempt in progress. After a
    /// drop the feed reconnects to it while someone listens. Throws
    /// `.cancelled` when `suspend()` came meanwhile: the link stays down.
    public func connect(vin: String) async throws {
        startPumpIfNeeded()
        connectCalls += 1
        holdDisconnected = false
        defer {
            connectCalls -= 1
            updatePolling()
        }
        await stopKeeper()
        do {
            try await client.connect(vin: vin)
        } catch {
            // suspend() disconnected it.
            if suspended { throw TeslaClientError.cancelled }
            throw error
        }
        // The app left the front while it connected: no link in the background (L60).
        if suspended {
            await client.disconnect()
            throw TeslaClientError.cancelled
        }
    }

    /// Disconnects and forgets the car of the last `connect(vin:)` (a pairing
    /// that did not finish): from now on the feed connects to the paired car,
    /// if any, while someone listens.
    public func returnToPairedCar() async {
        startPumpIfNeeded()
        holdDisconnected = false
        // Like `suspend()`: the request in flight is cancelled, not answered on a link going down.
        await stopLoop()
        await stopKeeper()
        await client.disconnect(forgettingVIN: true)
        updatePolling()
    }

    /// Disconnects; the feed does not reconnect until `connect(vin:)` or `resume()`.
    public func disconnect() async {
        startPumpIfNeeded()
        holdDisconnected = true
        // Like `suspend()`: the request in flight is cancelled, not answered on a link going down.
        await stopLoop()
        await stopKeeper()
        await client.disconnect()
    }

    /// `TeslaVehicleClient.startSessions(_:)`, with polling paused until it
    /// ends, so its handshakes are never in flight with a poll's request.
    public func startSessions() async throws {
        await pausePolling()
        defer { resumePolling() }
        try await client.startSessions()
    }

    /// The app left the front, or the phone locked: stops polling and
    /// reconnecting, and disconnects.
    public func suspend() async {
        startPumpIfNeeded()
        suspended = true
        await stopLoop()
        await stopKeeper()
        // A 連線 still scanning is ended too (CoreBluetoothLink stops the scan).
        let connected = await client.isConnected
        if connected || connectCalls > 0 || systemReconnecting { await client.disconnect() }
    }

    /// The app is in front again: connects and polls again while someone listens.
    public func resume() {
        suspended = false
        holdDisconnected = false
        updatePolling()
    }

    /// `TeslaVehicleClient.enrollKey(onStateChange:)`, with polling paused
    /// until it ends.
    public func enrollKey(onStateChange: @Sendable (EnrollmentState) -> Void = { _ in }) async throws {
        await pausePolling()
        defer { resumePolling() }
        try await client.enrollKey(onStateChange: onStateChange)
    }

    /// Asks every category once, drive state last, with polling paused. The
    /// result goes to the caller only. It counts as asking the slow
    /// categories: the next slots ask them `slowInterval` later.
    public func readOnce() async -> VehicleDataPoll {
        await pausePolling()
        defer { resumePolling() }
        let askedAt = clock.now
        let poll = await client.pollVehicleData(Self.allCategories)
        for category in Self.slowCategories { slowAskedAt[category] = askedAt }
        // Its drive request was sent before now: the next one waits from here.
        lastDriveSentAt = clock.now
        if poll.hasVerifiedReply { nextRetryDelay = nil }
        return poll
    }

    // MARK: Polling

    private var wantsPolling: Bool {
        !suspended && pauses == 0 && pollResults.count > 0
    }

    private var wantsLink: Bool {
        wantsPolling && !holdDisconnected && connectCalls == 0
    }

    /// Starts the loop and the keeper when they are wanted and not running;
    /// stops them when they are no longer wanted.
    private func updatePolling() {
        startPumpIfNeeded()
        kicked = true
        guard wantsPolling else {
            loop?.cancel()
            keeper?.cancel()
            return
        }
        if loop == nil { loop = Task { await self.run() } }
        if wantsLink {
            if let keeper {
                if keeper.isCancelled { relink = true }
            } else {
                keeper = Task { await self.keepLink() }
            }
        }
    }

    private func run() async {
        // The first request after polling (re)starts is drive state.
        lastSentWasDrive = false
        while !Task.isCancelled {
            // Cleared only by a loop that goes on, so a cancelled loop keeps
            // the signal of a listener or connect that arrived meanwhile.
            kicked = false
            let connected = await client.isConnected
            guard !Task.isCancelled, wantsPolling, connected else { break }
            let poll = await cycle()
            pollResults.yield(poll)
            if poll.hasVerifiedReply {
                nextRetryDelay = nil
            } else if let failure = poll.firstError, !Task.isCancelled, failure != .cancelled, !Self.isLinkDown(failure) {
                do { try await waitToRetry() } catch { break }
            }
        }
        loop = nil
        // A connect or a new listener arrived while this loop was ending.
        if kicked, wantsPolling { updatePolling() }
    }

    /// One slot: one slow category when due (only right after a drive
    /// request), then drive state.
    private func cycle() async -> VehicleDataPoll {
        var entries: [VehicleDataPoll.Entry] = []
        /// The slow category asked in this slot, and when it was asked before.
        var asked: (category: VehicleDataCategory, before: ContinuousClock.Instant?)?
        /// Cancelled before drive state came back: the slot writes no row,
        /// so its slow category is due again.
        func cancelled() -> VehicleDataPoll {
            if let asked { slowAskedAt[asked.category] = asked.before }
            return VehicleDataPoll(entries: entries)
        }
        if lastSentWasDrive, let slow = dueSlowCategory() {
            asked = (slow, slowAskedAt[slow])
            slowAskedAt[slow] = clock.now
            lastSentWasDrive = false
            let result = await fetch(slow)
            entries.append(.init(category: slow, result: result))
            if case .failure(let failure) = result {
                if failure == .cancelled || Task.isCancelled { return cancelled() }
                if TeslaVehicleClient.endsPoll(failure) { return VehicleDataPoll(entries: entries, skipped: [.drive]) }
            }
        }
        if let lastDriveSentAt {
            do {
                try await clock.sleep(until: lastDriveSentAt + cadence.driveInterval)
            } catch {
                entries.append(.init(category: .drive, result: .failure(.cancelled)))
                return cancelled()
            }
        }
        // Stamped again each time the request itself goes out, so a handshake
        // or a resend inside the fetch moves the next drive request back too.
        lastDriveSentAt = clock.now
        lastSentWasDrive = true
        let sent = SendTime()
        let clock = clock
        let drive = await fetch(.drive) { sent.set(clock.now) }
        if let sentAt = sent.value { lastDriveSentAt = sentAt }
        entries.append(.init(category: .drive, result: drive))
        if drive == .failure(.cancelled) { return cancelled() }
        return VehicleDataPoll(entries: entries)
    }

    /// The slow category asked longest ago (never asked first, in
    /// `slowCategories` order), if `slowInterval` has passed since.
    private func dueSlowCategory() -> VehicleDataCategory? {
        let now = clock.now
        for category in Self.slowCategories where slowAskedAt[category] == nil {
            return category
        }
        let oldest = Self.slowCategories.min { slowAskedAt[$0]! < slowAskedAt[$1]! }!
        return now - slowAskedAt[oldest]! >= cadence.slowInterval ? oldest : nil
    }

    private func fetch(
        _ category: VehicleDataCategory,
        onRequestSent: (@Sendable () -> Void)? = nil
    ) async -> Result<VehicleDataResponse, TeslaClientError> {
        do {
            return .success(try await client.fetchVehicleDataResponse(category, onRequestSent: onRequestSent))
        } catch {
            return .failure(TeslaVehicleClient.clientError(error))
        }
    }

    /// Failures that mean the link is down: the keeper handles those.
    private static func isLinkDown(_ failure: TeslaClientError) -> Bool {
        switch failure {
        case .notConnected, .disconnected, .link: true
        default: false
        }
    }

    /// Sleeps the next quiet-retry wait, and doubles the one after it.
    private func waitToRetry() async throws {
        let wait = nextRetryDelay ?? cadence.retryDelay
        nextRetryDelay = min(wait * 2, cadence.maxRetryDelay)
        try await clock.sleep(until: clock.now + wait)
    }

    /// Stops the loop (cancelling the request in flight) and waits until it
    /// has ended.
    private func pausePolling() async {
        startPumpIfNeeded()
        pauses += 1
        await stopLoop()
        await stopKeeper()
    }

    private func resumePolling() {
        pauses -= 1
        updatePolling()
    }

    private func stopLoop() async {
        guard let loop else { return }
        loop.cancel()
        await loop.value
    }

    // MARK: Keeping the link up

    private func stopKeeper() async {
        guard let keeper else { return }
        keeper.cancel()
        await keeper.value
    }

    private func keepLink() async {
        await reconnect()
        keeper = nil
        if relink {
            relink = false
            updatePolling()
        }
    }

    /// Connects until the link is up, with quiet retries. Waits out a
    /// system reconnect first.
    private func reconnect() async {
        var attempt = 0
        while !Task.isCancelled, wantsLink {
            if await client.isConnected { return }
            // The link went down but its event is still on the way: its
            // handler starts the keeper again, knowing whether CoreBluetooth
            // reconnects by itself.
            if status == .connected { return }
            if systemReconnecting {
                do {
                    try await clock.sleep(until: clock.now + cadence.systemReconnectGrace)
                } catch {
                    return
                }
                guard !Task.isCancelled, wantsLink, systemReconnecting else { continue }
                if await client.isConnected { return }
                emit(.systemReconnectStalled(graceMs: LogDuration.ms(cadence.systemReconnectGrace)))
                // End CoreBluetooth's own reconnect first, so it does not tear down this one.
                systemReconnecting = false
                await client.disconnect()
                continue
            }
            var target = await client.vin
            if target == nil { target = await client.storedPairedVIN }
            guard let vin = target else { return }
            attempt += 1
            emit(.autoReconnect(attempt: attempt))
            if status != .lost { setStatus(.connecting) }
            do {
                try await client.connect(vin: vin)
                return
            } catch {
                let failure = TeslaVehicleClient.clientError(error)
                if failure == .cancelled || Task.isCancelled {
                    emit(.autoReconnectCancelled(attempt: attempt))
                    if status == .connecting { setStatus(.idle) }
                    return
                }
                emit(.autoReconnectFailed(attempt: attempt, failure))
            }
            do { try await waitToRetry() } catch { return }
        }
    }

    // MARK: Events

    private func emit(_ kind: TeslaClientEvent.Kind) {
        clientEvents.yield(TeslaClientEvent(kind: kind))
    }

    private func setStatus(_ next: LinkStatus) {
        guard next != status else { return }
        status = next
        linkStatuses.publish(next)
    }

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
        case .connected, .reconnected:
            systemReconnecting = false
            // The first request on a new link is drive state, even when the
            // loop never saw the link down.
            lastSentWasDrive = false
            setStatus(.connected)
            // A keeper waiting out a system reconnect is no longer needed.
            keeper?.cancel()
            updatePolling()
        case .disconnected(let reconnecting, let reason):
            systemReconnecting = reconnecting
            if reason == TeslaVehicleClient.requestedDisconnectReason {
                // A keeper's own disconnect (after a stalled system reconnect) is still a lost link.
                setStatus(keeper == nil ? .idle : .lost)
            } else {
                setStatus(.lost)
            }
            // Also after a requested one: a resume may have come meanwhile.
            updatePolling()
        default:
            break
        }
    }
}

extension VehicleDataPoll {
    /// At least one category came back verified.
    var hasVerifiedReply: Bool {
        entries.contains { if case .success = $0.result { true } else { false } }
    }
}

/// When a request went out, set from the client's actor.
private final class SendTime: @unchecked Sendable {
    private let lock = NSLock()
    private var instant: ContinuousClock.Instant?

    var value: ContinuousClock.Instant? { lock.withLock { instant } }
    func set(_ value: ContinuousClock.Instant) { lock.withLock { instant = value } }
}

/// Fans one stream of values out to any number of `AsyncStream`s.
final class Broadcast<Element: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuations: [UUID: AsyncStream<Element>.Continuation] = [:]
    /// Given first to every new stream, when set.
    private var latest: Element?

    init(latest: Element? = nil) {
        self.latest = latest
    }

    var count: Int { lock.withLock { continuations.count } }

    /// A new stream; `onChange` runs after it is added and after it ends.
    func subscribe(onChange: @escaping @Sendable () -> Void = {}) -> AsyncStream<Element> {
        let id = UUID()
        let (stream, continuation) = AsyncStream.makeStream(of: Element.self, bufferingPolicy: .bufferingNewest(1000))
        continuation.onTermination = { [weak self] _ in
            self?.remove(id)
            onChange()
        }
        lock.withLock {
            continuations[id] = continuation
            if let latest { continuation.yield(latest) }
        }
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

    /// Yields `element` and keeps it for streams that start later.
    func publish(_ element: Element) {
        lock.withLock {
            latest = element
            for continuation in continuations.values { continuation.yield(element) }
        }
    }

    /// Ends every stream.
    func finish() {
        for continuation in lock.withLock({ Array(continuations.values) }) {
            continuation.finish()
        }
    }
}
