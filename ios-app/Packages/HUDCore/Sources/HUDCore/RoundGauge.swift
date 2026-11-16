import CoreGraphics
import Foundation

/// The 844 × 390 design screen (DESIGN-atelier-tesla-edition.md: "All sizes are points on the 844 × 390
/// landscape screen"), scaled uniformly to the real screen by `min(w / 844, h / 390)` and centred
/// (owner, 2026-11-16). Everything drawn from design points goes through one canvas, so it scales as one.
public struct DesignCanvas: Equatable, Sendable {
    public static let size = CGSize(width: 844, height: 390)
    public let scale: CGFloat
    /// Where the design's (0, 0) lands on the screen.
    public let origin: CGPoint

    public init(screen: CGSize) {
        scale = min(screen.width / Self.size.width, screen.height / Self.size.height)
        origin = CGPoint(x: (screen.width - Self.size.width * scale) / 2, y: (screen.height - Self.size.height * scale) / 2)
    }

    /// A design point on the screen.
    public func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: origin.x + x * scale, y: origin.y + y * scale)
    }

    public func point(_ p: CGPoint) -> CGPoint { point(p.x, p.y) }

    /// A design length (a size, a radius, a line width) on the screen.
    public func length(_ value: CGFloat) -> CGFloat { value * scale }

    public func rect(_ r: CGRect) -> CGRect {
        CGRect(origin: point(r.origin), size: CGSize(width: length(r.width), height: length(r.height)))
    }

    /// Design points to screen points: draw in design points under this transform.
    public var transform: CGAffineTransform {
        CGAffineTransform(a: scale, b: 0, c: 0, d: scale, tx: origin.x, ty: origin.y)
    }
}

/// The round gauge (DESIGN-atelier-tesla-edition.md "Layout", the design page's `TE`), in design points.
/// Nothing here moves or resizes between states (the Fixed Ring Rule).
public enum RoundGauge {
    public static let center = CGPoint(x: 422, y: 172)
    public static let radius: CGFloat = 156
    /// Our ring over the owner's image (radius 143.4): the ring's line widths were measured on the image.
    static let imageScale: CGFloat = 156 / 143.4

    /// The point `r` from the centre at `degrees` clockwise from 12 o'clock (the page's `CK`).
    public static func point(radius r: CGFloat, degrees: CGFloat) -> CGPoint {
        let t = degrees * .pi / 180
        return CGPoint(x: center.x + r * sin(t), y: center.y - r * cos(t))
    }

    // MARK: Ring and ticks

    /// 44 ticks around the full circle, from 0.903 to 0.952 of the radius, 0.8 wide (`TE.tick`).
    public enum Ticks {
        public static let count = 44
        public static let inner: CGFloat = 0.903, outer: CGFloat = 0.952
        public static let lineWidth: CGFloat = 0.8
        /// Each tick's inner and outer end, from 12 o'clock clockwise.
        public static var lines: [(inner: CGPoint, outer: CGPoint)] {
            (0..<count).map { n in
                let a = CGFloat(n) * 360 / CGFloat(count)
                return (point(radius: radius * inner, degrees: a), point(radius: radius * outer, degrees: a))
            }
        }
    }

    /// One 2° piece of the ring (`ringT(true)`): an arc from `startDegrees` to `endDegrees` (clockwise
    /// from 12 o'clock, 0.2° past each end so the pieces meet), in one colour and line width.
    public struct RingSegment: Equatable, Sendable {
        public let startDegrees: CGFloat, endDegrees: CGFloat
        /// 0–255.
        public let red: Int, green: Int, blue: Int
        public let lineWidth: CGFloat
        /// The opacity of the soft light outside the ring here; nil below ±76° of the top.
        public let outerGlowOpacity: CGFloat?
    }

    /// The soft light along the ring (`ringT`'s `gin` and `gout`): the segments' colours, `width` wide,
    /// blurred by `blur` (an SVG standard deviation), the whole layer at `opacity`.
    public struct Glow: Equatable, Sendable {
        public let radius: CGFloat, width: CGFloat, blur: CGFloat, opacity: CGFloat
    }

