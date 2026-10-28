import Darwin
import HUDCore
import SwiftUI
import Testing
import UIKit
@testable import SpeedHUD

/// The drive screen fed by a real `HUDViewModel`, so card actions change what it shows.
private struct Harness: View {
    let model: HUDViewModel
    let screen: HUDRenderTests.Screen

    var body: some View {
        DriveScreen(state: model.state, now: HUDRenderTests.now, screen: screen.size, leftInset: screen.left,
                    rightInset: screen.right, bottomInset: screen.bottom,
                    actions: DriveScreenActions(cards: { model.handle($0) }))
    }
}

/// A view hosted in a window, read and driven through its accessibility elements, as VoiceOver does.
@MainActor
private final class Hosted {
    let window: UIWindow

    init(_ view: some View, size: CGSize, locale: String) {
        // SwiftUI builds its accessibility elements only while accessibility is on in the process.
        if let library = dlopen("/usr/lib/libAccessibility.dylib", RTLD_NOW),
           let symbol = dlsym(library, "_AXSApplicationAccessibilitySetEnabled") {
            typealias SetEnabled = @convention(c) (Bool) -> Void
            unsafeBitCast(symbol, to: SetEnabled.self)(true)
        }
        let host = UIHostingController(rootView: view.environment(\.locale, Locale(identifier: locale)).ignoresSafeArea())
        host.safeAreaRegions = []
        // In the app's scene, so the window is drawn and can be captured.
        if let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
            window = UIWindow(windowScene: scene)
            window.frame = CGRect(origin: .zero, size: size)
        } else {
            window = UIWindow(frame: CGRect(origin: .zero, size: size))
        }
        window.rootViewController = host
        window.makeKeyAndVisible()
        settle()
    }

    func close() { window.isHidden = true }

    /// The window as drawn now (an animation mid-way included), RGBA at 1x.
    func pixels() throws -> [UInt8] {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { _ in
            _ = window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        return try HUDRenderTests.rgba(try #require(image.cgImage))
    }

    func settle() {
        window.rootViewController?.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
    }

    /// Every accessibility element, in order.
    var elements: [NSObject] {
        var found: [NSObject] = []
        var seen = Set<ObjectIdentifier>()
        func walk(_ object: NSObject) {
            guard seen.insert(ObjectIdentifier(object)).inserted else { return }
            if object.isAccessibilityElement {
                found.append(object)
                return
            }
            for element in object.accessibilityElements as? [NSObject] ?? [] { walk(element) }
            let count = object.accessibilityElementCount()
            if count != NSNotFound {
                for i in 0..<count { (object.accessibilityElement(at: i) as? NSObject).map(walk) }
            }
            for subview in (object as? UIView)?.subviews ?? [] { walk(subview) }
        }
        window.rootViewController.map { walk($0.view) }
        return found
    }

    var labels: [String] { elements.map { $0.accessibilityLabel ?? "" } }

    func element(_ label: String) throws -> NSObject {
        try #require(elements.first { $0.accessibilityLabel == label }, "no element \(label) in \(labels)")
    }

    func actionNames(_ label: String) throws -> [String] {
        try element(label).accessibilityCustomActions?.map(\.name) ?? []
    }

    /// Double-tap with VoiceOver.
    func activate(_ label: String) throws {
        #expect(try element(label).accessibilityActivate(), "\(label) did not activate")
        settle()
    }

    /// A VoiceOver custom action (swipe up or down on the element, then double-tap).
    func perform(_ name: String, on label: String) throws {
        let action = try #require(try element(label).accessibilityCustomActions?.first { $0.name == name },
                                  "\(label) has no \(name)")
        if let handler = action.actionHandler {
            #expect(handler(action))
        } else {
            _ = (action.target as? NSObject)?.perform(action.selector, with: action)
        }
        settle()
    }
}

