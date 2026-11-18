import CoreText
import HUDCore
import SwiftUI
import UIKit

// The drive screen's frame (#100), ported from the design page's `navX`, `tyreColN(COL25.a)` and `footX`, drawn
// in design points on the layout's canvas. Text is the iOS system font (the page's `FF.fam`: SF Pro, PingFang TC
// for Chinese), placed by its ink as `placeF` places it.

/// The design page's `placeF`: one line of the system font, placed by its ink in design points. Horizontally its
/// ink starts at `left` or ends at `right`; vertically the ink of `ref` (the string itself when nil) is centred
/// on `cy`. Digits are tabular unless `proportional` (the page's `prop: 1`).
struct PlacedText {
    enum Horizontal {
        case left(CGFloat), right(CGFloat)
    }

    let line: CTLine
    /// The pen on the baseline.
    let pen: CGPoint
    /// The string's ink left and right, the ref's ink top and bottom (the page's `box`).
    let box: CGRect
    let color: Color

    init(_ string: String, _ horizontal: Horizontal, cy: CGFloat, weight: UIFont.Weight, size: CGFloat, color: Color,
         ref: String? = nil, proportional: Bool = false, language: String? = nil, maxWidth: CGFloat? = nil) {
        let font = Self.font(weight: weight, size: size, proportional: proportional)
        var line = GaugeLabels.line(string, font: font, language: language)
        if let maxWidth, CTLineGetTypographicBounds(line, nil, nil, nil) > maxWidth {
            let token = GaugeLabels.line("…", font: font, language: language)
            line = CTLineCreateTruncatedLine(line, maxWidth, .end, token) ?? line
        }
        let ink = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
        let refInk = ref.map { GaugeLabels.ink($0, font: font, language: language) } ?? ink
        let a = refInk.maxY, d = -refInk.minY
        let x = switch horizontal {
        case .left(let left): left - ink.minX
        case .right(let right): right - ink.maxX
        }
        let base = cy + (a - d) / 2
        self.line = line
        pen = CGPoint(x: x, y: base)
        box = CGRect(x: x + ink.minX, y: base - a, width: ink.width, height: a + d)
        self.color = color
    }

    static func font(weight: UIFont.Weight, size: CGFloat, proportional: Bool) -> UIFont {
        proportional ? .systemFont(ofSize: size, weight: weight) : .monospacedDigitSystemFont(ofSize: size, weight: weight)
    }

    /// The ascent of "0" (the page's `asc0`): a second size on the same baseline.
    static func zeroAscent(weight: UIFont.Weight, size: CGFloat) -> CGFloat {
        GaugeLabels.ink("0", font: font(weight: weight, size: size, proportional: true)).maxY
    }

    /// Draws the line in a context already in design points, with y down.
    func draw(in cg: CGContext) {
        cg.saveGState()
        cg.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
        GaugeLabels.placeGlyphsExactly(cg)
        cg.setFillColor(UIColor(color).cgColor)
        cg.textPosition = pen
        CTLineDraw(line, cg)
        cg.restoreGState()
    }
}

/// A view on the canvas that draws in design points: it covers `design` rounded out to whole points on the
/// screen, and `draw` gets a context in design points.
struct DesignDrawing: View {
    let canvas: DesignCanvas
    let design: CGRect
    let draw: (inout GraphicsContext) -> Void

    static func frame(_ design: CGRect, canvas: DesignCanvas) -> CGRect {
        let r = canvas.rect(design)
        let x = (r.minX + 1e-6).rounded(.down), y = (r.minY + 1e-6).rounded(.down)
        return CGRect(x: x, y: y, width: (r.maxX - 1e-6).rounded(.up) - x, height: (r.maxY - 1e-6).rounded(.up) - y)
    }

    var body: some View {
        let frame = Self.frame(design, canvas: canvas)
        Canvas { context, _ in
            context.concatenate(canvas.transform.concatenating(CGAffineTransform(translationX: -frame.minX, y: -frame.minY)))
            draw(&context)
        }
        .frame(width: frame.width, height: frame.height)
        .offset(x: frame.minX, y: frame.minY)
        .allowsHitTesting(false)
    }
}

extension GraphicsContext {
    /// `text` drawn with Core Text in this context's design points.
    func drawPlaced(_ texts: [PlacedText]) {
        withCGContext { cg in
            for text in texts { text.draw(in: cg) }
        }
    }
}

// MARK: Left card