    public static let innerGlow = Glow(radius: radius - 3.6, width: 4.5, blur: 2.1, opacity: 0.17)
    /// Only where `RingSegment.outerGlowOpacity` is set.
    public static let outerGlow = Glow(radius: radius + 3.2, width: 4.5, blur: 2.1, opacity: 0.11)

    /// The owner's ring, every 5° clockwise from 12 o'clock: red, green, blue and line width (`TE.ring`).
    static let ringSamples: [(Double, Double, Double, Double)] = [
        (155, 179, 198, 2.5), (156, 175, 194, 2.5), (145, 165, 183, 2.5), (139, 160, 178, 2.5), (149, 172, 191, 2.5), (144, 166, 187, 2.5),
        (138, 164, 185, 2.5), (129, 153, 171, 2.5), (132, 151, 168, 2.5), (127, 145, 163, 2.5), (128, 144, 159, 2.38), (119, 131, 143, 2.5),
        (123, 132, 143, 2.5), (130, 132, 135, 2.5), (148, 142, 124, 2.62), (177, 151, 107, 2.62), (223, 170, 96, 2.62), (237, 180, 90, 2.74),
        (235, 178, 86, 2.74), (197, 155, 95, 2.85), (154, 134, 99, 2.85), (121, 122, 113, 2.74), (91, 106, 116, 2.74), (71, 90, 105, 2.85),
        (81, 98, 112, 2.97), (84, 104, 119, 1.07), (64, 80, 93, 1.31), (55, 68, 80, 1.07), (43, 53, 63, 0.95), (43, 52, 61, 1.07),
        (27, 34, 43, 2.26), (26, 33, 41, 2.14), (25, 32, 40, 2.02), (23, 30, 38, 2.02), (23, 30, 38, 2.14), (22, 29, 37, 2.02),
        (22, 28, 36, 1.9), (21, 28, 36, 2.02), (23, 29, 37, 2.14), (23, 30, 38, 2.02), (24, 30, 38, 2.14), (24, 30, 39, 2.26),
        (24, 30, 39, 2.5), (32, 38, 46, 2.38), (44, 53, 62, 1.07), (56, 63, 73, 1.19), (68, 71, 80, 4.16), (87, 59, 66, 3.69),
        (124, 66, 73, 3.21), (163, 57, 63, 2.85), (202, 68, 72, 2.74), (198, 88, 93, 2.74), (175, 102, 112, 2.74), (160, 117, 132, 2.74),
        (125, 121, 136, 2.62), (120, 134, 149, 2.62), (125, 142, 159, 2.62), (130, 145, 160, 2.62), (137, 153, 166, 2.62), (134, 151, 166, 2.62),
        (128, 148, 169, 2.5), (103, 137, 169, 2.5), (104, 142, 176, 2.62), (111, 150, 184, 2.62), (130, 168, 200, 2.5), (135, 171, 201, 2.5),
        (157, 185, 209, 2.5), (148, 174, 200, 2.5), (150, 173, 193, 2.5), (140, 162, 183, 2.5), (141, 166, 187, 2.5), (159, 182, 202, 2.5),
    ]

    /// `coolRing`: the owner's amber and red sections recoloured to the same blue-white at the same
    /// brightness; the rest unchanged (the State Colour Rule).
    static func cool(_ s: (Double, Double, Double, Double)) -> (Double, Double, Double, Double) {
        let (r, g, b, w) = s
        let y = 0.2126 * r + 0.7152 * g + 0.0722 * b, k = max(0, min(1, (r - b + 8) / 20))
        return (r + (y * 0.903 - r) * k, g + (y * 1.018 - g) * k, b + (y * 1.111 - b) * k, w)
    }