/// #79: switching the parked cards (M12-14): the title button and its list, VoiceOver's sentence and
/// actions, and the swipe's decision. A `DragGesture` cannot be synthesized in-process, so the swipe is
/// covered by `CardSwipe` (the gesture's decision) and the actions it sends, the rest through the hosted
/// screen's accessibility elements.
@Suite(.serialized)
@MainActor
struct CardSwitchingTests {
    let clock = TestClock()

    private func model() -> HUDViewModel {
        let clock = clock
        let model = HUDViewModel(engine: HUDEngine(cards: CardSwitcher(hintDismissed: true)), now: { clock.now })
        model.handle(LocationEvent.authorization(.authorized))
        return model
    }

    private func reading(_ gear: CarGear, kmh: Double) -> CarEvent {
        .reading(CarReading(receivedAt: clock.now, carTimestamp: clock.now, speedMetersPerSecond: kmh / 3.6, gear: gear,
                            batteryPercent: 72, rangeKilometers: 315))
    }

    /// Two P readings 0.2 s apart: the parked screen.
    private func park(_ model: HUDViewModel) {
        model.handle(reading(.park, kmh: 0))
        clock.advance(0.2)
        model.handle(reading(.park, kmh: 0))
        #expect(model.state.layout == .parked)
    }

    @Test func theTitleReadsItsPlaceAndOffersNextAndPrevious() throws {
        let model = model()
        park(model)
        let screen = HUDRenderTests.Screen.iPhone844
        let hosted = Hosted(Harness(model: model, screen: screen), size: screen.size, locale: "zh-Hant")
        defer { hosted.close() }

        let left = try hosted.element("行程，第 1 張，共 2 張")
        #expect(left.accessibilityTraits.contains(.button))
        #expect(try hosted.actionNames("行程，第 1 張，共 2 張") == ["下一張"])
        let right = try hosted.element("胎壓，第 1 張，共 2 張")
        #expect(right.accessibilityTraits.contains(.button))
        #expect(try hosted.actionNames("胎壓，第 1 張，共 2 張") == ["下一張"])
        // The hit areas are 44 high; the right one stays below the settings gear.
        let layout = DriveLayout(screen: screen.size, leftInset: screen.left, rightInset: screen.right, bottomInset: screen.bottom)
        #expect(left.accessibilityFrame.height >= 44 && left.accessibilityFrame.width >= 120, "\(left.accessibilityFrame)")
        #expect(right.accessibilityFrame.height >= 44 && right.accessibilityFrame.width >= 120, "\(right.accessibilityFrame)")
        #expect(right.accessibilityFrame.minY >= layout.settingsGear.maxY, "\(right.accessibilityFrame)")

        try hosted.perform("下一張", on: "行程，第 1 張，共 2 張")
        #expect(model.state.panels?.left.current == .vehicle)
        #expect(try hosted.actionNames("車況，第 2 張，共 2 張") == ["上一張"])
        try hosted.perform("上一張", on: "車況，第 2 張，共 2 張")
        #expect(model.state.panels?.left.current == .trip)
        #expect(hosted.labels.contains("行程，第 1 張，共 2 張"), "\(hosted.labels)")
    }

    @Test func theTitleReadsInEnglish() throws {
        let model = model()
        park(model)
        let screen = HUDRenderTests.Screen.iPhone667
        let hosted = Hosted(Harness(model: model, screen: screen), size: screen.size, locale: "en")
        defer { hosted.close() }
        #expect(try hosted.actionNames("Trip, card 1 of 2") == ["Next card"])
        #expect(try hosted.actionNames("Tire pressure, card 1 of 2") == ["Next card"])
        let layout = DriveLayout(screen: screen.size, leftInset: screen.left, rightInset: screen.right, bottomInset: screen.bottom)
        #expect(try hosted.element("Tire pressure, card 1 of 2").accessibilityFrame.minY >= layout.settingsGear.maxY)
    }

