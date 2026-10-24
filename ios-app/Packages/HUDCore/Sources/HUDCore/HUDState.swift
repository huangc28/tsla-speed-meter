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
    case valid(SpeedSource)   // ● 車輛藍牙 / ● GPS
    case gpsFallback          // ◐ GPS · 藍牙資料過期: a car speed came this session and expired (DESIGN.md hardened states)
    case waiting              // ◌ Waiting for speed: cold start or back in the foreground (S04-g)
    case searchingGPS         // ▲ Searching for GPS…: no valid GPS speed since start (S05)
    case speedUnavailable     // ▲ Speed unavailable: speed expired, lost or stream ended (S05)
    case gpsUnavailable       // ▲ GPS unavailable: location permission denied (S05-b)

    public var marker: SourceMarker {
        switch self {
        case .valid: .valid
        case .gpsFallback: .fallback
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

/// Folds location events and car events into the drive screen's state. `now` is passed in,
/// so expiry needs no new event: asking for the state later is enough.
///
/// Speed source (L7): the car's speed while valid, else GPS while valid, else "—".
/// - A car speed is valid for `carMaxAge` after it reached the phone, and only with the
///   car's own timestamp. A car timestamp older than the last one is ignored; a repeated
///   one still updates and renews the speed.
/// - The first valid car speed of a foreground session shows at once (cold start). After
///   it lapsed, the car is shown again only after `carReturnReadings` distinct, in-order
///   readings in a row (car timestamps strictly increasing, none expired in between); GPS
///   or "—" shows meanwhile.
public struct HUDEngine: Sendable {
    /// Speeds at or below this (m/s) show as 0, so stopped GPS jitter does not flicker.
    /// Applied to the shown value only; it never delays a reading. GPS only: the car's own
    /// speed has no dead-band.
    public static let stationaryMetersPerSecond = 0.5
    /// How long a car speed stays valid after it reached the phone.
    public static let carMaxAge: TimeInterval = 2
    /// Distinct, in-order car readings needed to go back to the car after it lapsed.
    public static let carReturnReadings = 2

    public private(set) var processor: GPSSpeedProcessor
    private var authorization = LocationAuthorization.notDetermined
    /// A speed was shown and is gone, or the source failed while waiting after a resume.
    private var speedLost = false
    /// Background readings are void (01 §3.2): samples are ignored while suspended.
    private var suspended = false
    /// Set while suspended and after coming back, until the first new valid reading.
    private var awaitingResume = false

    /// The last accepted car speed, stamped with its phone receive time.
    private var carSpeed: SpeedReading?
    private var lastCarTimestamp: Date?
    /// The car is the speed source whenever its speed is valid; cleared when it lapses.
    private var carTrusted = false
    /// The car was trusted this foreground session, so a lapse needs the return readings.
    private var carTrustedThisSession = false
    /// Distinct readings in a row since the car lapsed.
    private var carReturnStreak = 0
    /// A car speed arrived this foreground session: GPS then shows as the fallback (◐).
    private var carSeen = false

    public init(processor: GPSSpeedProcessor = GPSSpeedProcessor()) {
        self.processor = processor
    }

    /// The app went to the background: drop the speed at once, so the app-switcher
    /// snapshot shows "—" and nothing from before comes back.
    public mutating func suspend() {
        processor.invalidate()
        suspended = true
        awaitingResume = true
        forgetCar()
    }

    /// The app is active again at `now`: "◌ Waiting for speed" until the first valid reading
    /// taken after this moment; fixes stamped earlier are background readings and void.
    /// Car Bluetooth starts a new foreground session: its first valid speed shows at once.
    public mutating func resume(now: Date) {
        processor.invalidate(rejectingFixesBefore: now)
        suspended = false
        awaitingResume = true
        forgetCar()
    }

    private mutating func forgetCar() {
        carSpeed = nil
        lastCarTimestamp = nil
        carTrusted = false
        carTrustedThisSession = false
        carReturnStreak = 0
        carSeen = false
    }

    public mutating func handle(_ event: CarEvent, now: Date) {
        switch event {
        case .link(.notPaired):
            forgetCar()
        case .link:
            break
        case .reading(let reading):
            guard !suspended, let speed = reading.speedMetersPerSecond, speed.isFinite,
                  let carTimestamp = reading.carTimestamp else { return }
            if let lastCarTimestamp, carTimestamp < lastCarTimestamp { return }
            let distinct = lastCarTimestamp.map { carTimestamp > $0 } ?? true
            let inARow = carSpeed?.isValid(at: now, maxAge: Self.carMaxAge) ?? false
            if !inARow {
                carTrusted = false
                carReturnStreak = 0
            }
            carSpeed = SpeedReading(metersPerSecond: speed, source: .carBluetooth, timestamp: reading.receivedAt)
            lastCarTimestamp = carTimestamp
            carSeen = true
            guard !carTrusted else { return }
            if carTrustedThisSession {
                if distinct { carReturnStreak += 1 }
                guard carReturnStreak >= Self.carReturnReadings else { return }
            }
            carTrusted = true
            carTrustedThisSession = true
            carReturnStreak = 0
        }
    }

    public mutating func handle(_ event: LocationEvent, now: Date) {
        switch event {
        case .authorization(let value):
            authorization = value
            if value == .denied { processor.invalidate() }
        case .sample(let sample):
            guard !suspended else { return }
            if processor.ingest(sample, now: now) == nil {
                speedLost = true // shown from here on whenever this speed is gone
                awaitingResume = false
            }
        case .failed, .ended:
            processor.invalidate()
            // A failure says more than "waiting": the source is known to be broken.
            if awaitingResume && !suspended {
                awaitingResume = false
                speedLost = true
            }
        }
    }

    public func state(at now: Date, unit: SpeedUnit) -> HUDState {
        // L9: denied location takes away GPS only, never a valid car speed.
        let car = carTrusted ? carSpeed.flatMap { $0.isValid(at: now, maxAge: Self.carMaxAge) ? $0 : nil } : nil
        if let car {
            // The car's own speed: its magnitude (reverse is never negative), no dead-band.
            let shown = abs(car.metersPerSecond)
            return HUDState(
                numeral: String(Int(unit.value(fromMetersPerSecond: shown).rounded())),
                reason: nil,
                unit: unit,
                source: .valid(.carBluetooth),
                gauge: .live(kilometersPerHour: SpeedUnit.kilometersPerHour.value(fromMetersPerSecond: shown))
            )
        }

        let speed = authorization == .denied ? nil : processor.speed(at: now)
        let source: SourceStatus
        if let speed, carSeen {
            source = .gpsFallback
        } else if carSeen {
            source = .speedUnavailable
        } else if authorization == .denied {
            source = .gpsUnavailable
        } else if let speed {
            source = .valid(speed.source)
        } else if awaitingResume {
            source = .waiting
        } else if speedLost {
            source = .speedUnavailable
        } else if authorization == .notDetermined {
            source = .waiting
        } else {
            source = .searchingGPS
        }

        var state = HUDState(
            numeral: HUDState.noSpeedNumeral,
            reason: authorization == .denied && !carSeen ? .gpsUnavailable : .speedUnavailable,
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
