import Foundation
import SequencerEngine

#if os(macOS)
import CoreMIDI

public enum CoreMIDIOutputError: Error, Equatable {
    case clientCreationFailed(OSStatus)
    case outputPortCreationFailed(OSStatus)
    case destinationNotFound(String)
    case sendFailed(OSStatus)
    case unsupportedEvent
}

public final class CoreMIDIOutputAdapter: RealtimePacketSink, @unchecked Sendable {
    private let client: MIDIClientRef
    private let outputPort: MIDIPortRef
    private let destinationName: String?
    private let destinationRef: MIDIEndpointRef

    public convenience init(destinationName: String? = nil, clientName: String = "SequencerEngineIO.Output") throws {
        let destination = try Self.resolveDestination(named: destinationName)
        try self.init(destinationEndpoint: destination, destinationName: destinationName, clientName: clientName)
    }

    public init(
        destinationEndpoint: MIDIEndpointRef,
        destinationName: String? = nil,
        clientName: String = "SequencerEngineIO.Output"
    ) throws {
        self.destinationName = destinationName

        var clientRef = MIDIClientRef()
        let clientStatus = MIDIClientCreateWithBlock(clientName as CFString, &clientRef) { _ in }
        guard clientStatus == noErr else {
            throw CoreMIDIOutputError.clientCreationFailed(clientStatus)
        }
        self.client = clientRef

        var portRef = MIDIPortRef()
        let portStatus = MIDIOutputPortCreate(clientRef, "\(clientName).Port" as CFString, &portRef)
        guard portStatus == noErr else {
            throw CoreMIDIOutputError.outputPortCreationFailed(portStatus)
        }
        self.outputPort = portRef

        self.destinationRef = destinationEndpoint
    }

    deinit {
        MIDIPortDispose(outputPort)
        MIDIClientDispose(client)
    }

    public func consume(_ packet: RealtimeScheduledPacket) {
        do {
            try send(packet: packet)
        } catch {
            // Keep callback path non-throwing; failures are observable from explicit send APIs.
        }
    }

    public func send(event: MIDIEvent) throws {
        try send(event: event, hostTimeNanoseconds: DispatchTime.now().uptimeNanoseconds)
    }

    public func send(packet: RealtimeScheduledPacket) throws {
        try send(event: packet.event, hostTimeNanoseconds: packet.hostTimeNanoseconds)
    }

    private func send(event: MIDIEvent, hostTimeNanoseconds: UInt64) throws {
        var packetList = MIDIPacketList()
        let timestamp = MIDITimeStamp(hostTimeNanoseconds)
        let packet = MIDIPacketListInit(&packetList)
        let added = try Self.withEncodedBytes(for: event) { bytes, count in
            MIDIPacketListAdd(
                &packetList,
                MemoryLayout<MIDIPacketList>.size,
                packet,
                timestamp,
                count,
                bytes
            )
        }
        guard added != nil else {
            throw CoreMIDIOutputError.sendFailed(-1)
        }

        let sendStatus = MIDISend(outputPort, destinationRef, &packetList)
        guard sendStatus == noErr else {
            throw CoreMIDIOutputError.sendFailed(sendStatus)
        }
    }

    private static func resolveDestination(named name: String?) throws -> MIDIEndpointRef {
        let destinationCount = MIDIGetNumberOfDestinations()
        guard destinationCount > 0 else {
            throw CoreMIDIOutputError.destinationNotFound(name ?? "No MIDI destinations available")
        }

        if let name {
            for index in 0..<destinationCount {
                let endpoint = MIDIGetDestination(index)
                if endpoint == 0 {
                    continue
                }
                var unmanagedName: Unmanaged<CFString>?
                let status = MIDIObjectGetStringProperty(endpoint, kMIDIPropertyDisplayName, &unmanagedName)
                if status == noErr,
                   let resolved = unmanagedName?.takeRetainedValue() as String?,
                   resolved == name {
                    return endpoint
                }
            }
            throw CoreMIDIOutputError.destinationNotFound(name)
        }

        let endpoint = MIDIGetDestination(0)
        guard endpoint != 0 else {
            throw CoreMIDIOutputError.destinationNotFound("Destination 0")
        }
        return endpoint
    }

