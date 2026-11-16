import HUDCore
import SwiftUI

/// The car-status icon discs inside the ring (#99, DESIGN-atelier-tesla-edition.md "Icon disc" and
/// "Shapes", the design page's `slotT` as `drawMain` calls it: `safe` and `rev` on). Each slot is drawn
/// only for an event (L108): an open part red in its open drawing, a low tire amber, an unknown part the
/// closed drawing in grey dashes; otherwise nothing, not even the disc. One door icon stands for any of
/// the four doors. Each lit disc is its own accessibility element, with no words on screen.
enum CarStatusIcon: CaseIterable {
    /// Side view, the hood lifted at the car's front (the upper-left disc).
    case frontTrunk
    /// The door, its leaf open (the left disc, at 9 o'clock).
    case door
    /// Side view, the trunk lid lifted at the rear (the upper-right disc).
    case rearTrunk
    /// The tire with the warning mark (the right disc, at 3 o'clock).
    case tire

    /// What a lit disc shows (the page's modes `on` and `unk`).
    enum Light {
        /// A front trunk, rear trunk or door open: red.
        case open
        /// The car warns about a tire (CONTEXT.md "Low tire"): amber.
        case low
        /// A front trunk, rear trunk or door with no fresh state: grey dashes.
        case unknown
    }

    /// The event rule (L108, CONTEXT.md "Car-status icons"); nil draws nothing. A tire with no reading
    /// draws nothing.
    func light(in status: CarStatus) -> Light? {
        func part(_ state: CarPartState) -> Light? {
            switch state {
            case .open: .open
            case .unknown: .unknown
            case .closed: nil
            }
        }
        return switch self {
        case .frontTrunk: part(status.frontTrunk)
        case .door: part(status.door)
        case .rearTrunk: part(status.rearTrunk)
        case .tire: status.tire == .low ? .low : nil
        }
    }

    /// The lit discs, in the slots' order: front trunk, door, rear trunk, tire.
    static func lit(_ status: CarStatus) -> [(icon: CarStatusIcon, light: Light)] {
        allCases.compactMap { icon in icon.light(in: status).map { (icon, $0) } }
    }

    /// The disc's centre, in design points.
    var center: CGPoint {
        switch self {
        case .frontTrunk: RoundGauge.slots.frontTrunk
        case .door: RoundGauge.slots.door
        case .rearTrunk: RoundGauge.slots.rearTrunk
        case .tire: RoundGauge.slots.tire
        }
    }

    /// The page's `SAY_T` (`on` and `unk`), in the app's words.
    func label(_ light: Light) -> LocalizedStringKey {
        switch (self, light == .unknown) {
        case (.frontTrunk, false): "Frunk open"
        case (.rearTrunk, false): "Rear trunk open"
        case (.door, false): "Door open"
        case (.frontTrunk, true): "Frunk status unknown"
        case (.rearTrunk, true): "Rear trunk status unknown"
        case (.door, true): "Door status unknown"
        case (.tire, _): "Tire pressure low"
        }
    }

    func color(_ light: Light) -> Color {
        switch light {
        case .open: Palette.iconOpen
        case .low: Palette.iconWarning
        case .unknown: Palette.iconUnknown
        }
    }

    // MARK: The disc (`discT`, `defsT`)

    /// `TE.disc`: the fill's radius (37.1 wide), and the rim, a 0.7 line on a circle of 18.2.
    static let discRadius = RoundGauge.discDiameter / 2
    static let rimRadius: CGFloat = 18.2, rimWidth: CGFloat = 0.7
    /// `tDisc` and `tRim`: top-to-bottom gradients across each circle's own box, around `disc-fill` and `disc-rim`.
    static let discFill = Gradient(stops: [.init(color: Palette.hex(0x192027), location: 0), .init(color: Palette.hex(0x13191F), location: 0.5),
                                           .init(color: Palette.hex(0x0D1218), location: 1)])
    static let discRim = Gradient(stops: [.init(color: Palette.hex(0x2D353C), location: 0), .init(color: Palette.hex(0x21272E), location: 0.5),
                                          .init(color: Palette.hex(0x161B21), location: 1)])

    // MARK: The icons (`tiInner`, `TI`, `tDash`)