    /// The ring in 180 pieces, as `ringT(true)` draws it: each piece's colour and width interpolated
    /// at its middle from the cooled samples, the colour 7% brighter, the width `min(w, 2.9) · k · 0.94`.
    public static let ringSegments: [RingSegment] = {
        let samples = ringSamples.map(cool)
        func at(_ a: Double) -> (Double, Double, Double, Double) {
            let x = (a.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360) / 5
            let i = Int(x.rounded(.down)), t = x - Double(i)
            let p = samples[i % 72], q = samples[(i + 1) % 72]
            return (p.0 + (q.0 - p.0) * t, p.1 + (q.1 - p.1) * t, p.2 + (q.2 - p.2) * t, p.3 + (q.3 - p.3) * t)
        }
        func c8(_ v: Double) -> Int { Int(min(255, (v * 1.07).rounded())) }
        return stride(from: 0, to: 360, by: 2).map { a in
            let (r, g, b, w) = at(Double(a + 1))
            let th = Double(a + 1 > 180 ? a + 1 - 360 : a + 1)
            return RingSegment(startDegrees: CGFloat(a) - 0.2, endDegrees: CGFloat(a) + 2.2, red: c8(r), green: c8(g), blue: c8(b),
                               lineWidth: CGFloat(min(w, 2.9)) * imageScale * 0.94,
                               outerGlowOpacity: abs(th) < 76 ? CGFloat(pow(cos(th / 76 * .pi / 2), 1.5)) : nil)
        }
    }()

    // MARK: Gear row

    /// `P R N D` (`TE.gear`): Hanken Grotesk 500 at 14.35 (cap height 10.0), the current gear 600;
    /// letters 21.6 apart, each centred on its ink; the row centred 0.692 of the radius above the centre.
    public enum GearRow {
        public static let fontSize: CGFloat = 14.35
        public static let pitch: CGFloat = 21.6
        public static let raise: CGFloat = 0.692
        public static var centerY: CGFloat { center.y - raise * radius }
        public static var capHeight: CGFloat { HankenMetrics.capHeight * fontSize }
        /// Cap height centred on `centerY`.
        public static var baselineY: CGFloat { centerY + capHeight / 2 }
        /// The ink centre of letter `index` (0 = P … 3 = D).
        public static func letterCenterX(_ index: Int) -> CGFloat { center.x + (CGFloat(index) - 1.5) * pitch }
    }

    // MARK: Numeral, unit, no speed

    /// The speed numeral (`TE.num`, `numBox`): Hanken Grotesk 500 at 103.2, one fixed cell per digit,
    /// its ink centre 8.9 above the ring centre. The baseline comes from the ink of "8", so no digit moves it.
    public enum Numeral {
        public static let fontSize: CGFloat = 103.2
        public static let raise: CGFloat = 8.9
        public static var inkCenterY: CGFloat { center.y - raise }
        /// The cell: a digit's advance (all digits share it).
        public static var cellWidth: CGFloat { HankenMetrics.digitAdvance * fontSize }
        /// The ink of "8": 73.8.
        public static var inkHeight: CGFloat { (HankenMetrics.eightInk.max - HankenMetrics.eightInk.min) * fontSize }
        public static var baselineY: CGFloat { inkCenterY + (HankenMetrics.eightInk.max + HankenMetrics.eightInk.min) * fontSize / 2 }
        public static var inkTop: CGFloat { baselineY - HankenMetrics.eightInk.max * fontSize }
        public static var inkBottom: CGFloat { baselineY - HankenMetrics.eightInk.min * fontSize }

        /// No valid speed (`numT(null)`): a round-capped dash 49.4 × 4.2 on the numeral's centre line.
        public static let dash = CGSize(width: 49.4, height: 4.2)
        public static var dashRect: CGRect {
            CGRect(x: center.x - dash.width / 2, y: inkCenterY - dash.height / 2, width: dash.width, height: dash.height)
        }
    }

    /// `km/h` or `mph` (`TE.unit`, `unitT`): Hanken Grotesk 500 at 17.2, its ink centred, the ascender
    /// top (of "k" or "h") 9.5 below the numeral's ink.
    public enum Unit {
        public static let fontSize: CGFloat = 17.2
        public static let gap: CGFloat = 9.5
        public static var inkTop: CGFloat { Numeral.inkBottom + gap }
        public static var baselineY: CGFloat { inkTop + HankenMetrics.capHeight * fontSize }
    }