/// The left card's face (`navX`'s first two rects): the fill from `#14171B` at the top right to `#101317` at the
/// bottom left (`xnFill`), and a 1 px white rim at 6–7% (`xnRim`), radius 17. It stays put while its content
/// changes, so the Q11 fade never dims it.
struct LeftCardFace: View {
    let canvas: DesignCanvas

    var body: some View {
        let card = DriveFrame.leftCard, r = DriveFrame.leftCardRadius
        DesignDrawing(canvas: canvas, design: card) { context in
            context.fill(Path(roundedRect: card, cornerRadius: r),
                         with: .linearGradient(Gradient(colors: [Palette.cardFillTop, Palette.cardFillBottom]),
                                               startPoint: CGPoint(x: card.maxX, y: card.minY), endPoint: CGPoint(x: card.minX, y: card.maxY)))
            context.stroke(Path(roundedRect: card.insetBy(dx: 0.5, dy: 0.5), cornerRadius: r - 0.5),
                           with: .linearGradient(Gradient(stops: [.init(color: .white.opacity(0.07), location: 0),
                                                                  .init(color: .white.opacity(0.06), location: 0.3),
                                                                  .init(color: .white.opacity(0.06), location: 1)]),
                                                 startPoint: CGPoint(x: card.minX, y: card.minY), endPoint: CGPoint(x: card.minX, y: card.maxY)),
                           lineWidth: 1)
        }
        .accessibilityHidden(true)
    }
}

/// The left card's content (owner decision 1, #96): the car navigation as `navX` draws it, or the trip in the same
/// frame. One VoiceOver element: 「車上導航」 read in words, 「車上導航資料過期」 for the stale pin, or 「行程」.
struct LeftCardContent: View {
    let card: DriveLeftCard
    let unit: SpeedUnit
    let canvas: DesignCanvas
    @Environment(\.locale) private var locale

