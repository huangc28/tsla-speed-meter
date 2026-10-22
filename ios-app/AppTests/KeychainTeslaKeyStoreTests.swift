import CryptoKit
import Foundation
import Security
import Testing
import TeslaBLE
@testable import SpeedHUD

/// Each test uses its own Keychain service and deletes it afterwards, so the
/// app's real key is never touched.
@Suite("Keychain key store", .serialized)
struct KeychainTeslaKeyStoreTests {
    private static func withStore(_ body: (KeychainTeslaKeyStore) throws -> Void) throws {
        let store = KeychainTeslaKeyStore(service: "com.tslaspeedmeter.hud.tests.\(UUID().uuidString)")
        defer { try? store.removeAll() }
        try body(store)
    }

    @Test("creates the client key once and loads the same key afterwards")
    func clientKeyPersists() throws {
        try Self.withStore { store in
            let created = try store.clientKey()
            #expect(created.publicKeyX963.count == 65)
            #expect(try store.clientKey().publicKeyX963 == created.publicKeyX963)
            let reopened = KeychainTeslaKeyStore(service: store.service)
            #expect(try reopened.clientKey().publicKeyX963 == created.publicKeyX963)
        }
    }

    @Test("the stored key agrees on the ECDH secret like an in-memory key")
    func clientKeyWorks() throws {
        try Self.withStore { store in
            let key = try store.clientKey()
            let peer = P256.KeyAgreement.PrivateKey()
            let expected = try peer.sharedSecretFromKeyAgreement(
                with: P256.KeyAgreement.PublicKey(x963Representation: key.publicKeyX963)
            ).withUnsafeBytes { Data($0) }
            #expect(try key.sharedSecret(withPublicKeyX963: peer.publicKey.x963Representation) == expected)
        }
    }

    @Test("the client key is WhenUnlockedThisDeviceOnly and not synchronizable")
    func clientKeyAttributes() throws {
        try Self.withStore { store in
            _ = try store.clientKey()
            let query: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: store.service,
                kSecAttrAccount: "client-key.p256",
                kSecAttrSynchronizable: kSecAttrSynchronizableAny,
                kSecReturnAttributes: true,
                kSecMatchLimit: kSecMatchLimitOne,
            ]
            var result: CFTypeRef?
            #expect(SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess)
            let attributes = try #require(result as? [String: Any])
            #expect(attributes[kSecAttrAccessible as String] as? String == kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String)
            #expect((attributes[kSecAttrSynchronizable as String] as? Bool) != true)
        }
    }

    @Test("stores and replaces the paired VIN")
    func pairedVIN() throws {
        try Self.withStore { store in
            #expect(try store.pairedVIN() == nil)
            try store.setPairedVIN("5YJ30123456789ABC")
            #expect(try store.pairedVIN() == "5YJ30123456789ABC")
            try store.setPairedVIN("5YJ3E1EA0KF000001")
            #expect(try store.pairedVIN() == "5YJ3E1EA0KF000001")
        }
    }

    @Test("pins a vehicle key per VIN and domain")
    func vehicleKeys() throws {
        try Self.withStore { store in
            let vcsec = Data(repeating: 1, count: 65)
            let infotainment = Data(repeating: 2, count: 65)
            try store.setVehiclePublicKey(vcsec, vin: "VIN1", domain: .vehicleSecurity)
            try store.setVehiclePublicKey(infotainment, vin: "VIN1", domain: .infotainment)
            #expect(try store.vehiclePublicKey(vin: "VIN1", domain: .vehicleSecurity) == vcsec)
            #expect(try store.vehiclePublicKey(vin: "VIN1", domain: .infotainment) == infotainment)
            #expect(try store.vehiclePublicKey(vin: "VIN2", domain: .vehicleSecurity) == nil)
        }
    }

    @Test("removeAll deletes the key, so the next use creates a new one")
    func removeAll() throws {
        try Self.withStore { store in
            let first = try store.clientKey().publicKeyX963
            try store.setPairedVIN("VIN1")
            try store.removeAll()
            #expect(try store.pairedVIN() == nil)
            #expect(try store.clientKey().publicKeyX963 != first)
        }
    }

    @Test @MainActor func liveClientBuilds() async {
        let client = TeslaVehicleClient.live()
        #expect(await !client.isConnected)
    }
}
