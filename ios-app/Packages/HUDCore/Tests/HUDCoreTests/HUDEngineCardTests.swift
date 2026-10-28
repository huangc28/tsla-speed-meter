import Foundation
import Testing
@testable import HUDCore

private let carEpoch = Date(timeIntervalSinceReferenceDate: 700_000_000)

private let taipei = CarRoute(destination: "台北車站", minutesToArrival: 17.6, kilometersToArrival: 12.3, energyAtArrival: 64.3)

/// A drive reply that reached the phone at `t0 + seconds`, stamped with the car's own time.
private func drive(_ navigation: CarNavigation = .noRoute, kmh: Double = 60, gear: CarGear = .drive,
                   at seconds: TimeInterval) -> CarEvent {
    .reading(CarReading(receivedAt: t0 + seconds, carTimestamp: carEpoch + seconds, speedMetersPerSecond: kmh / 3.6,
                        gear: gear, navigation: navigation))
}

/// #79: the parked screen's cards (07 §2.3, §3.1, M12-03, M12-04, M12-14, L84-5).
struct HUDEngineCardTests {
    private func authorized(_ cards: CardSwitcher = CardSwitcher()) -> HUDEngine {
        var engine = HUDEngine(cards: cards)
        engine.handle(.authorization(.authorized), now: t0)
        return engine
    }

    private func handle(_ engine: inout HUDEngine, _ event: CarEvent, at seconds: TimeInterval) {
        engine.handle(event, now: t0 + seconds)
    }

    private func act(_ engine: inout HUDEngine, _ action: CardAction, at seconds: TimeInterval) {
        engine.handle(action, now: t0 + seconds)
    }

    private func state(_ engine: HUDEngine, at seconds: TimeInterval) -> HUDState {
        engine.state(at: t0 + seconds, unit: .kilometersPerHour)
    }

    private func panels(_ engine: HUDEngine, at seconds: TimeInterval) -> ParkedPanels? {
        state(engine, at: seconds).panels
    }

    /// Two P readings 0.2 s apart, the last at `seconds`: the auto-parked layout.
    private func park(_ engine: inout HUDEngine, _ navigation: CarNavigation = .noRoute, at seconds: TimeInterval) {
        handle(&engine, drive(navigation, kmh: 0, gear: .park, at: seconds - 0.2), at: seconds - 0.2)
        handle(&engine, drive(navigation, kmh: 0, gear: .park, at: seconds), at: seconds)
        #expect(state(engine, at: seconds).layout == .parked)
    }

    // MARK: Cards per side

    @Test func cardsPerSide() {
        #expect(PanelCard.offered(on: .left, carData: true) == [.trip, .vehicle])
        #expect(PanelCard.offered(on: .right, carData: true) == [.tires, .navigation])
        // GPS only: only the trip, and the right panel offers nothing (「尚無車輛資料」).
        #expect(PanelCard.offered(on: .left, carData: false) == [.trip])
        #expect(PanelCard.offered(on: .right, carData: false) == [])
        #expect(PanelCard.allCases.filter(\.showsWhileDriving) == [.trip, .navigation])

        let switcher = CardSwitcher()
        #expect(switcher.deck(.left, carData: true) == CardDeck(cards: [.trip, .vehicle], current: .trip))
        #expect(switcher.deck(.right, carData: true) == CardDeck(cards: [.tires, .navigation], current: .tires))
        #expect(switcher.deck(.right, carData: true).position == 1)
        // A chosen card that is not offered gives way to the first offered, and is kept.
        let vehicle = CardSwitcher(left: .vehicle, right: .navigation)
        #expect(vehicle.deck(.left, carData: false) == CardDeck(cards: [.trip], current: .trip))
        #expect(vehicle.deck(.right, carData: false) == CardDeck(cards: [], current: nil))
        #expect(vehicle.deck(.right, carData: false).position == nil)
        #expect(vehicle.left == .vehicle && vehicle.right == .navigation)
    }

    @Test func aStoredCardOnTheWrongSideFallsBackToTheDefault() {
        let switcher = CardSwitcher(left: .tires, right: .trip)
        #expect(switcher.left == .trip && switcher.right == .tires)
    }