    var body: some View {
        switch card {
        case .navigation(.route(let route)):
            let copy = NavigationCopy(route: route, unit: unit, locale: locale)
            let texts = Self.routeTexts(copy, language: locale.identifier)
            DesignDrawing(canvas: canvas, design: DriveFrame.leftCard) { context in
                RoadArt.draw(in: &context)
                context.stroke(Self.pin, with: .color(Palette.frameText),
                               style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                context.drawPlaced(texts)
            }
            .accessibilityElement()
            .accessibilityLabel(Text(verbatim: copy.title))
            .accessibilityValue(Text(verbatim: copy.spoken))
        case .navigation:
            // Stale: the pin dashed in place, no words (L84-4); ended never reaches here (it is the trip).
            DesignDrawing(canvas: canvas, design: DriveFrame.leftCard) { context in
                context.stroke(Self.pinOutline, with: .color(Palette.textTertiary),
                               style: StrokeStyle(lineWidth: 1.8, lineJoin: .round, dash: [2.6, 1.8]))
                context.stroke(Self.pinDot, with: .color(Palette.textTertiary), lineWidth: 1.8)
            }
            .accessibilityElement()
            .accessibilityLabel(Text("Navigation data stale"))
            .accessibilityAddTraits(.isImage)
        case .trip(let trip):
            let copy = TripCopy(trip: trip, unit: unit, locale: locale)
            let texts = Self.tripTexts(copy, language: locale.identifier)
            DesignDrawing(canvas: canvas, design: DriveFrame.leftCard) { context in
                context.drawPlaced(texts)
            }
            .accessibilityElement()
            .accessibilityLabel(Text(verbatim: copy.title))
            .accessibilityValue(Text(verbatim: copy.spoken([copy.spokenDistance, copy.spokenDriveTime])))
        }
    }

    /// The destination pin (`navX`, at (82.3, 98), half size, line 3.6 there): outline and dot.
    static let pinTransform = CGAffineTransform(translationX: DriveFrame.leftCardTextX + 7.3, y: 98).scaledBy(x: 0.5, y: 0.5)
    static let pinOutline = SVGPath.parse("M0 16.5 C-7 9 -12.6 3 -12.6 -3.6 C-12.6 -10.6 -7 -16 0 -16 C7 -16 12.6 -10.6 12.6 -3.6 C12.6 3 7 9 0 16.5 Z")
        .applying(pinTransform)
    static let pinDot = Path(ellipseIn: CGRect(x: -4.2, y: -7.8, width: 8.4, height: 8.4)).applying(pinTransform)
    static var pin: Path {
        var path = pinOutline
        path.addPath(pinDot)
        return path
    }

    /// The destination's right end: the card's right edge less the text column's inset.
    static let destinationMaxX = DriveFrame.leftCard.maxX - (DriveFrame.leftCardTextX - DriveFrame.leftCard.minX)

    /// `navX`'s text: the destination 15/400 beside the pin (one line, `…`), the distance 20/600 with its unit
    /// 14/500 on the same baseline, 剩餘 time and 抵達時約剩 12/400 `FF.sec`.
    static func routeTexts(_ copy: NavigationCopy, language: String) -> [PlacedText] {
        let x = DriveFrame.leftCardTextX, destinationX = x + 22
        var texts = [PlacedText(copy.destination, .left(destinationX), cy: 98, weight: .regular, size: 15, color: Palette.frameText,
                                language: language, maxWidth: destinationMaxX - destinationX)]
        let distance = PlacedText(copy.distance, .left(x), cy: 196, weight: .semibold, size: 20, color: Palette.frameText, ref: "0",
                                  proportional: true, language: language)
        texts.append(distance)
        if let unit = copy.distanceUnit {
            texts.append(PlacedText(unit, .left(distance.box.maxX + 4), cy: distance.box.maxY - PlacedText.zeroAscent(weight: .medium, size: 14) / 2,
                                    weight: .medium, size: 14, color: Palette.frameText, ref: "0", proportional: true, language: language))
        }
        let minutes = [copy.remainingLabel, copy.minutes, copy.minutesUnit].compactMap { $0 }.joined(separator: " ")
        texts.append(PlacedText(minutes, .left(x), cy: 220, weight: .regular, size: 12, color: Palette.frameLabel, language: language))
        if let arrival = copy.arrival {
            texts.append(PlacedText(arrival, .left(x), cy: 241, weight: .regular, size: 12, color: Palette.frameLabel, language: language))
        }
        return texts
    }

    /// The trip in the card (the design never drew it): today's drive trip, 本趟 and 行駛時間, each a label 12/400
    /// `FF.sec` over its value 20/600 `FF.mid` (unit 14/500 on its baseline), as the navigation card's type; the
    /// block centred in the card's height, on its text column.
    static func tripTexts(_ copy: TripCopy, language: String) -> [PlacedText] {
        let x = DriveFrame.leftCardTextX, card = DriveFrame.leftCard
        // Label to value 22, item to item 50: the block's ink is about 79 high, centred in the card.
        let top = card.midY - 36.7
        var texts: [PlacedText] = []
        for (i, item) in [(copy.distanceLabel, copy.distance, copy.distanceUnit), (copy.driveTimeLabel, copy.driveTime, nil)].enumerated() {
            let labelY = top + CGFloat(i) * 50
            texts.append(PlacedText(item.0, .left(x), cy: labelY, weight: .regular, size: 12, color: Palette.frameLabel, language: language))
            let value = PlacedText(item.1, .left(x), cy: labelY + 22, weight: .semibold, size: 20, color: Palette.frameText, ref: "0",
                                   proportional: true, language: language)
            texts.append(value)
            if let unit = item.2 {
                texts.append(PlacedText(unit, .left(value.box.maxX + 4), cy: value.box.maxY - PlacedText.zeroAscent(weight: .medium, size: 14) / 2,
                                        weight: .medium, size: 14, color: Palette.frameText, ref: "0", proportional: true, language: language))
            }
        }
        return texts
    }
}

/// The road behind the navigation card (`roadF`, shifted by `742 − roadX` into the card): three faint lines fading
/// in from the left, the route ahead and the car's arrow. Decoration: not read aloud.
enum RoadArt {
    /// `roadF`'s `ax`, 742, moved to the card's `roadX`, 206.
    static let shift: CGFloat = 742 - 206
    static let top: CGFloat = 112

