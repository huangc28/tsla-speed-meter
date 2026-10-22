import Foundation

/// Where the client's key, the paired VIN and the pinned vehicle public keys
/// live. The app implements it with the Keychain; keys never go to
/// UserDefaults, files or logs.
public protocol TeslaKeyStore: Sendable {
    /// The app's one P-256 key, created and stored on first use.
    func clientKey() throws -> any KeyAgreementKey

    /// The VIN whose whitelist holds `clientKey()`, once enrollment succeeded.
    func pairedVIN() throws -> String?
    func setPairedVIN(_ vin: String) throws

    /// The vehicle public key seen in the first session with `domain` of
    /// `vin` (65-byte X9.63). Each domain has its own key.
    func vehiclePublicKey(vin: String, domain: UniversalMessage_Domain) throws -> Data?
    func setVehiclePublicKey(_ key: Data, vin: String, domain: UniversalMessage_Domain) throws
}
