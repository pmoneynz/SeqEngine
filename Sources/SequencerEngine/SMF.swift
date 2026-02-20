import Foundation

public enum SMFFileFormat: UInt16, Sendable, Equatable {
    case type0 = 0
    case type1 = 1
}

public enum SMFError: Error, Equatable {
    case sequenceIndexOutOfRange
    case sequenceLimitReached
    case invalidHeader
    case unsupportedFormat(UInt16)
    case unsupportedTimeDivision(UInt16)
    case missingTrackChunk
    case truncated
    case invalidVariableLengthQuantity
    case invalidRunningStatus
    case unsupportedEventStatus(UInt8)
}

private enum SMFCodec {
    static let headerChunkID: [UInt8] = [0x4D, 0x54, 0x68, 0x64] // MThd
    static let trackChunkID: [UInt8] = [0x4D, 0x54, 0x72, 0x6B] // MTrk

    struct ParsedSMF {
        let format: SMFFileFormat
        let ppqn: Int
        let tracks: [[MIDIEvent]]
    }

    static func export(sequence: Sequence, format: SMFFileFormat) throws -> Data {
        guard (1...0x7FFF).contains(sequence.ppqn) else {
            throw SMFError.unsupportedTimeDivision(UInt16(clamping: sequence.ppqn))
        }

        let trackPayloads: [[UInt8]]
        switch format {
        case .type0:
            let merged = mergeTracks(sequence.tracks)
            trackPayloads = [try encodeTrackEvents(merged)]
        case .type1:
            trackPayloads = try sequence.tracks.map { try encodeTrackEvents($0.events) }
        }

        var output: [UInt8] = []
        output += headerChunkID
        appendUInt32(6, to: &output)
        appendUInt16(format.rawValue, to: &output)
        appendUInt16(UInt16(trackPayloads.count), to: &output)
        appendUInt16(UInt16(sequence.ppqn), to: &output)

        for payload in trackPayloads {
            output += trackChunkID
            appendUInt32(UInt32(payload.count), to: &output)
            output += payload
        }

        return Data(output)
    }

    static func `import`(data: Data) throws -> ParsedSMF {
        var reader = ByteReader(data: data)

        let chunk = try reader.readBytes(4)
        guard chunk == headerChunkID else {
            throw SMFError.invalidHeader
        }

        let headerLength = try Int(reader.readUInt32())
        guard headerLength >= 6 else {
            throw SMFError.invalidHeader
        }

        let formatRaw = try reader.readUInt16()
        guard let format = SMFFileFormat(rawValue: formatRaw) else {
            throw SMFError.unsupportedFormat(formatRaw)
        }

        let declaredTrackCount = Int(try reader.readUInt16())
        let division = try reader.readUInt16()
        guard (division & 0x8000) == 0 else {
            throw SMFError.unsupportedTimeDivision(division)
        }

        if headerLength > 6 {
            try reader.skip(headerLength - 6)
        }

        var tracks: [[MIDIEvent]] = []
        tracks.reserveCapacity(declaredTrackCount)

        for _ in 0..<declaredTrackCount {
            let trackID = try reader.readBytes(4)
            guard trackID == trackChunkID else {
                throw SMFError.missingTrackChunk
            }

            let length = Int(try reader.readUInt32())
            let trackBytes = try reader.readBytes(length)
            tracks.append(try parseTrack(trackBytes))
        }

        return ParsedSMF(format: format, ppqn: Int(division), tracks: tracks)
    }

    private static func mergeTracks(_ tracks: [Track]) -> [MIDIEvent] {
        let ranked = tracks.enumerated().flatMap { trackIndex, track in
            track.events.enumerated().map { eventIndex, event in
                (trackIndex: trackIndex, eventIndex: eventIndex, event: event)
            }
        }

        return ranked.sorted { lhs, rhs in
            if lhs.event.tick != rhs.event.tick {
                return lhs.event.tick < rhs.event.tick
            }
            if lhs.trackIndex != rhs.trackIndex {
                return lhs.trackIndex < rhs.trackIndex
            }
            return lhs.eventIndex < rhs.eventIndex
        }.map(\.event)
    }

    private static func encodeTrackEvents(_ events: [MIDIEvent]) throws -> [UInt8] {
        let sorted = events.enumerated().sorted { lhs, rhs in
            if lhs.element.tick != rhs.element.tick {
                return lhs.element.tick < rhs.element.tick
            }
            return lhs.offset < rhs.offset
        }.map(\.element)

        var bytes: [UInt8] = []
        var lastTick = 0

        for event in sorted {
            let tick = max(0, event.tick)
            let delta = max(0, tick - lastTick)
            appendVariableLengthQuantity(delta, to: &bytes)
            try encode(event: event, to: &bytes)
            lastTick = tick
        }

        bytes += [0x00, 0xFF, 0x2F, 0x00]
        return bytes
    }