    @Test func parkedShowsTheDefaultsAndTheDriveScreenNoCards() {
        var engine = authorized()
        handle(&engine, drive(at: 0), at: 0)
        #expect(panels(engine, at: 0) == nil)
        park(&engine, at: 1)
        #expect(panels(engine, at: 1) == ParkedPanels(left: CardDeck(cards: [.trip, .vehicle], current: .trip),
                                                       right: CardDeck(cards: [.tires, .navigation], current: .tires),
                                                       openList: nil, showsHint: true))
    }

    // MARK: Switching

    @Test func theTitleOpensTheListAndChoosingClosesIt() {
        var engine = authorized()
        park(&engine, at: 1)
        act(&engine, .toggleList(.right), at: 1.1)
        #expect(panels(engine, at: 1.1)?.openList == .right)
        act(&engine, .choose(.navigation), at: 1.2)
        #expect(panels(engine, at: 1.2)?.openList == nil)
        #expect(panels(engine, at: 1.2)?.right.current == .navigation)
        #expect(panels(engine, at: 1.2)?.right.position == 2)
        // The title again closes the list without choosing; one list at a time.
        act(&engine, .toggleList(.left), at: 1.3)
        act(&engine, .toggleList(.right), at: 1.4)
        #expect(panels(engine, at: 1.4)?.openList == .right)
        act(&engine, .toggleList(.right), at: 1.5)
        #expect(panels(engine, at: 1.5)?.openList == nil)
        #expect(engine.cards.right == .navigation)
    }

    @Test func aSwipeMovesOneCardAndStopsAtTheEnds() {
        var engine = authorized()
        park(&engine, at: 1)
        act(&engine, .beginSwipe(.left), at: 1.1)
        act(&engine, .endSwipe(.left, forward: true), at: 1.2)
        #expect(panels(engine, at: 1.2)?.left.current == .vehicle)
        act(&engine, .beginSwipe(.left), at: 1.3)
        act(&engine, .endSwipe(.left, forward: true), at: 1.4)
        #expect(panels(engine, at: 1.4)?.left.current == .vehicle)
        // One swipe, one card: an end with no begin does nothing.
        act(&engine, .endSwipe(.left, forward: false), at: 1.5)
        #expect(panels(engine, at: 1.5)?.left.current == .vehicle)
        act(&engine, .beginSwipe(.left), at: 1.6)
        act(&engine, .endSwipe(.left, forward: false), at: 1.7)
        #expect(panels(engine, at: 1.7)?.left.current == .trip)
        // VoiceOver's next / previous, on the right.
        act(&engine, .step(.right, forward: false), at: 1.8)
        #expect(panels(engine, at: 1.8)?.right.current == .tires)
        act(&engine, .step(.right, forward: true), at: 1.9)
        #expect(panels(engine, at: 1.9)?.right.current == .navigation)
    }

    @Test func nothingSwitchesOnTheDriveScreen() {
        var engine = authorized()
        handle(&engine, drive(at: 0), at: 0)
        act(&engine, .toggleList(.right), at: 0.1)
        act(&engine, .choose(.navigation), at: 0.1)
        act(&engine, .step(.left, forward: true), at: 0.1)
        act(&engine, .dismissHint, at: 0.1)
        #expect(engine.cards == CardSwitcher())
    }

    // MARK: Leaving parked (M12-03, M12-04)

    @Test func leavingParkedCancelsTheOpenListForGood() {
        var engine = authorized()
        park(&engine, at: 1)
        act(&engine, .toggleList(.left), at: 1.1)
        #expect(panels(engine, at: 1.1)?.openList == .left)
        // The car moves: no cards on the drive screen.
        handle(&engine, drive(at: 1.3), at: 1.3)
        #expect(state(engine, at: 1.3).layout == .drive)
        #expect(panels(engine, at: 1.3) == nil)
        // Parked again: the list stays closed.
        park(&engine, at: 3)
        #expect(panels(engine, at: 3)?.openList == nil)
    }

    @Test func leavingParkedWithNoEventCancelsAtTheNextAction() {
        var engine = authorized()
        park(&engine, at: 1)
        act(&engine, .toggleList(.right), at: 1.1)
        // The P goes stale with no event (2 s): not parked, nothing shows, and the list is gone.
        #expect(panels(engine, at: 3.5) == nil)
        act(&engine, .choose(.navigation), at: 3.5)
        park(&engine, at: 5)
        #expect(panels(engine, at: 5)?.openList == nil)
        #expect(panels(engine, at: 5)?.right.current == .tires)
    }

    @Test func leavingParkedCancelsASwipeUnderWay() {
        var engine = authorized()
        park(&engine, at: 1)
        act(&engine, .beginSwipe(.left), at: 1.1)
        handle(&engine, drive(at: 1.3), at: 1.3)
        // The swipe ends on the drive screen, or after parking again: never resumed.
        act(&engine, .endSwipe(.left, forward: true), at: 1.4)
        park(&engine, at: 3)
        act(&engine, .endSwipe(.left, forward: true), at: 3.1)
        #expect(panels(engine, at: 3.1)?.left.current == .trip)
    }

    // MARK: The remembered choice

    @Test func theChoiceIsRememberedForTheNextParkedScreen() {
        var engine = authorized()
        park(&engine, at: 1)
        act(&engine, .choose(.vehicle), at: 1.1)
        act(&engine, .choose(.navigation), at: 1.2)
        handle(&engine, drive(at: 1.4), at: 1.4)
        // The background and a lost link keep it.
        engine.suspend()
        engine.resume(now: t0 + 2)
        handle(&engine, .link(.lost), at: 2.1)
        handle(&engine, .link(.connected), at: 2.2)
        park(&engine, at: 4)
        #expect(panels(engine, at: 4)?.left.current == .vehicle)
        #expect(panels(engine, at: 4)?.right.current == .navigation)
        #expect(engine.cards.left == .vehicle && engine.cards.right == .navigation)
        // What the app stored comes back with a new engine.
        let stored = authorized(CardSwitcher(left: engine.cards.left, right: engine.cards.right))
        var restored = stored
        park(&restored, at: 1)
        #expect(panels(restored, at: 1)?.left.current == .vehicle)
        #expect(panels(restored, at: 1)?.right.current == .navigation)
    }

    // MARK: Entering drive (07 §3.1)

    @Test func enteringDriveAfterNavigationParkedShowsNavigation() {
        var engine = authorized()
        park(&engine, at: 1)
        act(&engine, .choose(.navigation), at: 1.1)
        // No route: navigation is still the panel (a reply with no destination leaves it empty, L84-4) …
        handle(&engine, drive(at: 1.4), at: 1.4)
        #expect(state(engine, at: 1.4).navigation == .ended)
        // … and a route set later shows in place: not a Q11 switch.
        handle(&engine, drive(.route(taipei), at: 1.6), at: 1.6)
        #expect(state(engine, at: 1.6).navigation == .route(NavigationRoute(destination: "台北車站", minutes: 18, distance: 12, arrivalPercent: 64)))
        #expect(state(engine, at: 1.6).navigationSwitches == 0)
    }

    @Test func enteringDriveAfterTiresParkedFollowsTheRoute() {
        // Tires cannot show while driving: navigation if a fresh route is set …
        var engine = authorized()
        park(&engine, .route(taipei), at: 1)
        handle(&engine, drive(.route(taipei), at: 1.4), at: 1.4)
        if case .route = state(engine, at: 1.4).navigation {} else { Issue.record("no navigation") }
        // … otherwise empty.
        var empty = authorized()
        park(&empty, at: 1)
        handle(&empty, drive(at: 1.4), at: 1.4)
        #expect(state(empty, at: 1.4).navigation == nil)
    }

    @Test func enteringDriveOnGPSOnlyLeavesTheRightPanelEmpty() {
        var engine = authorized(CardSwitcher(right: .navigation))
        // No car at all: the app's first state on GPS.
        engine.handle(.sample(fix(20, at: 0)), now: t0)
        #expect(state(engine, at: 0).navigation == nil)
    }

    // MARK: Parked navigation card

    @Test func theParkedNavigationCardShowsTheCarsRoute() {
        var engine = authorized()
        park(&engine, .route(taipei), at: 1)
        // The tire card is showing: no navigation drawn.
        #expect(state(engine, at: 1).navigation == nil)
        act(&engine, .choose(.navigation), at: 1)
        #expect(state(engine, at: 1).navigation == .route(NavigationRoute(destination: "台北車站", minutes: 18, distance: 12, arrivalPercent: 64)))
        // No route: 「車上沒有在導航」 on the card.
        var ended = authorized(CardSwitcher(right: .navigation))
        park(&ended, at: 1)
        #expect(state(ended, at: 1).navigation == .ended)
    }

    // Parked, GPS supplying the speed does not hide the card: the car P with no speed, GPS at 0.
    @Test func theParkedNavigationCardShowsBesideGPSSpeed() {
        var engine = authorized(CardSwitcher(right: .navigation))
        engine.handle(.sample(fix(0, at: 0.9)), now: t0 + 0.9)
        for seconds in [0.8, 1.0] {
            handle(&engine, .reading(CarReading(receivedAt: t0 + seconds, carTimestamp: carEpoch + seconds, gear: .park,
                                                navigation: .route(taipei))), at: seconds)
        }
        let state = state(engine, at: 1)
        #expect(state.layout == .parked)
        #expect(state.source == .valid(.gps))
        #expect(state.navigation == .route(NavigationRoute(destination: "台北車站", minutes: 18, distance: 12, arrivalPercent: 64)))
    }

    // MARK: The one-time card (L84-5)

    @Test func theOneTimeCardStaysUntilGotIt() {
        var engine = authorized()
        park(&engine, at: 1)
        #expect(panels(engine, at: 1)?.showsHint == true)
        // Switching cards keeps it.
        act(&engine, .choose(.vehicle), at: 1.1)
        act(&engine, .step(.right, forward: true), at: 1.2)
        #expect(panels(engine, at: 1.2)?.showsHint == true)
        act(&engine, .dismissHint, at: 1.3)
        #expect(panels(engine, at: 1.3)?.showsHint == false)
        #expect(engine.cards.hintDismissed)
        // Stored, it never shows again.
        var stored = authorized(CardSwitcher(hintDismissed: engine.cards.hintDismissed))
        park(&stored, at: 1)
        #expect(panels(stored, at: 1)?.showsHint == false)
    }
}
