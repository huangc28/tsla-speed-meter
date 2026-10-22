import CryptoKit
import Foundation
import Testing
@testable import TeslaBLE

/// A vehicle simulated at the message level: answers session-info requests
/// with an HMAC-tagged SessionInfo, decrypts signed requests with the shared
/// key (so a request the real Verifier would reject is rejected here too),
/// and seals replies the way vehicle-command's Verifier does.
struct FakeVehicle {
    struct Domain {
        var key = SoftwareKeyAgreementKey()
        var epoch = Data.random(count: 16)
        var counter: UInt32 = 0
        var clockTime: UInt32 = 1000
    }

    let vin: String
    var domains: [UniversalMessage_Domain: Domain] = [.vehicleSecurity: Domain(), .infotainment: Domain()]
    var keyOnWhitelist = true
    /// Faults for the next signed requests, in order.
    var scriptedFaults: [(fault: UniversalMessage_MessageFault_E, attachSessionInfo: Bool)] = []
    /// Domains that never answer.
    var silentDomains: Set<UniversalMessage_Domain> = []
    /// Echo a wrong `request_uuid` in replies to signed requests.
    var corruptRequestUUID = false
    /// Bare reply to the add-key request.
    var whitelistReply: VCSEC_FromVCSECMessage?
    /// The response plaintext of a successful GetVehicleData.
    var responsePlaintext = UpstreamResponseVector.responsePlaintext

    private(set) var addKeyRequests: [Data] = []
    private(set) var sessionInfoRequests: [UniversalMessage_Domain: Int] = [:]
    private(set) var signedRequests = 0

    init(vin: String = ProtocolDoc.vin) {
        self.vin = vin
    }

    /// Starts a new epoch, as after a vehicle reboot: requests signed in the
    /// old one get INCORRECT_EPOCH with fresh session info attached.
    mutating func rotateEpoch(_ domain: UniversalMessage_Domain) {
        domains[domain]?.epoch = .random(count: 16)
        domains[domain]?.counter = 0
    }

    /// Whole reply messages for one whole request message.
    mutating func respond(to bytes: Data) throws -> [Data] {
        let request = try UniversalMessage_RoutableMessage(serializedBytes: bytes)
        guard request.hasToDestination else { return try respondToBareVCSEC(bytes) }
        let domain = request.toDestination.domain
        guard !silentDomains.contains(domain), let state = domains[domain] else { return [] }

        if case .sessionInfoRequest(let hello)? = request.payload {
            sessionInfoRequests[domain, default: 0] += 1
            return [try sessionInfoReply(to: request, domain: domain, clientPublicKey: hello.publicKey).serializedData()]
        }

        signedRequests += 1
        let signature = request.signatureData.aesGcmPersonalizedData
        let clientPublicKey = request.signatureData.signerIdentity.publicKey
        let gcm = TeslaGCM(key: try TeslaSessionKey.derive(clientKey: state.key, vehiclePublicKeyX963: clientPublicKey))
        guard keyOnWhitelist else { return [try faultReply(to: request, domain: domain, fault: .rrorUnknownKeyID).serializedData()] }
        guard signature.epoch == state.epoch else {
            return [try faultReply(to: request, domain: domain, fault: .rrorIncorrectEpoch, sessionInfoFor: clientPublicKey).serializedData()]
        }
        let requestMetadata = try SignatureMetadata.request(
            domain: domain, vin: vin, epoch: signature.epoch, expiresAt: signature.expiresAt,
            counter: signature.counter, flags: request.flags
        )
        do {
            _ = try gcm.decrypt(
                nonce: signature.nonce, ciphertext: request.protobufMessageAsBytes,
                tag: signature.tag, metadata: requestMetadata.serialized
            )
        } catch {
            return [try faultReply(to: request, domain: domain, fault: .rrorInvalidSignature).serializedData()]
        }
        domains[domain]?.counter = signature.counter

        if !scriptedFaults.isEmpty {
            let scripted = scriptedFaults.removeFirst()
            let reply = try faultReply(
                to: request, domain: domain, fault: scripted.fault,
                sessionInfoFor: scripted.attachSessionInfo ? clientPublicKey : nil
            )
            return [try reply.serializedData()]
        }

        let requestHash = Data([UInt8(Signatures_SignatureType.aesGcmPersonalized.rawValue)]) + signature.tag
        let responseMetadata = try SignatureMetadata.response(
            domain: domain, vin: vin, counter: 1, flags: request.flags,
            requestHash: requestHash, fault: .rrorNone
        )
        let sealed = try gcm.encrypt(plaintext: responsePlaintext, metadata: responseMetadata.serialized)
        var reply = replyEnvelope(to: request, domain: domain)
        reply.flags = request.flags
        reply.protobufMessageAsBytes = sealed.ciphertext
        reply.signatureData.aesGcmResponseData.nonce = sealed.nonce
        reply.signatureData.aesGcmResponseData.counter = 1
        reply.signatureData.aesGcmResponseData.tag = sealed.tag
        return [try reply.serializedData()]
    }

