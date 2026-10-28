import HUDCore
import SwiftUI

/// The parked right panel (#79, 07 §3.1): the chosen card in the tire panel's frame, or the one line
/// 「尚無車輛資料」 when no card is offered (no car data, 07 §2.3 「只有 GPS」).
struct RightCardView: View {
    let state: HUDState
    let deck: CardDeck
    let size: CGSize

    var body: some View {
        switch deck.current {
        case .tires?:
            if let tires = state.tires {
                TirePanelView(panel: tires, size: size)
            }
        case .navigation?:
            NavigationCardView(panel: state.navigation, unit: state.unit, size: size)
        default:
            CardLine(text: "No vehicle data yet")
                .frame(width: size.width, height: size.height, alignment: .topLeading)
        }
    }
}

/// The parked 車上導航 card (the master's `A-v-park-nav`): the title, then the drive panel's content from
/// the top, 20 below it. A route known to have ended says 「車上沒有在導航」 (07 §2.3); with no car data
/// only the title stays.
struct NavigationCardView: View {
    let panel: NavigationPanel?
    let unit: SpeedUnit
    let size: CGSize

    /// The title row, as `.pt` in a wing.
    static let titleHeight: CGFloat = 20
    /// From the title row to the destination (`.wing .dest`'s margin).
    static let contentGap: CGFloat = 20

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CardTitleText(text: "Car navigation")
                .frame(height: Self.titleHeight)
            switch panel {
            case .ended?:
                CardLine(text: "No route set in the car")
                    .padding(.top, CardLine.topGap)
            case let panel?:
                NavigationPanelView(panel: panel, unit: unit,
                                    size: CGSize(width: size.width, height: size.height - Self.titleHeight - Self.contentGap),
                                    top: true)
                    .padding(.top, Self.contentGap)
            case nil:
                EmptyView()
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
    }
}

/// A card's title while it is not yet a button: 14/600 `text.secondary`, as the tire panel's.
struct CardTitleText: View {
    let text: LocalizedStringKey

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Palette.textSecondary)
            .accessibilityAddTraits(.isHeader)
    }
}

/// One line in place of a card's content (the master's `.tu`): 14 `text.secondary`, 18 below the title row.
struct CardLine: View {
    let text: LocalizedStringKey

    static let topGap: CGFloat = 18

    var body: some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundStyle(Palette.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