    private static func encode(event: MIDIEvent, to bytes: inout [UInt8]) throws {
        switch event {
        case let .noteOn(channel, note, velocity, _):
            bytes += [0x90 | (channel & 0x0F), note & 0x7F, velocity & 0x7F]
        case let .noteOff(channel, note, velocity, _):
            bytes += [0x80 | (channel & 0x0F), note & 0x7F, velocity & 0x7F]
        case let .programChange(channel, program, _):
            bytes += [0xC0 | (channel & 0x0F), program & 0x7F]
        case let .pitchBend(channel, value, _):
            let clamped = max(0, min(16_383, value))
            let lsb = UInt8(clamped & 0x7F)
            let msb = UInt8((clamped >> 7) & 0x7F)
            bytes += [0xE0 | (channel & 0x0F), lsb, msb]
        case let .channelPressure(channel, pressure, _):
            bytes += [0xD0 | (channel & 0x0F), pressure & 0x7F]
        case let .polyPressure(channel, note, pressure, _):
            bytes += [0xA0 | (channel & 0x0F), note & 0x7F, pressure & 0x7F]
        case let .controlChange(channel, controller, value, _):
            bytes += [0xB0 | (channel & 0x0F), controller & 0x7F, value & 0x7F]
        case let .sysEx(data, _):
            bytes.append(0xF0)
            appendVariableLengthQuantity(data.count, to: &bytes)
            bytes += data
        }
    }

    private static func parseTrack(_ bytes: [UInt8]) throws -> [MIDIEvent] {
        var reader = ByteReader(data: Data(bytes))
        var events: [MIDIEvent] = []
        var absoluteTick = 0
        var runningStatus: UInt8?

        while !reader.isAtEnd {
            let delta = try reader.readVariableLengthQuantity()
            absoluteTick += delta

            let statusOrData = try reader.readByte()
            if statusOrData < 0x80 {
                guard let status = runningStatus else {
                    throw SMFError.invalidRunningStatus
                }
                let event = try decodeChannelEvent(
                    status: status,
                    firstDataByte: statusOrData,
                    reader: &reader,
                    tick: absoluteTick
                )
                if let event {
                    events.append(event)
                }
                continue
            }

            switch statusOrData {
            case 0x80...0xEF:
                runningStatus = statusOrData
                let event = try decodeChannelEvent(
                    status: statusOrData,
                    firstDataByte: nil,
                    reader: &reader,
                    tick: absoluteTick
                )
                if let event {
                    events.append(event)
                }
            case 0xFF:
                runningStatus = nil
                let metaType = try reader.readByte()
                let length = try reader.readVariableLengthQuantity()
                _ = try reader.readBytes(length)
                if metaType == 0x2F {
                    return events
                }
            case 0xF0, 0xF7:
                runningStatus = nil
                let length = try reader.readVariableLengthQuantity()
                let payload = try reader.readBytes(length)
                events.append(.sysEx(data: payload, tick: absoluteTick))
            default:
                throw SMFError.unsupportedEventStatus(statusOrData)
            }
        }

        return events
    }

    private static func decodeChannelEvent(
        status: UInt8,
        firstDataByte: UInt8?,
        reader: inout ByteReader,
        tick: Int
    ) throws -> MIDIEvent? {
        let kind = status & 0xF0
        let channel = status & 0x0F

        func readDataByte(_ fallback: UInt8?) throws -> UInt8 {
            if let fallback {
                return fallback
            }
            return try reader.readByte()
        }

        switch kind {
        case 0x80:
            let note = try readDataByte(firstDataByte)
            let velocity = try reader.readByte()
            return .noteOff(channel: channel, note: note, velocity: velocity, tick: tick)
        case 0x90:
            let note = try readDataByte(firstDataByte)
            let velocity = try reader.readByte()
            return .noteOn(channel: channel, note: note, velocity: velocity, tick: tick)
        case 0xA0:
            let note = try readDataByte(firstDataByte)
            let pressure = try reader.readByte()
            return .polyPressure(channel: channel, note: note, pressure: pressure, tick: tick)
        case 0xB0:
            let controller = try readDataByte(firstDataByte)
            let value = try reader.readByte()
            return .controlChange(channel: channel, controller: controller, value: value, tick: tick)
        case 0xC0:
            let program = try readDataByte(firstDataByte)
            return .programChange(channel: channel, program: program, tick: tick)
        case 0xD0:
            let pressure = try readDataByte(firstDataByte)
            return .channelPressure(channel: channel, pressure: pressure, tick: tick)
        case 0xE0:
            let lsb = try readDataByte(firstDataByte)
            let msb = try reader.readByte()
            let value = Int(lsb & 0x7F) | (Int(msb & 0x7F) << 7)
            return .pitchBend(channel: channel, value: value, tick: tick)
        default:
            throw SMFError.unsupportedEventStatus(status)
        }
    }

