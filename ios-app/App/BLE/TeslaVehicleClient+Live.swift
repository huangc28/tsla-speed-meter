import TeslaBLE

extension TeslaVehicleClient {
    /// The client the app uses: CoreBluetooth and the Keychain.
    /// `activateBluetooth` creates the central manager at once (needed for
    /// state restoration; shows the Bluetooth prompt on first use).
    @MainActor
    static func live(configuration: Configuration = Configuration(), activateBluetooth: Bool = false) -> TeslaVehicleClient {
        let link = CoreBluetoothLink()
        if activateBluetooth { link.activate() }
        return TeslaVehicleClient(link: link, keyStore: KeychainTeslaKeyStore(), configuration: configuration)
    }
}
