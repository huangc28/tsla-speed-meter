import Foundation

/// One category of vehicle data, asked for in its own GetVehicleData request.
public enum VehicleDataCategory: String, CaseIterable, Sendable {
    /// Drive state: speed, gear, power.
    case drive
    /// Charge state: battery level, range, charging.
    case charge
    /// Tire pressure state.
    case tirePressure
}

/// Builders for the unsigned messages the client sends. Signed requests come
/// from `VehicleSession.sign(payload:)`.
public enum TeslaRequests {
    /// Handshake request for one domain (vehicle-command
    /// internal/dispatcher/dispatcher.go `SessionInfoRequest`; protocol.md
    /// "Request"). Only the public key is set: the session-info HMAC challenge
    /// is this message's `uuid`, so keep it to verify the reply with
    /// `VehicleSession(sessionInfoResponse:requestUUID:...)`.
    public static func sessionInfoRequest(
        domain: UniversalMessage_Domain,
        clientPublicKey: Data,
        routingAddress: Data = .random(count: 16),
        uuid: Data = .random(count: 16)
    ) -> UniversalMessage_RoutableMessage {
        var message = UniversalMessage_RoutableMessage()
        message.toDestination.domain = domain
        message.fromDestination.routingAddress = routingAddress
        message.sessionInfoRequest.publicKey = clientPublicKey
        message.uuid = uuid
        return message
    }

    /// The infotainment action that asks for one category of vehicle data:
    /// a GetVehicleData with exactly one sub-message. Asking for several in
    /// one request can make the reply too big for the car to send
    /// (RESPONSE_MTU_EXCEEDED), so vehicle-command pkg/vehicle/state.go
    /// `GetState` and Moblin ask for one category per request too.
    /// Serialize it and pass it to `VehicleSession.sign(payload:)` on the
    /// infotainment session.
    public static func getVehicleDataAction(_ category: VehicleDataCategory) -> CarServer_Action {
        var action = CarServer_Action()
        switch category {
        case .drive:
            action.vehicleAction.getVehicleData.getDriveState = CarServer_GetDriveState()
        case .charge:
            action.vehicleAction.getVehicleData.getChargeState = CarServer_GetChargeState()
        case .tirePressure:
            action.vehicleAction.getVehicleData.getTirePressureState = CarServer_GetTirePressureState()
        }
        return action
    }

    /// One-time key enrollment: asks VCSEC to add `publicKey` to the vehicle
    /// whitelist. The owner approves by tapping a paired key card on the
    /// center console.
    ///
    /// The key role and form factor follow the Dart port (driver, iOS
    /// device). The envelope follows vehicle-command
    /// pkg/vehicle/security.go `SendAddKeyRequestWithRole` and Moblin
    /// Moblin/Integrations/Tesla/TeslaVehicle.swift `addKeyRequestWithRole`:
    /// a bare `ToVCSECMessage` with `SIGNATURE_TYPE_PRESENT_KEY`, written to
    /// the BLE characteristic as-is (not wrapped in a RoutableMessage).
    public static func addKeyToWhitelist(
        publicKey: Data,
        role: Keys_Role = .driver,
        formFactor: VCSEC_KeyFormFactor = .iosDevice
    ) throws -> VCSEC_ToVCSECMessage {
        var unsigned = VCSEC_UnsignedMessage()
        unsigned.whitelistOperation.addKeyToWhitelistAndAddPermissions.key.publicKeyRaw = publicKey
        unsigned.whitelistOperation.addKeyToWhitelistAndAddPermissions.keyRole = role
        unsigned.whitelistOperation.metadataForKey.keyFormFactor = formFactor

        var envelope = VCSEC_ToVCSECMessage()
        envelope.signedMessage.protobufMessageAsBytes = try unsigned.serializedData()
        envelope.signedMessage.signatureType = .presentKey
        return envelope
    }
}