    private static func appendUInt16(_ value: UInt16, to bytes: inout [UInt8]) {
        bytes.append(UInt8((value >> 8) & 0xFF))
        bytes.append(UInt8(value & 0xFF))
    }

    private static func appendUInt32(_ value: UInt32, to bytes: inout [UInt8]) {
        bytes.append(UInt8((value >> 24) & 0xFF))
        bytes.append(UInt8((value >> 16) & 0xFF))
        bytes.append(UInt8((value >> 8) & 0xFF))
        bytes.append(UInt8(value & 0xFF))
    }

    private static func appendVariableLengthQuantity(_ value: Int, to bytes: inout [UInt8]) {
        let clamped = max(0, value)
        var buffer = [UInt8(clamped & 0x7F)]
        var working = clamped >> 7

        while working > 0 {
            buffer.append(UInt8((working & 0x7F) | 0x80))
            working >>= 7
        }

        bytes += buffer.reversed()
    }
}

private struct ByteReader {
    private let data: Data
    private var offset: Int

    init(data: Data) {
        self.data = data
        self.offset = 0
    }

    var isAtEnd: Bool {
        offset >= data.count
    }

    mutating func readByte() throws -> UInt8 {
        guard offset < data.count else {
            throw SMFError.truncated
        }
        defer { offset += 1 }
        return data[offset]
    }

    mutating func readBytes(_ count: Int) throws -> [UInt8] {
        guard count >= 0, offset + count <= data.count else {
            throw SMFError.truncated
        }
        let range = offset..<(offset + count)
        offset += count
        return Array(data[range])
    }

    mutating func readUInt16() throws -> UInt16 {
        let bytes = try readBytes(2)
        return (UInt16(bytes[0]) << 8) | UInt16(bytes[1])
    }

    mutating func readUInt32() throws -> UInt32 {
        let bytes = try readBytes(4)
        return (UInt32(bytes[0]) << 24)
            | (UInt32(bytes[1]) << 16)
            | (UInt32(bytes[2]) << 8)
            | UInt32(bytes[3])
    }

    mutating func skip(_ count: Int) throws {
        _ = try readBytes(count)
    }

    mutating func readVariableLengthQuantity() throws -> Int {
        var value = 0
        for _ in 0..<4 {
            let byte = try readByte()
            value = (value << 7) | Int(byte & 0x7F)
            if (byte & 0x80) == 0 {
                return value
            }
        }
        throw SMFError.invalidVariableLengthQuantity
    }
}

extension SequencerEngine {
    public func exportSMFData(sequenceIndex: Int, format: SMFFileFormat) throws -> Data {
        guard sequenceIndex >= 0, sequenceIndex < project.sequences.count else {
            throw SMFError.sequenceIndexOutOfRange
        }
        return try SMFCodec.export(sequence: project.sequences[sequenceIndex], format: format)
    }

    @discardableResult
    public mutating func importSMFData(_ data: Data, sequenceName: String = "Imported Sequence") throws -> Int {
        let sequence = try Self.importSMFSequence(data, sequenceName: sequenceName)
        var updatedProject = project
        do {
            try updatedProject.addSequence(sequence)
        } catch {
            throw SMFError.sequenceLimitReached
        }
        load(project: updatedProject)
        return updatedProject.sequences.count - 1
    }

    public static func importSMFSequence(_ data: Data, sequenceName: String = "Imported Sequence") throws -> Sequence {
        let parsed = try SMFCodec.import(data: data)
        let importedTracks: [Track]

        switch parsed.format {
        case .type0:
            let merged = parsed.tracks.flatMap { $0 }
            importedTracks = [Track(name: "Track 1", kind: .midi, events: merged)]
        case .type1:
            importedTracks = parsed.tracks.enumerated().map { index, events in
                Track(name: "Track \(index + 1)", kind: .midi, events: events)
            }
        }

        return Sequence(
            name: sequenceName,
            ppqn: parsed.ppqn,
            trackCapacity: max(Sequence.minTrackCapacity, importedTracks.count),
            tracks: importedTracks
        )
    }
}
