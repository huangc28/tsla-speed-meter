import CoreGraphics
import Foundation
import Testing
@testable import HUDCore

/// The round gauge's numbers from DESIGN-atelier-tesla-edition.md and the design page's `TE` (#98).
struct RoundGaugeTests {
    private func near(_ a: CGFloat, _ b: CGFloat, _ tolerance: CGFloat = 1e-9) -> Bool { abs(a - b) <= tolerance }
    private func near(_ p: CGPoint, _ x: CGFloat, _ y: CGFloat, _ tolerance: CGFloat = 0.005) -> Bool {
        abs(p.x - x) <= tolerance && abs(p.y - y) <= tolerance
    }

    // One scale, min(w / 844, h / 390), and the scaled 844 × 390 box centred.
    @Test func canvasScalesUniformlyAndCentres() {
        let c844 = DesignCanvas(screen: CGSize(width: 844, height: 390))
        #expect(c844.scale == 1 && c844.origin == .zero)
        #expect(c844.point(422, 172) == CGPoint(x: 422, y: 172) && c844.length(156) == 156)
        let c667 = DesignCanvas(screen: CGSize(width: 667, height: 375))
        #expect(near(c667.scale, 667 / 844) && near(c667.origin.x, 0) && near(c667.origin.y, (375 - 390 * 667 / 844) / 2))
        let c956 = DesignCanvas(screen: CGSize(width: 956, height: 440))
        #expect(near(c956.scale, 440 / 390) && near(c956.origin.y, 0) && near(c956.origin.x, (956 - 844 * 440 / 390) / 2))
        #expect(near(c956.scale, 1.128, 0.001) && near(c667.scale, 0.790, 0.001))
        // Centred: the design's centre is the screen's.
        #expect(near(c956.point(422, 195), CGPoint(x: 478, y: 220).x, 220) && near(c667.point(422, 195), 333.5, 187.5))
        let r = CGRect(x: 266, y: 16, width: 312, height: 312)
        #expect(c956.rect(r) == CGRect(origin: c956.point(266, 16), size: CGSize(width: 312 * c956.scale, height: 312 * c956.scale)))
        #expect(c956.point(10, 20).applying(.identity) == CGPoint(x: 10, y: 20).applying(c956.transform))
    }

    @Test func ringAndTicks() {
        #expect(RoundGauge.center == CGPoint(x: 422, y: 172) && RoundGauge.radius == 156)
        // y 16 to 328.
        #expect(RoundGauge.center.y - RoundGauge.radius == 16 && RoundGauge.center.y + RoundGauge.radius == 328)
        let ticks = RoundGauge.Ticks.lines
        #expect(ticks.count == 44 && RoundGauge.Ticks.lineWidth == 0.8)
        for (i, t) in ticks.enumerated() {
            #expect(near(hypot(t.inner.x - 422, t.inner.y - 172), 0.903 * 156, 1e-9))
            #expect(near(hypot(t.outer.x - 422, t.outer.y - 172), 0.952 * 156, 1e-9))
            // Every 360 / 44 degrees from 12 o'clock, clockwise.
            let a = atan2(t.outer.x - 422, 172 - t.outer.y) * 180 / .pi
            #expect(near((a + 360).truncatingRemainder(dividingBy: 360), CGFloat(i) * 360 / 44, 1e-6))
        }
    }

    // `ringT(true)`: 180 pieces of 2°, overlapping 0.2° at each end, coloured from the cooled samples.
    @Test func ringSegmentsFollowThePage() {
        let s = RoundGauge.ringSegments
        #expect(s.count == 180)
        #expect(s[0].startDegrees == -0.2 && s[0].endDegrees == 2.2 && s[179].startDegrees == 357.8)
        // 1°: a fifth of the way from sample 0 to sample 1, cooled (k = 0, both are blue), × 1.07, rounded.
        let r = 155 + (156 - 155) * 0.2, g = 179 + (175 - 179) * 0.2, b = 198 + (194 - 198) * 0.2
        #expect(s[0].red == Int((r * 1.07).rounded()) && s[0].green == Int((g * 1.07).rounded()) && s[0].blue == min(255, Int((b * 1.07).rounded())))
        #expect(near(s[0].lineWidth, 2.5 * 156 / 143.4 * 0.94))
        // The owner's amber section (85°, sample 17, 237 / 180 / 90) is blue-white now: blue is the brightest.
        let amber = s[42]
        #expect(amber.blue > amber.red && amber.blue > amber.green, "\(amber)")
        // And the red one at the lower left (245°, sample 49).
        let red = s[122]
        #expect(red.blue > red.red, "\(red)")
        // The bright top and the almost black bottom.
        #expect(s[0].red + s[0].green + s[0].blue > 3 * s[90].red + 3 * s[90].green + 3 * s[90].blue)
        // Widths cap at 2.9 · k · 0.94 (the 4.16 sample at 230°).
        #expect(s.allSatisfy { $0.lineWidth <= 2.9 * 156 / 143.4 * 0.94 + 1e-9 })
        // The outer glow only within ±76° of the top, strongest at the top.
        #expect(s.filter { $0.outerGlowOpacity != nil }.count == 76)
        #expect(s[0].outerGlowOpacity! > 0.999 && s[37].outerGlowOpacity! < 0.01 && s[38].outerGlowOpacity == nil)
        #expect(RoundGauge.innerGlow == .init(radius: 152.4, width: 4.5, blur: 2.1, opacity: 0.17))
        #expect(RoundGauge.outerGlow == .init(radius: 159.2, width: 4.5, blur: 2.1, opacity: 0.11))
    }

