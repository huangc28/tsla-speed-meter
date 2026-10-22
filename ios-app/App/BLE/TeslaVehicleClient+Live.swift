import TeslaBLE

extension TeslaVehicleClient {
    /// The client the app uses: CoreBluetooth and the Keychain.
    @MainActor
    static func live(configuration: Configuration = Configuration()) -> TeslaVehicleClient {
        TeslaVehicleClient(link: CoreBluetoothLink(), keyStore: KeychainTeslaKeyStore(), configuration: configuration)
    }
}
