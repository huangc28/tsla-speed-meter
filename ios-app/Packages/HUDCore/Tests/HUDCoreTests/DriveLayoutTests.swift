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
        #expect(layout.settingsGear == CGRect(x: 721, y: 16, width: 48, height: 48))
        #expect(layout.contentBottom == 369)
    }

    @Test func minimumSize667() {
        let layout = DriveLayout(screen: CGSize(width: 667, height: 375), leftInset: 0, rightInset: 0, bottomInset: 0)
        #expect(layout.gaugeArea == CGRect(x: 193, y: 50, width: 280, height: 280))
        #expect(layout.sourceChipOrigin == CGPoint(x: 16, y: 16))
        #expect(layout.batterySlot == CGRect(x: 16, y: 306, width: 165, height: 53))
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

    @Test func gaugeMapsZeroToLeftFootAnd240ToRightFoot() {
        let g = GaugeGeometry(size: 300)
        #expect(g.angle(forKilometersPerHour: 0) == 180)
        #expect(g.angle(forKilometersPerHour: 120) == 90)
        #expect(g.angle(forKilometersPerHour: 240) == 0)
        #expect(g.angle(forKilometersPerHour: 400) == 0)
        #expect(g.angle(forKilometersPerHour: -5) == 180)
        let left = g.point(radius: g.outerRadius, angle: 180)
        #expect(abs(left.x - 2) < 1e-9 && abs(left.y - 157) < 1e-9)
        let top = g.point(radius: g.outerRadius, angle: 90)
        #expect(abs(top.x - 150) < 1e-9 && abs(top.y - 9) < 1e-9)
    }

    @Test func numeralSizesFollowDesign() {
        let big = GaugeGeometry(size: 300), small = GaugeGeometry(size: 280)
        #expect(big.numeralFontSize(digits: 2) == 176 && small.numeralFontSize(digits: 2) == 164)
        #expect(big.numeralFontSize(digits: 3) == 152 && small.numeralFontSize(digits: 3) == 144)
        #expect(big.numeralTracking(digits: 2) == -1 && big.numeralTracking(digits: 3) == -6)
        #expect(big.unitFontSize == 23 && small.unitFontSize == 21)
        #expect(big.numeralCenterY == 152 && small.numeralCenterY == 142)
    }
}
