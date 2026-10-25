import CoreGraphics

/// Drive-screen frames in screen points, origin top-left (01 §7.4, DESIGN.md Layout).
/// Reference sizes: 844×390 (side insets 59, bottom 21) and the 667×375 minimum.
public struct DriveLayout: Equatable, Sendable {
    public var gaugeArea: CGRect
    public var sourceChipOrigin: CGPoint
    /// Bottom-left battery / range block, reserved even while empty (L50).
    public var batterySlot: CGRect
    /// Top-right settings gear, its 48×48 hit area (DESIGN.md Layout).
    public var settingsGear: CGRect
    /// The lowest y content may use, above the home indicator.
    public var contentBottom: CGFloat

    public init(screen: CGSize, leftInset: CGFloat, rightInset: CGFloat, bottomInset: CGFloat) {
        // Both sides use the larger inset, so rotating 180° never shifts the layout.
        let side = max(leftInset, rightInset) + 16
        let bottom = screen.height - max(bottomInset, 16)
        let size: CGFloat = screen.width >= 844 ? 300 : 280
        gaugeArea = CGRect(x: ((screen.width - size) / 2).rounded(.down), y: 50, width: size, height: size)
        sourceChipOrigin = CGPoint(x: side, y: 16)
        let slotHeight: CGFloat = size == 300 ? 48 : 53
        batterySlot = CGRect(x: side, y: bottom - slotHeight, width: gaugeArea.minX - 12 - side, height: slotHeight)
        settingsGear = CGRect(x: screen.width - side - 48, y: 16, width: 48, height: 48)
        contentBottom = bottom
    }
}

/// Gauge C "fan" in gauge-area coordinates (DESIGN.md Gauge spec, `k = S / 300`).
public struct GaugeGeometry: Equatable, Sendable {
    public static let maxKilometersPerHour: Double = 240

    public let size: CGFloat
    public var k: CGFloat { size / 300 }
    public var center: CGPoint { CGPoint(x: size / 2, y: 157 * k) }
    public var outerRadius: CGFloat { 148 * k }
    public var innerRadius: CGFloat { 118 * k }
    /// Inner edge of the speed fill.
    public var fillInnerRadius: CGFloat { innerRadius + 10 * k }
    /// Ink center of the numeral: 2 below the area center (`S/2 − 6 + 8`).
    public var numeralCenterY: CGFloat { size / 2 + 2 }
    public var unitFontSize: CGFloat { (23 * k).rounded() }
    /// Unit ink center below the digit ink bottom.
    public var unitGap: CGFloat { 22 * k }
    /// Reason ink center below the digit ink bottom.
    public var reasonGap: CGFloat { 24 * k }

    public init(size: CGFloat) {
        self.size = size
    }

    /// Dial angle in degrees, counterclockwise from 3 o'clock: 0 km/h at 180 (left foot),
    /// 240 km/h at 0 (right foot). Speeds outside the dial are clamped.
    public func angle(forKilometersPerHour kmh: Double) -> Double {
        180 - 180 * min(max(kmh, 0), Self.maxKilometersPerHour) / Self.maxKilometersPerHour
    }

    /// The point at `radius` and `angle` (degrees, counterclockwise, y down on screen).
    public func point(radius: CGFloat, angle: Double) -> CGPoint {
        let t = angle * .pi / 180
        return CGPoint(x: center.x + radius * CGFloat(cos(t)), y: center.y - radius * CGFloat(sin(t)))
    }

    /// Two-digit size (176 / 164) for "—" and up to two digits; three digits 152 / 144.
    public func numeralFontSize(digits: Int) -> CGFloat {
        digits >= 3 ? (size < 300 ? 144 : 152) : (176 * k).rounded()
    }

    public func numeralTracking(digits: Int) -> CGFloat {
        digits >= 3 ? -6 : -1
    }
}
