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

/// The bottom-left battery / range block (L33, L50); the drive screen hides it with nil.
public enum BatteryBlock: Equatable, Sendable {
    /// `—% / — km`: no battery reading yet.
    case waiting
    /// Battery % and the car's rated range, whole, in km or in miles in mph mode. A part the
    /// car did not send is nil and shows as "—".
    case value(percent: Int?, range: Int?)
    /// The last battery reading is more than 60 s old: `—% / — km` on the drive screen; the parked
    /// screen keeps the value in `text.stale` with its own 「N 分鐘前」 line (L21).
    case stale(percent: Int?, range: Int?, ageMinutes: Int)
}

/// Drive or parked (L6, L31): only a fresh Car Bluetooth P chooses parked.
public enum ScreenLayout: Equatable, Sendable {
    case drive
    case parked
}

/// Everything the main screen shows. GPS speed never chooses the parked layout: only a fresh
/// Car Bluetooth P may (L6 item 5, 01 §3.5). `P R N D` and battery / range also need Car
/// Bluetooth and are not shown on GPS (L43, L50).
public struct HUDState: Equatable, Sendable {
    public static let noSpeedNumeral = "—"

    /// Digits, or "—" when there is no valid speed. Never a frozen value or a filler 0.
    public var numeral: String
    /// Shown under "—" in place of the unit; nil while a speed shows.
    public var reason: NoSpeedReason?
    public var unit: SpeedUnit
    public var source: SourceStatus
    /// The lit gear of the `P R N D` row; nil hides the whole row (L43).
    public var gearRow: CarGear? = nil
    /// Battery / range; nil hides the block.
    public var battery: BatteryBlock? = nil
    public var layout = ScreenLayout.drive
    /// The parked screen's tire panel; nil on the drive screen.
    public var tires: TirePanel? = nil

    public var hasSpeed: Bool { reason == nil }
    /// S06-f: parked with no speed shows 「P 檔」 large in the centre, and no `P R N D`.
    public var showsParkedGear: Bool { layout == .parked && !hasSpeed }
}

/// Folds location events and car events into the drive screen's state. `now` is passed in,
/// so expiry needs no new event: asking for the state later is enough.
///
/// Speed source (L7): the car's speed while valid, else GPS while valid, else "—".
/// - A car speed is valid for `carMaxAge` after the first reading with its car timestamp
///   reached the phone, and only with the car's own timestamp. A repeated car timestamp
///   is not a new reading (01 §3.2): it may update the shown value but never extends the
///   window, so a car whose drive state froze cannot keep a frozen number on screen. An
///   older car timestamp is ignored.
/// - The first valid car speed of a foreground session shows at once (cold start). After
///   it lapsed, the car is shown again only after `carReturnReadings` distinct, in-order
///   readings in a row (car timestamps strictly increasing, none expired in between); GPS
///   or "—" shows meanwhile.
///
/// Gear row (L43): the gear of the same drive readings, shown only while the car's speed is shown (or
/// parked, see below), and only after `carReturnReadings` distinct, in-order readings in a row with a known
/// gear, also on cold start. An unknown gear, a fresh P with a speed of 5 km/h or more, a lost
/// link or an idle one (disconnected on request) hides it until two more come.
///
/// Battery block (L33, L50): shown while a car link or reading came this foreground session
/// and GPS does not supply the speed. `—% / — km` until the first battery reading; stale (with
/// its value and age) once it is more than `batteryMaxAge` old; hidden once the link has been
/// lost for more than `linkLostMaxAge`, and at once when the feed stops trying (idle); a reply
/// that arrives after that does not bring it back until a new link status.
///
/// Parked layout (L6, L42, S04-i): after `carReturnReadings` distinct, in-order drive readings in
/// a row in P, with or without a speed, and only while the last of them is fresh (`carMaxAge`).
/// Anything that hides the gear row ends it too, except that it needs no speed; a P with no speed
/// of its own is judged against the speed on screen, GPS included, so any shown speed of 5 km/h or
/// more ends it. GPS never parks. Parked, P is lit whatever supplies the speed, and GPS supplying
/// it does not hide the battery block.
/// The tire panel shows the last tire reading of this foreground session, each wheel aged by the
/// car's own clock: `tireMaxAge` old or less is fresh.
public struct HUDEngine: Sendable {
    /// Speeds at or below this (m/s) show as 0, so stopped GPS jitter does not flicker.
    /// Applied to the shown value only; it never delays a reading. GPS only: the car's own
    /// speed has no dead-band.
    public static let stationaryMetersPerSecond = 0.5
    /// How long a car speed stays valid after it reached the phone.
    public static let carMaxAge: TimeInterval = 2
    /// Distinct, in-order car readings needed to go back to the car after it lapsed.
    public static let carReturnReadings = 2
    /// A P at this speed (whole km/h) or more contradicts the speed, so the gear row hides.
    public static let parkedMaxKilometersPerHour = 5
    /// How long a battery reading stays valid after it reached the phone.
    public static let batteryMaxAge: TimeInterval = 60
    /// The battery block hides once the link has been lost for longer than this.
    public static let linkLostMaxAge: TimeInterval = 10
    /// A tire reading is old after this, judged from the car's measurement time.
    public static let tireMaxAge: TimeInterval = 15 * 60

