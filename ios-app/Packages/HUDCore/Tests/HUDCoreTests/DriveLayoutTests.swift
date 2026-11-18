import CoreGraphics
import Testing
@testable import HUDCore

/// The drive screen's frame on the design canvas (#98, #100) and the parked panels' frames (#79), at the
/// reference sizes: 844 × 390, the 667 × 375 minimum and the owner's 956 × 440.
struct DriveLayoutTests {
    static let l844 = DriveLayout(screen: CGSize(width: 844, height: 390), leftInset: 59, rightInset: 59, bottomInset: 21)
    static let l667 = DriveLayout(screen: CGSize(width: 667, height: 375), leftInset: 0, rightInset: 0, bottomInset: 0)
    static let l956 = DriveLayout(screen: CGSize(width: 956, height: 440), leftInset: 62, rightInset: 0, bottomInset: 21)

    // At 844 the canvas is the screen: every frame is the design's own number.
    @Test func referenceSize844() {
        let layout = Self.l844
        #expect(layout.gaugeArea == CGRect(x: 266, y: 16, width: 312, height: 312))
        #expect(layout.leftCard == CGRect(x: 62, y: 79, width: 183, height: 181))
        #expect(layout.tireColumn == CGRect(x: 592, y: 79, width: 176, height: 181))
        #expect(layout.footer == CGRect(x: 90, y: 333, width: 679, height: 25))
        #expect(layout.sourceChipOrigin == CGPoint(x: 75, y: 16))
        #expect(layout.topRowHeight == 28)
        #expect(layout.settingsGear == CGRect(x: 721, y: 16, width: 48, height: 48))
        #expect(layout.temperatureSlot == CGRect(x: 633, y: 16, width: 76, height: 28))
        #expect(layout.contentBottom == 369)
        // The parked cards keep their widths; both end 3 above the footer's ink, the tire panel starts right below the gear.
        #expect(layout.leftPanel == CGRect(x: 75, y: 84, width: 185, height: 252))
        #expect(layout.tirePanel == CGRect(x: 585, y: 64, width: 184, height: 272))
    }

    // Uniform scaling, centred (owner decision 3, #96): at 667 about 0.79, the bands above and below.
    @Test func minimumSize667() {
        let layout = Self.l667
        #expect(abs(layout.canvas.scale - 667.0 / 844) < 1e-9)
        #expect(layout.gaugeArea == CGRect(x: 210, y: 46, width: 247, height: 247))
        #expect(layout.leftCard == CGRect(x: 48, y: 95, width: 146, height: 144))
        #expect(layout.tireColumn == CGRect(x: 467, y: 95, width: 140, height: 144))
        #expect(layout.footer.minX == 71 && layout.footer.maxX == 608)
        #expect(abs(layout.sourceChipOrigin.x - 75 * 667.0 / 844) < 1e-9)
        // The gear's hit area stays 48, centred on the gear.
        #expect(layout.settingsGear.size == CGSize(width: 48, height: 48))
        #expect(abs(layout.settingsGear.midX - layout.canvas.point(745, 40).x) < 1e-9)
        #expect(layout.contentBottom == 359)
        // The parked tire panel fits between the gear's hit area and the footer.
        #expect(layout.leftPanel == CGRect(x: 16, y: 84, width: 165, height: 214))
        #expect(layout.tirePanel == CGRect(x: 486, y: 90, width: 165, height: 208))
        // The one-time card moves the left panel up, but not into the top row (y 46–68 here).
        #expect(layout.parkedHintTop == 73 && Self.l844.parkedHintTop == 52)
    }

    @Test func proMax956() {
        let layout = Self.l956
        #expect(abs(layout.canvas.scale - 440.0 / 390) < 1e-9)
        #expect(layout.gaugeArea == CGRect(x: 302, y: 18, width: 352, height: 353))
        #expect(layout.leftCard == CGRect(x: 71, y: 89, width: 208, height: 205))
        #expect(layout.tirePanel == CGRect(x: 662, y: 70, width: 216, height: 288))
    }

