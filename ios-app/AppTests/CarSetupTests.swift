import Foundation
import Testing
import TeslaBLE
import TeslaBLETestSupport
@testable import SpeedHUD

@Suite("Setup dot and invitation", .serialized)
@MainActor
struct CarSetupTests {
    private func feed(pairedVIN: String?) -> CarFeed {
        let keyStore = InMemoryKeyStore()
        if let pairedVIN { try! keyStore.setPairedVIN(pairedVIN) }
        return CarFeed(client: TeslaVehicleClient(link: MockLink(), keyStore: keyStore))
    }

    /// Empty defaults of their own, removed when the test ends.
    private final class TestDefaults {
        let suite = "CarSetupTests.\(UUID().uuidString)"
        lazy var defaults = UserDefaults(suiteName: suite)!
        deinit { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
    }

    @Test("not read yet: neither the dot nor the invitation")
    func unknown() async throws {
        let store = TestDefaults()
        let defaults = store.defaults
        do {
            let setup = CarSetup(defaults: defaults)
            #expect(!setup.showsSetupDot)
            #expect(!setup.showsInvite)
        }
    }

    @Test("no paired car: the dot and the invitation")
    func unpaired() async throws {
        let store = TestDefaults()
        let defaults = store.defaults
        do {
            let setup = CarSetup(defaults: defaults)
            await setup.refresh(from: feed(pairedVIN: nil))
            #expect(setup.showsSetupDot)
            #expect(setup.showsInvite)
        }
    }

    @Test("之後再說: the invitation is gone for good, also after a restart; the dot stays")
    func dismissed() async throws {
        let store = TestDefaults()
        let defaults = store.defaults
        do {
            let setup = CarSetup(defaults: defaults)
            await setup.refresh(from: feed(pairedVIN: nil))
            setup.dismissInvite()
            #expect(!setup.showsInvite)
            #expect(setup.showsSetupDot)

            let relaunched = CarSetup(defaults: defaults)
            await relaunched.refresh(from: feed(pairedVIN: nil))
            #expect(!relaunched.showsInvite)
            #expect(relaunched.showsSetupDot)
        }
    }

    @Test("a paired car: no dot, no invitation")
    func paired() async throws {
        let store = TestDefaults()
        let defaults = store.defaults
        do {
            let setup = CarSetup(defaults: defaults)
            await setup.refresh(from: feed(pairedVIN: "5YJ3E1EA2SF935028"))
            #expect(!setup.showsSetupDot)
            #expect(!setup.showsInvite)
        }
    }
}