    static func draw(in context: inout GraphicsContext) {
        let card = DriveFrame.leftCard, r = DriveFrame.leftCardRadius
        let y0 = top, y1 = card.maxY, ax = 742 - shift, ay = y0 + 43
        var clipped = context
        // The card (`xNavClip`), the road's area (`xRoadClip`: the full width down to y 175, then from x 172 only),
        // and the road's own rounded box (`fnClip`).
        clipped.clip(to: Path(roundedRect: card, cornerRadius: r))
        var area = Path()
        area.addLines([CGPoint(x: card.minX, y: y0), CGPoint(x: card.maxX, y: y0), CGPoint(x: card.maxX, y: y1),
                       CGPoint(x: 172, y: y1), CGPoint(x: 172, y: 175), CGPoint(x: card.minX, y: 175)])
        area.closeSubpath()
        clipped.clip(to: area)
        var road = clipped
        road.clip(to: Path(roundedRect: CGRect(x: card.minX, y: y0, width: card.width, height: y1 - y0), cornerRadius: r))
        // The lines, masked by a fade from x 618 to 700 (−shift).
        road.drawLayer { layer in
            func line(_ x0: CGFloat, _ x1: CGFloat, opacity: Double, width: CGFloat, dash: [CGFloat] = []) {
                var path = Path()
                path.move(to: CGPoint(x: x0 - shift, y: y1))
                path.addLine(to: CGPoint(x: x1 - shift, y: y0))
                layer.stroke(path, with: .color(.white.opacity(opacity)), style: StrokeStyle(lineWidth: width, lineCap: .round, dash: dash))
            }
            line(632, 676, opacity: 0.1, width: 1.3)
            line(688, 714, opacity: 0.17, width: 1.6, dash: [8, 9])
            line(806, 782, opacity: 0.08, width: 1.3)
            layer.blendMode = .destinationIn
            layer.fill(Path(CGRect(x: card.minX, y: y0, width: card.width, height: y1 - y0)),
                       with: .linearGradient(Gradient(colors: [.white.opacity(0), .white]), startPoint: CGPoint(x: 618 - shift, y: 0),
                                             endPoint: CGPoint(x: 700 - shift, y: 0)))
        }
        var body = Path()
        body.addLines([CGPoint(x: ax - 6, y: y1), CGPoint(x: ax + 6, y: y1), CGPoint(x: ax + 5, y: ay), CGPoint(x: ax - 5, y: ay)])
        body.closeSubpath()
        road.fill(body, with: .color(Palette.road.opacity(0.22)))
        var ahead = Path()
        ahead.addLines([CGPoint(x: ax - 5, y: ay), CGPoint(x: ax + 5, y: ay), CGPoint(x: ax + 3.4, y: y0), CGPoint(x: ax - 3.4, y: y0)])
        ahead.closeSubpath()
        road.fill(ahead, with: .linearGradient(Gradient(stops: [.init(color: Palette.road.opacity(0.85), location: 0),
                                                                .init(color: Palette.road.opacity(0.55), location: 0.5),
                                                                .init(color: Palette.road.opacity(0.12), location: 1)]),
                                               startPoint: CGPoint(x: 0, y: y1), endPoint: CGPoint(x: 0, y: y0)))
        // The car's arrow, inside the card's clips only.
        var arrow = Path()
        arrow.addLines([CGPoint(x: ax, y: ay - 12), CGPoint(x: ax + 11.5, y: ay + 9), CGPoint(x: ax, y: ay + 3.4), CGPoint(x: ax - 11.5, y: ay + 9)])
        arrow.closeSubpath()
        clipped.fill(arrow, with: .color(Palette.navigationArrow))
        clipped.stroke(arrow, with: .color(Palette.frameText), style: StrokeStyle(lineWidth: 1.4, lineJoin: .round))
        var inner = Path()
        inner.addLines([CGPoint(x: ax, y: ay - 5), CGPoint(x: ax + 4.6, y: ay + 4), CGPoint(x: ax, y: ay + 1.8), CGPoint(x: ax - 4.6, y: ay + 4)])
        inner.closeSubpath()
        clipped.fill(inner, with: .color(Palette.frameText.opacity(0.9)))
        // The fade at the bottom right (`xRoadFadeB`), in the card's clip.
        var fadeClip = context
        fadeClip.clip(to: Path(roundedRect: card, cornerRadius: r))
        let bottom = CGRect(x: 172, y: card.maxY - 24, width: card.maxX - 172, height: 24)
        fadeClip.fill(Path(bottom), with: .linearGradient(Gradient(colors: [Palette.frameSurface.opacity(0), Palette.frameSurface]),
                                                         startPoint: CGPoint(x: 0, y: bottom.minY), endPoint: CGPoint(x: 0, y: bottom.maxY)))
        // The fade where the route meets the destination's line (`xRoadFade`), unclipped.
        let fade = CGRect(x: 206 - 40, y: y0, width: 80, height: 30)
        context.fill(Path(fade), with: .linearGradient(Gradient(colors: [Palette.frameSurface, Palette.frameSurface.opacity(0)]),
                                                      startPoint: CGPoint(x: 0, y: fade.minY), endPoint: CGPoint(x: 0, y: fade.maxY)))
    }
}

// MARK: Tire column

/// The drive screen's tire column (`tyreColN(COL25.a)`, L108): the tire mark and 「胎壓」, a top-view car 130 high
/// centred on x 683, and one reading 15/500 beside each tire, right-aligned at 640 on the left and left-aligned at
/// 726 on the right. A low wheel fills its tire and turns its reading amber (`icon-warning`); a reading more than
/// 15 minutes old, or with no known time, dims to `tire.stale`, unless it is low; no reading is a dash. Each wheel
/// is its own VoiceOver element, front left, front right, rear left, rear right.
struct TireColumnView: View {
    let wheels: TireWheels
    let canvas: DesignCanvas
    @Environment(\.locale) private var locale