    public private(set) var processor: GPSSpeedProcessor
    private var authorization = LocationAuthorization.notDetermined
    /// A speed was shown and is gone, or the source failed while waiting after a resume.
    private var speedLost = false
    /// Background readings are void (01 §3.2): samples are ignored while suspended.
    private var suspended = false
    /// Set while suspended and after coming back, until the first new valid reading.
    private var awaitingResume = false

    /// The last accepted car speed, stamped with the phone receive time of the first
    /// reading that carried its car timestamp.
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
    /// The gear of the last drive reading (nil when unknown), valid like a car speed from the phone
    /// receive time of the first reading that carried its car timestamp. Tracked apart from the
    /// speed, so a reading with a gear and no speed still counts (「P 檔」).
    private var carGear: (gear: CarGear?, validFrom: Date)?
    private var lastGearTimestamp: Date?
    /// Distinct readings in a row with a known gear, since the gear row last hid.
    private var gearStreak = 0
    /// Distinct readings in a row in P and not moving, since the parked layout last ended.
    private var parkStreak = 0
    /// A car link status other than idle, or a reading, came this foreground session, and the
    /// link has not gone idle since.
    private var carLinked = false
    /// The feed reported `.idle` and no other status since. A reply that was in flight may still
    /// arrive: it never brings the battery block or the gear row back (its speed follows #46).
    private var linkIdle = false
    /// When the link was lost, until it is connected again.
    private var linkLostAt: Date?
    /// The last battery reading, stamped with its phone receive time.
    private var battery: (percent: Int?, rangeKilometers: Double?, receivedAt: Date)?
    /// The last tire reading, with the car's time of that reply and its phone receive time.
    private var tires: (tires: CarTires, carTime: Date?, receivedAt: Date)?

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
        carGear = nil
        lastGearTimestamp = nil
        gearStreak = 0
        parkStreak = 0
        carLinked = false
        linkIdle = false
        linkLostAt = nil
        battery = nil
        tires = nil
    }

    public mutating func handle(_ event: CarEvent, now: Date) {
        // Background readings and link statuses are void (01 §3.2); `resume` starts afresh.
        guard !suspended else { return }
        switch event {
        case .link(.notPaired):
            forgetCar()
        case .link(.lost):
            gearStreak = 0
            parkStreak = 0
            carLinked = true
            linkIdle = false
            if linkLostAt == nil { linkLostAt = now }
        case .link(.connected):
            carLinked = true
            linkIdle = false
            linkLostAt = nil
        case .link(.connecting):
            carLinked = true
            linkIdle = false
        case .link(.idle):
            // Not trying: nothing about the car is current, so the block and the gear row hide at once.
            carLinked = false
            linkIdle = true
            linkLostAt = nil
            gearStreak = 0
            parkStreak = 0
        case .reading(let reading):
            if !linkIdle {
                carLinked = true
                // Charge state may come without drive state; its freshness is its receive time.
                if reading.batteryPercent != nil || reading.rangeKilometers != nil {
                    battery = (reading.batteryPercent, reading.rangeKilometers, reading.receivedAt)
                }
                if let tires = reading.tires {
                    self.tires = (tires, reading.carTimestamp, reading.receivedAt)
                }
            }
            trackGear(reading, now: now)
            guard let speed = reading.speedMetersPerSecond, speed.isFinite,
                  let carTimestamp = reading.carTimestamp else { return }
            if let lastCarTimestamp, carTimestamp < lastCarTimestamp { return }
            let distinct = lastCarTimestamp.map { carTimestamp > $0 } ?? true
            let inARow = carSpeed?.isValid(at: now, maxAge: Self.carMaxAge) ?? false
            if !inARow {
                carTrusted = false
                carReturnStreak = 0
            }
            // A repeated car timestamp keeps the window of its first arrival.
            let validFrom = distinct ? reading.receivedAt : (carSpeed?.timestamp ?? reading.receivedAt)
            carSpeed = SpeedReading(metersPerSecond: speed, source: .carBluetooth, timestamp: validFrom)
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

    /// The gear of a drive reading (one with a gear or a speed), in order by car timestamp like the
    /// speed. A gap of more than `carMaxAge` between readings starts the count over.
    private mutating func trackGear(_ reading: CarReading, now: Date) {
        guard reading.gear != nil || reading.speedMetersPerSecond != nil,
              let carTimestamp = reading.carTimestamp else { return }
        if let lastGearTimestamp, carTimestamp < lastGearTimestamp { return }
        let distinct = lastGearTimestamp.map { carTimestamp > $0 } ?? true
        if !gearIsFresh(at: now) {
            gearStreak = 0
            parkStreak = 0
        }
        // A repeated car timestamp keeps the window of its first arrival.
        let validFrom = distinct ? reading.receivedAt : (carGear?.validFrom ?? reading.receivedAt)
        carGear = (reading.gear, validFrom)
        lastGearTimestamp = carTimestamp
        // A P that contradicts the speed hides the row like an unknown gear: 2 more readings bring
        // it back. Compared in whole km/h, whatever the unit; a P with no speed of its own is judged
        // against the speed on screen (the car's, or GPS).
        let speed = reading.speedMetersPerSecond.map { $0.isFinite ? Int(abs($0 * 3.6).rounded()) : nil }
            ?? shownKilometersPerHour(at: now)
        let parkWhileMoving = reading.gear == .park && (speed ?? 0) >= Self.parkedMaxKilometersPerHour
        if linkIdle || reading.gear == nil || parkWhileMoving {
            gearStreak = 0
        } else if distinct {
            gearStreak += 1
        }
        if linkIdle || reading.gear != .park || parkWhileMoving {
            parkStreak = 0
        } else if distinct {
            parkStreak += 1
        }
    }

    private func gearIsFresh(at now: Date) -> Bool {
        guard let carGear else { return false }
        let age = now.timeIntervalSince(carGear.validFrom)
        return age >= -GPSSpeedProcessor.futureTolerance && age <= Self.carMaxAge
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
        var state = speedState(at: now, unit: unit)
        if state.source == .valid(.carBluetooth), gearStreak >= Self.carReturnReadings {
            state.gearRow = carGear?.gear
        }
        // A speed that arrived after the last P (a GPS fix) can contradict it too.
        let parked = parkStreak >= Self.carReturnReadings && carGear?.gear == .park && gearIsFresh(at: now)
            && (shownKilometersPerHour(at: now) ?? 0) < Self.parkedMaxKilometersPerHour
        state.battery = batteryBlock(at: now, unit: unit, source: state.source, parked: parked)
        if parked {
            state.layout = .parked
            state.tires = .wheels(tireWheels(at: now))
            // The fresh car P chose this layout, so P shows whatever supplies the speed; with no
            // speed 「P 檔」 says it instead.
            state.gearRow = state.hasSpeed ? .park : nil
        }
        return state
    }

    /// The speed on screen at `now` (L7) in whole km/h, whatever the unit; nil for "—".
    private func shownKilometersPerHour(at now: Date) -> Int? {
        if carTrusted, let car = carSpeed, car.isValid(at: now, maxAge: Self.carMaxAge) {
            return Int((abs(car.metersPerSecond) * 3.6).rounded())
        }
        guard authorization != .denied, let gps = processor.speed(at: now) else { return nil }
        return Int(((gps.metersPerSecond <= Self.stationaryMetersPerSecond ? 0 : gps.metersPerSecond) * 3.6).rounded())
    }

    private func tireWheels(at now: Date) -> TireWheels {
        guard let tires else { return .noReadings }
        // The car's clock now: its time of the reply, plus the phone time since it arrived.
        let carNow = tires.carTime.map { $0 + now.timeIntervalSince(tires.receivedAt) } ?? now
        func wheel(_ tire: CarTire?) -> TireWheel {
            guard let tire else { return .missing }
            let psi = Int(tire.psi.rounded())
            guard let lastSeen = tire.lastSeen, carNow >= lastSeen else {
                return TireWheel(psi: psi, ageMinutes: nil, freshness: .unknownTime)
            }
            let age = carNow.timeIntervalSince(lastSeen)
            return TireWheel(psi: psi, ageMinutes: Int(age / 60), freshness: age <= Self.tireMaxAge ? .fresh : .old)
        }
        return TireWheels(frontLeft: wheel(tires.tires.frontLeft), frontRight: wheel(tires.tires.frontRight),
                          rearLeft: wheel(tires.tires.rearLeft), rearRight: wheel(tires.tires.rearRight))
    }

    /// Parked, GPS supplying the speed does not hide it: the fresh car P chose the layout.
    private func batteryBlock(at now: Date, unit: SpeedUnit, source: SourceStatus, parked: Bool) -> BatteryBlock? {
        guard carLinked, parked || (source != .valid(.gps) && source != .gpsFallback) else { return nil }
        if let linkLostAt, now.timeIntervalSince(linkLostAt) > Self.linkLostMaxAge { return nil }
        guard let battery else { return .waiting }
        let age = now.timeIntervalSince(battery.receivedAt)
        let range = battery.rangeKilometers.map { Int(unit.distance(fromKilometers: $0).rounded()) }
        guard age <= Self.batteryMaxAge else {
            return .stale(percent: battery.percent, range: range, ageMinutes: Int(age / 60))
        }
        return .value(percent: battery.percent, range: range)
    }

    private func speedState(at now: Date, unit: SpeedUnit) -> HUDState {
        // L9: denied location takes away GPS only, never a valid car speed.
        let car = carTrusted ? carSpeed.flatMap { $0.isValid(at: now, maxAge: Self.carMaxAge) ? $0 : nil } : nil
        if let car {
            // The car's own speed: its magnitude (reverse is never negative), no dead-band.
            let shown = abs(car.metersPerSecond)
            return HUDState(
                numeral: String(Int(unit.value(fromMetersPerSecond: shown).rounded())),
                reason: nil,
                unit: unit,
                source: .valid(.carBluetooth)
            )
        }

        let speed = authorization == .denied ? nil : processor.speed(at: now)
        let source: SourceStatus
        if speed != nil, carSeen {
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
            source: source
        )
        if let speed {
            let shown = speed.metersPerSecond <= Self.stationaryMetersPerSecond ? 0 : speed.metersPerSecond
            state.numeral = String(Int(unit.value(fromMetersPerSecond: shown).rounded()))
            state.reason = nil
        }
        return state
    }
}
