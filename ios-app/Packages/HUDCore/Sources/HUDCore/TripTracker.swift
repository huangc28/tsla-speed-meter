import Foundation

/// The trip (L89): the drive screen's left panel and the parked screen's trip card. Values are
/// whole or to 0.1 as shown, so the state changes only when the screen does.
public struct TripSummary: Equatable, Sendable {
    /// In km, or miles in mph mode, rounded down to 0.1; nil shows "—": the trip is running and
    /// no speed is valid now (L84-3).
    public var distance: Double?
    /// Whole minutes since the trip started (`h:mm`), counting while there is no speed (L84-3);
    /// an ended trip's stops at its end.
    public var driveMinutes: Int
    /// Distance / drive time, whole km/h or mph; nil while the distance is "—". Parked only.
    public var averageSpeed: Int?
    /// The highest speed shown this trip, whole km/h or mph. Parked only.
    public var maxSpeed: Int
    /// The Car Bluetooth battery % now minus at the trip's start (−4 used, positive gained); nil
    /// hides the group: GPS only, or no battery % at the start. Parked only.
    public var batteryChange: Int?

    public init(distance: Double?, driveMinutes: Int, averageSpeed: Int?, maxSpeed: Int, batteryChange: Int?) {
        self.distance = distance
        self.driveMinutes = driveMinutes
        self.averageSpeed = averageSpeed
        self.maxSpeed = maxSpeed
        self.batteryChange = batteryChange
    }
}

/// What counts as one trip and what it adds up (L89). `HUDEngine` owns it and feeds it the speed on
/// screen (L7: the car's, else GPS) and the battery %, with the engine's own `now`.
///
/// - A trip starts at the first valid speed of the app run, and ends when the layout turns parked
///   (the auto-parked P). The ended trip stays, frozen, until the next one starts: at the first
///   valid speed of `restartKilometersPerHour` or more while not parked, so GPS jitter beside a
///   parked car does not replace it. None starts while the car's fresh gear is P, and a trip
///   whose highest shown speed stayed under `restartKilometersPerHour` is dropped when it ends, so
///   opening the app in a parked car (GPS jitter, a link blip) leaves no trip.
/// - GPS only: a valid speed above 0 after `gpsOnlyStop` with no speed above 0 and no Car Bluetooth
///   reading starts a new trip. A car that sends readings ends a trip only by parking.
/// - Distance is the shown speed held until the next one (left rectangles over a step function, so
///   exact), in m/s before rounding. Nothing is added while no speed is valid (L84-3).
/// - The battery % at the start is the fresh one known then (the engine passes only a battery %
///   within its 60 s window), else the first that arrives within `batteryStartGrace`: the car feed
///   asks drive state first and charge state a slot later.
struct TripTracker: Sendable {
    /// GPS only: this long with no speed above 0 starts a new trip at the next one.
    static let gpsOnlyStop: TimeInterval = 10 * 60
    /// A battery % arriving this soon after the start still counts as the start's (the car feed asks
    /// charge state at least once per 10 s).
    static let batteryStartGrace: TimeInterval = 10
    /// After a park, a new trip needs a shown speed of this much (whole km/h): the threshold at
    /// which a P counts as moving.
    static let restartKilometersPerHour = HUDEngine.parkedMaxKilometersPerHour

    /// `metersPerSecond` shows as `restartKilometersPerHour` or more, compared in whole km/h.
    private static func reachesRestart(_ metersPerSecond: Double) -> Bool {
        Int((metersPerSecond * 3.6).rounded()) >= restartKilometersPerHour
    }

    private var start: Date?
    private var end: Date?
    private var meters = 0.0
    private var maxMetersPerSecond = 0.0
    /// The last time a speed above 0 was shown this trip.
    private var lastMovingAt: Date?
    /// The last time a Car Bluetooth reading arrived, whatever trip.
    private var lastCarReadingAt: Date?
    private var batteryAtStart: Int?

    init() {}

    private var running: Bool { start != nil && end == nil }

    /// `speed` (m/s as shown, nil for "—") was on screen from `from` to `to`, with no event between.
    mutating func hold(_ speed: Double?, from: Date, to: Date) {
        guard running, let speed, to > from else { return }
        meters += speed * to.timeIntervalSince(from)
        maxMetersPerSecond = max(maxMetersPerSecond, speed)
        if speed > 0 { lastMovingAt = to }
    }

    /// After an event at `now`: `speed` is on screen (nil for "—"), `parked` is the layout, `inPark`
    /// says the car's fresh gear is P (parked or not yet) and `battery` is the battery % if it is
    /// fresh; `carReading` says the event was a Car Bluetooth reading.
    mutating func update(at now: Date, speed: Double?, parked: Bool, inPark: Bool, battery: Int?, carReading: Bool) {
        let moving = (speed ?? 0) > 0
        let mayBegin = !parked && !inPark
        if start == nil {
            if speed != nil, mayBegin { begin(at: now, battery: battery) }
        } else if end != nil {
            let restarts = speed.map(Self.reachesRestart) ?? false
            if restarts, mayBegin { begin(at: now, battery: battery) }
        } else if let start, moving, mayBegin {
            let stoppedSince = lastMovingAt ?? start
            let carSince = lastCarReadingAt.map { $0 > stoppedSince } ?? false
            if !carSince, now.timeIntervalSince(stoppedSince) >= Self.gpsOnlyStop { begin(at: now, battery: battery) }
        }
        if running {
            if parked {
                // A trip that never reached the restart speed (the app opened beside a parked car,
                // GPS jitter) is not kept.
                if Self.reachesRestart(maxMetersPerSecond) { end = now } else { start = nil }
            } else if let speed {
                maxMetersPerSecond = max(maxMetersPerSecond, speed)
                if moving { lastMovingAt = now }
            }
            if batteryAtStart == nil, let battery, let start, now.timeIntervalSince(start) <= Self.batteryStartGrace {
                batteryAtStart = battery
            }
        }
        if carReading { lastCarReadingAt = now }
    }

    private mutating func begin(at now: Date, battery: Int?) {
        start = now
        end = nil
        meters = 0
        maxMetersPerSecond = 0
        lastMovingAt = nil
        batteryAtStart = battery
    }

    /// The trip at `now`, with `speed` on screen and `battery` the last battery %; nil before the first.
    func summary(at now: Date, speed: Double?, battery: Int?, unit: SpeedUnit) -> TripSummary? {
        guard let start else { return nil }
        let seconds = max(0, (end ?? now).timeIntervalSince(start))
        // Rounded down like an odometer; the epsilon keeps 12.4 from reading as 12.3999….
        let distance = running && speed == nil ? nil
            : (unit.distance(fromKilometers: meters / 1000) * 10 + 1e-9).rounded(.down) / 10
        let average = distance.map { _ in
            seconds > 0 ? Int(unit.value(fromMetersPerSecond: meters / seconds).rounded()) : 0
        }
        return TripSummary(
            distance: distance,
            driveMinutes: Int(seconds / 60),
            averageSpeed: average,
            maxSpeed: Int(unit.value(fromMetersPerSecond: maxMetersPerSecond).rounded()),
            batteryChange: battery.flatMap { current in batteryAtStart.map { current - $0 } }
        )
    }
}