    private mutating func respondToBareVCSEC(_ bytes: Data) throws -> [Data] {
        let envelope = try VCSEC_ToVCSECMessage(serializedBytes: bytes)
        let unsigned = try VCSEC_UnsignedMessage(serializedBytes: envelope.signedMessage.protobufMessageAsBytes)
        guard case .whitelistOperation(let operation)? = unsigned.subMessage,
              case .addKeyToWhitelistAndAddPermissions(let add)? = operation.subMessage
        else { return [] }
        addKeyRequests.append(add.key.publicKeyRaw)
        return try whitelistReply.map { [try $0.serializedData()] } ?? []
    }

    private func replyEnvelope(to request: UniversalMessage_RoutableMessage, domain: UniversalMessage_Domain) -> UniversalMessage_RoutableMessage {
        var reply = UniversalMessage_RoutableMessage()
        reply.toDestination.routingAddress = request.fromDestination.routingAddress
        reply.fromDestination.domain = domain
        var isHandshake = false
        if case .sessionInfoRequest? = request.payload { isHandshake = true }
        reply.requestUuid = corruptRequestUUID && !isHandshake ? .random(count: 16) : request.uuid
        return reply
    }

    /// Session info, tagged with `HMAC(SESSION_INFO_KEY, metadata || info)`
    /// when the key is on the whitelist; untagged with status
    /// KEY_NOT_ON_WHITELIST otherwise.
    private func attachSessionInfo(
        to reply: inout UniversalMessage_RoutableMessage,
        challenge: Data,
        domain: UniversalMessage_Domain,
        clientPublicKey: Data
    ) throws {
        let state = domains[domain]!
        var info = Signatures_SessionInfo()
        info.counter = state.counter
        info.publicKey = state.key.publicKeyX963
        info.epoch = state.epoch
        info.clockTime = state.clockTime
        info.status = keyOnWhitelist ? .ok : .keyNotOnWhitelist
        let encoded = try info.serializedData()
        reply.sessionInfo = encoded
        guard keyOnWhitelist else { return }
        let sessionKey = try TeslaSessionKey.derive(clientKey: state.key, vehiclePublicKeyX963: clientPublicKey)
        let metadata = try SignatureMetadata.sessionInfo(vin: vin, challenge: challenge)
        reply.signatureData.sessionInfoTag.tag = Data(HMAC<SHA256>.authenticationCode(
            for: metadata.serialized + encoded,
            using: VehicleSession.sessionInfoKey(sessionKey)
        ))
    }

    private func sessionInfoReply(
        to request: UniversalMessage_RoutableMessage,
        domain: UniversalMessage_Domain,
        clientPublicKey: Data
    ) throws -> UniversalMessage_RoutableMessage {
        var reply = replyEnvelope(to: request, domain: domain)
        try attachSessionInfo(to: &reply, challenge: request.uuid, domain: domain, clientPublicKey: clientPublicKey)
        return reply
    }

    private func faultReply(
        to request: UniversalMessage_RoutableMessage,
        domain: UniversalMessage_Domain,
        fault: UniversalMessage_MessageFault_E,
        sessionInfoFor clientPublicKey: Data? = nil
    ) throws -> UniversalMessage_RoutableMessage {
        var reply = replyEnvelope(to: request, domain: domain)
        reply.signedMessageStatus.operationStatus = .rror
        reply.signedMessageStatus.signedMessageFault = fault
        if let clientPublicKey {
            try attachSessionInfo(to: &reply, challenge: request.uuid, domain: domain, clientPublicKey: clientPublicKey)
        }
        return reply
    }
}

