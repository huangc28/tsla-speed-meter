import SwiftUI
import UIKit

/// Tokens from DESIGN.md.
enum Palette {
    static func hex(_ value: UInt32, opacity: Double = 1) -> Color {
        Color(red: Double((value >> 16) & 0xFF) / 255, green: Double((value >> 8) & 0xFF) / 255,
              blue: Double(value & 0xFF) / 255, opacity: opacity)
    }

    /// `bg.base`; the HUD sits on a radial gradient `#1D1F23` → `#0A0B0D` centered at 50% 45%.
    static let background = hex(0x0A0B0D)
    static let backgroundGlow = hex(0x1D1F23)
    static let textPrimary = hex(0xF5F7FA)
    static let textSecondary = hex(0xCDD2D9)
    static let unit = hex(0xA6ACB5)

    /// `panel`: dialogs.
    static let dialFace = hex(0x1A1C20)

    /// The round gauge (#98, DESIGN-atelier-tesla-edition.md colours): the ground around it and toward the
    /// corners, the numeral, `P R N D`, the unit and the ticks. The dash and the reason under it use the
    /// design page's `FF.sec`.
    static let ground = hex(0x0A0F15)
    static let groundEdge = hex(0x070B11)
    static let gaugeNumeral = hex(0xFDFCFE)
    static let gearActive = hex(0xFFFFFF)
    static let gearInactive = hex(0x7C828A)
    static let gaugeUnit = hex(0x969EA7)
    static let gaugeTick = hex(0x48525C)
    static let gaugeNoSpeed = hex(0x92969C)

    /// The car-status icons (#99, DESIGN-atelier-tesla-edition.md `icon-open`, `icon-warning`, `icon-unknown`):
    /// red for an open part, amber for a low tire, grey dashes for an unknown part. The discs' gradients are
    /// `CarStatusIcon.discFill` and `discRim`.
    static let iconOpen = hex(0xEF6A69)
    static let iconWarning = hex(0xEFA83F)
    static let iconUnknown = hex(0xA6ACB5)

    /// The drive screen's frame (#100, the design page's `FF` and `FH`): `FF.mid` for values and the destination,
    /// `FF.sec` for labels, the tire column's lines, the clock and the gear; the left card's fill runs from
    /// `cardFillTop` to `cardFillBottom` (`xnFill`), the road's fades end in `surf`; the tires are `tyreF` inside
    /// `tyreE`.
    static let frameText = hex(0xCDD2D9)
    static let frameLabel = hex(0x92969C)
    static let cardFillTop = hex(0x14171B)
    static let cardFillBottom = hex(0x101317)
    static let frameSurface = hex(0x13161A)
    static let tireFill = hex(0x5E6166)
    static let tireEdge = hex(0xB4B8BE)
    /// The road art's route and the navigation arrow (`roadF`): `#C9CDD2`, and `FF.blue`.
    static let road = hex(0xC9CDD2)
    static let navigationArrow = hex(0x3E8BFA)

    static let sourceOK = hex(0x3DE0A8)
    static let sourceDegraded = hex(0xF5B53C)

    /// The footer's battery level for a stale value (parked).
    static let batteryStaleFill = hex(0x5D6168)
    /// `text.stale`: a stale battery value; "stale" is carried by its own time line (L21).
    static let textStale = hex(0x8F949B)

    /// `tire.stale`: an old or unknown-time reading, wheel by wheel.
    static let tireStale = hex(0xA6ACB5)

    static let textRow = hex(0xE1E5EA)
    /// Chrome icons such as the stale navigation pin.
    static let textTertiary = hex(0x8E949C)
    static let card = hex(0x15171A)
    static let cardBorder = hex(0x4A4F57)
    static let surfaceRaised = hex(0x24272C)
    /// Disabled button text.
    static let textInactive = hex(0x9EA3AA)
    static let divider = hex(0x2A2D32)
    /// Cyan, only for what can be acted on (L55).
    static let accent = hex(0x2BD4E0)
    static let accentText = hex(0x6FD8E2)
    static let accentSegActiveBackground = hex(0x1E3C45)
}

/// The app's bundled fonts (`App/Fonts`, SIL OFL 1.1). The numeral never follows Dynamic Type (DESIGN.md Typography).
enum HUDFont {
    /// Inter Medium (SIL OFL 1.1, bundled in `App/Fonts`) for the one-time card and the parked outside temperature.
    /// Everything else outside the gauge is the system font (#100, #101).
    static let interMedium = "Inter-Medium"

    /// Hanken Grotesk (SIL OFL 1.1, bundled in `App/Fonts`) for the round gauge's numeral, unit and
    /// `P R N D` (DESIGN-atelier-tesla-edition.md Typography): 500, and 600 for the current gear only.
    static let hankenMedium = "HankenGrotesk-Medium"
    static let hankenSemiBold = "HankenGrotesk-SemiBold"

    /// Glyph-ink bounds of `string` relative to its baseline origin (y up), as CoreText lays it out.
    static func inkBounds(_ string: String, font: UIFont, tracking: CGFloat) -> CGRect {
        let text = NSAttributedString(string: string, attributes: [.font: font, .kern: tracking])
        return CTLineGetBoundsWithOptions(CTLineCreateWithAttributedString(text), .useGlyphPathBounds)
    }
}
