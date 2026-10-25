import Security
import TeslaBLE

extension TeslaVehicleClient {
    /// The client the app uses: CoreBluetooth and the Keychain. Call it at
    /// launch: with a paired car it creates the central manager at once,
    /// because state restoration only reaches a central that exists then.
    /// Without one the central, and with it the Bluetooth permission prompt,
    /// waits for the first connect (pairing's S15, or the test page's 連線), so a
    /// GPS-only phone is never asked.
    @MainActor
    static func live(configuration: Configuration = Configuration(), keyStore: any TeslaKeyStore = KeychainTeslaKeyStore()) -> TeslaVehicleClient {
        let link = CoreBluetoothLink()
        if activatesBluetoothAtLaunch(keyStore) { link.activate() }
        return TeslaVehicleClient(link: link, keyStore: keyStore, configuration: configuration)
    }

    /// A paired car exists, or the Keychain cannot tell because the phone is locked (a
    /// background relaunch). Any other Keychain error counts as no paired car, so a phone
    /// that was never paired is never asked for Bluetooth.
    static func activatesBluetoothAtLaunch(_ keyStore: any TeslaKeyStore) -> Bool {
        do {
            return try keyStore.pairedVIN() != nil
        } catch KeychainTeslaKeyStore.Error.unexpectedStatus(errSecInteractionNotAllowed) {
            return true
        } catch {
            return false
        }
    }
}

extension TeslaVehicleClient.Configuration {
    /// The app's one client (`CarFeed.live()`).
    static let app = TeslaVehicleClient.Configuration(
        connectTimeout: .seconds(30),
        handshakeTimeout: .seconds(10),
        requestTimeout: .seconds(3),
        enrollmentTimeout: .seconds(60),
        enrollmentPollInterval: .seconds(2),
        captureRawFrames: true
    )
}

extension CarFeed {
    /// The app's one car feed, over the live client. Created once at launch.
    @MainActor
    static func live() -> CarFeed {
        CarFeed(client: .live(configuration: .app))
    }
}