/// `BLELink` over a `FakeVehicle`. Reassembles what the client writes with
/// the same `FrameAssembler`, and delivers replies framed and split into
/// `notifyChunkLength`-byte notifications.
actor MockLink: BLELink {
    nonisolated let events: AsyncStream<BLELinkEvent>
    private let sink: AsyncStream<BLELinkEvent>.Continuation

    private(set) var vehicle: FakeVehicle
    var maxWriteLength = 20
    var notifyChunkLength = 7
    var connectError: BLELinkError?
    var writeError: BLELinkError?
    /// Keep replies until `releaseHeld` (to reorder them).
    var holdReplies = false

    private(set) var isConnected = false
    private(set) var writes: [Data] = []
    private(set) var held: [Data] = []
    private(set) var disconnectCalls = 0
    private var outbound = FrameAssembler()

    init(vehicle: FakeVehicle = FakeVehicle()) {
        self.vehicle = vehicle
        (events, sink) = AsyncStream.makeStream(of: BLELinkEvent.self)
    }

    func connect(localName: String, timeout: Duration) async throws -> Int {
        if let connectError { throw connectError }
        guard localName == TeslaBLEConstants.localName(forVIN: vehicle.vin) else { throw BLELinkError.scanTimedOut }
        isConnected = true
        return maxWriteLength
    }

    func write(_ value: Data) async throws {
        if let writeError { throw writeError }
        guard isConnected else { throw BLELinkError.notConnected }
        precondition(value.count <= maxWriteLength, "write longer than the negotiated length")
        writes.append(value)
        for output in outbound.append(value) {
            guard case .message(let message) = output else { continue }
            for reply in try vehicle.respond(to: message) {
                if holdReplies { held.append(reply) } else { deliver(reply) }
            }
        }
    }

    func disconnect() async {
        isConnected = false
        disconnectCalls += 1
    }

    func update(_ body: @Sendable (inout FakeVehicle) -> Void) {
        body(&vehicle)
    }

    func set(holdReplies: Bool) { self.holdReplies = holdReplies }
    func set(writeError: BLELinkError?) { self.writeError = writeError }
    func set(connectError: BLELinkError?) { self.connectError = connectError }

    func releaseHeld(reversed: Bool = false) {
        let replies = reversed ? held.reversed() : held
        held = []
        replies.forEach(deliver)
    }

    /// One raw notification value.
    func inject(_ chunk: Data) {
        sink.yield(.received(chunk))
    }

    func deliver(_ message: Data) {
        for chunk in try! TeslaFraming.chunks(for: message, chunkLength: notifyChunkLength) {
            sink.yield(.received(chunk))
        }
    }

    func drop(reconnecting: Bool) {
        isConnected = false
        outbound.reset()
        sink.yield(.disconnected(reconnecting: reconnecting, reason: "test"))
    }

    func reconnect() {
        isConnected = true
        sink.yield(.reconnected(maxWriteLength: maxWriteLength))
    }
}

/// In-memory `TeslaKeyStore`.
final class InMemoryKeyStore: TeslaKeyStore, @unchecked Sendable {
    private let lock = NSLock()
    private var key: SoftwareKeyAgreementKey?
    private var vin: String?
    private var vehicleKeys: [String: Data] = [:]

    func clientKey() throws -> any KeyAgreementKey {
        lock.withLock {
            if let key { return key }
            let created = SoftwareKeyAgreementKey()
            key = created
            return created
        }
    }

    func pairedVIN() throws -> String? { lock.withLock { vin } }
    func setPairedVIN(_ vin: String) throws { lock.withLock { self.vin = vin } }

    func vehiclePublicKey(vin: String, domain: UniversalMessage_Domain) throws -> Data? {
        lock.withLock { vehicleKeys["\(vin).\(domain.rawValue)"] }
    }

    func setVehiclePublicKey(_ key: Data, vin: String, domain: UniversalMessage_Domain) throws {
        lock.withLock { vehicleKeys["\(vin).\(domain.rawValue)"] = key }
    }
}

extension TeslaVehicleClient {
    /// Ends the event stream and returns everything emitted so far.
    func drainEvents() async -> [TeslaClientEvent.Kind] {
        finishEvents()
        var kinds: [TeslaClientEvent.Kind] = []
        for await event in events { kinds.append(event.kind) }
        return kinds
    }
}

/// Polls `condition` until it holds or about two seconds pass.
func eventually(_ condition: () async -> Bool) async throws {
    for _ in 0..<200 {
        if await condition() { return }
        try await Task.sleep(for: .milliseconds(10))
    }
    Issue.record("condition never became true")
}