    // `coolRing` leaves blue samples alone and moves warm ones to blue-white at the same luminance.
    @Test func coolRingKeepsBrightness() {
        let blue = (155.0, 179.0, 198.0, 2.5)
        #expect(RoundGauge.cool(blue) == blue)
        let amber = RoundGauge.cool((237, 180, 90, 2.74))
        let y = 0.2126 * 237 + 0.7152 * 180 + 0.0722 * 90.0
        #expect(abs(amber.0 - y * 0.903) < 1e-9 && abs(amber.1 - y * 1.018) < 1e-9 && abs(amber.2 - y * 1.111) < 1e-9)
    }

    // P R N D 0.692 of the radius above the centre, 21.6 apart, cap height 10.0.
    @Test func gearRow() {
        typealias G = RoundGauge.GearRow
        #expect(near(G.centerY, 172 - 0.692 * 156) && G.pitch == 21.6 && G.fontSize == 14.35)
        #expect(near(G.capHeight, 10.0, 0.01))
        #expect(near(G.baselineY - G.capHeight / 2, G.centerY))
        #expect((0..<4).map(G.letterCenterX) == [389.6, 411.2, 432.8, 454.4].map { CGFloat($0) }
                || zip((0..<4).map(G.letterCenterX), [389.6, 411.2, 432.8, 454.4]).allSatisfy { abs($0 - $1) < 1e-9 })
    }

    // The numeral's ink centre 8.9 above the ring centre, ink height 73.7, cell width 57.8; the unit 9.5 below.
    @Test func numeralAndUnit() {
        typealias N = RoundGauge.Numeral
        #expect(near(N.inkCenterY, 163.1) && N.fontSize == 103.2)
        #expect(near(N.inkHeight, 73.7, 0.1) && near(N.cellWidth, 57.8, 0.01))
        #expect(near((N.inkTop + N.inkBottom) / 2, 163.1) && near(N.inkBottom - N.inkTop, N.inkHeight))
        // The page's numBox: base = cy + (a8 − d8) / 2.
        #expect(near(N.baselineY, 163.1 + (0.706 - 0.009) * 103.2 / 2))
        #expect(near(RoundGauge.Unit.inkTop - N.inkBottom, 9.5) && RoundGauge.Unit.fontSize == 17.2)
        #expect(near(RoundGauge.Unit.baselineY - RoundGauge.Unit.inkTop, 0.697 * 17.2))
        // No speed: the 49.4 × 4.2 dash on the numeral's centre line, the reason's ink 12 below it.
        #expect(N.dashRect == CGRect(x: 422 - 24.7, y: 163.1 - 2.1, width: 49.4, height: 4.2))
        #expect(near(RoundGauge.Reason.inkTop - N.dashRect.maxY, 12.3, 1e-6))
    }

    // The guide's disc centres, orbit 113, and the empty bottom slot.
    @Test func discSlots() {
        let s = RoundGauge.slots
        #expect(near(s.frontTrunk, 335.44, 99.37) && near(s.door, 309.00, 172.39))
        #expect(near(s.rearTrunk, 508.56, 99.37) && near(s.tire, 535.00, 172.39))
        #expect(near(s.speedLimit, 422, 281.82))
        #expect(RoundGauge.discDiameter == 37.1 && s.discs.count == 4)
        for p in s.discs { #expect(near(hypot(p.x - 422, p.y - 172), 113, 1e-9)) }
    }
}