    /// `TK`: the icons are drawn in the owner's crop coordinates (576 × 576), one unit 0.4758 / 6 design points.
    static let cropUnit: CGFloat = 0.4758 / 6
    /// `TSW`: the line width in crop units (1.67 design points).
    static let lineWidth: CGFloat = 21
    /// `T_SEG_REV` and `T_MIN_REV`: the target and shortest dash, in crop units.
    static let dashTarget: CGFloat = 60, dashMin: CGFloat = 50
    /// The app's gap between dashes, in crop units (3.57 at 1×); the dashes come from the design's `tDash` at this gap.
    /// The design drew a gap of 35 (`T_GAP`) with `T_OFF_LOW`'s phases, both tuned on Chrome's 1× render; CoreGraphics
    /// places dash ends near corners differently from Chrome (up to 1 px), and there they left 1 px gaps. What the
    /// app keeps is the guide's rule, a real gap of at least 2 px at 1× 844 (`dashgap.py`): 45 is the smallest gap at
    /// which every icon passes over a band of at least five phases, and `nativePhase` is each band's centre (#99).
    /// The sweep (native 1× 844, the dashes from `tDash` at each gap, phases 0 to the period in steps of 1):
    /// - 36–44: no; the rear trunk's longest passing band is 3 phases;
    /// - 45: yes (front trunk 22–31, door 0–87, rear trunk 26–34); 46–48: yes.
    static let nativeGap: CGFloat = 45

    /// The disc's centre on the crop (`TI[name].c`).
    var cropCenter: CGPoint {
        switch self {
        case .frontTrunk: CGPoint(x: 290.3, y: 285.0)
        case .door: CGPoint(x: 289.4, y: 289.5)
        case .rearTrunk: CGPoint(x: 294.3, y: 285.5)
        case .tire: CGPoint(x: 292.9, y: 289.7)
        }
    }

    /// Where the dashes start on each closed outline with `nativeGap`: the centre of the band of phases that pass
    /// the 2 px rule on the native 1× 844 render (front trunk 22–31, door 0–87, rear trunk 26–34). The design's
    /// `T_OFF_LOW` was 24 / 33 / 9 for its gap of 35. The tire is never dashed.
    var nativePhase: CGFloat {
        switch self {
        case .frontTrunk: 26.5
        case .door: 43.5
        case .rearTrunk: 30
        case .tire: 0
        }
    }

    enum Part: Equatable {
        /// A stroked line; `closed` outlines take whole dash periods, and `width` overrides `lineWidth`.
        case line(String, closed: Bool = false, width: CGFloat? = nil)
        case fill(String)
        case dot(CGPoint, radius: CGFloat)
    }

    /// `TI[name].parts(tiForm(name, mode, true), dash, true)`: open is the owner's drawing (the front
    /// trunk's lid at the car's front, the door's leaf lengthened); unknown is the closed drawing with no
    /// fills, the door's sill shortened; the tire is always its warning drawing.
    func parts(_ light: Light) -> [Part] {
        let dashed = light == .unknown
        switch self {
        case .frontTrunk:
            return [.line(Self.frunkBody, closed: true)] + (dashed ? [] : [.line(Self.frunkLidFront)])
        case .rearTrunk:
            return [.line(Self.trunkBody, closed: true)] + (dashed ? [] : [.line(Self.trunkLid)])
        case .door:
            return dashed
                ? [.line(Self.doorBody, closed: true), .line("M262 257 H332")]
                : [.line(Self.doorBody, closed: true), .line("M205 247 L128 304"), .line("M240.5 257 H354"),
                   .dot(CGPoint(x: 252, y: 288), radius: 6.5)]
        case .tire:
            return [.line(Self.tireArmLeft), .line(Self.tireArmRight), .line("M292 220 V276", width: 26),
                    .dot(CGPoint(x: 292, y: 317), radius: 14), .fill(Self.tireTread)]
        }
    }

    /// `tDash` with `T_SEG_REV` / `T_MIN_REV` at `gap`: the gap fixed, the dash stretched so each line ends cleanly
    /// (a closed outline in whole periods, an open line solid at both ends), rounded to 0.01 as the page writes it.
    /// Nil when the line is too short for a gap (solid).
    static func dash(length: CGFloat, closed: Bool, phase: CGFloat, gap: CGFloat = nativeGap) -> (lengths: [CGFloat], phase: CGFloat)? {
        let period = dashTarget + gap
        var n = closed ? max(1, Int((length / period).rounded())) : max(0, Int(((length - dashTarget) / period).rounded()))
        func dash() -> CGFloat { closed ? length / CGFloat(n) - gap : (length - CGFloat(n) * gap) / CGFloat(n + 1) }
        while n > (closed ? 1 : 0) && dash() < dashMin { n -= 1 }
        guard n > 0 else { return nil }
        return ([(dash() * 100).rounded() / 100, gap], closed ? phase : 0)
    }