    // On a panel that scrolls (667, English, with the battery group) the title's hit area still reaches
    // 12 above the panel: the scroll view does not cut it.
    @Test func aScrollingPanelKeepsTheTitlesHitArea() throws {
        let screen = HUDRenderTests.Screen.iPhone667
        let state = try #require(HUDRenderTests.tripStates["parked-trip"]?.state)
        #expect(HUDRenderTests.needsWindow(state, screen: screen, locale: Locale(identifier: "en")))
        let view = DriveScreen(state: state, now: HUDRenderTests.now, screen: screen.size, leftInset: screen.left,
                               rightInset: screen.right, bottomInset: screen.bottom)
        let hosted = Hosted(view, size: screen.size, locale: "en")
        defer { hosted.close() }
        let title = try hosted.element("Trip, card 1 of 2").accessibilityFrame
        #expect(abs(title.minY - 72) < 0.5 && title.height >= 44, "\(title)")
    }

    @Test func theTitleOpensTheListAndChoosingClosesIt() throws {
        let model = model()
        park(model)
        let screen = HUDRenderTests.Screen.iPhone844
        let hosted = Hosted(Harness(model: model, screen: screen), size: screen.size, locale: "zh-Hant")
        defer { hosted.close() }

        try hosted.activate("胎壓，第 1 張，共 2 張")
        #expect(model.state.panels?.openList == .right)
        // A row per card; the current one is selected (and drawn with a check).
        let tires = try hosted.element("胎壓")
        let navigation = try hosted.element("車上導航")
        #expect(tires.accessibilityTraits.contains(.selected) && tires.accessibilityTraits.contains(.button))
        #expect(!navigation.accessibilityTraits.contains(.selected) && navigation.accessibilityTraits.contains(.button))
        #expect(tires.accessibilityFrame.height >= 44 && navigation.accessibilityFrame.height >= 44)

        try hosted.activate("車上導航")
        #expect(model.state.panels?.openList == nil)
        #expect(model.state.panels?.right.current == .navigation)
        #expect(hosted.labels.contains("車上導航，第 2 張，共 2 張"), "\(hosted.labels)")
        #expect(!hosted.labels.contains("胎壓"), "the list is still open: \(hosted.labels)")
    }

    // M12-03, M12-04: the car moves while the list is open: it closes at once and does not come back.
    @Test func leavingParkedClosesTheListForGood() throws {
        let model = model()
        park(model)
        let screen = HUDRenderTests.Screen.iPhone844
        let hosted = Hosted(Harness(model: model, screen: screen), size: screen.size, locale: "zh-Hant")
        defer { hosted.close() }
        try hosted.activate("行程，第 1 張，共 2 張")
        #expect(hosted.labels.contains("車況"), "\(hosted.labels)")

        clock.advance(0.2)
        model.handle(reading(.drive, kmh: 30))
        hosted.settle()
        #expect(model.state.layout == .drive)
        #expect(!hosted.labels.contains("車況"), "\(hosted.labels)")
        // Nothing on the drive screen's panels can be tapped: the only button is the settings gear.
        #expect(hosted.elements.filter { $0.accessibilityTraits.contains(.button) }.map { $0.accessibilityLabel ?? "" } == ["設定"])

        clock.advance(0.2)
        park(model)
        hosted.settle()
        #expect(model.state.panels?.openList == nil)
        #expect(!hosted.labels.contains("車況"), "\(hosted.labels)")
    }

