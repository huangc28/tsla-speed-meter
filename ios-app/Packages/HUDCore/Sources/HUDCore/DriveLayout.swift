import CoreGraphics

/// Main-screen frames in screen points, origin top-left (01 §7.4, DESIGN.md Layout), for the drive
/// and the parked layout: both read the same `gaugeArea`, so switching never moves the gauge (L31).
/// Reference sizes: 844×390 (side insets 59, bottom 21) and the 667×375 minimum.
public struct DriveLayout: Equatable, Sendable {
    public var gaugeArea: CGRect
    public var sourceChipOrigin: CGPoint
    /// Bottom-left battery / range block, reserved even while empty (L50).
    public var batterySlot: CGRect
    /// The parked screen's battery / range block: the same column, three lines high, so the stale
    /// value's age line fits under it (the master's `battTopP`).
    public var parkedBatterySlot: CGRect
    /// The parked screen's tire panel, right of the gauge (L42).
    public var tirePanel: CGRect
    /// Top-right settings gear, its 48×48 hit area (DESIGN.md Layout).
    public var settingsGear: CGRect
    /// The lowest y content may use, above the home indicator.
    public var contentBottom: CGFloat
    /// `P R N D` baseline (#48), reserved so the row can appear without moving anything.
    public var gearRowBaselineY: CGFloat
    /// Car-status icon centers inside the ring (L87), reserved like the gear row.
    public var carStatusSlots: CarStatusSlots

    public init(screen: CGSize, leftInset: CGFloat, rightInset: CGFloat, bottomInset: CGFloat) {
        // Both sides use the larger inset, so rotating 180° never shifts the layout.
        let side = max(leftInset, rightInset) + 16
        let bottom = screen.height - max(bottomInset, 16)
        let size: CGFloat = screen.width >= 844 ? 300 : 280
        gaugeArea = CGRect(x: ((screen.width - size) / 2).rounded(.down), y: 50, width: size, height: size)
        sourceChipOrigin = CGPoint(x: side, y: 16)
        let slotHeight: CGFloat = size == 300 ? 48 : 53
        batterySlot = CGRect(x: side, y: bottom - slotHeight, width: gaugeArea.minX - 12 - side, height: slotHeight)
        let parkedSlotHeight: CGFloat = size == 300 ? 69 : 73
        parkedBatterySlot = CGRect(x: side, y: bottom - parkedSlotHeight, width: batterySlot.width, height: parkedSlotHeight)
        let tireX = gaugeArea.maxX + 13
        tirePanel = CGRect(x: tireX, y: 72, width: screen.width - side - tireX, height: size == 300 ? 288 : 272)
        settingsGear = CGRect(x: screen.width - side - 48, y: 16, width: 48, height: 48)
        contentBottom = bottom
        let gauge = GaugeGeometry(size: size)
        gearRowBaselineY = gaugeArea.minY + gauge.gearRowBaselineY
        carStatusSlots = CarStatusSlots(gaugeSize: size).offsetBy(gaugeArea.origin)
    }
}

/// Car-status icon centers (DESIGN.md "Car-status icons"): the car seen from the side, nose
/// to the left. A slot never moves when another icon lights or goes out.
public struct CarStatusSlots: Equatable, Sendable {
    public var frontTrunk: CGPoint
    public var door: CGPoint
    public var rearTrunk: CGPoint
    /// Top-center, above `P R N D`.
    public var customThreshold: CGPoint

    /// In gauge-area coordinates. The master places each size on its own (in 300 units, × k at 280).
    public init(gaugeSize: CGFloat) {
        let k = gaugeSize / 300
        func at(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * k, y: y * k) }
        if gaugeSize < 300 {
            frontTrunk = at(71.5, 233.5); door = at(152, 266.75); rearTrunk = at(227, 236.5)
        } else {
            frontTrunk = at(74.5, 235); door = at(152, 266.5); rearTrunk = at(224, 237.5)
        }
        customThreshold = at(150, 36.5)
    }

    func offsetBy(_ origin: CGPoint) -> CarStatusSlots {
        func moved(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x + origin.x, y: p.y + origin.y) }
        var slots = self
        slots.frontTrunk = moved(frontTrunk)
        slots.door = moved(door)
        slots.rearTrunk = moved(rearTrunk)
        slots.customThreshold = moved(customThreshold)
        return slots
    }
}