    /// `COL25.a`: the title's left edge (x 592 + 6.5), its centre line, the car's top, height and centre, the
    /// readings' edges, and the car's line width.
    static let titleX: CGFloat = 598.5, titleY: CGFloat = 98.2
    static let carTop: CGFloat = 117, carHeight: CGFloat = 130, carCenterX: CGFloat = 683
    static let readingRight: CGFloat = 640, readingLeft: CGFloat = 726
    static let lineWidth: CGFloat = 1.2
    /// The car's drawing units (262.4 high) to design points.
    static var carScale: CGFloat { carHeight / 262.4 }
    static var readingY: [CGFloat] { [carTop + 66.2 * carScale, carTop + 198.8 * carScale] }

    var body: some View {
        let language = locale.identifier
        let texts = Self.readings(wheels, language: language)
        let title = PlacedText(locale.localized("Tires"), .left(Self.titleX + 22), cy: Self.titleY, weight: .regular, size: 15,
                               color: Palette.frameLabel, language: language)
        let spoken = Self.spoken(wheels, locale: locale)
        ZStack(alignment: .topLeading) {
            DesignDrawing(canvas: canvas, design: DriveFrame.tireColumn) { context in
                Self.drawMark(in: &context)
                Self.drawCar(wheels, in: &context)
                context.drawPlaced([title] + texts)
            }
            .accessibilityHidden(true)
            ForEach(0..<4, id: \.self) { i in
                let frame = canvas.rect(texts[i].box)
                Color.clear
                    .frame(width: frame.width, height: frame.height)
                    .offset(x: frame.minX, y: frame.minY)
                    .accessibilityElement()
                    .accessibilityLabel(Text(verbatim: spoken[i]))
                    .accessibilitySortPriority(Double(4 - i))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(verbatim: locale.localized("Tires")))
        .allowsHitTesting(false)
    }

    /// The four readings, front left, front right, rear left, rear right.
    static func readings(_ wheels: TireWheels, language: String) -> [PlacedText] {
        wheels.all.enumerated().map { i, wheel in
            let left = i % 2 == 0
            return PlacedText(wheel.psi.map { "\($0) psi" } ?? HUDState.noSpeedNumeral, left ? .right(readingRight) : .left(readingLeft),
                              cy: readingY[i / 2], weight: .medium, size: 15, color: color(wheel), ref: "0", proportional: true,
                              language: language)
        }
    }

    static func color(_ wheel: TireWheel) -> Color {
        wheel.isLow ? Palette.iconWarning : wheel.isDimmed ? Palette.tireStale : Palette.frameText
    }

    /// 「左前,42 psi」, 「左後,31 psi,胎壓不足」, 「右後,尚無讀值」, with the age of an old reading.
    static func spoken(_ wheels: TireWheels, locale: Locale) -> [String] {
        let copy = TireCopy(panel: .wheels(wheels), locale: locale)
        return zip(copy.spoken, wheels.all).map { said, wheel in wheel.isLow ? locale.localized("\(said), low") : said }
    }

    /// The tire mark (`tyreColN`'s first group): at the title's left, scaled 1.25, line 1.3 `FF.sec`.
    static func drawMark(in context: inout GraphicsContext) {
        var mark = context
        mark.translateBy(x: titleX + 7.5, y: titleY)
        mark.scaleBy(x: 1.25, y: 1.25)
        let style = StrokeStyle(lineWidth: 1.3, lineCap: .round, lineJoin: .round)
        mark.stroke(SVGPath.parse("M-4.6 -5.6 C-5.8 -2.6 -5.9 1 -4.4 3.6 C-3.4 5.3 -1.8 6 0 6 C1.8 6 3.4 5.3 4.4 3.6 C5.9 1 5.8 -2.6 4.6 -5.6"),
                    with: .color(Palette.frameLabel), style: style)
        mark.stroke(SVGPath.parse("M-3.4 6 V7.4 M-1.1 6.2 V7.6 M1.1 6.2 V7.6 M3.4 6 V7.4"), with: .color(Palette.frameLabel),
                    style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
        mark.stroke(SVGPath.parse("M0 -3.2 V.6"), with: .color(Palette.frameLabel), style: style)
        let dot = Path(ellipseIn: CGRect(x: -0.6, y: 2.4, width: 1.2, height: 1.2))
        mark.fill(dot, with: .color(Palette.frameLabel))
        mark.stroke(dot, with: .color(Palette.frameLabel), style: style)
    }

    /// The top-view car (`CAR_BODY`, `CAR_GLASS`, the windows, the tires, the mirrors), in its 262.4-high units.
    static func drawCar(_ wheels: TireWheels, in context: inout GraphicsContext) {
        var car = context
        car.translateBy(x: carCenterX, y: carTop)
        car.scaleBy(x: carScale, y: carScale)
        let line = StrokeStyle(lineWidth: lineWidth / carScale, lineJoin: .round)
        for path in [CarOutline.body, CarOutline.glass, CarOutline.window, CarOutline.window.applying(CGAffineTransform(scaleX: -1, y: 1))] {
            car.stroke(path, with: .color(Palette.frameLabel), style: line)
        }
        for (wheel, origin) in zip(wheels.all, [CGPoint(x: -64, y: 43.2), CGPoint(x: 41, y: 43.2), CGPoint(x: -64, y: 175.8), CGPoint(x: 41, y: 175.8)]) {
            let tire = Path(roundedRect: CGRect(origin: origin, size: CGSize(width: 23, height: 46)), cornerRadius: 6)
            car.fill(tire, with: .color(wheel.isLow ? Palette.iconWarning : Palette.tireFill))
            car.stroke(tire, with: .color(wheel.isLow ? Palette.iconWarning : Palette.tireEdge), style: line)
        }
        for path in [CarOutline.mirror, CarOutline.mirror.applying(CGAffineTransform(scaleX: -1, y: 1))] {
            car.stroke(path, with: .color(Palette.frameLabel), style: line)
        }
    }
}

/// The design page's top-view car, nose up, centred on x 0 and 262.4 high: the body and the glass are the
/// page's `mirrorPath` (a closed Catmull-Rom curve through the right half and its mirror); the window and the
/// mirror are its SVG paths.
enum CarOutline {
    static let body = mirrored([(0, 0.4), (10, 0.9), (19.4, 2.2), (27.6, 5), (33.5, 8), (38.4, 11), (42.4, 14), (45.5, 17), (47.7, 20),
                                (49.5, 23), (51, 26), (52.1, 29), (52.8, 32), (53.5, 35), (54.2, 41), (54.7, 48), (54.7, 66), (54.1, 72),
                                (53.5, 80), (53.3, 95), (53.3, 180), (53.7, 186), (54.3, 192), (54.4, 205), (54.2, 212), (53.6, 218),
                                (52.7, 224), (51.3, 230), (49.3, 236), (47.2, 242), (45.8, 245), (43.8, 248), (40.7, 251), (35.8, 254),
                                (28.9, 257), (18.6, 260), (9, 261.7), (0, 262.2)])
    static let glass = mirrored([(0, 54.2), (12, 54.8), (22, 56), (30, 57.9), (35.4, 60.4), (38.3, 64.2), (38.7, 72), (38.5, 100), (37.5, 140),
                                 (36.3, 165), (35.3, 185), (34.3, 200), (33.3, 210), (32.2, 220), (31, 228), (29.4, 235), (27, 239.4),
                                 (22.6, 242.6), (13, 245.2), (0, 246.6)])
    static let window = SVGPath.parse("M43 65 C46 70 47.8 77 47.9 88 L47.9 138 C47.8 160 46.8 180 44.8 192 C43.8 199 42.6 206 40.8 212 "
        + "C40.5 204 40.5 196 40.7 186 C41 168 41.6 150 42.4 124 L42.6 76 Z")
    static let mirror = SVGPath.parse("M52.4 86.6 C56.8 87.8 61.8 92 64.8 97.4 C65.8 99.2 65.2 101.6 63 101.4 C60 101.1 56.4 99.4 52.8 96.8 Z")

    /// `mirrorPath(pts)`: the points, then the inner ones mirrored in reverse, joined by the closed Catmull-Rom
    /// curve's Bézier segments.
    static func mirrored(_ points: [(CGFloat, CGFloat)]) -> Path {
        let half = points.map { CGPoint(x: $0.0, y: $0.1) }
        let all = half + half.dropFirst().dropLast().reversed().map { CGPoint(x: -$0.x, y: $0.y) }
        let n = all.count
        func p(_ i: Int) -> CGPoint { all[(i % n + n) % n] }
        var path = Path()
        path.move(to: all[0])
        for i in 0..<n {
            let p0 = p(i - 1), p1 = p(i), p2 = p(i + 1), p3 = p(i + 2)
            path.addCurve(to: p2, control1: CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6),
                          control2: CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6))
        }
        path.closeSubpath()
        return path
    }
}

// MARK: Footer

/// The footer's left (`footX`, L33, L50): a battery outline 23.6 × 12.4 filled with the level, `72` 17/500 and `%`
/// 17/400 in `FF.mid`, a dot, then `315 km` 16/500 `FF.sec`, on the centre line y 345.6 from x 90. Waiting, or stale
/// on the drive screen, shows `—% · — km` with an empty outline; parked, a stale value stays in `text.stale` and
/// its age follows after a dot (where the page puts 充電中). One VoiceOver element 「電量與續航」.
struct BatteryBlockView: View {
    let block: BatteryBlock
    let unit: SpeedUnit
    var parked = false
    let canvas: DesignCanvas
    @Environment(\.locale) private var locale