    /// The dashes this icon's unknown outline `path` is drawn with: `tDash` at `nativeGap`, from `nativePhase`.
    func dash(_ path: Path, closed: Bool) -> (lengths: [CGFloat], phase: CGFloat)? {
        Self.dash(length: Self.length(path.cgPath), closed: closed, phase: nativePhase)
    }

    /// The length of `path` (SVG's `getTotalLength`), its curves split finely.
    static func length(_ path: CGPath) -> CGFloat {
        var total: CGFloat = 0, last = CGPoint.zero, start = CGPoint.zero
        func line(to p: CGPoint) {
            total += hypot(p.x - last.x, p.y - last.y)
            last = p
        }
        let steps = 256
        path.applyWithBlock { element in
            let e = element.pointee, p = e.points
            switch e.type {
            case .moveToPoint:
                last = p[0]
                start = p[0]
            case .addLineToPoint:
                line(to: p[0])
            case .addQuadCurveToPoint:
                let p0 = last
                for i in 1...steps {
                    let t = CGFloat(i) / CGFloat(steps), u = 1 - t
                    line(to: CGPoint(x: u * u * p0.x + 2 * u * t * p[0].x + t * t * p[1].x,
                                     y: u * u * p0.y + 2 * u * t * p[0].y + t * t * p[1].y))
                }
            case .addCurveToPoint:
                let p0 = last
                for i in 1...steps {
                    let t = CGFloat(i) / CGFloat(steps), u = 1 - t
                    let a = u * u * u, b = 3 * u * u * t, c = 3 * u * t * t, d = t * t * t
                    line(to: CGPoint(x: a * p0.x + b * p[0].x + c * p[1].x + d * p[2].x,
                                     y: a * p0.y + b * p[0].y + c * p[1].y + d * p[2].y))
                }
            case .closeSubpath:
                line(to: start)
            @unknown default: break
            }
        }
        return total
    }

    /// Crop units to design points: the crop's disc centre onto the slot (`slotT`'s transform).
    var cropTransform: CGAffineTransform {
        CGAffineTransform(translationX: center.x, y: center.y).scaledBy(x: Self.cropUnit, y: Self.cropUnit)
            .translatedBy(x: -cropCenter.x, y: -cropCenter.y)
    }

    /// The disc and its icon, in design points (the context's user space).
    func draw(_ light: Light, in context: GraphicsContext) {
        let r = Self.discRadius, rim = Self.rimRadius, c = center
        context.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)),
                     with: .linearGradient(Self.discFill, startPoint: CGPoint(x: c.x, y: c.y - r), endPoint: CGPoint(x: c.x, y: c.y + r)))
        context.stroke(Path(ellipseIn: CGRect(x: c.x - rim, y: c.y - rim, width: 2 * rim, height: 2 * rim)),
                       with: .linearGradient(Self.discRim, startPoint: CGPoint(x: c.x, y: c.y - rim), endPoint: CGPoint(x: c.x, y: c.y + rim)),
                       lineWidth: Self.rimWidth)
        var icon = context
        icon.concatenate(cropTransform)
        let ink = GraphicsContext.Shading.color(color(light)), dashed = light == .unknown
        for part in parts(light) {
            switch part {
            case .line(let data, let closed, let width):
                let path = SVGPath.parse(data)
                let dash = dashed ? self.dash(path, closed: closed) : nil
                icon.stroke(path, with: ink, style: StrokeStyle(lineWidth: width ?? Self.lineWidth, lineCap: dashed ? .butt : .round,
                                                                lineJoin: .round, dash: dash?.lengths ?? [], dashPhase: dash?.phase ?? 0))
            case .fill(let data):
                icon.fill(SVGPath.parse(data), with: ink)
            case .dot(let p, let radius):
                icon.fill(Path(ellipseIn: CGRect(x: p.x - radius, y: p.y - radius, width: 2 * radius, height: 2 * radius)), with: ink)
            }
        }
    }

    // MARK: The owner's crop drawings (`T_BODY_F`, `T_LID_FRONT`, `T_BODY_T`, `T_LID_T`, `T_DOOR`, `T_ARM_*`, `T_TREAD`)

    private static let frunkBody = "M151 300 V338 Q151 354 167 354 H173 L185 372 H206 L218 354 H357.5 L369 372 H390 L401.5 354 H407 Q422.5 354 422.5 338 V309 Q422.5 295 409 294.5 L390 294 C378 293 372 287 364 280 C350 268 334 257 308 256 H238 L170 273 Q151 277 151 296 Z"
    private static let frunkLidFront = "M270 250 C248 222 224 186 177 184 C154 183 136 196 124 210"
    private static let trunkBody = "M148 300 V337 Q148 353 164 353 H170.5 L182.5 371 H203.5 L215.5 353 H359.5 L371 371 H392 L403.5 353 H410 Q426 353 426 337 V308 Q426 293 412 292.5 L394 292 C382 291 377 286 369 279.5 C355 268 339 256 312 254.5 H235 L167 274 Q148 278 148 297 Z"
    private static let trunkLid = "M304 250 C326 222 350 186 397 184 C420 183 438 196 450 210"
    private static let doorBody = "M208.5 388 V262 L224.5 187 Q229.5 166 249 166 H365 Q384 166 384 185 V388 Q384 402.5 369.5 402.5 H223 Q208.5 402.5 208.5 388 Z"
    private static let tireArmLeft = "M208 178 V200 A118 118 0 0 0 207 364"
    private static let tireArmRight = "M376 178 V200 A118 118 0 0 1 377 364"
    private static let tireTread = "M197 365 H388 V398 Q388 405 381 405 H368 Q364 405 363.500 398 V389 H350.5 V398 Q350.5 405 344 405 H336 Q329.5 405 329.5 398 V389 H318.5 V398 Q318.5 405 312 405 H304 Q297.500 405 297.500 398 V389 H286.5 V398 Q286.5 405 280 405 H272 Q265.5 405 265.5 398 V389 H254.5 V398 Q254.5 405 248 405 H240 Q233.5 405 233.5 398 V389 H221 V398 Q221 405 216 405 H204 Q197 405 197 398 Z"
}

