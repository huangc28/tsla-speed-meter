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

/// One poll of several vehicle-data categories, one request each. A
/// category that failed does not discard the others.
public struct VehicleDataPoll: Sendable, Equatable {
    public struct Entry: Sendable, Equatable {
        public let category: VehicleDataCategory
        public let result: Result<VehicleDataResponse, TeslaClientError>

        public init(category: VehicleDataCategory, result: Result<VehicleDataResponse, TeslaClientError>) {
            self.category = category
            self.result = result
        }
    }

    /// One entry per category sent, in the order sent. A poll that was
    /// cancelled ends with the cancelled category.
    public let entries: [Entry]
    /// Categories not sent because an earlier one failed on the link or
    /// the handshake (`TeslaVehicleClient.pollVehicleData(_:)`). Not failures.
    public let skipped: [VehicleDataCategory]

    public init(entries: [Entry], skipped: [VehicleDataCategory] = []) {
        self.entries = entries
        self.skipped = skipped
    }

    public func result(for category: VehicleDataCategory) -> Result<VehicleDataResponse, TeslaClientError>? {
        entries.first { $0.category == category }?.result
    }

    public func response(for category: VehicleDataCategory) -> VehicleDataResponse? {
        guard case .success(let response)? = result(for: category) else { return nil }
        return response
    }

    public func error(for category: VehicleDataCategory) -> TeslaClientError? {
        guard case .failure(let error)? = result(for: category) else { return nil }
        return error
    }

    /// The categories that came back, merged into one reading. Nil when
    /// none came back.
    public var reading: VehicleReading? {
        guard entries.contains(where: { if case .success = $0.result { true } else { false } }) else { return nil }
        return VehicleReading(
            drive: response(for: .drive)?.reading,
            charge: response(for: .charge)?.reading,
            tirePressure: response(for: .tirePressure)?.reading
        )
    }

    /// The first category's error, in the order sent; nil when all came back.
    public var firstError: TeslaClientError? {
        entries.lazy.compactMap { entry -> TeslaClientError? in
            if case .failure(let error) = entry.result { error } else { nil }
        }.first
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

/// One structured event, for the drive logger: from the client, or from the
/// car feed (`autoReconnect…`, `systemReconnectStalled`). Raw frames appear only when
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
        /// The scan saw the car advertising `localName`: the nearby match (L64).
        case vehicleFound(localName: String)
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
        /// A reply whose AES-GCM tag failed claimed this fault. Unverified:
        /// the client does not act on it (the request fails with
        /// `.session(.invalidResponseTag(reportedFault:))`).
        case unverifiedFault(UniversalMessage_Domain, UniversalMessage_MessageFault_E)
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

        // From the car feed, which connects and reconnects on its own.

        /// The feed connects to the car by itself (attempt 1 right after the
        /// link dropped or the app came to the front).
        case autoReconnect(attempt: Int)
        case autoReconnectFailed(attempt: Int, TeslaClientError)
        /// Ended because nobody needs the link any more (or the app left the front).
        case autoReconnectCancelled(attempt: Int)
        /// CoreBluetooth's own reconnect did not finish in time; the feed takes over.
        case systemReconnectStalled(graceMs: Int)
    }
}
