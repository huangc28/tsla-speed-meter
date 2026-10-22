import HUDCore
import SwiftUI

/// Placeholder HUD: a dark full-screen view with the speed readout centered.
struct HUDView: View {
    var body: some View {
        ZStack {
            Palette.background.ignoresSafeArea()
            VStack(spacing: 4) {
                Text(HUDPlaceholder.speedText)
                    .font(.system(size: 160, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text(HUDPlaceholder.unitText)
                    .font(.system(size: 28, weight: .medium))
            }
            .foregroundStyle(Palette.textPrimary)
        }
        .preferredColorScheme(.dark)
    }
}

/// Tokens from DESIGN.md.
enum Palette {
    /// `bg.base` #0A0B0D
    static let background = Color(red: 0x0A / 255, green: 0x0B / 255, blue: 0x0D / 255)
    /// `text.primary` #F5F7FA
    static let textPrimary = Color(red: 0xF5 / 255, green: 0xF7 / 255, blue: 0xFA / 255)
}

#Preview(traits: .landscapeLeft) {
    HUDView()
}
