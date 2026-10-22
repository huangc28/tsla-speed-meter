import Foundation

/// What the location provider says about permission.
public enum LocationAuthorization: Equatable, Sendable {
    case notDetermined
    case denied          // denied or restricted
    case authorized
}

/// Everything the GPS side can tell the HUD.
public enum LocationEvent: Equatable, Sendable {
    case authorization(LocationAuthorization)
    case sample(GPSSample)
    case failed          // a location error other than a denial
    case ended           // the location stream finished
}

/// Which screen the HUD shows. Only a fresh Car Bluetooth P may choose `.parked`
/// (L6 item 5, 01 §3.5); GPS speed, zero or not, never does.
public enum HUDLayout: Equatable, Sendable {
    case drive
    case parked
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
    case waiting              // ◌ Waiting for speed: permission not decided yet (S04-g)
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

/// Everything the drive screen shows.
public struct HUDState: Equatable, Sendable {
    public static let noSpeedNumeral = "—"

    public var layout: HUDLayout
    /// Digits, or "—" when there is no valid speed. Never a frozen value or a filler 0.
    public var numeral: String
    /// Shown under "—" in place of the unit; nil while a speed shows.
    public var reason: NoSpeedReason?
    public var unit: SpeedUnit
    public var source: SourceStatus
    public var gauge: GaugeFill
    /// `P R N D` needs a fresh Car Bluetooth gear; hidden as a whole on GPS (L43).
    public var showsGearRow: Bool
    /// Battery / range needs Car Bluetooth; the bottom-left slot stays empty on GPS (L50).
    public var showsBattery: Bool

    public var hasSpeed: Bool { reason == nil }
}

/// Folds location events into the drive screen's state. `now` is passed in, so expiry
/// needs no new event: asking for the state later is enough.
public struct HUDEngine: Sendable {
    public private(set) var processor: GPSSpeedProcessor
    private var authorization = LocationAuthorization.notDetermined
    private var hadSpeed = false

    public init(processor: GPSSpeedProcessor = GPSSpeedProcessor()) {
        self.processor = processor
    }

    public mutating func handle(_ event: LocationEvent, now: Date) {
        switch event {
        case .authorization(let value):
            authorization = value
            if value == .denied { processor.invalidate() }
        case .sample(let sample):
            if processor.ingest(sample, now: now) == nil { hadSpeed = true }
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
        } else if hadSpeed {
            source = .speedUnavailable
        } else if authorization == .notDetermined {
            source = .waiting
        } else {
            source = .searchingGPS
        }

        var state = HUDState(
            layout: .drive,
            numeral: HUDState.noSpeedNumeral,
            reason: authorization == .denied ? .gpsUnavailable : .speedUnavailable,
            unit: unit,
            source: source,
            gauge: .noData,
            showsGearRow: false,
            showsBattery: false
        )
        if let speed {
            state.numeral = String(Int(unit.value(fromMetersPerSecond: speed.metersPerSecond).rounded()))
            state.reason = nil
            state.gauge = .live(kilometersPerHour: SpeedUnit.kilometersPerHour.value(fromMetersPerSecond: speed.metersPerSecond))
        }
        return state
    }
}
