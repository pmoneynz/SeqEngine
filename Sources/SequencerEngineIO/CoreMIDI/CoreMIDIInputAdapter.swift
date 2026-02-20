import Foundation
import SequencerEngine

#if os(macOS)
import CoreMIDI

public enum CoreMIDIInputError: Error, Equatable {
    case clientCreationFailed(OSStatus)
    case inputPortCreationFailed(OSStatus)
    case sourceNotFound(String)
    case connectFailed(OSStatus)
}

public final class CoreMIDIInputAdapter: MIDIInput, @unchecked Sendable {
    private var client: MIDIClientRef = 0
    private var inputPort: MIDIPortRef = 0
    private var sourceRef: MIDIEndpointRef = 0
    private let inputQueue = SPSCRingBuffer<MIDIEvent>(capacity: 4_096)
    private let overflowPolicy: QueueOverflowPolicy
    private var onEvent: ((MIDIEvent) -> Void)?

    public convenience init(
        sourceName: String? = nil,
        overflowPolicy: QueueOverflowPolicy = .dropOldest,
        clientName: String = "SequencerEngineIO.Input"
    ) throws {
        let source = try Self.resolveSource(named: sourceName)
        try self.init(
            sourceEndpoint: source,
            overflowPolicy: overflowPolicy,
            clientName: clientName
        )
    }

    public init(
        sourceEndpoint: MIDIEndpointRef,
        overflowPolicy: QueueOverflowPolicy = .dropOldest,
        clientName: String = "SequencerEngineIO.Input"
    ) throws {
        self.overflowPolicy = overflowPolicy

        var clientRef = MIDIClientRef()
        let clientStatus = MIDIClientCreateWithBlock(clientName as CFString, &clientRef) { _ in }
        guard clientStatus == noErr else {
            throw CoreMIDIInputError.clientCreationFailed(clientStatus)
        }
        self.client = clientRef

        self.sourceRef = sourceEndpoint

        var portRef = MIDIPortRef()
        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let portStatus = MIDIInputPortCreate(
            clientRef,
            "\(clientName).Port" as CFString,
            Self.readProc,
            context,
            &portRef
        )
        guard portStatus == noErr else {
            throw CoreMIDIInputError.inputPortCreationFailed(portStatus)
        }
        self.inputPort = portRef

        let connectStatus = MIDIPortConnectSource(inputPort, sourceRef, nil)
        guard connectStatus == noErr else {
            throw CoreMIDIInputError.connectFailed(connectStatus)
        }
    }

    deinit {
        if inputPort != 0, sourceRef != 0 {
            MIDIPortDisconnectSource(inputPort, sourceRef)
        }
        if inputPort != 0 {
            MIDIPortDispose(inputPort)
        }
        if client != 0 {
            MIDIClientDispose(client)
        }
    }

    public func setOnEvent(_ callback: ((MIDIEvent) -> Void)?) {
        onEvent = callback
    }

    public func pollEvents(_ body: (MIDIEvent) -> Void) {
        while let event = inputQueue.pop() {
            body(event)
        }
    }

    private func handle(packetList: UnsafePointer<MIDIPacketList>) {
        var packet = packetList.pointee.packet
        for _ in 0..<packetList.pointee.numPackets {
            let timestamp = Int(packet.timeStamp)
            let bytes: [UInt8] = withUnsafeBytes(of: packet.data) { raw in
                Array(raw.prefix(Int(packet.length)))
            }
            let decoded = Self.decodeEventBytes(bytes, tick: timestamp)
            for event in decoded {
                _ = inputQueue.push(event, overflowPolicy: overflowPolicy)
                onEvent?(event)
            }
            packet = MIDIPacketNext(&packet).pointee
        }
    }

    private static let readProc: MIDIReadProc = { packetList, readProcRefCon, _ in
        guard let readProcRefCon else {
            return
        }
        let adapter = Unmanaged<CoreMIDIInputAdapter>.fromOpaque(readProcRefCon).takeUnretainedValue()
        adapter.handle(packetList: packetList)
    }

    private static func resolveSource(named name: String?) throws -> MIDIEndpointRef {
        let sourceCount = MIDIGetNumberOfSources()
        guard sourceCount > 0 else {
            throw CoreMIDIInputError.sourceNotFound(name ?? "No MIDI sources available")
        }

        if let name {
            for index in 0..<sourceCount {
                let endpoint = MIDIGetSource(index)
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
            throw CoreMIDIInputError.sourceNotFound(name)
        }

        let endpoint = MIDIGetSource(0)
        guard endpoint != 0 else {
            throw CoreMIDIInputError.sourceNotFound("Source 0")
        }
        return endpoint
    }

}

#else

public enum CoreMIDIInputError: Error, Equatable {
    case unavailablePlatform
}

public final class CoreMIDIInputAdapter: MIDIInput, @unchecked Sendable {
    public init(
        sourceName: String? = nil,
        overflowPolicy: QueueOverflowPolicy = .dropOldest,
        clientName: String = "SequencerEngineIO.Input"
    ) throws {
        throw CoreMIDIInputError.unavailablePlatform
    }

    public func setOnEvent(_ callback: ((MIDIEvent) -> Void)?) {}
    public func pollEvents(_ body: (MIDIEvent) -> Void) {}
}

#endif
