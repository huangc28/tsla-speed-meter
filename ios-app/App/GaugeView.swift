import CoreText
import HUDCore
import SwiftUI
import UIKit

/// What the round gauge draws, one layer at a time for the clearance test (the design page's `&ink=`).
enum GaugeLayer: CaseIterable {
    case ring, ticks, numeral, unit
}

/// The round gauge (#98, DESIGN-atelier-tesla-edition.md, the design page's `drawMain`): the ring and
/// its 44 ticks, the numeral in fixed cells centred on the ring, and `km/h` under it, drawn in design
/// points on the layout's canvas. With no speed the numeral is a dash with the reason under it, and the
/// ring stays the same (the Fixed Ring Rule). Parked with no speed, 「P 檔」 takes the numeral's place.
/// `P R N D` is its own view (`GearRow`).
struct GaugeView: View {
    let state: HUDState
    let canvas: DesignCanvas
    var layers: Set<GaugeLayer> = Set(GaugeLayer.allCases)
    @Environment(\.locale) private var locale

    /// The view's frame on the screen: the ring's box and room for its glow.
    static func frame(_ canvas: DesignCanvas) -> CGRect {
        let r = RoundGauge.radius + glowRoom, c = RoundGauge.center
        return canvas.rect(CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r))
    }

    /// The outer glow reaches 3.2 + 2.25 past the ring, and its blur about 3 × 2.1 more.
    static let glowRoom: CGFloat = 12

    var body: some View {
        let frame = Self.frame(canvas)
        // Design points to this view's points.
        let transform = canvas.transform.concatenating(CGAffineTransform(translationX: -frame.minX, y: -frame.minY))
        let labels = GaugeLabels(state: state, locale: locale)
        ZStack(alignment: .topLeading) {
            if !layers.isDisjoint(with: [.ring, .ticks]) {
                RingView(canvas: canvas, transform: transform, ring: layers.contains(.ring), ticks: layers.contains(.ticks))
            }
            Canvas { context, _ in
                labels.draw(in: &context, transform: transform, scale: canvas.scale,
                            numeral: layers.contains(.numeral), unit: layers.contains(.unit))
            }
        }
        .frame(width: frame.width, height: frame.height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: HUDAccessibility.speedLabel(for: state)))
    }
}

/// The ring and the ticks (`ringT(true)`, `ticksT`). They never change, so they are their own view, whose
/// inputs stay equal while the numeral changes, and SwiftUI does not redraw it.
struct RingView: View {
    let canvas: DesignCanvas
    let transform: CGAffineTransform
    var ring = true
    var ticks = true

    var body: some View {
        Canvas { context, _ in
            if ring { Self.drawRing(in: context, transform: transform, scale: canvas.scale) }
            if ticks { Self.drawTicks(in: context, transform: transform) }
        }
    }

    static func color(_ s: RoundGauge.RingSegment) -> Color {
        Color(red: Double(s.red) / 255, green: Double(s.green) / 255, blue: Double(s.blue) / 255)
    }

    /// One piece of the ring as a butt-capped arc, in design points.
    static func arc(_ s: RoundGauge.RingSegment, radius: CGFloat) -> Path {
        // `degrees` runs clockwise from 12 o'clock; CoreGraphics' angle from 3 o'clock, toward +y.
        let start = (s.startDegrees - 90) * .pi / 180, delta = (s.endDegrees - s.startDegrees) * .pi / 180
        var path = Path()
        path.addRelativeArc(center: RoundGauge.center, radius: radius, startAngle: .radians(start), delta: .radians(delta))
        return path
    }

    /// The soft light inside the ring all round and outside it across the top, then the ring itself.
    static func drawRing(in context: GraphicsContext, transform: CGAffineTransform, scale: CGFloat) {
        for (glow, outer) in [(RoundGauge.innerGlow, false), (RoundGauge.outerGlow, true)] {
            var layer = context
            layer.opacity = glow.opacity
            // SVG's stdDeviation in design points; SwiftUI's blur radius is in this view's points.
            layer.addFilter(.blur(radius: glow.blur * scale))
            layer.drawLayer { inner in
                for s in RoundGauge.ringSegments {
                    let opacity = outer ? s.outerGlowOpacity : 1
                    guard let opacity else { continue }
                    inner.stroke(arc(s, radius: glow.radius).applying(transform), with: .color(color(s).opacity(opacity)),
                                 lineWidth: glow.width * scale)
                }
            }
        }
        for s in RoundGauge.ringSegments {
            context.stroke(arc(s, radius: RoundGauge.radius).applying(transform), with: .color(color(s)),
                           lineWidth: s.lineWidth * scale)
        }
    }

