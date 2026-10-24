import TeslaBLE

extension TeslaVehicleClient {
    /// The client the app uses: CoreBluetooth and the Keychain. Creates the
    /// central manager at once, so call it at launch: state restoration only
    /// reaches a central that exists then. Because of that, the Bluetooth
    /// permission prompt appears at the first app launch, not at the first
    /// 連線.
    @MainActor
    static func live(configuration: Configuration = Configuration()) -> TeslaVehicleClient {
        let link = CoreBluetoothLink()
        link.activate()
        return TeslaVehicleClient(link: link, keyStore: KeychainTeslaKeyStore(), configuration: configuration)
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
