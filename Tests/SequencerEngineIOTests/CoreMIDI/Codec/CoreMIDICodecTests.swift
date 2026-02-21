import Foundation
import XCTest
@testable import SequencerEngine
@testable import SequencerEngineIO

final class CoreMIDICodecTests: XCTestCase {
    func testEncodeEventBytesForChannelVoiceMessages() throws {
        let encodedNoteOn = try CoreMIDIOutputAdapter.encodeEventBytes(
            .noteOn(channel: 1, note: 64, velocity: 120, tick: 0)
        )
        XCTAssertEqual(encodedNoteOn, [0x91, 64, 120])

        let encodedCC = try CoreMIDIOutputAdapter.encodeEventBytes(
            .controlChange(channel: 0, controller: 74, value: 100, tick: 0)
        )
        XCTAssertEqual(encodedCC, [0xB0, 74, 100])

        let encodedBend = try CoreMIDIOutputAdapter.encodeEventBytes(
            .pitchBend(channel: 2, value: 8192, tick: 0)
        )
        XCTAssertEqual(encodedBend, [0xE2, 0x00, 0x40])
    }

    func testEncodeEventBytesForSysExMessage() throws {
        let bytes = try CoreMIDIOutputAdapter.encodeEventBytes(
            .sysEx(data: [0x7D, 0x01, 0x02], tick: 0)
        )
        XCTAssertEqual(bytes, [0xF0, 0x7D, 0x01, 0x02, 0xF7])
    }

    func testDecodeEventBytesForMixedMessages() {
        let bytes: [UInt8] = [
            0x91, 64, 120,
            0x81, 64, 0,
            0xF0, 0x7D, 0x11, 0x22, 0xF7
        ]
        let decoded = CoreMIDIInputAdapter.decodeEventBytes(bytes, tick: 480)
        XCTAssertEqual(decoded.count, 3)
        XCTAssertEqual(decoded[0], .noteOn(channel: 1, note: 64, velocity: 120, tick: 480))
        XCTAssertEqual(decoded[1], .noteOff(channel: 1, note: 64, velocity: 0, tick: 480))
        XCTAssertEqual(decoded[2], .sysEx(data: [0x7D, 0x11, 0x22], tick: 480))
    }
}