    static func drawTicks(in context: GraphicsContext, transform: CGAffineTransform) {
        var path = Path()
        for line in RoundGauge.Ticks.lines {
            path.move(to: line.inner)
            path.addLine(to: line.outer)
        }
        // `transform.a` is the canvas scale.
        context.stroke(path.applying(transform), with: .color(Palette.gaugeTick),
                       style: StrokeStyle(lineWidth: RoundGauge.Ticks.lineWidth * transform.a, lineCap: .butt))
    }
}

/// The numeral (digits, the dash or 「P 檔」), the unit or the reason, and the GPS cue, in design points.
struct GaugeLabels {
    let text: String
    /// 「P 檔」 in the numeral's place (S06-f).
    let parkedGear: String?
    /// The digits' glyph origins; nil for the dash and 「P 檔」.
    let numeral: NumeralLayout?
    /// The reason, as shown, under the dash or 「P 檔」; nil with a speed.
    let reason: String?
    /// The reason's ink top: 12 below the dash, or where the unit goes under 「P 檔」, which fills the
    /// numeral's height.
    let reasonInkTop: CGFloat
    let language: String?
    /// Ink of the unit; nil with no speed. It hangs off the numeral's fixed ink, so it never moves.
    let unitInk: CGRect?
    let unit: String
    /// Design points: the cue's 24-box origin and size.
    let gpsCue: (origin: CGPoint, size: CGFloat, color: Color)?

    static let numeralFont = UIFont(name: HUDFont.hankenMedium, size: RoundGauge.Numeral.fontSize)
        ?? .systemFont(ofSize: RoundGauge.Numeral.fontSize, weight: .medium)
    static let unitFont = UIFont(name: HUDFont.hankenMedium, size: RoundGauge.Unit.fontSize)
        ?? .systemFont(ofSize: RoundGauge.Unit.fontSize, weight: .medium)
    /// The page's `placeF` face for the reason: the system font 500.
    static let reasonFont = UIFont.systemFont(ofSize: RoundGauge.Reason.fontSize, weight: .medium)
    /// 「P 檔」 and "Gear P": the numeral's face and size, smaller when its ink would be wider or taller than
    /// this, so it stays clear of the door and tire discs and of the reason under it.
    static let parkedGearMaxInk = CGSize(width: 150, height: 60)

    init(state: HUDState, locale: Locale) {
        text = state.numeral
        language = locale.identifier
        parkedGear = state.showsParkedGear ? locale.localized("Gear P") : nil
        numeral = state.hasSpeed ? NumeralLayout(digits: state.numeral) : nil
        reason = state.hasSpeed ? nil : state.reason.map { locale.localized($0.text) }
        reasonInkTop = state.showsParkedGear ? RoundGauge.Unit.inkTop : RoundGauge.Reason.inkTop
        unit = state.unit.symbol
        guard state.hasSpeed else {
            unitInk = nil
            gpsCue = nil
            return
        }
        let ink = Self.ink(unit, font: Self.unitFont)
        let unitInk = CGRect(x: RoundGauge.center.x - ink.width / 2, y: RoundGauge.Unit.baselineY - ink.maxY,
                             width: ink.width, height: ink.height)
        self.unitInk = unitInk
        // GPS only: amber as the fallback, green as the normal source.
        let color: Color? = switch state.source {
        case .valid(.gps): Palette.sourceOK
        case .gpsFallback: Palette.sourceDegraded
        default: nil
        }
        if let color {
            // Lucide's arrow ink (with its stroke) spans x 2–23 and y 1–22 of the 24 box: its ink 8 left of
            // the unit's ink and centred on it, as gauge A placed it.
            let size = RoundGauge.GPSCue.size, scale = size / 24
            gpsCue = (CGPoint(x: unitInk.minX - RoundGauge.GPSCue.gap - 23 * scale, y: unitInk.midY - 11.5 * scale), size, color)
        } else {
            gpsCue = nil
        }
    }

