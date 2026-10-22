import Foundation

/// What a request to the vehicle was for.
public enum TeslaRequestKind: String, Sendable, Equatable {
    case sessionInfo
    case getVehicleData
    case addKeyToWhitelist
}

/// A vehicle-data reply and how it arrived.
public struct VehicleDataResponse: Sendable, Equatable {
    public let reading: VehicleReading
    /// False when the vehicle ignored FLAG_ENCRYPT_RESPONSE (older firmware).
    public let isEncrypted: Bool
    /// Request fully written to reply received, for the request that succeeded.
    public let roundTripMs: Int
    /// Queued behind other writes until the request was fully written.
    public let sendWaitMs: Int
    /// A fault was resynced and the request sent a second time.
    public let retried: Bool

    public init(reading: VehicleReading, isEncrypted: Bool, roundTripMs: Int, sendWaitMs: Int = 0, retried: Bool) {
        self.reading = reading
        self.isEncrypted = isEncrypted
        self.roundTripMs = roundTripMs
        self.sendWaitMs = sendWaitMs
        self.retried = retried
    }
}

/// Key enrollment progress, for the UI.
public enum EnrollmentState: Sendable, Equatable {
    /// Asking VCSEC whether the key is already on the whitelist.
    case checking
    /// The add-key request was sent: "tap your key card on the console now".
    case awaitingKeyCardTap
    /// VCSEC knows the key; waiting for it to reach Infotainment.
    case waitingForSync
    case enrolled
    case timedOut
    /// VCSEC refused the whitelist operation; carries its reason.
    case rejected(String)
}

/// Errors from `TeslaVehicleClient`.
public enum TeslaClientError: Error, Equatable, Sendable {
    /// `connect(vin:)` has not succeeded, or the link dropped.
    case notConnected
    case link(BLELinkError)
    /// The link dropped while a request was waiting for its reply.
    case disconnected
    /// The calling Task was cancelled.
    case cancelled
    /// The vehicle did not answer a session-info request (asleep, out of
    /// range, or busy). Enrollment did not start.
    case vehicleUnreachable
    /// No reply in time.
    case timeout(TeslaRequestKind)
    /// The vehicle does not know this app's key (session info status
    /// KEY_NOT_ON_WHITELIST, or fault UNKNOWN_KEY_ID). Run `enrollKey()`.
    case keyNotPaired
    /// The vehicle answered with a protocol fault that a resync did not fix.
    case vehicleFault(UniversalMessage_MessageFault_E)
    /// The domain's public key differs from the one pinned for this VIN.
    case vehiclePublicKeyMismatch(UniversalMessage_Domain)
    /// Authentication or decryption failed.
    case session(TeslaSessionError)
    /// The vehicle's reply could not be parsed or was not the expected kind.
    case malformedReply(String)
    /// The infotainment action failed (`VehicleReadingError`).
    case reading(VehicleReadingError)
    case enrollmentTimedOut
    case enrollmentRejected(String)
    case framing(TeslaFraming.Error)
    case keyStore(String)
}

/// One structured event, for the drive logger. Raw frames appear only when
/// `TeslaVehicleClient.Configuration.captureRawFrames` is set. No event ever
/// carries private key material.
public struct TeslaClientEvent: Sendable, Equatable {
    public let date: Date
    public let kind: Kind

    public init(date: Date = Date(), kind: Kind) {
        self.date = date
        self.kind = kind
    }

    public enum Kind: Sendable, Equatable {
        case connecting(localName: String)
        case connected(localName: String, maxWriteLength: Int, durationMs: Int)
        case connectFailed(TeslaClientError, durationMs: Int)
        case disconnected(reconnecting: Bool, reason: String?)
        case reconnected(maxWriteLength: Int)
        case handshakeStarted(UniversalMessage_Domain)
        case handshakeSucceeded(UniversalMessage_Domain, durationMs: Int)
        case handshakeFailed(UniversalMessage_Domain, TeslaClientError, durationMs: Int)
        case requestSent(UniversalMessage_Domain, TeslaRequestKind, bytes: Int)
        /// `durationMs` runs from the completed write to the reply;
        /// `sendWaitMs` is the time spent queued and writing before that.
        case responseReceived(UniversalMessage_Domain, TeslaRequestKind, bytes: Int, durationMs: Int, sendWaitMs: Int)
        case fault(UniversalMessage_Domain, UniversalMessage_MessageFault_E)
        /// Session state was refreshed from session info the vehicle attached
        /// to a fault reply.
        case sessionResynced(UniversalMessage_Domain)
        case timeout(UniversalMessage_Domain, TeslaRequestKind, durationMs: Int)
        case enrollment(EnrollmentState)
        /// A bare VCSEC whitelist-operation status (reply to the add-key request).
        case whitelistStatus(VCSEC_OperationStatus_E, information: VCSEC_WhitelistOperation_information_E)
        /// An inbound message that matched no pending request, or bytes the
        /// frame assembler threw away.
        case messageDropped(reason: String)
        /// One whole message written (before framing).
        case frameSent(Data)
        /// One whole message received (after reassembly).
        case frameReceived(Data)
    }
}
