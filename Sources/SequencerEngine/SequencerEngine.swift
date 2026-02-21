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
        captureIncomingRecordedEvent(event.withTick(transport.tickPosition))
        return event
    }
}

extension SequencerEngine {
    mutating func captureIncomingRecordedEvent(_ event: MIDIEvent) {
        let sequenceIndex = resolveRecordingSequenceIndex()
        guard sequenceIndex >= 0, sequenceIndex < project.sequences.count else {
            return
        }

        let trackIndex = ensureRecordTrackIndex(sequenceIndex: sequenceIndex)
        guard trackIndex >= 0, trackIndex < project.sequences[sequenceIndex].tracks.count else {
            return
        }

        var events = project.sequences[sequenceIndex].tracks[trackIndex].events
        var insertionIndex = events.count
        while insertionIndex > 0, events[insertionIndex - 1].tick > event.tick {
            insertionIndex -= 1
        }
        events.insert(event, at: insertionIndex)
        project.sequences[sequenceIndex].tracks[trackIndex].events = events
    }

    mutating func resolveRecordingSequenceIndex() -> Int {
        if let state = songPlayback,
           let song = songIfExists(index: state.songIndex),
           state.stepIndex >= 0,
           state.stepIndex < song.steps.count {
            let sequenceIndex = song.steps[state.stepIndex].sequenceIndex
            if sequenceIndex >= 0, sequenceIndex < project.sequences.count {
                return sequenceIndex
            }
        }

        if project.sequences.isEmpty {
            project.sequences.append(Sequence())
        }
        return 0
    }

    mutating func ensureRecordTrackIndex(sequenceIndex: Int) -> Int {
        let sequence = project.sequences[sequenceIndex]
        if let existingMIDITrack = sequence.tracks.firstIndex(where: { $0.kind == .midi }) {
            return existingMIDITrack
        }

        if project.sequences[sequenceIndex].tracks.count < sequence.trackCapacity {
            project.sequences[sequenceIndex].tracks.append(
                Track(
                    name: "Recorded Track",
                    kind: .midi,
                    events: []
                )
            )
            return project.sequences[sequenceIndex].tracks.count - 1
        }

        if project.sequences[sequenceIndex].tracks.isEmpty {
            project.sequences[sequenceIndex].tracks.append(
                Track(
                    name: "Recorded Track",
                    kind: .midi,
                    events: []
                )
            )
            return 0
        }
        return 0
    }
}
