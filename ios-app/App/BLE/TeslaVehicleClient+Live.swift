import TeslaBLE

extension TeslaVehicleClient {
    /// The client the app uses: CoreBluetooth and the Keychain. Creates the
    /// central manager at once, so call it at launch: state restoration only
    /// reaches a central that exists then (the Bluetooth prompt appears on
    /// first use).
    @MainActor
    static func live(configuration: Configuration = Configuration()) -> TeslaVehicleClient {
        let link = CoreBluetoothLink()
        link.activate()
        return TeslaVehicleClient(link: link, keyStore: KeychainTeslaKeyStore(), configuration: configuration)
    }
}
