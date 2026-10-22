import Foundation
import Security
import TeslaBLE

/// `TeslaKeyStore` in the Keychain. Every item is a generic password under
/// one service, `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` and not
/// synchronizable: never in iCloud Keychain; included in encrypted backups
/// but cannot be restored to another phone. The client key is the 32-byte
/// P-256 private scalar, created on first use, one per app on this device.
/// On current iOS the items survive deleting and reinstalling the app (so
/// the car's whitelist entry stays valid), but Apple does not guarantee it.
struct KeychainTeslaKeyStore: TeslaKeyStore {
    static let defaultService = "com.tslaspeedmeter.hud.tesla-ble"

    enum Error: Swift.Error, Equatable {
        case unexpectedStatus(OSStatus)
    }

    let service: String

    init(service: String = Self.defaultService) {
        self.service = service
    }

    private static let clientKeyAccount = "client-key.p256"
    private static let pairedVINAccount = "paired-vin"

    private static func vehicleKeyAccount(vin: String, domain: UniversalMessage_Domain) -> String {
        "vehicle-key.\(vin).\(domain.rawValue)"
    }

    func clientKey() throws -> any KeyAgreementKey {
        if let raw = try read(Self.clientKeyAccount) {
            return try SoftwareKeyAgreementKey(rawRepresentation: raw)
        }
        let key = SoftwareKeyAgreementKey()
        let status = add(Self.clientKeyAccount, key.privateKey.rawRepresentation)
        switch status {
        case errSecSuccess:
            return key
        case errSecDuplicateItem:
            // Another caller created it first; use theirs.
            guard let raw = try read(Self.clientKeyAccount) else { throw Error.unexpectedStatus(status) }
            return try SoftwareKeyAgreementKey(rawRepresentation: raw)
        default:
            throw Error.unexpectedStatus(status)
        }
    }

    func pairedVIN() throws -> String? {
        try read(Self.pairedVINAccount).map { String(decoding: $0, as: UTF8.self) }
    }

    func setPairedVIN(_ vin: String) throws {
        try upsert(Self.pairedVINAccount, Data(vin.utf8))
    }

    func vehiclePublicKey(vin: String, domain: UniversalMessage_Domain) throws -> Data? {
        try read(Self.vehicleKeyAccount(vin: vin, domain: domain))
    }

    func setVehiclePublicKey(_ key: Data, vin: String, domain: UniversalMessage_Domain) throws {
        try upsert(Self.vehicleKeyAccount(vin: vin, domain: domain), key)
    }

    /// Deletes every item of this service (the key, the VIN and the pins).
    func removeAll() throws {
        let status = SecItemDelete([
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
        ] as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw Error.unexpectedStatus(status) }
    }

    // MARK: Keychain

    private func baseQuery(_ account: String) -> [CFString: Any] {
        [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ]
    }

    private func read(_ account: String) throws -> Data? {
        var query = baseQuery(account)
        query[kSecReturnData] = true
        query[kSecMatchLimit] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess: return result as? Data
        case errSecItemNotFound: return nil
        default: throw Error.unexpectedStatus(status)
        }
    }

    private func add(_ account: String, _ data: Data) -> OSStatus {
        var attributes = baseQuery(account)
        attributes[kSecValueData] = data
        attributes[kSecAttrAccessible] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        attributes[kSecAttrSynchronizable] = false
        return SecItemAdd(attributes as CFDictionary, nil)
    }

    private func upsert(_ account: String, _ data: Data) throws {
        let status = add(account, data)
        if status == errSecDuplicateItem {
            let update = SecItemUpdate(baseQuery(account) as CFDictionary, [kSecValueData: data] as CFDictionary)
            guard update == errSecSuccess else { throw Error.unexpectedStatus(update) }
        } else if status != errSecSuccess {
            throw Error.unexpectedStatus(status)
        }
    }
}
