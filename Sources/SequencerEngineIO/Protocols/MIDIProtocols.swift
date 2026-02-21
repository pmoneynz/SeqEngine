import Foundation
import SequencerEngine

public protocol RealtimePacketSink: Sendable {
    func consume(_ packet: RealtimeScheduledPacket)
}

public protocol MIDIOutput: RealtimePacketSink {
    func send(event: MIDIEvent) throws
    func send(packet: RealtimeScheduledPacket) throws
}

public protocol MIDIInput: Sendable {
    func setOnEvent(_ callback: ((MIDIEvent) -> Void)?)
    func pollEvents(_ body: (MIDIEvent) -> Void)
}