/// One lit disc with its own sentence (「後車廂開著」「車門狀態未知」「胎壓不足」), drawn in design points.
struct CarStatusDiscView: View {
    let icon: CarStatusIcon
    let light: CarStatusIcon.Light
    let canvas: DesignCanvas

    /// The disc's box on the screen, snapped outward to whole points, so the view sits on the pixel grid
    /// and the disc keeps its exact place inside it.
    static func frame(_ icon: CarStatusIcon, canvas: DesignCanvas) -> CGRect {
        let r = CarStatusIcon.discRadius + 1, c = icon.center
        let box = canvas.rect(CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r))
        let minX = box.minX.rounded(.down), minY = box.minY.rounded(.down)
        return CGRect(x: minX, y: minY, width: box.maxX.rounded(.up) - minX, height: box.maxY.rounded(.up) - minY)
    }

    var body: some View {
        let frame = Self.frame(icon, canvas: canvas)
        // Design points to this view's points.
        let transform = canvas.transform.concatenating(CGAffineTransform(translationX: -frame.minX, y: -frame.minY))
        Canvas { context, _ in
            var context = context
            context.concatenate(transform)
            icon.draw(light, in: context)
        }
        .frame(width: frame.width, height: frame.height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(icon.label(light)))
    }
}

/// The lit discs at their fixed slots, placed from the screen's top-left corner. A slot never moves and is
/// never filled by another icon; a disc appears and goes at once. VoiceOver reads them in the slots' order
/// (front trunk, door, rear trunk, tire), after the gear row.
struct CarStatusDiscs: View {
    let status: CarStatus
    let canvas: DesignCanvas

    /// The four slots' box on the screen, whichever are lit.
    static func frame(_ canvas: DesignCanvas) -> CGRect {
        CarStatusIcon.allCases.reduce(CGRect.null) { $0.union(CarStatusDiscView.frame($1, canvas: canvas)) }
    }

    var body: some View {
        let box = Self.frame(canvas)
        ZStack(alignment: .topLeading) {
            ForEach(CarStatusIcon.lit(status), id: \.icon) { item in
                let frame = CarStatusDiscView.frame(item.icon, canvas: canvas)
                CarStatusDiscView(icon: item.icon, light: item.light, canvas: canvas)
                    .offset(x: frame.minX - box.minX, y: frame.minY - box.minY)
                    .accessibilitySortPriority(Double(CarStatusIcon.allCases.count - CarStatusIcon.allCases.firstIndex(of: item.icon)!))
            }
        }
        .frame(width: box.width, height: box.height, alignment: .topLeading)
        .offset(x: box.minX, y: box.minY)
        .accessibilityElement(children: .contain)
        .allowsHitTesting(false)
        .transaction { $0.animation = nil }
    }
}
