import Foundation

/// The parked screen's tire panel (L42, DESIGN.md "Parked screen" → Tire pressure). The app
/// shows the readings and never judges a pressure normal or abnormal.
public enum TirePanel: Equatable, Sendable {
    /// The four wheels: a reading or `—` each, and the shared time line under the car.
    case wheels(TireWheels)
    /// A car confirmed to send no tire pressure: only the title and 「這台車沒有提供胎壓資料」.
    /// Hook: the engine never says this yet. A tire reply with no wheels in it reads as "no
    /// reading yet", because nothing tells a car without sensors from one whose sensors have not
    /// reported since it woke.
    case notSupported
}

/// Front left, front right, rear left, rear right.
public struct TireWheels: Equatable, Sendable {
    public var frontLeft: TireWheel
    public var frontRight: TireWheel
    public var rearLeft: TireWheel
    public var rearRight: TireWheel

    /// Before any tire reading: `—` × 4 and 「尚無讀值」.
    public static let noReadings = TireWheels(frontLeft: .missing, frontRight: .missing, rearLeft: .missing, rearRight: .missing)

    public init(frontLeft: TireWheel, frontRight: TireWheel, rearLeft: TireWheel, rearRight: TireWheel) {
        self.frontLeft = frontLeft
        self.frontRight = frontRight
        self.rearLeft = rearLeft
        self.rearRight = rearRight
    }

    public var all: [TireWheel] { [frontLeft, frontRight, rearLeft, rearRight] }

    /// The one time line under the car, based on the oldest wheel; "time unknown" wins
    /// (DESIGN.md "Shared time line"). Since L82 it also shows when every reading is fresh.
    public var summary: TireSummary {
        let present = all.filter { $0.psi != nil }
        guard !present.isEmpty else { return .noReadings }
        let unknown = present.filter { $0.freshness == .unknownTime }
        if !unknown.isEmpty { return unknown.count == present.count ? .timeUnknown : .someTimeUnknown }
        let oldest = present.compactMap(\.ageMinutes).max() ?? 0
        let old = present.filter { $0.freshness == .old }
        return .age(minutes: oldest, partial: !old.isEmpty && old.count < present.count)
    }
}

/// One wheel: whole psi, or `—` before its first reading.
public struct TireWheel: Equatable, Sendable {
    public var psi: Int?
    /// Whole minutes since the car measured it; nil with no reading or an unknown time.
    public var ageMinutes: Int?
    public var freshness: TireFreshness

    public static let missing = TireWheel(psi: nil, ageMinutes: nil, freshness: .missing)

    public init(psi: Int?, ageMinutes: Int?, freshness: TireFreshness) {
        self.psi = psi
        self.ageMinutes = ageMinutes
        self.freshness = freshness
    }

    /// Old and unknown-time readings dim to `tire.stale`, wheel by wheel (L21, R7-15).
    public var isDimmed: Bool { freshness == .old || freshness == .unknownTime }
}

public enum TireFreshness: Equatable, Sendable {
    /// Measured 15 minutes ago or less.
    case fresh
    /// Measured more than 15 minutes ago.
    case old
    /// The car gave no measurement time, or one in the future.
    case unknownTime
    /// No reading: `—`.
    case missing
}

/// The shared time line's wording.
public enum TireSummary: Equatable, Sendable {
    /// 「尚無讀值」: all four are `—`.
    case noReadings
    /// 「時間未知」: no reading has a time.
    case timeUnknown
    /// 「部分讀值時間未知」.
    case someTimeUnknown
    /// 「N 分鐘前」, the oldest reading; 「部分讀值 N 分鐘前」 when only some are old.
    case age(minutes: Int, partial: Bool)
}