/// Gauge A in gauge-area coordinates (DESIGN.md "Main screen — direction A", `k = S / 300`):
/// a ring and a disc, with the numeral, unit and reason hung off fixed lines.
public struct GaugeGeometry: Equatable, Sendable {
    public let size: CGFloat
    public var k: CGFloat { size / 300 }
    public var center: CGPoint { CGPoint(x: size / 2, y: size / 2) }
    /// Center line of the ring's 2 px stroke.
    public var ringRadius: CGFloat { 139 * k }
    public var discRadius: CGFloat { ringRadius - 1 }
    /// One size for every speed and for "—" (L88).
    public var numeralFontSize: CGFloat { size < 300 ? 149 : 160 }
    /// `yc`: 3k above C's numeral center (`S/2 + 2`), so the group looks centered on the disc.
    public var numeralCenterY: CGFloat { size / 2 + 2 - 3 * k }
    /// Ink height of "0" at the numeral size. The unit, the reason and `P R N D` hang off it,
    /// so they never move with the digit count.
    public var zeroInkHeight: CGFloat { NumeralLayout.zeroInkHeight * numeralFontSize / 1000 }
    public var unitFontSize: CGFloat { (23 * k).rounded() }
    /// Unit ink center: `22k` below the ink of "0".
    public var unitCenterY: CGFloat { numeralCenterY + zeroInkHeight / 2 + 22 * k }
    /// Reason ink center under "—": `24k` below the ink of "0".
    public var reasonCenterY: CGFloat { numeralCenterY + zeroInkHeight / 2 + 24 * k }
    /// `P R N D` baseline: its 2 px underline, 3 below the baseline, ends 13 above the ink of "0".
    public var gearRowBaselineY: CGFloat { numeralCenterY - zeroInkHeight / 2 - 13 - 3 - 2 }

    public init(size: CGFloat) {
        self.size = size
    }
}

/// Where the speed numeral's digits go (L88, the master's `NUM15`): fixed cells 0.46 em wide,
/// so a digit's position depends only on the digit count and on whether the first digit is 1.
/// Coordinates are gauge-area points; each origin is a tabular glyph's origin on the baseline.
public struct NumeralLayout: Equatable, Sendable {
    /// Barlow Semi Condensed 400 tabular digits (`.tf`), in 1/1000 em: ink x range of each
    /// digit (all advances are 481) and the ink y range of "0".
    static let tabularInk: [Character: (min: CGFloat, max: CGFloat)] = [
        "0": (55, 426), "1": (74, 335), "2": (53, 434), "3": (49, 415), "4": (36, 439),
        "5": (65, 432), "6": (65, 432), "7": (49, 443), "8": (59, 422), "9": (49, 415),
    ]
    public static let zeroInk: (min: CGFloat, max: CGFloat) = (-10, 709)
    public static var zeroInkHeight: CGFloat { zeroInk.max - zeroInk.min }
    static let cell: CGFloat = 460
    /// The narrow 1 sits on its advance center, not its ink center.
    static let oneCenter: CGFloat = 240.5
    /// A 1 moves right when leading, in the middle of 11x, or last; a leading 1 moves the whole number left.
    static let leadingOne: CGFloat = 60, middleOne: CGFloat = 30, trailingOne: CGFloat = 20, leadingOneRecenter: CGFloat = 37

    public let fontSize: CGFloat
    /// The glyph origin x of each digit, left to right.
    public let digitOrigins: [CGFloat]
    public let baselineY: CGFloat

    /// Nil unless `digits` is one or more ASCII digits.
    public init?(digits: String, gaugeSize: CGFloat) {
        let s = Array(digits)
        guard !s.isEmpty, s.allSatisfy({ Self.tabularInk[$0] != nil }) else { return nil }
        let g = GaugeGeometry(size: gaugeSize)
        let u = g.numeralFontSize / 1000, n = s.count, w = Self.cell * u
        let leadsWithOne = n > 1 && s[0] == "1"
        var g0 = gaugeSize / 2 - CGFloat(n) * w / 2
        if leadsWithOne { g0 -= Self.leadingOneRecenter * u }
        digitOrigins = s.enumerated().map { i, d in
            let ink = Self.tabularInk[d]!
            var x = g0 + CGFloat(i) * w + w / 2 - (d == "1" ? Self.oneCenter : (ink.min + ink.max) / 2) * u
            if d == "1" && n > 1 {
                x += (i == 0 ? Self.leadingOne : i == n - 1 ? Self.trailingOne
                      : n == 3 && leadsWithOne ? Self.middleOne : 0) * u
            }
            return x
        }
        fontSize = g.numeralFontSize
        baselineY = g.numeralCenterY + 350 * u
    }
}
