import CoreGraphics
import Testing
@testable import HUDCore

/// 01 §7.4 coordinates for the two reference sizes; the gauge area is the round gauge's ring (#98).
struct DriveLayoutTests {
    @Test func referenceSize844() {
        let layout = DriveLayout(screen: CGSize(width: 844, height: 390), leftInset: 59, rightInset: 59, bottomInset: 21)
        #expect(layout.gaugeArea == CGRect(x: 266, y: 16, width: 312, height: 312))
        #expect(layout.sourceChipOrigin == CGPoint(x: 75, y: 16))
        #expect(layout.batterySlot == CGRect(x: 75, y: 321, width: 185, height: 48))
        #expect(layout.parkedBatterySlot == CGRect(x: 75, y: 300, width: 185, height: 69))
        #expect(layout.tirePanel == CGRect(x: 585, y: 72, width: 184, height: 288))
        #expect(layout.leftPanel == CGRect(x: 75, y: 84, width: 185, height: 212))
        #expect(layout.rightPanel == CGRect(x: 584, y: 84, width: 185, height: 212))
        #expect(layout.settingsGear == CGRect(x: 721, y: 16, width: 48, height: 48))
        #expect(layout.temperatureSlot == CGRect(x: 633, y: 16, width: 76, height: 28))
        #expect(layout.contentBottom == 369)
    }

    @Test func minimumSize667() {
        let layout = DriveLayout(screen: CGSize(width: 667, height: 375), leftInset: 0, rightInset: 0, bottomInset: 0)
        #expect(layout.gaugeArea == CGRect(x: 210, y: 46, width: 247, height: 247))
        #expect(layout.sourceChipOrigin == CGPoint(x: 16, y: 16))
        #expect(layout.batterySlot == CGRect(x: 16, y: 306, width: 165, height: 53))
        #expect(layout.parkedBatterySlot == CGRect(x: 16, y: 286, width: 165, height: 73))
        #expect(layout.tirePanel == CGRect(x: 486, y: 72, width: 165, height: 272))
        #expect(layout.leftPanel == CGRect(x: 16, y: 84, width: 165, height: 198))
        #expect(layout.rightPanel == CGRect(x: 485, y: 84, width: 166, height: 198))
        #expect(layout.settingsGear == CGRect(x: 603, y: 16, width: 48, height: 48))
        #expect(layout.temperatureSlot == CGRect(x: 515, y: 16, width: 76, height: 28))
        #expect(layout.contentBottom == 359)
    }

    @Test func bothSidesUseTheLargerInset() {
        let left = DriveLayout(screen: CGSize(width: 956, height: 440), leftInset: 62, rightInset: 0, bottomInset: 21)
        let right = DriveLayout(screen: CGSize(width: 956, height: 440), leftInset: 0, rightInset: 62, bottomInset: 21)
        #expect(left == right)
        #expect(left.sourceChipOrigin.x == 78)
        #expect(left.gaugeArea.midX == 478)
        #expect(left.settingsGear == CGRect(x: 830, y: 16, width: 48, height: 48))
    }

    // #98: the ring's box at the three sizes; the panels keep gauge A's frames at 844 and 667 and give way
    // to the ring on the Pro Max.
    @Test func gaugeAreaIsTheRingBox() {
        let l844 = DriveLayout(screen: CGSize(width: 844, height: 390), leftInset: 59, rightInset: 59, bottomInset: 21)
        #expect(l844.gaugeArea == CGRect(x: 266, y: 16, width: 312, height: 312))
        let l667 = DriveLayout(screen: CGSize(width: 667, height: 375), leftInset: 0, rightInset: 0, bottomInset: 0)
        #expect(l667.gaugeArea == CGRect(x: 210, y: 46, width: 247, height: 247))
        let l956 = DriveLayout(screen: CGSize(width: 956, height: 440), leftInset: 62, rightInset: 0, bottomInset: 21)
        #expect(l956.gaugeArea == CGRect(x: 302, y: 18, width: 352, height: 353))
        #expect(l956.leftPanel.maxX == 295 && l956.batterySlot.maxX == 295)
        #expect(l956.rightPanel.minX == 661 && l956.tirePanel.minX == 662)
    }

    // No panel or slot meets the ring: each stays outside the ring's line by at least its clearance.
    @Test(arguments: [(CGSize(width: 844, height: 390), CGFloat(59), CGFloat(21)), (CGSize(width: 667, height: 375), 0, 0),
                      (CGSize(width: 956, height: 440), 62, 21)])
    func panelsClearTheRing(screen: CGSize, inset: CGFloat, bottom: CGFloat) {
        let layout = DriveLayout(screen: screen, leftInset: inset, rightInset: inset, bottomInset: bottom)
        let c = layout.canvas.point(RoundGauge.center), r = layout.canvas.length(RoundGauge.radius)
        let frames = [layout.leftPanel, layout.rightPanel, layout.tirePanel, layout.batterySlot, layout.parkedBatterySlot,
                      layout.settingsGear, layout.temperatureSlot]
        for frame in frames {
            // The frame's point nearest the ring centre.
            let near = CGPoint(x: min(max(c.x, frame.minX), frame.maxX), y: min(max(c.y, frame.minY), frame.maxY))
            let nearest = hypot(near.x - c.x, near.y - c.y)
            // Farther than the ring's line plus the clearance, or wholly inside the ring (none is).
            #expect(nearest >= r + layout.canvas.length(DriveLayout.panelClearance) - 0.5, "\(screen) \(frame) is \(nearest - r) from the ring")
        }
    }

    // The four disc centres and the empty bottom slot, as the guide lists them, on the canvas.
    @Test func carStatusSlotsFollowTheCanvas() {
        let l844 = DriveLayout(screen: CGSize(width: 844, height: 390), leftInset: 59, rightInset: 59, bottomInset: 21)
        #expect(l844.carStatusSlots == RoundGauge.slots)
        let l956 = DriveLayout(screen: CGSize(width: 956, height: 440), leftInset: 0, rightInset: 0, bottomInset: 21)
        let s = l956.canvas.scale
        #expect(abs(l956.carStatusSlots.tire.x - (l956.canvas.origin.x + 535.00 * s)) < 0.01)
        #expect(abs(l956.carStatusSlots.tire.y - 172.39 * s) < 0.01)
    }
}