    @Test func bothSidesUseTheLargerInset() {
        let left = DriveLayout(screen: CGSize(width: 956, height: 440), leftInset: 62, rightInset: 0, bottomInset: 21)
        let right = DriveLayout(screen: CGSize(width: 956, height: 440), leftInset: 0, rightInset: 62, bottomInset: 21)
        #expect(left == right)
        #expect(left.gaugeArea.midX == 478)
    }

    // Landscape with the sensor housing on either side: the source icon, the left card, the battery, the tire column,
    // the odometer and the gear's hit area stay inside the safe area (the side insets, and above the home indicator).
    @Test(arguments: [(CGSize(width: 844, height: 390), CGFloat(59), CGFloat(21), true), (CGSize(width: 844, height: 390), 59, 21, false),
                      (CGSize(width: 956, height: 440), 62, 21, true), (CGSize(width: 956, height: 440), 62, 21, false)])
    func theFrameClearsTheSafeArea(screen: CGSize, inset: CGFloat, bottom: CGFloat, housingLeft: Bool) {
        let layout = DriveLayout(screen: screen, leftInset: housingLeft ? inset : 0, rightInset: housingLeft ? 0 : inset, bottomInset: bottom)
        let left = inset, right = screen.width - inset
        #expect(layout.sourceChipOrigin.x >= left)
        #expect(layout.leftCard.minX >= left)
        #expect(layout.footer.minX >= left)
        #expect(layout.tireColumn.maxX <= right)
        #expect(layout.footer.maxX <= right)
        #expect(layout.settingsGear.maxX <= right)
        #expect(layout.footer.maxY <= screen.height - bottom)
        #expect(layout.settingsGear.minY >= 0)
    }

    /// The Euclidean distance from `rect` to the ring's line, in design points.
    static func ringDistance(_ rect: CGRect) -> CGFloat {
        let c = RoundGauge.center
        let near = CGPoint(x: min(max(c.x, rect.minX), rect.maxX), y: min(max(c.y, rect.minY), rect.maxY))
        return hypot(near.x - c.x, near.y - c.y) - RoundGauge.radius
    }

    // The guide's gate: the left card's frame stays 20 clear of the ring's line at 844 (21 from its right
    // edge, 245, to the ring's left, 266). The tire column's ink is measured in the app (`DriveFrameTests`).
    @Test func theLeftCardClearsTheRing() {
        #expect(Self.ringDistance(DriveFrame.leftCard) >= DriveFrame.ringClearance)
        #expect(abs(Self.ringDistance(DriveFrame.leftCard) - 21) < 1e-9)
    }

    // Nothing the screen lays out meets the ring, at every size: the drive frame on the canvas, and the parked
    // panels at least `panelClearance` outside the ring's line.
    @Test(arguments: [l844, l667, l956])
    func framesClearTheRing(layout: DriveLayout) {
        let c = layout.canvas.point(RoundGauge.center), r = layout.canvas.length(RoundGauge.radius)
        for (frame, clearance) in [(layout.leftPanel, DriveLayout.panelClearance), (layout.tirePanel, DriveLayout.panelClearance),
                                   (layout.settingsGear, 0), (layout.temperatureSlot, 0)] {
            let near = CGPoint(x: min(max(c.x, frame.minX), frame.maxX), y: min(max(c.y, frame.minY), frame.maxY))
            #expect(hypot(near.x - c.x, near.y - c.y) >= r + layout.canvas.length(clearance) - 0.5, "\(frame)")
        }
        // Rounded out to whole points, the left card stays within a point of its design clearance.
        let card = layout.leftCard
        let near = CGPoint(x: min(max(c.x, card.minX), card.maxX), y: min(max(c.y, card.minY), card.maxY))
        #expect(hypot(near.x - c.x, near.y - c.y) - r >= layout.canvas.length(DriveFrame.ringClearance) - 1)
    }

    // The parked panels stay off the top row and the footer's ink.
    @Test(arguments: [l844, l667, l956])
    func parkedPanelsClearTheGearAndTheFooter(layout: DriveLayout) {
        #expect(layout.tirePanel.minY >= layout.settingsGear.maxY)
        let footerInk = layout.canvas.point(0, DriveFrame.footerY - 6.2).y
        #expect(layout.tirePanel.maxY <= footerInk - 3)
        #expect(layout.leftPanel.maxY <= footerInk - 3)
    }
}
