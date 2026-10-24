import Foundation
import HUDCore
import Observation

/// Feeds location events and car events into `HUDEngine` and republishes the drive screen's state.
/// A periodic tick re-reads the state, so an expired speed turns into "—" with no new event.
@MainActor @Observable
final class HUDViewModel {
    /// How often the state is re-read: a fix leaves the screen at most this long after it expires.
    static let defaultTick: Duration = .milliseconds(250)

    private(set) var state: HUDState
    var unit: SpeedUnit {
        didSet { refresh() }
    }

    private var engine: HUDEngine
    private var suspended = false
    private let now: () -> Date

    init(unit: SpeedUnit = .kilometersPerHour, engine: HUDEngine = HUDEngine(), now: @escaping () -> Date = Date.init) {
        self.unit = unit
        self.engine = engine
        self.now = now
        state = engine.state(at: now(), unit: unit)
    }

    func handle(_ event: LocationEvent) {
        engine.handle(event, now: now())
        refresh()
    }

    func handle(_ event: CarEvent) {
        engine.handle(event, now: now())
        refresh()
    }

    /// The scene went to the background: show "—" before the app-switcher snapshot is taken.
    func suspend() {
        suspended = true
        engine.suspend()
        refresh()
    }

    /// The scene is active again after the background: "◌ Waiting for speed" until a new valid reading.
    func resume() {
        guard suspended else { return }
        suspended = false
        engine.resume(now: now())
        refresh()
    }

    /// Re-evaluates the state at the current time.
    func refresh() {
        let next = engine.state(at: now(), unit: unit)
        if next != state { state = next }
    }

    /// Consumes `events` until they finish (then reports `.ended`) or the task is cancelled,
    /// refreshing every `tick` in between.
    func run(_ events: AsyncStream<LocationEvent>, tick: Duration = HUDViewModel.defaultTick) async {
        let ticker = startTicker(tick)
        defer { ticker.cancel() }
        for await event in events { handle(event) }
        if !Task.isCancelled { handle(.ended) }
    }

    /// Consumes car events until they finish or the task is cancelled, refreshing every
    /// `tick` in between, so a car speed expires even after the location stream ended.
    func run(car events: AsyncStream<CarEvent>, tick: Duration = HUDViewModel.defaultTick) async {
        let ticker = startTicker(tick)
        defer { ticker.cancel() }
        for await event in events { handle(event) }
    }

    private func startTicker(_ tick: Duration) -> Task<Void, Never> {
        Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: tick)
                self?.refresh()
            }
        }
    }
}
