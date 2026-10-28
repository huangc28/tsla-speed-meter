import CoreGraphics
import Testing
@testable import HUDCore

/// 01 §7.4 coordinates for the two reference sizes.
struct DriveLayoutTests {
    @Test func referenceSize844() {
        let layout = DriveLayout(screen: CGSize(width: 844, height: 390), leftInset: 59, rightInset: 59, bottomInset: 21)
        #expect(layout.gaugeArea == CGRect(x: 272, y: 50, width: 300, height: 300))
        #expect(layout.sourceChipOrigin == CGPoint(x: 75, y: 16))
        #expect(layout.batterySlot == CGRect(x: 75, y: 321, width: 185, height: 48))
        #expect(layout.parkedBatterySlot == CGRect(x: 75, y: 300, width: 185, height: 69))
        #expect(layout.tirePanel == CGRect(x: 585, y: 72, width: 184, height: 288))
        #expect(layout.leftPanel == CGRect(x: 75, y: 84, width: 185, height: 212))
        #expect(layout.rightPanel == CGRect(x: 584, y: 84, width: 185, height: 212))
        #expect(layout.settingsGear == CGRect(x: 721, y: 16, width: 48, height: 48))
        #expect(layout.contentBottom == 369)
    }

    @Test func minimumSize667() {
        let layout = DriveLayout(screen: CGSize(width: 667, height: 375), leftInset: 0, rightInset: 0, bottomInset: 0)
        #expect(layout.gaugeArea == CGRect(x: 193, y: 50, width: 280, height: 280))
        #expect(layout.sourceChipOrigin == CGPoint(x: 16, y: 16))
        #expect(layout.batterySlot == CGRect(x: 16, y: 306, width: 165, height: 53))
        #expect(layout.parkedBatterySlot == CGRect(x: 16, y: 286, width: 165, height: 73))
        #expect(layout.tirePanel == CGRect(x: 486, y: 72, width: 165, height: 272))
        #expect(layout.leftPanel == CGRect(x: 16, y: 84, width: 165, height: 198))
        #expect(layout.rightPanel == CGRect(x: 485, y: 84, width: 166, height: 198))
        #expect(layout.settingsGear == CGRect(x: 603, y: 16, width: 48, height: 48))
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

    @Test func gaugeAFollowsDesign() {
        let big = GaugeGeometry(size: 300), small = GaugeGeometry(size: 280)
        #expect(big.center == CGPoint(x: 150, y: 150) && small.center == CGPoint(x: 140, y: 140))
        #expect(big.ringRadius == 139 && big.discRadius == 138)
        #expect(abs(small.ringRadius - 139 * 280 / 300) < 1e-9)
        #expect(big.numeralFontSize == 160 && small.numeralFontSize == 149)
        #expect(big.unitFontSize == 23 && small.unitFontSize == 21)
        #expect(big.numeralCenterY == 149 && abs(small.numeralCenterY - 139.2) < 1e-9)
        // The ink of "0" at 160: 719/1000 em.
        #expect(abs(big.zeroInkHeight - 115.04) < 1e-9)
        #expect(abs(big.unitCenterY - (149 + 115.04 / 2 + 22)) < 1e-9)
        #expect(abs(big.reasonCenterY - (149 + 115.04 / 2 + 24)) < 1e-9)
    }

    // #48's anchors: the P R N D baseline and the four car-status slot centers, in screen points.
    @Test func gearRowAndCarStatusAnchors844() {
        let layout = DriveLayout(screen: CGSize(width: 844, height: 390), leftInset: 59, rightInset: 59, bottomInset: 21)
        // (yc − h0/2) − 13 − 3 − 2 in the gauge, plus the gauge's y 50.
        #expect(abs(layout.gearRowBaselineY - (50 + 149 - 115.04 / 2 - 18)) < 1e-9)
        let slots = layout.carStatusSlots
        #expect(slots.frontTrunk == CGPoint(x: 272 + 74.5, y: 50 + 235))
        #expect(slots.door == CGPoint(x: 272 + 152, y: 50 + 266.5))
        #expect(slots.rearTrunk == CGPoint(x: 272 + 224, y: 50 + 237.5))
        #expect(slots.customThreshold == CGPoint(x: 272 + 150, y: 50 + 36.5))
    }

    @Test func gearRowAndCarStatusAnchors667() {
        let layout = DriveLayout(screen: CGSize(width: 667, height: 375), leftInset: 0, rightInset: 0, bottomInset: 0)
        let h0 = 719 * 0.149
        #expect(abs(layout.gearRowBaselineY - (50 + 139.2 - h0 / 2 - 18)) < 1e-9)
        // DESIGN.md's 667 table, rounded to 0.1.
        func near(_ p: CGPoint, _ x: CGFloat, _ y: CGFloat) -> Bool {
            abs(p.x - (193 + x)) <= 0.05 && abs(p.y - (50 + y)) <= 0.05
        }
        let slots = layout.carStatusSlots
        #expect(near(slots.frontTrunk, 66.7, 217.9))
        #expect(near(slots.door, 141.9, 249.0))
        #expect(near(slots.rearTrunk, 211.9, 220.7))
        #expect(near(slots.customThreshold, 140, 34.1))
    }
}