    /// `72%` and `315 km`, or `—%` and `— km` while waiting or stale. Range groups thousands
    /// (`1,015 km`) in every language.
    static func parts(_ block: BatteryBlock, unit: SpeedUnit) -> (battery: String, range: String) {
        guard case .value(let percent, let range) = block else { return ("—%", "— \(unit.distanceSymbol)") }
        let rangeText = range.map { $0.formatted(.number.locale(Locale(identifier: "en_US"))) } ?? "—"
        return ("\(percent.map(String.init) ?? "—")%", "\(rangeText) \(unit.distanceSymbol)")
    }

    /// The shown text, or words when there is no value: VoiceOver never reads "—% / — km".
    static func spokenValue(_ block: BatteryBlock, unit: SpeedUnit) -> Text {
        guard case .value = block else { return Text("Battery: no reading yet") }
        let parts = parts(block, unit: unit)
        return Text(verbatim: "\(parts.battery) / \(parts.range)")
    }

    /// What the block shows: parked, a stale value is shown as a value.
    private var shown: BatteryBlock {
        if parked, case .stale(let percent, let range, _) = block { .value(percent: percent, range: range) } else { block }
    }

    /// The age's minutes: parked with a stale value only.
    private var staleMinutes: Int? {
        if parked, case .stale(_, _, let minutes) = block { minutes } else { nil }
    }

