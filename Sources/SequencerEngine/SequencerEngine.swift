import Foundation

public struct SequencerEngine: Sendable {
    public internal(set) var project: Project
    public internal(set) var transport: TransportState
    public internal(set) var activeEditLoopSequenceIndex: Int?
    var songPlayback: SongPlaybackState?
    var editLoopState: EditLoopState?
    var tapTempoTimestamps: [TimeInterval]
    var schedulingMergeCursors: [Int]

    public init(project: Project = Project()) {
        self.project = project
        self.transport = TransportState()
        self.activeEditLoopSequenceIndex = nil
        self.songPlayback = nil
        self.editLoopState = nil
        self.tapTempoTimestamps = []
        self.schedulingMergeCursors = []
    }

    public mutating func load(project: Project) {
        self.project = project
        activeEditLoopSequenceIndex = nil
        songPlayback = nil
        editLoopState = nil
        tapTempoTimestamps = []
        schedulingMergeCursors.removeAll(keepingCapacity: true)
        updateSongTransportIndicators(nil)
    }

    public mutating func handleIncomingMIDI(_ event: MIDIEvent) -> MIDIEvent? {
        if transport.isWaitingForKey {
            guard event.isKeyPress else {
                return nil
            }
            transport.mode = .recording
            transport.isWaitingForKey = false
            return nil
        }

        if transport.isCountInActive {
            return nil
        }

        guard transport.mode == .recording || transport.mode == .overdubbing else {
            return nil
        }
        return event
    }
}
