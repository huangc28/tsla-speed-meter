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
/// `pollVehicleData(_:)` repeatedly. After the link drops, `connect(vin:)`
/// again; after an automatic reconnect (`.reconnected`), the next request
/// re-handshakes on its own. Every request honors Task cancellation.
public actor TeslaVehicleClient {
    public struct Configuration: Sendable {
        /// Scan + connect + service discovery.
        public var connectTimeout: Duration
        /// One session-info round trip (Moblin's handshake timer is 10 s).
        public var handshakeTimeout: Duration
        /// One signed request round trip.
        public var requestTimeout: Duration
        /// How long the owner has to tap the key card, and for the key to
        /// reach Infotainment.
        public var enrollmentTimeout: Duration
        /// How often the vehicle is asked whether the key is on the whitelist yet.
        public var enrollmentPollInterval: Duration
        /// Wait before resending after BUSY, TIMEOUT or INTERNAL
        /// (vehicle-command BLE `RetryInterval`, 1 s).
        public var busyRetryDelay: Duration
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
            busyRetryDelay: Duration = .seconds(1),
            requestLifetimeSeconds: UInt32 = 30,
            captureRawFrames: Bool = false
        ) {
            self.connectTimeout = connectTimeout
            self.handshakeTimeout = handshakeTimeout
            self.requestTimeout = requestTimeout
            self.enrollmentTimeout = enrollmentTimeout
            self.enrollmentPollInterval = enrollmentPollInterval
            self.busyRetryDelay = busyRetryDelay
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

    /// Retriable faults that say "try again shortly", not "your session is
    /// stale": resent on the same session after `busyRetryDelay`.
    static let waitFaults: Set<UniversalMessage_MessageFault_E> = [.rrorBusy, .rrorTimeout, .rrorInternal]

    /// Single consumer. Keeps the newest 1,000 events while nobody reads.
    public nonisolated let events: AsyncStream<TeslaClientEvent>
    public let configuration: Configuration

    /// The VIN of the last successful `connect(vin:)`.
    public private(set) var vin: String?

    private let eventSink: AsyncStream<TeslaClientEvent>.Continuation
    private let link: any BLELink
    private let keyStore: any TeslaKeyStore
    private var clientKey: (any KeyAgreementKey)?
    /// Read once, then served from memory, so a re-handshake works while
    /// the phone is locked and the Keychain is unavailable.
    private var pairedVINCache: String??
    private var pinCache: [String: Data?] = [:]
    /// Set while the link is up; the largest value one write may carry.
    private var maxWriteLength: Int?
    private var assembler = FrameAssembler()
    private var sessions: [UniversalMessage_Domain: VehicleSession] = [:]
    /// The highest counter used per domain and epoch; survives dropped sessions.
    private var counterFloor: [UniversalMessage_Domain: (epoch: Data, counter: UInt32)] = [:]
    /// One handshake in flight per domain, shared by every caller.
    private var handshakes: [UniversalMessage_Domain: Task<VehicleSession, any Error>] = [:]
    private var pending: [Data: PendingRequest] = [:]
    private var pump: Task<Void, Never>?
    /// Serializes writes so chunks of two messages never interleave.
    private var writeTail: Task<Void, Never>?
    private var enrolling = false
    private var whitelistOutcome: WhitelistOutcome?

    private struct PendingRequest {
        let domain: UniversalMessage_Domain
        let kind: TeslaRequestKind
        let uuid: Data
        let timeout: Duration
        /// When the request was queued for writing.
        let queuedAt: ContinuousClock.Instant
        /// When its last chunk was acknowledged; the reply timeout runs from here.
        var writtenAt: ContinuousClock.Instant?
        let continuation: CheckedContinuation<RoutedReply, any Error>
        var timeoutTask: Task<Void, Never>?
        /// Ends the request even if the write never completes.
        var backstopTask: Task<Void, Never>?

        func cancelTimers() {
            timeoutTask?.cancel()
            backstopTask?.cancel()
        }
    }

    /// A reply matched to its request, with the request's timing.
    private struct RoutedReply {
        let message: UniversalMessage_RoutableMessage
        /// Queued until the last chunk was acknowledged (waiting behind other writes).
        let sendWaitMs: Int
        /// Last chunk acknowledged until the reply arrived.
        let roundTripMs: Int
    }

    /// Extra time a request may spend waiting for its write before it fails
    /// regardless (the CoreBluetooth link times out each write after 5 s).
    static let writeAllowance: Duration = .seconds(15)

    private enum WhitelistOutcome {
        case accepted
        case rejected(String)
    }

    private enum ProbeResult {
        case onWhitelist, notOnWhitelist, noAnswer, notYet
    }

    private struct SignedReply {
        let payload: ResponsePayload
        let sendWaitMs: Int
        let roundTripMs: Int
        let retried: Bool
    }

    public init(link: any BLELink, keyStore: any TeslaKeyStore, configuration: Configuration = Configuration()) {
        self.link = link
        self.keyStore = keyStore
        self.configuration = configuration
        (events, eventSink) = AsyncStream.makeStream(of: TeslaClientEvent.self, bufferingPolicy: .bufferingNewest(1000))
    }

    deinit {
        pump?.cancel()
        eventSink.finish()
    }

    // MARK: Public API

    /// Loads (or creates) the client key and reads the paired VIN and pinned
    /// vehicle keys into memory, then scans for the vehicle's VIN-derived
    /// local name and connects. Drops any previous sessions.
    public func connect(vin: String) async throws {
        startPumpIfNeeded()
        _ = try loadClientKey()
        _ = try pairedVIN()
        for domain in [UniversalMessage_Domain.vehicleSecurity, .infotainment] {
            _ = try pinnedKey(vin: vin, domain: domain)
        }
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
            // A link may report a cancelled connect as its own error.
            let clientError = Task.isCancelled ? .cancelled : Self.clientError(error)
            emit(.connectFailed(clientError, durationMs: Self.ms(since: start)))
            throw clientError
        }
    }

    /// Adds this app's key to the vehicle and waits until Infotainment knows
    /// it (vehicle-command pkg/vehicle/security.go `SendAddKeyRequest`:
    /// enrollment is complete once Infotainment session info is no longer
    /// KEY_NOT_ON_WHITELIST). Only then is the paired VIN stored.
    ///
    /// 1. Asks VCSEC for session info. No answer is `.vehicleUnreachable`,
    ///    and no key-card prompt is shown.
    /// 2. If VCSEC does not know the key: sends the add-key request, reports
    ///    `.awaitingKeyCardTap`, and polls VCSEC until it knows the key or
    ///    confirms the whitelist operation.
    /// 3. Reports `.waitingForSync` and polls Infotainment.
    ///
    /// While polling, WAIT, retriable faults, replies without session info
    /// and timeouts all mean "not yet". It ends only on success, a specific
    /// whitelist rejection code (`.enrollmentRejected`), or
    /// `enrollmentTimeout` (`.enrollmentTimedOut`).
    public func enrollKey(onStateChange: @Sendable (EnrollmentState) -> Void = { _ in }) async throws {
        let key = try loadClientKey()
        let vin = try requireVIN()
        func report(_ state: EnrollmentState) {
            emit(.enrollment(state))
            onStateChange(state)
        }

        report(.checking)
        let vcsecKnowsKey: Bool
        switch try await probeUntilAnswer(.vehicleSecurity, within: configuration.handshakeTimeout) {
        case .onWhitelist: vcsecKnowsKey = true
        case .notOnWhitelist, .notYet: vcsecKnowsKey = false
        case .noAnswer: throw TeslaClientError.vehicleUnreachable
        }

        let deadline = ContinuousClock.now + configuration.enrollmentTimeout
        if !vcsecKnowsKey {
            // Set before sending: VCSEC may answer before the write returns.
            enrolling = true
            whitelistOutcome = nil
            defer { enrolling = false }
            try await sendAddKeyRequest(publicKey: key.publicKeyX963)
            report(.awaitingKeyCardTap)

            vcsecPolling: while true {
                guard try await pause(until: deadline) else {
                    return try enrollmentTimedOut(report)
                }
                switch whitelistOutcome {
                case .rejected(let reason)?:
                    report(.rejected(reason))
                    throw TeslaClientError.enrollmentRejected(reason)
                case .accepted?:
                    break vcsecPolling
                case nil:
                    break
                }
                if try await probe(.vehicleSecurity, timeout: remaining(until: deadline)) == .onWhitelist {
                    break vcsecPolling
                }
            }
        }

        var reportedSync = false
        while true {
            if try await probe(.infotainment, timeout: remaining(until: deadline)) == .onWhitelist {
                try recordPaired(vin: vin)
                report(.enrolled)
                return
            }
            if !reportedSync {
                report(.waitingForSync)
                reportedSync = true
            }
            guard try await pause(until: deadline) else {
                return try enrollmentTimedOut(report)
            }
        }
    }

    /// Handshakes with each domain in order (reusing a live session).
    /// Throws `.keyNotPaired` when the key is not on the whitelist.
    public func startSessions(_ domains: [UniversalMessage_Domain] = [.vehicleSecurity, .infotainment]) async throws {
        for domain in domains {
            try await ensureSession(domain)
        }
    }

    /// Signed GetVehicleData for one category on the infotainment domain.
    /// Handshakes first when there is no session. On a retriable fault,
    /// retries once: after `busyRetryDelay` on the same session for
    /// BUSY/TIMEOUT/INTERNAL, else after resyncing (session info in the
    /// fault, or a new handshake).
    public func fetchVehicleData(_ category: VehicleDataCategory) async throws -> VehicleReading {
        try await fetchVehicleDataResponse(category).reading
    }

    /// `fetchVehicleData(_:)` plus how the reply arrived, for logging. The
    /// reading holds only `category`'s fields.
    public func fetchVehicleDataResponse(_ category: VehicleDataCategory) async throws -> VehicleDataResponse {
        let payload: Data
        do {
            payload = try TeslaRequests.getVehicleDataAction(category).serializedData()
        } catch {
            throw Self.clientError(error)
        }
        let reply = try await sendSigned(payload, domain: .infotainment, kind: .getVehicleData)
        do {
            return VehicleDataResponse(
                reading: try VehicleReading(responsePlaintext: reply.payload.plaintext, category: category),
                isEncrypted: reply.payload.isEncrypted,
                roundTripMs: reply.roundTripMs,
                sendWaitMs: reply.sendWaitMs,
                retried: reply.retried
            )
        } catch {
            throw Self.clientError(error)
        }
    }

    /// Fetches each category in turn, one request in flight at a time (as
    /// vehicle-command pkg/vehicle/state.go `GetState` asks for one category
    /// per request). A vehicle fault or a failed reply in one category is
    /// recorded and the next one is still asked for. Cancellation stops the
    /// poll; a link or handshake failure (`endsPoll`) stops it too, and the
    /// categories not asked are marked skipped, so a silent car costs one
    /// handshake timeout per poll, not one per category.
    public func pollVehicleData(_ categories: [VehicleDataCategory] = VehicleDataCategory.allCases) async -> VehicleDataPoll {
        var entries: [VehicleDataPoll.Entry] = []
        for (index, category) in categories.enumerated() {
            do {
                entries.append(.init(category: category, result: .success(try await fetchVehicleDataResponse(category))))
            } catch {
                let failure = Self.clientError(error)
                entries.append(.init(category: category, result: .failure(failure)))
                if failure == .cancelled || Task.isCancelled { break }
                if Self.endsPoll(failure) {
                    return VehicleDataPoll(entries: entries, skipped: Array(categories[(index + 1)...]))
                }
            }
        }
        return VehicleDataPoll(entries: entries)
    }

    /// Failures the next category would hit too: no link, a dropped link, or
    /// a handshake the vehicle did not answer.
    static func endsPoll(_ failure: TeslaClientError) -> Bool {
        switch failure {
        case .notConnected, .disconnected, .link, .timeout(.sessionInfo): true
        default: false
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

    // MARK: Enrollment

    private func sendAddKeyRequest(publicKey: Data) async throws {
        let envelope: Data
        do {
            envelope = try TeslaRequests.addKeyToWhitelist(publicKey: publicKey).serializedData()
        } catch {
            throw Self.clientError(error)
        }
        guard let chunkLength = maxWriteLength else { throw TeslaClientError.notConnected }
        let chunks = try Self.chunks(for: envelope, chunkLength: chunkLength)
        emit(.requestSent(.vehicleSecurity, .addKeyToWhitelist, bytes: envelope.count))
        if configuration.captureRawFrames { emit(.frameSent(envelope)) }
        do {
            try await enqueueWrite(chunks).value
        } catch {
            throw Self.clientError(error)
        }
    }

    /// Probes until the vehicle gives a definite answer, or `within` passes.
    private func probeUntilAnswer(_ domain: UniversalMessage_Domain, within: Duration) async throws -> ProbeResult {
        let deadline = ContinuousClock.now + within
        var sawReply = false
        while true {
            let result = try await probe(domain, timeout: remaining(until: deadline))
            switch result {
            case .onWhitelist, .notOnWhitelist:
                return result
            case .noAnswer:
                if !sawReply { return .noAnswer }
            case .notYet:
                sawReply = true
            }
            guard try await pause(until: deadline) else { return sawReply ? .notYet : .noAnswer }
        }
    }

    /// One session-info attempt with `domain`, classified. Errors that no
    /// retry can fix are thrown.
    private func probe(_ domain: UniversalMessage_Domain, timeout: Duration) async throws -> ProbeResult {
        do {
            try await ensureSession(domain, timeout: timeout)
            return .onWhitelist
        } catch TeslaClientError.keyNotPaired {
            return .notOnWhitelist
        } catch TeslaClientError.timeout {
            return .noAnswer
        } catch let error as TeslaClientError where Self.isFatal(error) {
            throw error
        } catch {
            return .notYet
        }
    }

    /// Sleeps one poll interval, but not past `deadline`. False when the
    /// deadline has passed.
    private func pause(until deadline: ContinuousClock.Instant) async throws -> Bool {
        let left = deadline - .now
        guard left > .zero else { return false }
        try await Self.sleep(for: min(configuration.enrollmentPollInterval, left))
        return deadline - .now > .zero
    }

    private func remaining(until deadline: ContinuousClock.Instant) -> Duration {
        max(.milliseconds(1), min(configuration.handshakeTimeout, deadline - .now))
    }

    private func enrollmentTimedOut(_ report: (EnrollmentState) -> Void) throws {
        emit(.timeout(.vehicleSecurity, .addKeyToWhitelist, durationMs: LogDuration.ms(configuration.enrollmentTimeout)))
        report(.timedOut)
        throw TeslaClientError.enrollmentTimedOut
    }

    private static func isFatal(_ error: TeslaClientError) -> Bool {
        switch error {
        case .vehiclePublicKeyMismatch, .keyStore, .link, .notConnected, .disconnected, .cancelled, .framing:
            true
        default:
            false
        }
    }

    // MARK: Sessions

    /// The live session for `domain`, or one handshake shared by every
    /// caller that needs it at the same time.
    @discardableResult
    private func ensureSession(_ domain: UniversalMessage_Domain, timeout: Duration? = nil) async throws -> VehicleSession {
        while true {
            if let session = sessions[domain] { return session }
            let task: Task<VehicleSession, any Error>
            if let running = handshakes[domain] {
                task = running
            } else {
                let limit = timeout ?? configuration.handshakeTimeout
                task = Task { try await self.handshake(domain, timeout: limit) }
                handshakes[domain] = task
            }
            do {
                let session = try await withTaskCancellationHandler {
                    try await task.value
                } onCancel: {
                    task.cancel()
                }
                handshakeFinished(domain, task)
                return session
            } catch TeslaClientError.cancelled where !Task.isCancelled {
                // Another caller cancelled the shared handshake; start again.
                handshakeFinished(domain, task)
                continue
            } catch {
                handshakeFinished(domain, task)
                throw error
            }
        }
    }

    private func handshakeFinished(_ domain: UniversalMessage_Domain, _ task: Task<VehicleSession, any Error>) {
        if handshakes[domain] == task { handshakes[domain] = nil }
    }

    private func handshake(_ domain: UniversalMessage_Domain, timeout: Duration) async throws -> VehicleSession {
        let vin = try requireVIN()
        let key = try loadClientKey()
        let uuid = Data.random(count: 16)
        let request = TeslaRequests.sessionInfoRequest(domain: domain, clientPublicKey: key.publicKeyX963, uuid: uuid)
        emit(.handshakeStarted(domain))
        let start = ContinuousClock.now
        do {
            let reply = try await send(request, domain: domain, kind: .sessionInfo, timeout: timeout).message
            let session = try adoptSessionInfo(from: reply, requestUUID: uuid, domain: domain, vin: vin, key: key)
            emit(.handshakeSucceeded(domain, durationMs: Self.ms(since: start)))
            return session
        } catch {
            let clientError = Self.clientError(error)
            emit(.handshakeFailed(domain, clientError, durationMs: Self.ms(since: start)))
            throw clientError
        }
    }

    /// Verifies the session info carried by `reply`, checks the pinned
    /// vehicle key, and stores the session without letting its counter go
    /// back. Status KEY_NOT_ON_WHITELIST (or fault UNKNOWN_KEY_ID) is
    /// `.keyNotPaired`, checked before the HMAC because the vehicle cannot
    /// authenticate to an unknown key. An Infotainment session proves the
    /// key is fully enrolled, so it records the paired VIN.
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
        var session: VehicleSession
        do {
            session = try VehicleSession(sessionInfoResponse: reply, requestUUID: requestUUID, vin: vin, clientKey: key)
        } catch {
            throw Self.clientError(error)
        }
        try checkPin(session.vehiclePublicKey, vin: vin, domain: domain)
        if let floor = counterFloor[domain], floor.epoch == session.epoch {
            session.raiseCounter(to: floor.counter)
        }
        sessions[domain] = session
        if domain == .infotainment { try recordPaired(vin: vin) }
        return session
    }

    private func checkPin(_ vehicleKey: Data, vin: String, domain: UniversalMessage_Domain) throws {
        if let pinned = try pinnedKey(vin: vin, domain: domain) {
            guard pinned == vehicleKey else { throw TeslaClientError.vehiclePublicKeyMismatch(domain) }
            return
        }
        do {
            try keyStore.setVehiclePublicKey(vehicleKey, vin: vin, domain: domain)
        } catch {
            throw TeslaClientError.keyStore(String(describing: error))
        }
        pinCache[Self.pinKey(vin: vin, domain: domain)] = .some(vehicleKey)
    }

    private func pinnedKey(vin: String, domain: UniversalMessage_Domain) throws -> Data? {
        let cacheKey = Self.pinKey(vin: vin, domain: domain)
        if let cached = pinCache[cacheKey] { return cached }
        do {
            let stored = try keyStore.vehiclePublicKey(vin: vin, domain: domain)
            pinCache[cacheKey] = .some(stored)
            return stored
        } catch {
            throw TeslaClientError.keyStore(String(describing: error))
        }
    }

    private static func pinKey(vin: String, domain: UniversalMessage_Domain) -> String {
        "\(vin).\(domain.rawValue)"
    }

    private func pairedVIN() throws -> String? {
        if let cached = pairedVINCache { return cached }
        do {
            let stored = try keyStore.pairedVIN()
            pairedVINCache = .some(stored)
            return stored
        } catch {
            throw TeslaClientError.keyStore(String(describing: error))
        }
    }

    private func recordPaired(vin: String) throws {
        guard try pairedVIN() != vin else { return }
        do {
            try keyStore.setPairedVIN(vin)
        } catch {
            throw TeslaClientError.keyStore(String(describing: error))
        }
        pairedVINCache = .some(vin)
    }

    private func sendSigned(_ payload: Data, domain: UniversalMessage_Domain, kind: TeslaRequestKind) async throws -> SignedReply {
        let vin = try requireVIN()
        let key = try loadClientKey()
        var retried = false
        while true {
            try await ensureSession(domain)
            // Read, sign and store with no suspension in between, so two
            // callers never sign with the same counter.
            guard var session = sessions[domain] else { continue }
            let uuid = Data.random(count: 16)
            var request: SignedRequest
            do {
                request = try session.sign(payload: payload, uuid: uuid, lifetimeSeconds: configuration.requestLifetimeSeconds)
            } catch {
                sessions[domain] = nil
                throw Self.clientError(error)
            }
            sessions[domain] = session
            counterFloor[domain] = (session.epoch, session.counter)

            let routed = try await send(request.message, domain: domain, kind: kind, timeout: configuration.requestTimeout)
            let reply = routed.message
            var fault = reply.signedMessageStatus.signedMessageFault
            var isEncrypted = false
            if case .aesGcmResponseData? = reply.signatureData.sigType { isEncrypted = true }
            if isEncrypted || fault == .rrorNone {
                // An encrypted reply is authenticated before its fault is
                // believed; a forged fault fails here as invalidResponseTag.
                do {
                    let opened = try session.openResponse(reply, to: &request)
                    return SignedReply(
                        payload: opened,
                        sendWaitMs: routed.sendWaitMs,
                        roundTripMs: routed.roundTripMs,
                        retried: retried
                    )
                } catch TeslaSessionError.vehicleFault(let authenticated) {
                    fault = authenticated
                } catch TeslaSessionError.invalidResponseTag(let claimed) {
                    // Logged, never acted on: no retry, no resync.
                    if claimed != .rrorNone { emit(.unverifiedFault(domain, claimed)) }
                    throw TeslaClientError.session(.invalidResponseTag(reportedFault: claimed))
                } catch {
                    throw Self.clientError(error)
                }
            }

            emit(.fault(domain, fault))
            if fault == .rrorUnknownKeyID {
                sessions[domain] = nil
                throw TeslaClientError.keyNotPaired
            }
            guard !retried, Self.retriableFaults.contains(fault) else {
                throw TeslaClientError.vehicleFault(fault)
            }
            retried = true
            // vehicle-command dispatcher.go `checkForSessionUpdate`: use
            // session info attached to the fault.
            var resynced = false
            if case .sessionInfo? = reply.payload {
                do {
                    try adoptSessionInfo(from: reply, requestUUID: uuid, domain: domain, vin: vin, key: key)
                    emit(.sessionResynced(domain))
                    resynced = true
                } catch TeslaClientError.vehiclePublicKeyMismatch(let domain) {
                    throw TeslaClientError.vehiclePublicKeyMismatch(domain)
                } catch {}
            }
            if Self.waitFaults.contains(fault) {
                try await Self.sleep(for: configuration.busyRetryDelay)
            } else if !resynced {
                sessions[domain] = nil
            }
        }
    }

    // MARK: Transport

    private func send(
        _ message: UniversalMessage_RoutableMessage,
        domain: UniversalMessage_Domain,
        kind: TeslaRequestKind,
        timeout: Duration
    ) async throws -> RoutedReply {
        if Task.isCancelled { throw TeslaClientError.cancelled }
        guard let chunkLength = maxWriteLength else { throw TeslaClientError.notConnected }
        let bytes: Data
        do {
            bytes = try message.serializedData()
        } catch {
            throw Self.clientError(error)
        }
        let chunks = try Self.chunks(for: bytes, chunkLength: chunkLength)
        let address = message.fromDestination.routingAddress
        let queuedAt = ContinuousClock.now
        emit(.requestSent(domain, kind, bytes: bytes.count))
        if configuration.captureRawFrames { emit(.frameSent(bytes)) }

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                var request = PendingRequest(
                    domain: domain, kind: kind, uuid: message.uuid, timeout: timeout,
                    queuedAt: queuedAt, continuation: continuation
                )
                // The reply timeout starts once the write completes, so a
                // request queued behind others cannot expire unsent.
                request.backstopTask = Task { [weak self] in
                    try? await Task.sleep(for: timeout + Self.writeAllowance)
                    guard !Task.isCancelled else { return }
                    await self?.expire(address)
                }
                pending[address] = request
                let write = enqueueWrite(chunks)
                Task { [weak self] in
                    switch await write.result {
                    case .success: await self?.writeCompleted(address)
                    case .failure(let error): await self?.fail(address, with: Self.clientError(error))
                    }
                }
            }
        } onCancel: {
            Task { [weak self] in await self?.fail(address, with: .cancelled) }
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

    private func writeCompleted(_ address: Data) {
        guard var request = pending[address] else { return }
        request.writtenAt = .now
        let timeout = request.timeout
        request.timeoutTask = Task { [weak self] in
            try? await Task.sleep(for: timeout)
            guard !Task.isCancelled else { return }
            await self?.expire(address)
        }
        pending[address] = request
    }

    private func expire(_ address: Data) {
        guard let request = pending.removeValue(forKey: address) else { return }
        request.cancelTimers()
        emit(.timeout(request.domain, request.kind, durationMs: Self.ms(since: request.writtenAt ?? request.queuedAt)))
        request.continuation.resume(throwing: TeslaClientError.timeout(request.kind))
    }

    private func fail(_ address: Data, with error: TeslaClientError) {
        guard let request = pending.removeValue(forKey: address) else { return }
        request.cancelTimers()
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
            // The same reply wrapped in a RoutableMessage without a routing address.
            if message.fromDestination.domain == .vehicleSecurity,
               case .protobufMessageAsBytes(let inner)? = message.payload,
               handleBareVCSEC(inner) { return }
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
        request.cancelTimers()
        // A reply can beat the write acknowledgement; then the whole wait counts as round trip.
        let sendWaitMs = request.writtenAt.map { LogDuration.ms($0 - request.queuedAt) } ?? 0
        let roundTripMs = Self.ms(since: request.writtenAt ?? request.queuedAt)
        emit(.responseReceived(request.domain, request.kind, bytes: bytes.count, durationMs: roundTripMs, sendWaitMs: sendWaitMs))
        request.continuation.resume(returning: RoutedReply(message: message, sendWaitMs: sendWaitMs, roundTripMs: roundTripMs))
    }

    /// Handles a `FromVCSECMessage` outside a routed reply. Returns false
    /// when `bytes` is not one.
    ///
    /// protocol.md "VCSEC application-layer responses" and vehicle-command
    /// pkg/vehicle/vcsec.go: WAIT means VCSEC waits for the card tap; a
    /// generic ERROR without whitelist information is for legacy clients
    /// and is ignored; a reply with `whitelistOperationStatus` is terminal:
    /// information NONE (or "already on the whitelist") is success, any
    /// other code a rejection.
    private func handleBareVCSEC(_ bytes: Data) -> Bool {
        guard let message = try? VCSEC_FromVCSECMessage(serializedBytes: bytes), let subMessage = message.subMessage else {
            return false
        }
        guard case .commandStatus(let status) = subMessage else {
            emit(.messageDropped(reason: "unsolicited VCSEC message"))
            return true
        }
        let information = status.whitelistOperationStatus.whitelistOperationInformation
        emit(.whitelistStatus(status.operationStatus, information: information))
        guard enrolling,
              status.operationStatus != .operationstatusWait,
              case .whitelistOperationStatus? = status.subMessage
        else { return true }
        switch information {
        case .whitelistoperationInformationNone, .whitelistoperationInformationAttemptingToAddKeyThatIsAlreadyOnTheWhitelist:
            whitelistOutcome = .accepted
        default:
            whitelistOutcome = .rejected(String(describing: information))
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

    private static func sleep(for duration: Duration) async throws {
        do {
            try await Task.sleep(for: duration)
        } catch {
            throw TeslaClientError.cancelled
        }
    }

    private static func chunks(for message: Data, chunkLength: Int) throws -> [Data] {
        do {
            return try TeslaFraming.chunks(for: message, chunkLength: chunkLength)
        } catch {
            throw clientError(error)
        }
    }

    /// Maps any error this package throws to `TeslaClientError`.
    public static func clientError(_ error: any Error) -> TeslaClientError {
        switch error {
        case let error as TeslaClientError: error
        case let error as BLELinkError: .link(error)
        case let error as TeslaSessionError: .session(error)
        case let error as TeslaFraming.Error: .framing(error)
        case let error as VehicleReadingError: .reading(error)
        case is CancellationError: .cancelled
        default: .malformedReply(String(describing: error))
        }
    }

    private static func ms(since start: ContinuousClock.Instant) -> Int {
        LogDuration.ms(ContinuousClock.now - start)
    }
}

enum LogDuration {
    /// Whole milliseconds of a duration.
    static func ms(_ duration: Duration) -> Int {
        let parts = duration.components
        return Int(parts.seconds) * 1000 + Int(parts.attoseconds / 1_000_000_000_000_000)
    }
}