    /// The icon's level, 0–1; none while waiting or stale on the drive screen, so no old level shows.
    private var level: CGFloat? {
        if case .value(let percent?, _) = shown { CGFloat(min(max(percent, 0), 100)) / 100 } else { nil }
    }

    /// The design box the block draws in: from the icon to past the longest line it can show.
    static let design = CGRect(x: DriveFrame.footerLeft - 1, y: DriveFrame.footerY - 12, width: 300, height: 24)

    var body: some View {
        let age = staleMinutes.map { AgeText.text(minutes: $0, locale: locale) }
        let texts = Self.texts(shown, unit: unit, age: age, stale: staleMinutes != nil, language: locale.identifier)
        let level = level, stale = staleMinutes != nil
        DesignDrawing(canvas: canvas, design: Self.design) { context in
            Self.drawIcon(level: level, stale: stale, in: &context)
            context.fill(Self.dot(after: texts[1]), with: .color(Palette.frameLabel))
            if texts.count > 3 { context.fill(Self.ageDot(after: texts[2]), with: .color(Palette.frameLabel)) }
            context.drawPlaced(texts)
        }
        .accessibilityElement()
        .accessibilityLabel(Text("Battery and range"))
        .accessibilityValue(age.map { Text("\(Self.spokenValue(shown, unit: unit)), \($0)") } ?? Self.spokenValue(shown, unit: unit))
    }