    /// Glyph-ink bounds of `string` relative to its baseline origin (y up).
    static func ink(_ string: String, font: UIFont, language: String? = nil) -> CGRect {
        CTLineGetBoundsWithOptions(line(string, font: font, language: language), .useGlyphPathBounds)
    }

    static func line(_ string: String, font: UIFont, language: String?) -> CTLine {
        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            NSAttributedString.Key(kCTForegroundColorFromContextAttributeName as String): true,
        ]
        if let language { attributes[NSAttributedString.Key(kCTLanguageAttributeName as String)] = language }
        return CTLineCreateWithAttributedString(NSAttributedString(string: string, attributes: attributes))
    }

    /// 「P 檔」's font: the numeral's, or smaller to fit `parkedGearMaxInk`.
    static func parkedGearFont(_ string: String, language: String?) -> UIFont {
        let size = ink(string, font: numeralFont, language: language).size
        let fit = min(1, parkedGearMaxInk.width / size.width, parkedGearMaxInk.height / size.height)
        guard fit < 1 else { return numeralFont }
        return numeralFont.withSize((numeralFont.pointSize * fit * 10).rounded(.down) / 10)
    }

    func draw(in context: inout GraphicsContext, transform: CGAffineTransform, scale: CGFloat, numeral drawsNumeral: Bool,
              unit drawsUnit: Bool) {
        context.withCGContext { cg in
            cg.concatenate(transform)
            cg.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
            Self.placeGlyphsExactly(cg)
            if drawsNumeral {
                if let parkedGear {
                    // Its ink centred on the numeral's ink centre.
                    let font = Self.parkedGearFont(parkedGear, language: language)
                    let ink = Self.ink(parkedGear, font: font, language: language)
                    Self.drawLine(parkedGear, font: font, language: language, color: Palette.gaugeNumeral,
                                  at: CGPoint(x: RoundGauge.center.x - ink.midX, y: RoundGauge.Numeral.inkCenterY + ink.midY), in: cg)
                } else if let numeral {
                    for (digit, x) in zip(text, numeral.digitOrigins) {
                        Self.drawLine(String(digit), font: Self.numeralFont, language: nil, color: Palette.gaugeNumeral,
                                      at: CGPoint(x: x, y: numeral.baselineY), in: cg)
                    }
                } else {
                    // The page's round-capped line, in `FF.sec`.
                    let dash = RoundGauge.Numeral.dashRect
                    cg.setFillColor(UIColor(Palette.gaugeNoSpeed).cgColor)
                    cg.addPath(CGPath(roundedRect: dash, cornerWidth: dash.height / 2, cornerHeight: dash.height / 2, transform: nil))
                    cg.fillPath()
                }
            }
            guard drawsUnit else { return }
            if let unitInk {
                let ink = Self.ink(unit, font: Self.unitFont)
                Self.drawLine(unit, font: Self.unitFont, language: nil, color: Palette.gaugeUnit,
                              at: CGPoint(x: unitInk.minX - ink.minX, y: RoundGauge.Unit.baselineY), in: cg)
            } else if let reason {
                // Centred by its advance, its ink top at the reason line (`placeF` with `cx` and `top`).
                let line = Self.line(reason, font: Self.reasonFont, language: language)
                let advance = CTLineGetTypographicBounds(line, nil, nil, nil)
                let ink = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
                Self.drawLine(reason, font: Self.reasonFont, language: language, color: Palette.gaugeNoSpeed,
                              at: CGPoint(x: RoundGauge.center.x - advance / 2, y: reasonInkTop + ink.maxY), in: cg)
            }
            if let cue = gpsCue {
                let place = CGAffineTransform(translationX: cue.origin.x, y: cue.origin.y).scaledBy(x: cue.size / 24, y: cue.size / 24)
                cg.addPath(LucideIcon.navigation.path.applying(place).cgPath)
                cg.setStrokeColor(UIColor(cue.color).cgColor)
                cg.setLineWidth(2 * cue.size / 24)
                cg.setLineCap(.round)
                cg.setLineJoin(.round)
                cg.strokePath()
            }
        }
    }

    /// Glyphs at their fractional pens, as the design page's SVG draws them: CoreText otherwise rounds a
    /// glyph's position, which moved the 4 of "104" a pixel left of its ink at 1×.
    static func placeGlyphsExactly(_ cg: CGContext) {
        cg.setAllowsFontSubpixelPositioning(true)
        cg.setShouldSubpixelPositionFonts(true)
        cg.setAllowsFontSubpixelQuantization(true)
        cg.setShouldSubpixelQuantizeFonts(false)
    }

    /// One CoreText line with its pen at `pen` on the baseline (design points).
    static func drawLine(_ string: String, font: UIFont, language: String?, color: Color, at pen: CGPoint, in cg: CGContext) {
        cg.setFillColor(UIColor(color).cgColor)
        cg.textPosition = pen
        CTLineDraw(line(string, font: font, language: language), cg)
    }
}