    /// The reason under the dash (`unitT(…, has = false)`, `TE.num.noteTop`): the system font 500 at 12,
    /// centred, its ink top at 177.5, 12.3 below the dash, where the unit goes.
    public enum Reason {
        public static let fontSize: CGFloat = 12
        public static let inkTop: CGFloat = 177.5
    }

    /// The GPS cue left of the unit (L87): Lucide's arrow, 14 high, its ink 8 left of the unit's ink.
    public enum GPSCue {
        public static let size: CGFloat = 14
        public static let gap: CGFloat = 8
    }

    // MARK: Icon discs

    /// The car-status icon discs (the guide's "Icon discs"): 37.1 wide, centres 113 from the ring centre.
    public static let discDiameter: CGFloat = 37.1
    public static let discOrbit: CGFloat = 113
    /// The empty speed-limit slot at the bottom (`FUT27.signR`), kept for map data later (#2).
    public static let speedLimitOrbit: CGFloat = 0.704 * radius
    public static let slots = CarStatusSlots(
        frontTrunk: point(radius: discOrbit, degrees: -50), door: point(radius: discOrbit, degrees: -90.2),
        rearTrunk: point(radius: discOrbit, degrees: 50), tire: point(radius: discOrbit, degrees: 90.2),
        speedLimit: point(radius: speedLimitOrbit, degrees: 180))
}

/// Hanken Grotesk 500's metrics, per em, for the layout here (HUDCore cannot load the font; the app
/// tests check these against the bundled file).
public enum HankenMetrics {
    /// Every digit's advance (the digits are tabular).
    public static let digitAdvance: CGFloat = 0.560
    /// The ink of "8", y up from the baseline.
    public static let eightInk: (min: CGFloat, max: CGFloat) = (-0.009, 0.706)
    /// The ink top of "P", "k" and "m" (cap and ascender height).
    public static let capHeight: CGFloat = 0.697
}

/// The car-status icon disc centres (the guide's "Icon discs"), the car seen as on the owner's image:
/// the front trunk 50° left of the top, the door 90.2° left, the rear trunk 50° right, the tire 90.2° right.
/// A slot never moves when another icon lights or goes out.
public struct CarStatusSlots: Equatable, Sendable {
    public var frontTrunk: CGPoint
    public var door: CGPoint
    public var rearTrunk: CGPoint
    public var tire: CGPoint
    /// The bottom slot, drawn as nothing (L109).
    public var speedLimit: CGPoint

    public init(frontTrunk: CGPoint, door: CGPoint, rearTrunk: CGPoint, tire: CGPoint, speedLimit: CGPoint) {
        self.frontTrunk = frontTrunk
        self.door = door
        self.rearTrunk = rearTrunk
        self.tire = tire
        self.speedLimit = speedLimit
    }

    /// The four icon discs, without the empty speed-limit slot.
    public var discs: [CGPoint] { [frontTrunk, door, rearTrunk, tire] }
}

/// Where the speed numeral's digits go (the Centred Numeral Rule, `numT(v, "hk")`): one fixed cell
/// per digit, the group centred on the ring, each digit centred in its cell by its advance. A digit's
/// position depends only on the digit count. Design points; each origin is a glyph's pen on the baseline.
public struct NumeralLayout: Equatable, Sendable {
    /// The glyph origin x of each digit, left to right.
    public let digitOrigins: [CGFloat]
    public let baselineY: CGFloat

    /// Nil unless `digits` is one or more ASCII digits.
    public init?(digits: String) {
        let s = Array(digits)
        guard !s.isEmpty, s.allSatisfy({ $0.isASCII && $0.isNumber }) else { return nil }
        let cell = RoundGauge.Numeral.cellWidth, n = CGFloat(s.count)
        digitOrigins = s.indices.map { i in RoundGauge.center.x + (CGFloat(i) - (n - 1) / 2) * cell - cell / 2 }
        baselineY = RoundGauge.Numeral.baselineY
    }
}