    /// `72`, `%`, `315 km` and, parked with a stale value, its age.
    static func texts(_ block: BatteryBlock, unit: SpeedUnit, age: String?, stale: Bool, language: String) -> [PlacedText] {
        let parts = parts(block, unit: unit), y = DriveFrame.footerY
        let value = stale ? Palette.textStale : Palette.frameText, label = stale ? Palette.textStale : Palette.frameLabel
        let percent = PlacedText(String(parts.battery.dropLast()), .left(DriveFrame.footerLeft + 35.5), cy: y, weight: .medium, size: 17,
                                 color: value, ref: "0", proportional: true)
        let sign = PlacedText("%", .left(percent.box.maxX + 1), cy: y, weight: .regular, size: 17, color: value, ref: "0", proportional: true)
        let range = PlacedText(parts.range, .left(sign.box.maxX + 14.5), cy: y, weight: .medium, size: 16, color: label, ref: "0",
                               proportional: true)
        var texts = [percent, sign, range]
        if let age {
            texts.append(PlacedText(age, .left(range.box.maxX + 15.5), cy: y, weight: .regular, size: 15, color: Palette.frameLabel,
                                    language: language))
        }
        return texts
    }

    /// The dot between `%` and the range (`pc.box.r + 7.2`), r 1.3 `FF.sec`.
    static func dot(after sign: PlacedText) -> Path {
        Path(ellipseIn: CGRect(x: sign.box.maxX + 7.2 - 1.3, y: DriveFrame.footerY - 1.3, width: 2.6, height: 2.6))
    }

    /// The dot before the age (`km.box.r + 8.5`).
    static func ageDot(after range: PlacedText) -> Path {
        Path(ellipseIn: CGRect(x: range.box.maxX + 8.5 - 1.3, y: DriveFrame.footerY - 1.3, width: 2.6, height: 2.6))
    }

    /// The outline (line 1.4, radius 3.4), the terminal 1.8 × 4.8, and the level up to 18.8 wide.
    static func drawIcon(level: CGFloat?, stale: Bool, in context: inout GraphicsContext) {
        let x = DriveFrame.footerLeft, y = DriveFrame.footerY
        context.stroke(Path(roundedRect: CGRect(x: x, y: y - 6.2, width: 23.6, height: 12.4), cornerRadius: 3.4),
                       with: .color(Palette.frameText), lineWidth: 1.4)
        context.fill(Path(roundedRect: CGRect(x: x + 24.7, y: y - 2.4, width: 1.8, height: 4.8), cornerRadius: 0.9),
                     with: .color(Palette.frameText))
        if let level, level > 0 {
            context.fill(Path(roundedRect: CGRect(x: x + 2.4, y: y - 3.8, width: 18.8 * level, height: 7.6), cornerRadius: 1.4),
                         with: .color(stale ? Palette.batteryStaleFill : Palette.frameText))
        }
    }
}

/// The footer's right (`footX`): `48,213 km` 16/500 `FF.mid` ending at x 769, and `ODO` 14/500 `FF.sec` 8 left of
/// it on its baseline; `— km` before the first value. VoiceOver reads 「總里程 48,213 公里」.
struct OdometerView: View {
    let odometer: Odometer
    let unit: SpeedUnit
    let canvas: DesignCanvas
    @Environment(\.locale) private var locale

    static let design = CGRect(x: DriveFrame.footerRight - 200, y: DriveFrame.footerY - 12, width: 201, height: 24)

    static func value(_ odometer: Odometer) -> String? {
        guard case .value(let value) = odometer else { return nil }
        return value.formatted(.number.locale(Locale(identifier: "en_US")))
    }

    static func texts(_ odometer: Odometer, unit: SpeedUnit) -> [PlacedText] {
        let number = PlacedText("\(value(odometer) ?? HUDState.noSpeedNumeral) \(unit.distanceSymbol)", .right(DriveFrame.footerRight),
                                cy: DriveFrame.footerY, weight: .medium, size: 16, color: Palette.frameText, ref: "0", proportional: true)
        let label = PlacedText("ODO", .right(number.box.minX - 8), cy: number.box.maxY - PlacedText.zeroAscent(weight: .medium, size: 14) / 2,
                               weight: .medium, size: 14, color: Palette.frameLabel, ref: "0", proportional: true)
        return [label, number]
    }

    var body: some View {
        let texts = Self.texts(odometer, unit: unit)
        let words = unit == .kilometersPerHour ? locale.localized("kilometers") : locale.localized("miles")
        DesignDrawing(canvas: canvas, design: Self.design) { context in
            context.drawPlaced(texts)
        }
        .accessibilityElement()
        .accessibilityLabel(Text(verbatim: Self.value(odometer).map { locale.localized("Odometer \($0) \(words)") }
                ?? locale.localized("Odometer: no reading yet")))
    }
}
