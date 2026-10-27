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

    /// Gauge A's ring and the disc inside it.
    static let ring = hex(0xCFD3D9)
    static let disc = hex(0x0F1013)
    /// `panel`: dialogs.
    static let dialFace = hex(0x1A1C20)
    static let dialNoData = hex(0x5A5F67)
    static let speedUnavailable = hex(0xB7BCC4)

    static let sourceOK = hex(0x3DE0A8)
    static let sourceDegraded = hex(0xF5B53C)

    /// `P R N D`: the current gear is `gear.on` (`textPrimary`), the others `gear.off`.
    static let gearOff = hex(0x83868A)
    /// `battery.fill`, left to right; the icon's body and border are `surfaceRaised` and `cardBorder`.
    static let batteryFill = [hex(0x2BBF86), hex(0x3DE0A8)]

    static let textRow = hex(0xE1E5EA)
    /// Chrome icons such as the settings gear.
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

/// Barlow Semi Condensed (SIL OFL 1.1, bundled in `App/Fonts`) for the numeral, its unit and `P R N D` only.
/// Tabular figures on, fixed size: the numeral never follows Dynamic Type (DESIGN.md Typography).
enum HUDFont {
    static let regular = "BarlowSemiCondensed-Regular"
    static let medium = "BarlowSemiCondensed-Medium"
    /// The current gear of `P R N D` only.
    static let bold = "BarlowSemiCondensed-Bold"

    static func barlow(_ name: String, size: CGFloat) -> UIFont {
        let base = UIFont(name: name, size: size) ?? .systemFont(ofSize: size)
        let tabular = base.fontDescriptor.addingAttributes([
            .featureSettings: [[UIFontDescriptor.FeatureKey.type: kNumberSpacingType,
                                UIFontDescriptor.FeatureKey.selector: kMonospacedNumbersSelector]],
        ])
        return UIFont(descriptor: tabular, size: size)
    }

    /// Inter (SIL OFL 1.1, bundled in `App/Fonts`) for Latin UI text such as the time. CJK text
    /// keeps the system font.
    static let interRegular = "Inter-Regular"
    static let interMedium = "Inter-Medium"
    static let interSemiBold = "Inter-SemiBold"
    static let interBold = "Inter-Bold"

    /// Glyph-ink bounds of `string` relative to its baseline origin (y up), as CoreText lays it out.
    static func inkBounds(_ string: String, font: UIFont, tracking: CGFloat) -> CGRect {
        let text = NSAttributedString(string: string, attributes: [.font: font, .kern: tracking])
        return CTLineGetBoundsWithOptions(CTLineCreateWithAttributedString(text), .useGlyphPathBounds)
    }
}
