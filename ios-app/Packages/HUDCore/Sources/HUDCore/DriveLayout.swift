import CoreGraphics

/// The drive screen's frame in design points (#100, the design page's `drawMain`): the left card (`FH.nav`),
/// the tire column (`tyreColN(COL25.a)`), the footer (`FH.foot`, `footX`) and the top row (`topRow`, its CSS).
/// DESIGN-atelier-tesla-edition.md "Layout": the left card and the right column stay at least 20 clear of the
/// ring's line (`ringClearance`).
public enum DriveFrame {
    /// The left card: navigation, or the trip in the same frame (owner decision 1, #96), corner radius 17.
    public static let leftCard = CGRect(x: 62, y: 79, width: 183, height: 181)
    public static let leftCardRadius: CGFloat = 17
    /// The left card's text column (`Nv.tx`).
    public static let leftCardTextX: CGFloat = 75

    /// The tire column: from `FH.col.x` to the readings' right edge, as high as the left card.
    public static let tireColumn = CGRect(x: 592, y: 79, width: 176, height: 181)

    /// The footer's centre line, and its left (battery) and right (odometer) ends.
    public static let footerY: CGFloat = 345.6
    public static let footerLeft: CGFloat = 90
    public static let footerRight: CGFloat = 769
    /// The footer's band: 12 either side of its centre line.
    public static var footer: CGRect { CGRect(x: footerLeft, y: footerY - 12, width: footerRight - footerLeft, height: 24) }

    /// The top row (`.chip`, `.htime`, `.gear`): the source icon at (75, 16) on a 28-high line, the time 12 right
    /// of a one-icon chip (x 109), the settings gear's 48 box at (721, 16).
    public static let chipOrigin = CGPoint(x: 75, y: 16)
    public static let topRowHeight: CGFloat = 28
    public static let settingsGear = CGRect(x: 721, y: 16, width: 48, height: 48)

    /// The guide's clearance from the left card and the right column to the ring's line.
    public static let ringClearance: CGFloat = 20
}

/// Main-screen frames in screen points, origin top-left (01 §7.4, DESIGN.md Layout), for the drive
/// and the parked layout: both draw the same gauge, so switching never moves it (L31).
/// Reference sizes: 844×390 (side insets 59, bottom 21) and the 667×375 minimum.
///
/// Everything the drive screen draws lives on `canvas`, the 844 × 390 design scaled uniformly (#98, #100):
/// the gauge, the left card, the tire column, the footer and the top row. The parked cards (#79) keep their
/// frames from gauge A's box until #101 re-lays them into the drive screen's frames; they stay clear of the
/// gear and the footer.
public struct DriveLayout: Equatable, Sendable {
    /// The design canvas everything is drawn on.
    public var canvas: DesignCanvas
    /// The ring's box on the screen, rounded out to whole points.
    public var gaugeArea: CGRect
    /// The left card on the screen, rounded out to whole points.
    public var leftCard: CGRect
    /// The tire column on the screen, rounded out to whole points.
    public var tireColumn: CGRect
    /// The footer's band on the screen, rounded out to whole points.
    public var footer: CGRect
    /// The source icon's top-left, on the top row's line.
    public var sourceChipOrigin: CGPoint
    /// The top row's height on the screen.
    public var topRowHeight: CGFloat
    /// The parked screen's tire panel, right of the gauge (L42), and its 胎壓 / 車上導航 cards (#79).
    public var tirePanel: CGRect
    /// The parked screen's left panel, its 行程 / 車況 cards (#79), from y 84 to 4 above where the old
    /// battery slot was (the master's `LW` and `scrollB`).
    public var leftPanel: CGRect
    /// Top-right settings gear: its 48×48 hit area, centred on the gear's place on the canvas (DESIGN.md
    /// Layout: the hit area does not scale).
    public var settingsGear: CGRect
    /// The parked top row's outside temperature (#79, the master's `tempG`): 76 wide, its content
    /// right-aligned 12 left of the gear's box, on the top row's line (x 633 at 844).
    public var temperatureSlot: CGRect
    /// The lowest y content may use, above the home indicator.
    public var contentBottom: CGFloat

    /// The parked panels stay this far outside the ring's centre line, in design points.
    public static let panelClearance: CGFloat = 6

    public init(screen: CGSize, leftInset: CGFloat, rightInset: CGFloat, bottomInset: CGFloat) {
        // Both sides use the larger inset, so rotating 180° never shifts the layout.
        let side = max(leftInset, rightInset) + 16
        let bottom = screen.height - max(bottomInset, 16)
        canvas = DesignCanvas(screen: screen)
        let r = RoundGauge.radius, c = RoundGauge.center
        // Out to whole points, ignoring floating-point dust (956 × 440 puts the ring's right edge on 654).
        func down(_ v: CGFloat) -> CGFloat { (v + 1e-6).rounded(.down) }
        func up(_ v: CGFloat) -> CGFloat { (v - 1e-6).rounded(.up) }
        func whole(_ rect: CGRect) -> CGRect {
            CGRect(x: down(rect.minX), y: down(rect.minY), width: up(rect.maxX) - down(rect.minX), height: up(rect.maxY) - down(rect.minY))
        }
        gaugeArea = whole(canvas.rect(CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)))
        leftCard = whole(canvas.rect(DriveFrame.leftCard))
        tireColumn = whole(canvas.rect(DriveFrame.tireColumn))
        footer = whole(canvas.rect(DriveFrame.footer))
        sourceChipOrigin = canvas.point(DriveFrame.chipOrigin)
        topRowHeight = canvas.length(DriveFrame.topRowHeight)
        let gear = canvas.rect(DriveFrame.settingsGear)
        settingsGear = CGRect(x: gear.midX - 24, y: gear.midY - 24, width: 48, height: 48)
        let temperature = canvas.rect(CGRect(x: DriveFrame.settingsGear.minX - 88, y: DriveFrame.chipOrigin.y, width: 76,
                                             height: DriveFrame.topRowHeight))
        temperatureSlot = temperature
        contentBottom = bottom

        // The parked panels (#79): gauge A's box (300 at 844 and wider, else 280), pulled back from the ring.
        let wide = screen.width >= 844
        let gaugeA: CGFloat = wide ? 300 : 280, gaugeAX = ((screen.width - gaugeA) / 2).rounded(.down)
        let clear = canvas.length(r + Self.panelClearance), ringX = canvas.point(c).x
        let leftEdge = min(gaugeAX - 12, down(ringX - clear))
        let rightX = max(gaugeAX + gaugeA + 12, up(ringX + clear))
        let oldBatteryTop = bottom - (wide ? 69 : 73)
        leftPanel = CGRect(x: side, y: 84, width: leftEdge - side, height: oldBatteryTop - 4 - 84)
        // Right below the gear's hit area, and 3 clear of the footer's ink (its battery outline's top, y 339.4): 288
        // high where that fits (956), else 272 (844, 8 higher than before so its backing clears the ODO), and at 667
        // only the room between the gear and the footer (the card lists its wheels; #101 re-lays it).
        let tireX = rightX + 1, tireTop = up(settingsGear.maxY)
        let footerTop = canvas.point(0, DriveFrame.footerY - 6.2).y
        let tireHeight = tireTop + 288 <= footerTop - 3 ? 288 : min(272, down(footerTop - 3 - tireTop))
        tirePanel = CGRect(x: tireX, y: tireTop, width: screen.width - side - tireX, height: tireHeight)
    }
}
