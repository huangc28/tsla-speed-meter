import Foundation
import Testing
@testable import TeslaBLE

@Suite("Framing and reassembly")
struct FramingTests {
    @Test("prefixes the big-endian length and splits at the chunk length")
    func framesAndChunks() throws {
        let chunks = try TeslaFraming.chunks(for: Data([0xa1, 0xa2, 0xa3, 0xa4, 0xa5]), chunkLength: 3)
        #expect(chunks == [Data([0x00, 0x05, 0xa1]), Data([0xa2, 0xa3, 0xa4]), Data([0xa5])])
    }

    @Test("a framed length that is a multiple of the chunk length leaves no empty chunk")
    func exactMultiple() throws {
        let chunks = try TeslaFraming.chunks(for: Data(repeating: 7, count: 18), chunkLength: 20)
        #expect(chunks.count == 1)
        #expect(chunks[0].count == 20)
        #expect(chunks[0].prefix(2) == Data([0x00, 0x12]))
    }

    @Test("a 300-byte message has a two-byte length")
    func twoByteLength() throws {
        let chunks = try TeslaFraming.chunks(for: Data(repeating: 1, count: 300), chunkLength: 1021)
        #expect(chunks[0].prefix(2) == Data([0x01, 0x2c]))
    }

    @Test("rejects messages over 1024 bytes and empty chunk lengths")
    func rejectsInvalid() {
        #expect(throws: TeslaFraming.Error.messageTooLong(1025)) {
            try TeslaFraming.chunks(for: Data(count: 1025), chunkLength: 20)
        }
        #expect(throws: TeslaFraming.Error.invalidChunkLength(0)) {
            try TeslaFraming.chunks(for: Data([1]), chunkLength: 0)
        }
    }

    @Test("reassembles two messages split at every chunk length from 1 to 40", arguments: 1...40)
    func roundTrip(chunkLength: Int) throws {
        let first = Data((0..<33).map { UInt8($0) })
        let second = Data((0..<5).map { UInt8(200 + $0) })
        let bytes = try TeslaFraming.chunks(for: first, chunkLength: 1024)[0]
            + TeslaFraming.chunks(for: second, chunkLength: 1024)[0]
        var assembler = FrameAssembler()
        var outputs: [FrameAssembler.Output] = []
        for offset in stride(from: 0, to: bytes.count, by: chunkLength) {
            outputs += assembler.append(Data(bytes[offset..<min(offset + chunkLength, bytes.count)]))
        }
        #expect(outputs == [.message(first), .message(second)])
    }

    @Test("a length prefix split across notifications")
    func splitPrefix() {
        var assembler = FrameAssembler()
        #expect(assembler.append(Data([0x00])).isEmpty)
        #expect(assembler.append(Data([0x02, 0xaa])).isEmpty)
        #expect(assembler.append(Data([0xbb])) == [.message(Data([0xaa, 0xbb]))])
    }

    @Test("one notification completing a message and starting the next")
    func messageAndPartial() {
        var assembler = FrameAssembler()
        #expect(assembler.append(Data([0x00, 0x01, 0x11, 0x00, 0x02, 0x22])) == [.message(Data([0x11]))])
        #expect(assembler.append(Data([0x33])) == [.message(Data([0x22, 0x33]))])
    }

    @Test("a length over 1024 discards the buffer")
    func tooLong() {
        var assembler = FrameAssembler()
        #expect(assembler.append(Data([0x04, 0x01, 0x00])) == [.discarded(.tooLong(length: 1025))])
        #expect(assembler.append(Data([0x00, 0x01, 0x42])) == [.message(Data([0x42]))])
    }

    @Test("a gap of more than one second abandons a partial message")
    func staleGap() {
        var assembler = FrameAssembler()
        let start = ContinuousClock.now
        #expect(assembler.append(Data([0x00, 0x03, 0x01]), at: start).isEmpty)
        #expect(assembler.append(Data([0x02]), at: start + .milliseconds(900)).isEmpty)
        let late = assembler.append(Data([0x00, 0x01, 0x09]), at: start + .milliseconds(2000))
        #expect(late == [.discarded(.stale(bytes: 4)), .message(Data([0x09]))])
    }
}
