import Foundation

/// Talks to one vehicle over a `BLELink`: framing, request/response routing,
/// per-domain sessions (VCSEC for enrollment, Infotainment for vehicle data),
/// timeouts, fault resync and key enrollment. Every step is reported on
/// `events`.
///
/// Routing follows vehicle-command internal/dispatcher/dispatcher.go
/// `process`: a reply is matched by its `to_destination.routing_address`
/// (a fresh random address per request, as Moblin does), plus its
/// `request_uuid` outside VCSEC, and must come from the request's domain.
/// Session info attached to any reply (a handshake reply, or a fault) is
/// verified with the request's uuid as the HMAC challenge.
///
/// Typical use: `connect(vin:)`, `enrollKey()` once, `startSessions()`, then
/// `fetchVehicleData()` repeatedly. After the link drops, `connect(vin:)`
/// again; after an automatic reconnect (`.reconnected`), the next request
/// re-handshakes on its own.
public actor TeslaVehicleClient {
    public struct Configuration: Sendable {
        /// Scan + connect + service discovery.
        public var connectTimeout: Duration
        /// One session-info round trip (Moblin's handshake timer is 10 s).
        public var handshakeTimeout: Duration
        /// One signed request round trip.
        public var requestTimeout: Duration
        /// How long the owner has to tap the key card.
        public var enrollmentTimeout: Duration
        /// How often VCSEC is asked whether the key is on the whitelist yet.
        public var enrollmentPollInterval: Duration
        /// Lifetime of a signed request on the vehicle clock.
        public var requestLifetimeSeconds: UInt32
        /// Emit `.frameSent` / `.frameReceived` with whole message bytes.
        public var captureRawFrames: Bool

        public init(
            connectTimeout: Duration = .seconds(30),
            handshakeTimeout: Duration = .seconds(10),
            requestTimeout: Duration = .seconds(10),
            enrollmentTimeout: Duration = .seconds(60),
            enrollmentPollInterval: Duration = .seconds(2),
            requestLifetimeSeconds: UInt32 = 30,
            captureRawFrames: Bool = false
        ) {
            self.connectTimeout = connectTimeout
            self.handshakeTimeout = handshakeTimeout
            self.requestTimeout = requestTimeout
            self.enrollmentTimeout = enrollmentTimeout
            self.enrollmentPollInterval = enrollmentPollInterval
            self.requestLifetimeSeconds = requestLifetimeSeconds
            self.captureRawFrames = captureRawFrames
        }
    }

    /// Faults worth one resync and retry (vehicle-command
    /// pkg/protocol/error.go `retriableErrors`).
    static let retriableFaults: Set<UniversalMessage_MessageFault_E> = [
        .rrorBusy, .rrorTimeout, .rrorInvalidSignature, .rrorInvalidTokenOrCounter,
        .rrorInternal, .rrorIncorrectEpoch, .rrorTimeExpired, .rrorTimeToLiveTooLong,
    ]

    public nonisolated let events: AsyncStream<TeslaClientEvent>
    public let configuration: Configuration

    /// The VIN of the last successful `connect(vin:)`.
    public private(set) var vin: String?

    private let eventSink: AsyncStream<TeslaClientEvent>.Continuation
    private let link: any BLELink
    private let keyStore: any TeslaKeyStore
    private var clientKey: (any KeyAgreementKey)?
    /// Set while the link is up; the largest value one write may carry.
    private var maxWriteLength: Int?
    private var assembler = FrameAssembler()
    private var sessions: [UniversalMessage_Domain: VehicleSession] = [:]
    private var pending: [Data: PendingRequest] = [:]
    private var pump: Task<Void, Never>?
    /// Serializes writes so chunks of two messages never interleave.
    private var writeTail: Task<Void, Never>?
    private var enrolling = false
    private var whitelistRejection: String?

    private struct PendingRequest {
        let domain: UniversalMessage_Domain
        let kind: TeslaRequestKind
        let uuid: Data
        let sentAt: ContinuousClock.Instant
        let continuation: CheckedContinuation<UniversalMessage_RoutableMessage, any Error>
        var timeoutTask: Task<Void, Never>?
    }

    public init(link: any BLELink, keyStore: any TeslaKeyStore, configuration: Configuration = Configuration()) {
        self.link = link
        self.keyStore = keyStore
        self.configuration = configuration
        (events, eventSink) = AsyncStream.makeStream(of: TeslaClientEvent.self)
    }

    deinit {
        pump?.cancel()
        eventSink.finish()
    }

    // MARK: Public API

    /// Loads (or creates) the client key, then scans for the vehicle's
    /// VIN-derived local name and connects. Drops any previous sessions.
    public func connect(vin: String) async throws {
        startPumpIfNeeded()
        _ = try loadClientKey()
        let localName = TeslaBLEConstants.localName(forVIN: vin)
        emit(.connecting(localName: localName))
        let start = ContinuousClock.now
        do {
            let length = try await link.connect(localName: localName, timeout: configuration.connectTimeout)
            linkDropped()
            self.vin = vin
            maxWriteLength = length
            emit(.connected(localName: localName, maxWriteLength: length, durationMs: Self.ms(since: start)))
        } catch {
            let clientError = Self.clientError(error)
            emit(.connectFailed(clientError, durationMs: Self.ms(since: start)))
            throw clientError
        }
    }

    /// Adds this app's key to the vehicle whitelist. Returns at once when the
    /// key is already enrolled. Otherwise sends the add-key request, reports
    /// `.awaitingKeyCardTap`, and polls VCSEC session info until its status
    /// is no longer KEY_NOT_ON_WHITELIST. Stores the paired VIN on success.
    /// Throws `.enrollmentTimedOut` or `.enrollmentRejected`.
    public func enrollKey(onStateChange: @Sendable (EnrollmentState) -> Void = { _ in }) async throws {
        let key = try loadClientKey()
        _ = try requireVIN()
        func report(_ state: EnrollmentState) {
            emit(.enrollment(state))
            onStateChange(state)
        }

        report(.checking)
        if try await isEnrolled(handshakeTimeout: configuration.handshakeTimeout) {
            report(.enrolled)
            return
        }

        let envelope: Data
        do {
            envelope = try TeslaRequests.addKeyToWhitelist(publicKey: key.publicKeyX963).serializedData()
        } catch {
            throw Self.clientError(error)
        }
        guard let chunkLength = maxWriteLength else { throw TeslaClientError.notConnected }
        let chunks = try Self.chunks(for: envelope, chunkLength: chunkLength)
        enrolling = true
        whitelistRejection = nil
        defer { enrolling = false }
        emit(.requestSent(.vehicleSecurity, .addKeyToWhitelist, bytes: envelope.count))
        if configuration.captureRawFrames { emit(.frameSent(envelope)) }
        do {
            try await enqueueWrite(chunks).value
        } catch {
            throw Self.clientError(error)
        }
        report(.awaitingKeyCardTap)

        let deadline = ContinuousClock.now + configuration.enrollmentTimeout
        while true {
            let untilDeadline = deadline - .now
            guard untilDeadline > .zero else { break }
            try await Task.sleep(for: min(configuration.enrollmentPollInterval, untilDeadline))
            if let reason = whitelistRejection {
                report(.rejected(reason))
                throw TeslaClientError.enrollmentRejected(reason)
            }
            let remaining = deadline - .now
            guard remaining > .zero else { break }
            if try await isEnrolled(handshakeTimeout: min(configuration.handshakeTimeout, remaining)) {
                report(.enrolled)
                return
            }
        }
        emit(.timeout(.vehicleSecurity, .addKeyToWhitelist, durationMs: Self.ms(since: deadline - configuration.enrollmentTimeout)))
        report(.timedOut)
        throw TeslaClientError.enrollmentTimedOut
    }

    /// Handshakes with each domain in order. Throws `.keyNotPaired` when the
    /// key is not on the whitelist.
    public func startSessions(_ domains: [UniversalMessage_Domain] = [.vehicleSecurity, .infotainment]) async throws {
        for domain in domains {
            try await handshake(domain, timeout: configuration.handshakeTimeout)
        }
    }

    /// Signed GetVehicleData (drive, charge, tire pressure) on the
    /// infotainment domain. Handshakes first when there is no session; on a
    /// retriable fault, resyncs once (session info in the fault, else a new
    /// handshake) and retries once.
    public func fetchVehicleData() async throws -> VehicleReading {
        let payload: Data
        do {
            payload = try TeslaRequests.getVehicleDataAction().serializedData()
        } catch {
            throw Self.clientError(error)
        }
        let plaintext = try await sendSigned(payload, domain: .infotainment, kind: .getVehicleData)
        do {
            return try VehicleReading(responsePlaintext: plaintext)
        } catch {
            throw Self.clientError(error)
        }
    }

    /// Whether the link is up (connected, or back after a reconnect).
    public var isConnected: Bool {
        maxWriteLength != nil
    }

    /// Whether a session with `domain` is established.
    public func hasSession(_ domain: UniversalMessage_Domain) -> Bool {
        sessions[domain] != nil
    }

    /// Disconnects; pending requests fail with `.disconnected`.
    public func disconnect() async {
        await link.disconnect()
        maxWriteLength = nil
        linkDropped()
        emit(.disconnected(reconnecting: false, reason: "requested"))
    }

    // MARK: Sessions

    @discardableResult
    private func handshake(_ domain: UniversalMessage_Domain, timeout: Duration) async throws -> VehicleSession {
        let vin = try requireVIN()
        let key = try loadClientKey()
        let uuid = Data.random(count: 16)
        let request = TeslaRequests.sessionInfoRequest(domain: domain, clientPublicKey: key.publicKeyX963, uuid: uuid)
        emit(.handshakeStarted(domain))
        let start = ContinuousClock.now
        do {
            let reply = try await send(request, domain: domain, kind: .sessionInfo, timeout: timeout)
            let session = try adoptSessionInfo(from: reply, requestUUID: uuid, domain: domain, vin: vin, key: key)
            emit(.handshakeSucceeded(domain, durationMs: Self.ms(since: start)))
            return session
        } catch {
            let clientError = Self.clientError(error)
            emit(.handshakeFailed(domain, clientError, durationMs: Self.ms(since: start)))
            throw clientError
        }
    }

    /// True when a VCSEC handshake succeeds; false when the key is not on
    /// the whitelist yet or VCSEC did not answer in time.
    private func isEnrolled(handshakeTimeout: Duration) async throws -> Bool {
        do {
            try await handshake(.vehicleSecurity, timeout: handshakeTimeout)
            return true
        } catch TeslaClientError.keyNotPaired {
            return false
        } catch TeslaClientError.timeout {
            return false
        }
    }

    /// Verifies the session info carried by `reply`, checks the pinned
    /// vehicle key, and stores the session. Status KEY_NOT_ON_WHITELIST (or
    /// fault UNKNOWN_KEY_ID) is `.keyNotPaired`, checked before the HMAC
    /// because the vehicle cannot authenticate to an unknown key.
    @discardableResult
    private func adoptSessionInfo(
        from reply: UniversalMessage_RoutableMessage,
        requestUUID: Data,
        domain: UniversalMessage_Domain,
        vin: String,
        key: any KeyAgreementKey
    ) throws -> VehicleSession {
        let fault = reply.signedMessageStatus.signedMessageFault
        if fault == .rrorUnknownKeyID { throw TeslaClientError.keyNotPaired }
        guard case .sessionInfo(let encodedInfo)? = reply.payload else {
            if fault != .rrorNone { throw TeslaClientError.vehicleFault(fault) }
            throw TeslaClientError.malformedReply("reply carries no session info")
        }
        let info: Signatures_SessionInfo
        do {
            info = try Signatures_SessionInfo(serializedBytes: encodedInfo)
        } catch {
            throw TeslaClientError.malformedReply("session info does not decode")
        }
        if info.status == .keyNotOnWhitelist { throw TeslaClientError.keyNotPaired }
        let session: VehicleSession
        do {
            session = try VehicleSession(sessionInfoResponse: reply, requestUUID: requestUUID, vin: vin, clientKey: key)
        } catch {
            throw Self.clientError(error)
        }
        try checkPin(session.vehiclePublicKey, vin: vin, domain: domain)
        sessions[domain] = session
        try recordPaired(vin: vin)
        return session
    }

    private func checkPin(_ vehicleKey: Data, vin: String, domain: UniversalMessage_Domain) throws {
        do {
            if let pinned = try keyStore.vehiclePublicKey(vin: vin, domain: domain) {
                guard pinned == vehicleKey else { throw TeslaClientError.vehiclePublicKeyMismatch(domain) }
            } else {
                try keyStore.setVehiclePublicKey(vehicleKey, vin: vin, domain: domain)
            }
        } catch let error as TeslaClientError {
            throw error
        } catch {
            throw TeslaClientError.keyStore(String(describing: error))
        }
    }

    private func recordPaired(vin: String) throws {
        do {
            if try keyStore.pairedVIN() != vin { try keyStore.setPairedVIN(vin) }
        } catch {
            throw TeslaClientError.keyStore(String(describing: error))
        }
    }

    private func sendSigned(_ payload: Data, domain: UniversalMessage_Domain, kind: TeslaRequestKind) async throws -> Data {
        let vin = try requireVIN()
        let key = try loadClientKey()
        var resynced = false
        while true {
            var session: VehicleSession
            if let existing = sessions[domain] {
                session = existing
            } else {
                session = try await handshake(domain, timeout: configuration.handshakeTimeout)
            }
            let uuid = Data.random(count: 16)
            var request: SignedRequest
            do {
                request = try session.sign(payload: payload, uuid: uuid, lifetimeSeconds: configuration.requestLifetimeSeconds)
            } catch {
                sessions[domain] = nil
                throw Self.clientError(error)
            }
            sessions[domain] = session

            let reply = try await send(request.message, domain: domain, kind: kind, timeout: configuration.requestTimeout)
            let fault = reply.signedMessageStatus.signedMessageFault
            if fault != .rrorNone {
                emit(.fault(domain, fault))
                if fault == .rrorUnknownKeyID {
                    sessions[domain] = nil
                    throw TeslaClientError.keyNotPaired
                }
                guard !resynced, Self.retriableFaults.contains(fault) else {
                    throw TeslaClientError.vehicleFault(fault)
                }
                resynced = true
                // vehicle-command dispatcher.go `checkForSessionUpdate`: the
                // fault reply may carry fresh session info; otherwise
                // re-handshake on the next pass.
                do {
                    try adoptSessionInfo(from: reply, requestUUID: uuid, domain: domain, vin: vin, key: key)
                    emit(.sessionResynced(domain))
                } catch TeslaClientError.vehiclePublicKeyMismatch(let domain) {
                    throw TeslaClientError.vehiclePublicKeyMismatch(domain)
                } catch {
                    sessions[domain] = nil
                }
                continue
            }
            do {
                return try session.openResponse(reply, to: &request).plaintext
            } catch {
                throw Self.clientError(error)
            }
        }
    }

    // MARK: Transport

    private func send(
        _ message: UniversalMessage_RoutableMessage,
        domain: UniversalMessage_Domain,
        kind: TeslaRequestKind,
        timeout: Duration
    ) async throws -> UniversalMessage_RoutableMessage {
        guard let chunkLength = maxWriteLength else { throw TeslaClientError.notConnected }
        let bytes: Data
        do {
            bytes = try message.serializedData()
        } catch {
            throw Self.clientError(error)
        }
        let chunks = try Self.chunks(for: bytes, chunkLength: chunkLength)
        let address = message.fromDestination.routingAddress
        let sentAt = ContinuousClock.now
        emit(.requestSent(domain, kind, bytes: bytes.count))
        if configuration.captureRawFrames { emit(.frameSent(bytes)) }

        return try await withCheckedThrowingContinuation { continuation in
            var request = PendingRequest(domain: domain, kind: kind, uuid: message.uuid, sentAt: sentAt, continuation: continuation)
            request.timeoutTask = Task { [weak self] in
                try? await Task.sleep(for: timeout)
                guard !Task.isCancelled else { return }
                await self?.expire(address)
            }
            pending[address] = request
            let write = enqueueWrite(chunks)
            Task { [weak self] in
                if case .failure(let error) = await write.result {
                    await self?.fail(address, with: Self.clientError(error))
                }
            }
        }
    }

    private func enqueueWrite(_ chunks: [Data]) -> Task<Void, any Error> {
        let previous = writeTail
        let link = link
        let write = Task {
            await previous?.value
            for chunk in chunks {
                try await link.write(chunk)
            }
        }
        writeTail = Task { _ = await write.result }
        return write
    }

    private func expire(_ address: Data) {
        guard let request = pending.removeValue(forKey: address) else { return }
        emit(.timeout(request.domain, request.kind, durationMs: Self.ms(since: request.sentAt)))
        request.continuation.resume(throwing: TeslaClientError.timeout(request.kind))
    }

    private func fail(_ address: Data, with error: TeslaClientError) {
        guard let request = pending.removeValue(forKey: address) else { return }
        request.timeoutTask?.cancel()
        request.continuation.resume(throwing: error)
    }

    /// Forgets sessions and partial frames; pending requests fail.
    private func linkDropped() {
        sessions = [:]
        assembler.reset()
        for address in Array(pending.keys) {
            fail(address, with: .disconnected)
        }
    }

    private func startPumpIfNeeded() {
        guard pump == nil else { return }
        let linkEvents = link.events
        pump = Task { [weak self] in
            for await event in linkEvents {
                guard let self else { return }
                await self.handle(event)
            }
        }
    }

    private func handle(_ event: BLELinkEvent) {
        switch event {
        case .received(let chunk):
            for output in assembler.append(chunk) {
                switch output {
                case .message(let bytes):
                    receive(bytes)
                case .discarded(let reason):
                    emit(.messageDropped(reason: "frame discarded: \(reason)"))
                }
            }
        case .disconnected(let reconnecting, let reason):
            maxWriteLength = nil
            linkDropped()
            emit(.disconnected(reconnecting: reconnecting, reason: reason))
        case .reconnected(let length):
            maxWriteLength = length
            emit(.reconnected(maxWriteLength: length))
        }
    }

    private func receive(_ bytes: Data) {
        if configuration.captureRawFrames { emit(.frameReceived(bytes)) }
        guard let message = try? UniversalMessage_RoutableMessage(serializedBytes: bytes) else {
            if !handleBareVCSEC(bytes) { emit(.messageDropped(reason: "unparseable message")) }
            return
        }
        guard case .routingAddress(let address)? = message.toDestination.subDestination, address.count == 16 else {
            // A bare FromVCSECMessage (reply to the add-key request) parses as a
            // RoutableMessage with no destinations: its fields are reserved there.
            if !message.hasToDestination, !message.hasFromDestination, handleBareVCSEC(bytes) { return }
            emit(.messageDropped(reason: "no routing address"))
            return
        }
        guard let request = pending[address] else {
            emit(.messageDropped(reason: "no pending request for routing address"))
            return
        }
        guard message.fromDestination.domain == request.domain else {
            emit(.messageDropped(reason: "reply from another domain"))
            return
        }
        // dispatcher.go `process`: VCSEC replies are matched on address only.
        if request.domain != .vehicleSecurity, message.requestUuid != request.uuid {
            emit(.messageDropped(reason: "request uuid mismatch"))
            return
        }
        pending[address] = nil
        request.timeoutTask?.cancel()
        emit(.responseReceived(request.domain, request.kind, bytes: bytes.count, durationMs: Self.ms(since: request.sentAt)))
        request.continuation.resume(returning: message)
    }

    /// Handles a bare `FromVCSECMessage`. Returns false when `bytes` is not one.
    private func handleBareVCSEC(_ bytes: Data) -> Bool {
        guard let message = try? VCSEC_FromVCSECMessage(serializedBytes: bytes), let subMessage = message.subMessage else {
            return false
        }
        guard case .commandStatus(let status) = subMessage else {
            emit(.messageDropped(reason: "unsolicited VCSEC message"))
            return true
        }
        let whitelist = status.whitelistOperationStatus
        let info = whitelist.whitelistOperationInformation
        emit(.whitelistStatus(status.operationStatus, information: info))
        let failed = status.operationStatus == .rror || whitelist.operationStatus == .rror
        if enrolling, failed, info != .whitelistoperationInformationAttemptingToAddKeyThatIsAlreadyOnTheWhitelist {
            whitelistRejection = String(describing: info)
        }
        return true
    }

    // MARK: Helpers

    private func loadClientKey() throws -> any KeyAgreementKey {
        if let clientKey { return clientKey }
        do {
            let key = try keyStore.clientKey()
            clientKey = key
            return key
        } catch {
            throw TeslaClientError.keyStore(String(describing: error))
        }
    }

    private func requireVIN() throws -> String {
        guard let vin, maxWriteLength != nil else { throw TeslaClientError.notConnected }
        return vin
    }

    private func emit(_ kind: TeslaClientEvent.Kind) {
        eventSink.yield(TeslaClientEvent(kind: kind))
    }

    /// Ends `events` (tests drain the buffered events after this).
    func finishEvents() {
        eventSink.finish()
    }

    private static func chunks(for message: Data, chunkLength: Int) throws -> [Data] {
        do {
            return try TeslaFraming.chunks(for: message, chunkLength: chunkLength)
        } catch {
            throw clientError(error)
        }
    }

    static func clientError(_ error: any Error) -> TeslaClientError {
        switch error {
        case let error as TeslaClientError: error
        case let error as BLELinkError: .link(error)
        case let error as TeslaSessionError: .session(error)
        case let error as TeslaFraming.Error: .framing(error)
        case let error as VehicleReadingError: .reading(error)
        default: .malformedReply(String(describing: error))
        }
    }

    private static func ms(since start: ContinuousClock.Instant) -> Int {
        let elapsed = (ContinuousClock.now - start).components
        return Int(elapsed.seconds) * 1000 + Int(elapsed.attoseconds / 1_000_000_000_000_000)
    }
}