/// `P R N D` (L43, `gearsT(gl, true)`): Hanken Grotesk 500 in `gear-inactive`, the current gear 600
/// in `gear-active`, each letter centred on its ink, 21.6 apart, 0.692 of the radius above the ring
/// centre. Showing or hiding it never moves the numeral; the row is one accessibility element.
struct GearRow: View {
    let gear: CarGear
    let canvas: DesignCanvas

    static let letters: [(gear: CarGear, letter: String)] = [(.park, "P"), (.reverse, "R"), (.neutral, "N"), (.drive, "D")]
    static let offFont = UIFont(name: HUDFont.hankenMedium, size: RoundGauge.GearRow.fontSize)
        ?? .systemFont(ofSize: RoundGauge.GearRow.fontSize, weight: .medium)
    static let onFont = UIFont(name: HUDFont.hankenSemiBold, size: RoundGauge.GearRow.fontSize)
        ?? .systemFont(ofSize: RoundGauge.GearRow.fontSize, weight: .semibold)

    /// The row's box in design points: the four cells and room above and below the letters.
    static var designFrame: CGRect {
        let g = RoundGauge.GearRow.self
        return CGRect(x: RoundGauge.center.x - 2 * g.pitch, y: g.centerY - 10, width: 4 * g.pitch, height: 20)
    }

    static func frame(_ canvas: DesignCanvas) -> CGRect { canvas.rect(designFrame) }

    var body: some View {
        let frame = Self.frame(canvas)
        let transform = canvas.transform.concatenating(CGAffineTransform(translationX: -frame.minX, y: -frame.minY))
        Canvas { context, _ in
            context.withCGContext { cg in
                cg.concatenate(transform)
                cg.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
                GaugeLabels.placeGlyphsExactly(cg)
                for (i, item) in Self.letters.enumerated() {
                    let on = item.gear == gear, font = on ? Self.onFont : Self.offFont
                    let ink = GaugeLabels.ink(item.letter, font: font)
                    GaugeLabels.drawLine(item.letter, font: font, language: nil, color: on ? Palette.gearActive : Palette.gearInactive,
                                         at: CGPoint(x: RoundGauge.GearRow.letterCenterX(i) - ink.midX, y: RoundGauge.GearRow.baselineY),
                                         in: cg)
                }
            }
        }
        .frame(width: frame.width, height: frame.height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Gear \(Self.letters.first { $0.gear == gear }!.letter)"))
    }
}

extension NoSpeedReason {
    /// Under the dash, on one line in both languages.
    var text: String.LocalizationValue {
        switch self {
        case .speedUnavailable: "Speed unavailable"
        case .gpsUnavailable: "GPS unavailable"
        }
    }
}

/// Screen-reader wording (01 §6.1, §7.3): the speed with its unit and source, or the same
/// reason the screen shows under the dash.
enum HUDAccessibility {
    static func speedLabel(for state: HUDState) -> String {
        guard state.hasSpeed else {
            let reason = state.reason == .gpsUnavailable ? String(localized: "GPS unavailable") : String(localized: "Speed unavailable")
            return state.showsParkedGear ? String(localized: "Gear P, \(reason)") : reason
        }
        let unit = state.unit == .kilometersPerHour ? String(localized: "kilometers per hour") : String(localized: "miles per hour")
        return String(localized: "Current speed \(state.numeral) \(unit), from \(sourceName(state.source))")
    }

    private static func sourceName(_ source: SourceStatus) -> String {
        switch source {
        case .valid(.carBluetooth): String(localized: "Car Bluetooth")
        case .valid(.gps), .gpsFallback: "GPS"
        default: ""
        }
    }
}
