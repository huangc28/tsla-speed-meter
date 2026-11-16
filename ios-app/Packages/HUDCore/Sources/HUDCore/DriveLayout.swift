import CoreGraphics

/// Main-screen frames in screen points, origin top-left (01 §7.4, DESIGN.md Layout), for the drive
/// and the parked layout: both draw the same gauge, so switching never moves it (L31).
/// Reference sizes: 844×390 (side insets 59, bottom 21) and the 667×375 minimum.
///
/// The round gauge (#98) lives on `canvas`, the 844 × 390 design scaled uniformly; the panels, the
/// footer and the top row keep their frames for now and only make room for the ring (#100 moves them
/// onto the canvas too).
public struct DriveLayout: Equatable, Sendable {
    /// The design canvas the gauge is drawn on.
    public var canvas: DesignCanvas
    /// The ring's box on the screen, rounded out to whole points.
    public var gaugeArea: CGRect
    public var sourceChipOrigin: CGPoint
    /// Bottom-left battery / range block, reserved even while empty (L50).
    public var batterySlot: CGRect
    /// The parked screen's battery / range block: the same column, three lines high, so the stale
    /// value's age line fits under it (the master's `battTopP`).
    public var parkedBatterySlot: CGRect
    /// The parked screen's tire panel, right of the gauge (L42).
    public var tirePanel: CGRect
    /// The left panel, the same frame in both layouts: the drive screen's trip, centered in it (L80),
    /// and the parked trip card from its top; it ends 4 above the parked battery slot (the master's
    /// `LW` and `scrollB`).
    public var leftPanel: CGRect
    /// The drive screen's right panel (#77, the master's `RW`): as high as the left one, from 12 right
    /// of gauge A's box to the content's right edge.
    public var rightPanel: CGRect
    /// Top-right settings gear, its 48×48 hit area (DESIGN.md Layout).
    public var settingsGear: CGRect
    /// The parked top row's outside temperature (#79, the master's `tempG`): 76 wide, its content
    /// right-aligned 12 left of the gear, on the source chip's 28-high line (x 633 at 844, 515 at 667).
    public var temperatureSlot: CGRect
    /// The lowest y content may use, above the home indicator.
    public var contentBottom: CGFloat

    /// The panels stay this far outside the ring's centre line, in design points: at 844 and 667 that
    /// is where gauge A's box left them, so only larger screens pull them back.
    public static let panelClearance: CGFloat = 6

    public init(screen: CGSize, leftInset: CGFloat, rightInset: CGFloat, bottomInset: CGFloat) {
        // Both sides use the larger inset, so rotating 180° never shifts the layout.
        let side = max(leftInset, rightInset) + 16
        let bottom = screen.height - max(bottomInset, 16)
        canvas = DesignCanvas(screen: screen)
        let r = RoundGauge.radius, c = RoundGauge.center
        let ring = canvas.rect(CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r))
        // Out to whole points, ignoring floating-point dust (956 × 440 puts the right edge on 654).
        func down(_ v: CGFloat) -> CGFloat { (v + 1e-6).rounded(.down) }
        func up(_ v: CGFloat) -> CGFloat { (v - 1e-6).rounded(.up) }
        gaugeArea = CGRect(x: down(ring.minX), y: down(ring.minY), width: up(ring.maxX) - down(ring.minX),
                           height: up(ring.maxY) - down(ring.minY))
        // Gauge A's box (300 at 844 and wider, else 280) still places the panels, pulled back from the ring.
        let wide = screen.width >= 844
        let gaugeA: CGFloat = wide ? 300 : 280, gaugeAX = ((screen.width - gaugeA) / 2).rounded(.down)
        let clear = canvas.length(r + Self.panelClearance), ringX = canvas.point(c).x
        let leftEdge = min(gaugeAX - 12, down(ringX - clear))
        let rightX = max(gaugeAX + gaugeA + 12, up(ringX + clear))
        sourceChipOrigin = CGPoint(x: side, y: 16)
        let slotHeight: CGFloat = wide ? 48 : 53
        batterySlot = CGRect(x: side, y: bottom - slotHeight, width: leftEdge - side, height: slotHeight)
        let parkedSlotHeight: CGFloat = wide ? 69 : 73
        parkedBatterySlot = CGRect(x: side, y: bottom - parkedSlotHeight, width: batterySlot.width, height: parkedSlotHeight)
        leftPanel = CGRect(x: side, y: 84, width: batterySlot.width, height: parkedBatterySlot.minY - 4 - 84)
        rightPanel = CGRect(x: rightX, y: 84, width: screen.width - side - rightX, height: leftPanel.height)
        let tireX = rightX + 1
        tirePanel = CGRect(x: tireX, y: 72, width: screen.width - side - tireX, height: wide ? 288 : 272)
        settingsGear = CGRect(x: screen.width - side - 48, y: 16, width: 48, height: 48)
        temperatureSlot = CGRect(x: settingsGear.minX - 88, y: 16, width: 76, height: 28)
        contentBottom = bottom
    }
}
