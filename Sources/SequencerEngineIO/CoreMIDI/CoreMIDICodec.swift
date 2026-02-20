import Foundation
import SequencerEngine

extension CoreMIDIOutputAdapter {
    public static func encodeEventBytes(_ event: MIDIEvent) throws -> [UInt8] {
        switch event {
        case let .noteOn(channel, note, velocity, _):
            return [0x90 | (channel & 0x0F), note, velocity]
        case let .noteOff(channel, note, velocity, _):
            return [0x80 | (channel & 0x0F), note, velocity]
        case let .programChange(channel, program, _):
            return [0xC0 | (channel & 0x0F), program]
        case let .pitchBend(channel, value, _):
            let clamped = max(0, min(16_383, value))
            return [
                0xE0 | (channel & 0x0F),
                UInt8(clamped & 0x7F),
                UInt8((clamped >> 7) & 0x7F)
            ]
        case let .channelPressure(channel, pressure, _):
            return [0xD0 | (channel & 0x0F), pressure]
        case let .polyPressure(channel, note, pressure, _):
            return [0xA0 | (channel & 0x0F), note, pressure]
        case let .controlChange(channel, controller, value, _):
            return [0xB0 | (channel & 0x0F), controller, value]
        case let .sysEx(data, _):
            var payload = [UInt8]()
            payload.reserveCapacity(data.count + 2)
            payload.append(0xF0)
            payload.append(contentsOf: data)
            payload.append(0xF7)
            return payload
        }
    }
}

extension CoreMIDIInputAdapter {
    public static func decodeEventBytes(_ bytes: [UInt8], tick: Int) -> [MIDIEvent] {
        var events: [MIDIEvent] = []
        var cursor = 0

        while cursor < bytes.count {
            let status = bytes[cursor]
            if status == 0xF0 {
                let remaining = Array(bytes[cursor...])
                if let terminator = remaining.firstIndex(of: 0xF7) {
                    let payload = Array(remaining.dropFirst().prefix(terminator - 1))
                    events.append(.sysEx(data: payload, tick: tick))
                    cursor += terminator + 1
                    continue
                } else {
                    events.append(.sysEx(data: Array(remaining.dropFirst()), tick: tick))
                    break
                }
            }

            let kind = status & 0xF0
            let channel = status & 0x0F
            switch kind {
            case 0x80, 0x90, 0xA0, 0xB0, 0xE0:
                guard cursor + 2 < bytes.count else {
                    cursor = bytes.count
                    continue
                }
                let data1 = bytes[cursor + 1]
                let data2 = bytes[cursor + 2]
                switch kind {
                case 0x80:
                    events.append(.noteOff(channel: channel, note: data1, velocity: data2, tick: tick))
                case 0x90:
                    events.append(.noteOn(channel: channel, note: data1, velocity: data2, tick: tick))
                case 0xA0:
                    events.append(.polyPressure(channel: channel, note: data1, pressure: data2, tick: tick))
                case 0xB0:
                    events.append(.controlChange(channel: channel, controller: data1, value: data2, tick: tick))
                case 0xE0:
                    let value = Int(data1 & 0x7F) | (Int(data2 & 0x7F) << 7)
                    events.append(.pitchBend(channel: channel, value: value, tick: tick))
                default:
                    break
                }
                cursor += 3
            case 0xC0, 0xD0:
                guard cursor + 1 < bytes.count else {
                    cursor = bytes.count
                    continue
                }
                let data1 = bytes[cursor + 1]
                if kind == 0xC0 {
                    events.append(.programChange(channel: channel, program: data1, tick: tick))
                } else {
                    events.append(.channelPressure(channel: channel, pressure: data1, tick: tick))
                }
                cursor += 2
            default:
                cursor += 1
            }
        }

        return events
    }
}