    // L84-5, R7-16: the one-time card is whole on the first parked screen, above the fade, at 844 in
    // Chinese and 667 in English; switching cards keeps it; 知道了 dismisses it, stored for good.
    @Test(arguments: [(HUDRenderTests.Screen.iPhone844, "zh-Hant", "知道了"), (.iPhone667, "en", "Got it")])
    func theOneTimeCardStaysUntilGotIt(screen: HUDRenderTests.Screen, locale: String, gotIt: String) throws {
        let suite = "CardSwitchingTests.\(UUID().uuidString)"
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let store = CardStore(defaults: try #require(UserDefaults(suiteName: suite)))
        let clock = clock
        let model = HUDViewModel(cardStore: store, now: { clock.now })
        model.handle(LocationEvent.authorization(.authorized))
        park(model)
        let hosted = Hosted(Harness(model: model, screen: screen), size: screen.size, locale: locale)
        defer { hosted.close() }

        let layout = DriveLayout(screen: screen.size, leftInset: screen.left, rightInset: screen.right, bottomInset: screen.bottom)
        let button = try hosted.element(gotIt)
        #expect(button.accessibilityTraits.contains(.button))
        #expect(button.accessibilityFrame.height >= 44)
        #expect(button.accessibilityFrame.maxY <= layout.leftPanel.maxY - CardScroll<EmptyView>.fadeHeight, "\(button.accessibilityFrame)")
        #expect(button.accessibilityFrame.minY >= layout.sourceChipOrigin.y + 28)
        let note = locale == "en" ? "Tire pressure is for reference only" : "胎壓僅供參考"
        #expect(hosted.labels.contains { $0.hasPrefix(note) }, "\(hosted.labels)")

        let title = locale == "en" ? "Trip, card 1 of 2" : "行程，第 1 張，共 2 張"
        try hosted.perform(locale == "en" ? "Next card" : "下一張", on: title)
        #expect(model.state.panels?.left.current == .vehicle)
        #expect(hosted.labels.contains(gotIt))

        try hosted.activate(gotIt)
        #expect(model.state.panels?.showsHint == false)
        #expect(!hosted.labels.contains(gotIt))
        #expect(store.load().hintDismissed)
    }

    // The swipe's decision: one card per swipe, up for the next; short or sideways drags do nothing.
    /// Runs a whole drag through `CardSwipe` as the gesture does: the actions it sends and the haptics.
    private func drag(_ translation: CGSize, on surface: CardSwipe.Surface, scrolls: Bool,
                      deck: CardDeck = CardDeck(cards: [.trip, .vehicle], current: .trip)) -> (actions: [CardAction], haptics: Int) {
        var actions: [CardAction] = []
        var haptics = 0
        let title = CardTitle(side: .left, deck: deck, act: { actions.append($0) })
        CardSwipe.began(on: surface, scrolls: scrolls, title: title)
        CardSwipe.end(translation, on: surface, scrolls: scrolls, title: title, haptic: { haptics += 1 })
        return (actions, haptics)
    }

    // The gesture's decision: on a card that does not scroll, anywhere on the panel (the title row's own
    // gesture leaves it to the panel's, which covers it); on one that scrolls, only from the title row.
    // Up is the next card; at least 30 pt, more vertical than sideways; a haptic only when the card changes.
    @Test func theSwipeDecides() {
        let up = CGSize(width: 0, height: -40)
        let swipe: [CardAction] = [.beginSwipe(.left), .endSwipe(.left, forward: true)]
        #expect(drag(up, on: .panel, scrolls: false) == (swipe, 1))
        #expect(drag(up, on: .titleRow, scrolls: false) == ([], 0))
        #expect(drag(up, on: .titleRow, scrolls: true) == (swipe, 1))
        #expect(drag(up, on: .panel, scrolls: true) == ([], 0))

        #expect(drag(CGSize(width: 6, height: 52), on: .panel, scrolls: false).actions.last == .endSwipe(.left, forward: false))
        #expect(drag(CGSize(width: 0, height: -30), on: .panel, scrolls: false).actions.count == 2)
        // Too short, or more sideways than vertical: begun, nothing more.
        #expect(drag(CGSize(width: 0, height: -29), on: .panel, scrolls: false) == ([.beginSwipe(.left)], 0))
        #expect(drag(CGSize(width: 40, height: -40), on: .panel, scrolls: false) == ([.beginSwipe(.left)], 0))
        // At an end the swipe is sent (the engine ignores it), with no haptic: nothing changes.
        #expect(drag(CGSize(width: 0, height: 40), on: .panel, scrolls: false)
            == ([.beginSwipe(.left), .endSwipe(.left, forward: false)], 0))
        let last = CardDeck(cards: [.trip, .vehicle], current: .vehicle)
        #expect(drag(up, on: .panel, scrolls: false, deck: last).haptics == 0)
        #expect(drag(CGSize(width: 0, height: 40), on: .panel, scrolls: false, deck: last).haptics == 1)
        #expect(drag(up, on: .panel, scrolls: false, deck: CardDeck(cards: [], current: nil)).haptics == 0)
        // Only the title row of a card that scrolls takes the drag from the scroll view.
        #expect(CardSwipe.takesOverScrolling(on: .titleRow, scrolls: true))
        #expect(!CardSwipe.takesOverScrolling(on: .panel, scrolls: true))
        #expect(!CardSwipe.takesOverScrolling(on: .titleRow, scrolls: false))
        #expect(!CardSwipe.takesOverScrolling(on: .panel, scrolls: false))
    }

