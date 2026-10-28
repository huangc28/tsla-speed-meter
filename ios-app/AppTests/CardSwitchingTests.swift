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
        let host = UIHostingController(rootView: view.environment(\.locale, Locale(identifier: locale)))
        window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = host
        window.makeKeyAndVisible()
        settle()
    }

    func close() { window.isHidden = true }

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
    @Test func theSwipeDecides() {
        #expect(CardSwipe.step(CGSize(width: 0, height: -40)) == true)
        #expect(CardSwipe.step(CGSize(width: 6, height: 52)) == false)
        #expect(CardSwipe.step(CGSize(width: 0, height: -20)) == nil)
        #expect(CardSwipe.step(CGSize(width: 60, height: -40)) == nil)
        let first = CardDeck(cards: [.tires, .navigation], current: .tires)
        #expect(CardSwipe.moves(first, forward: true))
        #expect(!CardSwipe.moves(first, forward: false))
        #expect(!CardSwipe.moves(CardDeck(cards: [], current: nil), forward: true))
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

    @Test func leavingParkedFadesWithinTheLimit() {
        #expect(DriveScreen.panelFade(reduceMotion: true) == nil)
        #expect(DriveScreen.panelFade(reduceMotion: false) == .easeInOut(duration: 0.25))
    }
}