    private static func withEncodedBytes(
        for event: MIDIEvent,
        _ body: (_ bytes: UnsafePointer<UInt8>, _ count: Int) -> UnsafeMutablePointer<MIDIPacket>?
    ) throws -> UnsafeMutablePointer<MIDIPacket>? {
        switch event {
        case let .noteOn(channel, note, velocity, _):
            var payload: (UInt8, UInt8, UInt8) = (0x90 | (channel & 0x0F), note, velocity)
            return withUnsafePointer(to: &payload) {
                $0.withMemoryRebound(to: UInt8.self, capacity: 3) { bytes in
                    body(bytes, 3)
                }
            }
        case let .noteOff(channel, note, velocity, _):
            var payload: (UInt8, UInt8, UInt8) = (0x80 | (channel & 0x0F), note, velocity)
            return withUnsafePointer(to: &payload) {
                $0.withMemoryRebound(to: UInt8.self, capacity: 3) { bytes in
                    body(bytes, 3)
                }
            }
        case let .programChange(channel, program, _):
            var payload: (UInt8, UInt8) = (0xC0 | (channel & 0x0F), program)
            return withUnsafePointer(to: &payload) {
                $0.withMemoryRebound(to: UInt8.self, capacity: 2) { bytes in
                    body(bytes, 2)
                }
            }
        case let .pitchBend(channel, value, _):
            let clamped = max(0, min(16_383, value))
            var payload: (UInt8, UInt8, UInt8) = (
                0xE0 | (channel & 0x0F),
                UInt8(clamped & 0x7F),
                UInt8((clamped >> 7) & 0x7F)
            )
            return withUnsafePointer(to: &payload) {
                $0.withMemoryRebound(to: UInt8.self, capacity: 3) { bytes in
                    body(bytes, 3)
                }
            }
        case let .channelPressure(channel, pressure, _):
            var payload: (UInt8, UInt8) = (0xD0 | (channel & 0x0F), pressure)
            return withUnsafePointer(to: &payload) {
                $0.withMemoryRebound(to: UInt8.self, capacity: 2) { bytes in
                    body(bytes, 2)
                }
            }
        case let .polyPressure(channel, note, pressure, _):
            var payload: (UInt8, UInt8, UInt8) = (0xA0 | (channel & 0x0F), note, pressure)
            return withUnsafePointer(to: &payload) {
                $0.withMemoryRebound(to: UInt8.self, capacity: 3) { bytes in
                    body(bytes, 3)
                }
            }
        case let .controlChange(channel, controller, value, _):
            var payload: (UInt8, UInt8, UInt8) = (0xB0 | (channel & 0x0F), controller, value)
            return withUnsafePointer(to: &payload) {
                $0.withMemoryRebound(to: UInt8.self, capacity: 3) { bytes in
                    body(bytes, 3)
                }
            }
        case let .sysEx(data, _):
            var payload = [UInt8]()
            payload.reserveCapacity(data.count + 2)
            payload.append(0xF0)
            payload.append(contentsOf: data)
            payload.append(0xF7)
            return payload.withUnsafeBufferPointer { buffer in
                body(buffer.baseAddress!, buffer.count)
            }
        }
    }
}

#else

public enum CoreMIDIOutputError: Error, Equatable {
    case unavailablePlatform
}

public final class CoreMIDIOutputAdapter: RealtimePacketSink, @unchecked Sendable {
    public init(destinationName: String? = nil, clientName: String = "SequencerEngineIO.Output") throws {
        throw CoreMIDIOutputError.unavailablePlatform
    }

    public func consume(_ packet: RealtimeScheduledPacket) {}
}

#endif