    // What the gesture sends: a swipe up then down on the left panel, one card each.
    @Test func theSwipesActionsSwitchOneCardEach() {
        let model = model()
        park(model)
        model.handle(CardAction.beginSwipe(.left))
        model.handle(CardAction.endSwipe(.left, forward: true))
        #expect(model.state.panels?.left.current == .vehicle)
        model.handle(CardAction.beginSwipe(.left))
        model.handle(CardAction.endSwipe(.left, forward: false))
        #expect(model.state.panels?.left.current == .trip)
    }

    /// Pixels inside `rect` where a channel differs by more than `HUDRenderTests.channelTolerance`.
    private func changed(_ a: [UInt8], _ b: [UInt8], width: Int, inside rect: CGRect) -> Int {
        var count = 0
        for pixel in stride(from: 0, to: a.count, by: 4)
        where (0..<4).contains(where: { abs(Int(a[pixel + $0]) - Int(b[pixel + $0])) > HUDRenderTests.channelTolerance }) {
            let point = CGPoint(x: CGFloat(pixel / 4 % width) + 0.5, y: CGFloat(pixel / 4 / width) + 0.5)
            if rect.contains(point) { count += 1 }
        }
        return count
    }

    // M12-03: leaving parked, the panels fade instead of switching at once. Just after the car moves, each
    // panel is still mostly its parked card (it is fading out), while a screen that starts on the drive
    // state shows the drive panels. (SwiftUI's animations hardly advance in a test window, so this
    // pins that the change is animated; `panelFade` pins its length.)
    @Test func leavingParkedFadesThePanels() throws {
        let model = model()
        park(model)
        let screen = HUDRenderTests.Screen.iPhone844
        let hosted = Hosted(Harness(model: model, screen: screen), size: screen.size, locale: "zh-Hant")
        defer { hosted.close() }
        let parked = try hosted.pixels()
        clock.advance(0.2)
        model.handle(reading(.drive, kmh: 30))
        #expect(model.state.layout == .drive)
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        let during = try hosted.pixels()
        let instant = Hosted(Harness(model: model, screen: screen), size: screen.size, locale: "zh-Hant")
        defer { instant.close() }
        let drive = try instant.pixels()

        let layout = DriveLayout(screen: screen.size, leftInset: screen.left, rightInset: screen.right, bottomInset: screen.bottom)
        let width = Int(screen.size.width)
        for panel in [layout.leftPanel, layout.tirePanel] {
            let whole = changed(parked, drive, width: width, inside: panel)
            #expect(whole > 500, "the drive panel is not different: \(whole) in \(panel)")
            let sofar = changed(parked, during, width: width, inside: panel)
            #expect(sofar * 2 < whole, "switched at once: \(sofar) of \(whole) pixels changed in \(panel)")
        }
    }

    @Test func leavingParkedFadesWithinTheLimit() {
        #expect(DriveScreen.panelFade(reduceMotion: true) == nil)
        #expect(DriveScreen.panelFade(reduceMotion: false) == .easeInOut(duration: 0.25))
    }
}
