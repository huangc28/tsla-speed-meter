import Foundation

/// What the location provider says about permission.
public enum LocationAuthorization: Equatable, Sendable {
    case notDetermined
    case denied          // denied, restricted, or approximate location only (no usable speed)
    case authorized
}

/// Everything the GPS side can tell the HUD.
public enum LocationEvent: Equatable, Sendable {
    case authorization(LocationAuthorization)
    case sample(GPSSample)
    case failed          // a location error other than a denial
    case ended           // the location stream finished
}

/// The shape that pairs with the source chip's color and word (01 §3.4).
public enum SourceMarker: Equatable, Sendable {
    case valid           // ● filled
    case fallback        // ◐ half
    case waiting         // ◌ hollow
    case noSpeed         // ▲
}

/// What the source chip says: always the current speed source (L9).
public enum SourceStatus: Equatable, Sendable {
    case valid(SpeedSource)   // ● GPS
    case waiting              // ◌ Waiting for speed: cold start or back in the foreground (S04-g)
    case searchingGPS         // ▲ Searching for GPS…: no valid GPS speed since start (S05)
    case speedUnavailable     // ▲ Speed unavailable: speed expired, lost or stream ended (S05)
    case gpsUnavailable       // ▲ GPS unavailable: location permission denied (S05-b)

    public var marker: SourceMarker {
        switch self {
        case .valid: .valid
        case .waiting: .waiting
        case .searchingGPS, .speedUnavailable, .gpsUnavailable: .noSpeed
        }
    }
}

/// The reason text under "—" (L18 Q9, 01 §6.1).
public enum NoSpeedReason: Equatable, Sendable {
    case speedUnavailable     // 車速暫不可用 / Speed unavailable
    case gpsUnavailable       // GPS 不可用 / GPS unavailable
}

/// What the gauge draws: fill and needle at a speed (km/h, also in mph mode), or only
/// the dashed outline that must not look like 0 km/h (L39 Q39).
public enum GaugeFill: Equatable, Sendable {
    case live(kilometersPerHour: Double)
    case noData
}

/// Everything the drive screen shows. GPS speed never chooses a parked layout: only a
/// fresh Car Bluetooth P may (L6 item 5, 01 §3.5), so there is nothing to choose yet.
/// `P R N D` and battery / range also need Car Bluetooth and are not shown on GPS (L43, L50).
public struct HUDState: Equatable, Sendable {
    public static let noSpeedNumeral = "—"

    /// Digits, or "—" when there is no valid speed. Never a frozen value or a filler 0.
    public var numeral: String
    /// Shown under "—" in place of the unit; nil while a speed shows.
    public var reason: NoSpeedReason?
    public var unit: SpeedUnit
    public var source: SourceStatus
    public var gauge: GaugeFill

    public var hasSpeed: Bool { reason == nil }
}

/// Folds location events into the drive screen's state. `now` is passed in, so expiry
/// needs no new event: asking for the state later is enough.
public struct HUDEngine: Sendable {
    /// Speeds at or below this (m/s) show as 0, so stopped GPS jitter does not flicker.
    /// Applied to the shown value only; it never delays a reading.
    public static let stationaryMetersPerSecond = 0.5

    public private(set) var processor: GPSSpeedProcessor
    private var authorization = LocationAuthorization.notDetermined
    private var hadSpeed = false
    /// Set while suspended and after coming back, until the first new valid reading (01 §3.2).
    private var awaitingResume = false

    public init(processor: GPSSpeedProcessor = GPSSpeedProcessor()) {
        self.processor = processor
    }

    /// The app went to the background: drop the speed at once, so the app-switcher
    /// snapshot shows "—" and nothing from before comes back.
    public mutating func suspend() {
        processor.invalidate()
        awaitingResume = true
    }

    /// The app is active again: "◌ Waiting for speed" until the first new valid reading.
    public mutating func resume() {
        processor.invalidate()
        awaitingResume = true
    }

    public mutating func handle(_ event: LocationEvent, now: Date) {
        switch event {
        case .authorization(let value):
            authorization = value
            if value == .denied { processor.invalidate() }
        case .sample(let sample):
            if processor.ingest(sample, now: now) == nil {
                hadSpeed = true
                awaitingResume = false
            }
        case .failed, .ended:
            processor.invalidate()
        }
    }

    public func state(at now: Date, unit: SpeedUnit) -> HUDState {
        let speed = authorization == .denied ? nil : processor.speed(at: now)
        let source: SourceStatus
        if authorization == .denied {
            source = .gpsUnavailable
        } else if let speed {
            source = .valid(speed.source)
        } else if awaitingResume {
            source = .waiting
        } else if hadSpeed {
            source = .speedUnavailable
        } else if authorization == .notDetermined {
            source = .waiting
        } else {
            source = .searchingGPS
        }

        var state = HUDState(
            numeral: HUDState.noSpeedNumeral,
            reason: authorization == .denied ? .gpsUnavailable : .speedUnavailable,
            unit: unit,
            source: source,
            gauge: .noData
        )
        if let speed {
            let shown = speed.metersPerSecond <= Self.stationaryMetersPerSecond ? 0 : speed.metersPerSecond
            state.numeral = String(Int(unit.value(fromMetersPerSecond: shown).rounded()))
            state.reason = nil
            state.gauge = .live(kilometersPerHour: SpeedUnit.kilometersPerHour.value(fromMetersPerSecond: shown))
        }
        return state
    }
}
