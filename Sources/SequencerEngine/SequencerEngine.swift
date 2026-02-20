import Foundation

public struct SequencerEngine: Sendable {
    public struct ScheduledEvent: Sendable, Equatable {
        public var sequenceIndex: Int
        public var trackIndex: Int
        public var eventIndex: Int
        public var event: MIDIEvent

        public init(sequenceIndex: Int, trackIndex: Int, eventIndex: Int, event: MIDIEvent) {
            self.sequenceIndex = sequenceIndex
            self.trackIndex = trackIndex
            self.eventIndex = eventIndex
            self.event = event
        }
    }

    private struct SongPlaybackState: Sendable, Equatable {
        var songIndex: Int
        var stepIndex: Int
        var repeatIndex: Int
        var tickInRepeat: Int
    }

    private struct EditLoopState: Sendable, Equatable {
        var sequenceIndex: Int
        var startBar: Int
        var barCount: Int
        var sequenceSnapshot: Sequence
    }

    public enum PunchMode: Sendable, Equatable {
        case record
        case overdub
    }

    public enum SongConversionError: Error, Equatable {
        case songIndexOutOfRange
        case sequenceIndexOutOfRange(stepIndex: Int, sequenceIndex: Int)
        case noMaterializedSteps
    }

    public enum StepEditError: Error, Equatable {
        case sequenceIndexOutOfRange
        case trackIndexOutOfRange
        case eventIndexOutOfRange
    }

    public enum EditOperationError: Error, Equatable {
        case sequenceIndexOutOfRange
        case trackIndexOutOfRange
        case invalidBar
        case invalidBarCount
        case invalidTicksPerBar
        case invalidTickLength
    }

    public enum EraseOperationError: Error, Equatable {
        case sequenceIndexOutOfRange
        case trackIndexOutOfRange
        case invalidTickLength
        case transportMustBeStopped
        case transportMustBeOverdubbing
    }

    public enum EditLoopError: Error, Equatable {
        case sequenceIndexOutOfRange
        case invalidStartBar
        case invalidBarCount
        case alreadyActive
        case notActive
    }

    public struct TransportState: Sendable, Equatable {
        public enum Mode: Sendable, Equatable {
            case stopped
            case playing
            case recording
            case overdubbing
        }

        public var mode: Mode
        public var tickPosition: Int
        public var isRecordReady: Bool
        public var isWaitingForKey: Bool
        public var countInRemainingTicks: Int
        public var activeSongIndex: Int?
        public var activeSongStepIndex: Int?
        public var activeSongRepeat: Int?

        public var isCountInActive: Bool {
            countInRemainingTicks > 0
        }

        public var isRunning: Bool {
            mode != .stopped
        }

        public init(
            mode: Mode = .stopped,
            tickPosition: Int = 0,
            isRecordReady: Bool = false,
            isWaitingForKey: Bool = false,
            countInRemainingTicks: Int = 0,
            activeSongIndex: Int? = nil,
            activeSongStepIndex: Int? = nil,
            activeSongRepeat: Int? = nil
        ) {
            self.mode = mode
            self.tickPosition = max(0, tickPosition)
            self.isRecordReady = isRecordReady
            self.isWaitingForKey = isWaitingForKey
            self.countInRemainingTicks = max(0, countInRemainingTicks)
            self.activeSongIndex = activeSongIndex
            self.activeSongStepIndex = activeSongStepIndex
            self.activeSongRepeat = activeSongRepeat
        }
    }

    public private(set) var project: Project
    public private(set) var transport: TransportState
    public private(set) var activeEditLoopSequenceIndex: Int?
    private var songPlayback: SongPlaybackState?
    private var editLoopState: EditLoopState?
    private var tapTempoTimestamps: [TimeInterval]
    private var schedulingMergeCursors: [Int]

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

    public mutating func setTempoSource(_ source: TempoSource) {
        project.setTempoSource(source)
    }

    public mutating func setMasterTempoBPM(_ bpm: Double) {
        project.setMasterTempoBPM(bpm)
    }

    @discardableResult
    public mutating func setSequenceTempoBPM(_ bpm: Double, at sequenceIndex: Int) -> Bool {
        guard sequenceIndex >= 0, sequenceIndex < project.sequences.count else {
            return false
        }
        project.sequences[sequenceIndex].setTempoBPM(bpm)
        return true
    }

    @discardableResult
    public mutating func insertTempoChange(
        sequenceIndex: Int,
        tick: Int,
        bpm: Double,
        isEnabled: Bool = true
    ) -> Sequence.TempoChange? {
        guard sequenceIndex >= 0, sequenceIndex < project.sequences.count else {
            return nil
        }
        return project.sequences[sequenceIndex].insertTempoChange(
            atTick: tick,
            bpm: bpm,
            isEnabled: isEnabled
        )
    }

    public func listTempoChanges(sequenceIndex: Int, includeDisabled: Bool = true) -> [Sequence.TempoChange] {
        guard sequenceIndex >= 0, sequenceIndex < project.sequences.count else {
            return []
        }
        return project.sequences[sequenceIndex].listedTempoChanges(includeDisabled: includeDisabled)
    }

    @discardableResult
    public mutating func setTempoChangeEnabled(
        sequenceIndex: Int,
        tempoChangeID: UUID,
        _ isEnabled: Bool
    ) -> Bool {
        guard sequenceIndex >= 0, sequenceIndex < project.sequences.count else {
            return false
        }
        return project.sequences[sequenceIndex].setTempoChangeEnabled(id: tempoChangeID, isEnabled)
    }

    @discardableResult
    public mutating func deleteTempoChange(sequenceIndex: Int, tempoChangeID: UUID) -> Bool {
        guard sequenceIndex >= 0, sequenceIndex < project.sequences.count else {
            return false
        }
        return project.sequences[sequenceIndex].deleteTempoChange(id: tempoChangeID)
    }

    public func effectiveTempoBPM(sequenceIndex: Int? = nil, tick: Int? = nil) -> Double {
        if project.tempoSource == .master {
            return project.masterTempoBPM
        }

        let resolvedTick = max(0, tick ?? transport.tickPosition)

        if let explicitSequenceIndex = sequenceIndex,
           explicitSequenceIndex >= 0,
           explicitSequenceIndex < project.sequences.count {
            return project.sequences[explicitSequenceIndex].tempoBPM(atTick: resolvedTick)
        }

        if let activeSequenceIndex = activeSequenceIndexForTempo() {
            return project.sequences[activeSequenceIndex].tempoBPM(atTick: resolvedTick)
        }
        return project.masterTempoBPM
    }

    public mutating func clearTapTempoHistory() {
        tapTempoTimestamps.removeAll(keepingCapacity: true)
    }

    @discardableResult
    public mutating func registerTapTempoTap(
        mode: TapTempoAveragingMode,
        at timestamp: TimeInterval
    ) -> Double? {
        let sanitizedTimestamp = max(0, timestamp)

        if let lastTimestamp = tapTempoTimestamps.last, sanitizedTimestamp <= lastTimestamp {
            tapTempoTimestamps = [sanitizedTimestamp]
            return nil
        }

        tapTempoTimestamps.append(sanitizedTimestamp)
        tapTempoTimestamps = Array(tapTempoTimestamps.suffix(TapTempoAveragingMode.taps4.tapCount))

        let requiredTaps = mode.tapCount
        guard tapTempoTimestamps.count >= requiredTaps else {
            return nil
        }

        let tapsWindow = tapTempoTimestamps.suffix(requiredTaps)
        let intervals = zip(tapsWindow.dropFirst(), tapsWindow).map { pair in
            pair.0 - pair.1
        }
        guard intervals.isEmpty == false else {
            return nil
        }

        let averageInterval = intervals.reduce(0.0, +) / Double(intervals.count)
        guard averageInterval > 0 else {
            return nil
        }

        let bpm = max(1.0, 60.0 / averageInterval)
        applyTappedTempo(bpm)
        return bpm
    }

    @discardableResult
    public mutating func registerTapTempoTap(mode: TapTempoAveragingMode) -> Double? {
        registerTapTempoTap(mode: mode, at: Date().timeIntervalSinceReferenceDate)
    }

    public mutating func play() {
        transport.mode = .playing
        transport.isWaitingForKey = false
        transport.countInRemainingTicks = 0
        songPlayback = nil
        updateSongTransportIndicators(nil)
    }

    public mutating func stop() {
        transport.mode = .stopped
        transport.countInRemainingTicks = 0
        songPlayback = nil
        updateSongTransportIndicators(nil)
    }

    public mutating func locate(tick: Int) {
        transport.tickPosition = max(0, tick)
    }

    public mutating func record() {
        transport.mode = .recording
        transport.isWaitingForKey = false
        transport.countInRemainingTicks = 0
        songPlayback = nil
        updateSongTransportIndicators(nil)
    }

    public mutating func overdub() {
        transport.mode = .overdubbing
        transport.isWaitingForKey = false
        transport.countInRemainingTicks = 0
        songPlayback = nil
        updateSongTransportIndicators(nil)
    }

    public mutating func stepEditInsertEvent(
        sequenceIndex: Int,
        trackIndex: Int,
        eventIndex: Int,
        event: MIDIEvent
    ) throws {
        guard sequenceIndex >= 0, sequenceIndex < project.sequences.count else {
            throw StepEditError.sequenceIndexOutOfRange
        }
        guard trackIndex >= 0, trackIndex < project.sequences[sequenceIndex].tracks.count else {
            throw StepEditError.trackIndexOutOfRange
        }
        do {
            try project.sequences[sequenceIndex].tracks[trackIndex].insertStepEvent(event, at: eventIndex)
        } catch {
            throw StepEditError.eventIndexOutOfRange
        }
    }

    public mutating func stepEditUpdateEvent(
        sequenceIndex: Int,
        trackIndex: Int,
        eventIndex: Int,
        event: MIDIEvent
    ) throws {
        guard sequenceIndex >= 0, sequenceIndex < project.sequences.count else {
            throw StepEditError.sequenceIndexOutOfRange
        }
        guard trackIndex >= 0, trackIndex < project.sequences[sequenceIndex].tracks.count else {
            throw StepEditError.trackIndexOutOfRange
        }
        do {
            try project.sequences[sequenceIndex].tracks[trackIndex].updateStepEvent(at: eventIndex, with: event)
        } catch {
            throw StepEditError.eventIndexOutOfRange
        }
    }

    @discardableResult
    public mutating func stepEditDeleteEvent(
        sequenceIndex: Int,
        trackIndex: Int,
        eventIndex: Int
    ) throws -> MIDIEvent {
        guard sequenceIndex >= 0, sequenceIndex < project.sequences.count else {
            throw StepEditError.sequenceIndexOutOfRange
        }
        guard trackIndex >= 0, trackIndex < project.sequences[sequenceIndex].tracks.count else {
            throw StepEditError.trackIndexOutOfRange
        }
        do {
            return try project.sequences[sequenceIndex].tracks[trackIndex].deleteStepEvent(at: eventIndex)
        } catch {
            throw StepEditError.eventIndexOutOfRange
        }
    }

    public mutating func insertBars(
        sequenceIndex: Int,
        atBar bar: Int,
        count: Int,
        beatsPerBar: Int = Sequence.defaultBeatsPerBar
    ) throws {
        guard sequenceIndex >= 0, sequenceIndex < project.sequences.count else {
            throw EditOperationError.sequenceIndexOutOfRange
        }

        do {
            try project.sequences[sequenceIndex].insertBars(
                atBar: bar,
                count: count,
                beatsPerBar: beatsPerBar
            )
        } catch let error as Sequence.EditError {
            throw mapEditError(error)
        }
    }

    public mutating func deleteBars(
        sequenceIndex: Int,
        startingAt bar: Int,
        count: Int,
        beatsPerBar: Int = Sequence.defaultBeatsPerBar
    ) throws {
        guard sequenceIndex >= 0, sequenceIndex < project.sequences.count else {
            throw EditOperationError.sequenceIndexOutOfRange
        }

        do {
            try project.sequences[sequenceIndex].deleteBars(
                startingAt: bar,
                count: count,
                beatsPerBar: beatsPerBar
            )
        } catch let error as Sequence.EditError {
            throw mapEditError(error)
        }
    }

    public mutating func copyBars(
        sequenceIndex: Int,
        from sourceBar: Int,
        count: Int,
        to destinationBar: Int,
        mode: Track.EventCopyMode,
        beatsPerBar: Int = Sequence.defaultBeatsPerBar
    ) throws {
        guard sequenceIndex >= 0, sequenceIndex < project.sequences.count else {
            throw EditOperationError.sequenceIndexOutOfRange
        }

        do {
            try project.sequences[sequenceIndex].copyBars(
                from: sourceBar,
                count: count,
                to: destinationBar,
                mode: mode,
                beatsPerBar: beatsPerBar
            )
        } catch let error as Sequence.EditError {
            throw mapEditError(error)
        }
    }

    public mutating func copyEvents(
        sequenceIndex: Int,
        trackIndex: Int,
        sourceStartTick: Int,
        length: Int,
        destinationStartTick: Int,
        mode: Track.EventCopyMode
    ) throws {
        guard sequenceIndex >= 0, sequenceIndex < project.sequences.count else {
            throw EditOperationError.sequenceIndexOutOfRange
        }

        do {
            try project.sequences[sequenceIndex].copyEvents(
                trackIndex: trackIndex,
                sourceStartTick: sourceStartTick,
                length: length,
                destinationStartTick: destinationStartTick,
                mode: mode
            )
        } catch let error as Sequence.EditError {
            throw mapEditError(error)
        }
    }

    @discardableResult
    public mutating func eraseRegion(
        sequenceIndex: Int,
        trackIndex: Int,
        startTick: Int,
        length: Int,
        filter: Track.EventTypeFilter = .all
    ) throws -> Int {
        guard transport.mode == .stopped else {
            throw EraseOperationError.transportMustBeStopped
        }
        guard sequenceIndex >= 0, sequenceIndex < project.sequences.count else {
            throw EraseOperationError.sequenceIndexOutOfRange
        }
        guard trackIndex >= 0, trackIndex < project.sequences[sequenceIndex].tracks.count else {
            throw EraseOperationError.trackIndexOutOfRange
        }
        guard startTick >= 0, length > 0 else {
            throw EraseOperationError.invalidTickLength
        }

        return project.sequences[sequenceIndex].tracks[trackIndex].eraseEvents(
            inRange: startTick..<(startTick + length),
            filter: filter
        )
    }

    @discardableResult
    public mutating func eraseOverdubHold(
        sequenceIndex: Int,
        trackIndex: Int,
        heldRange: Range<Int>,
        filter: Track.EventTypeFilter = .all
    ) throws -> Int {
        guard transport.mode == .overdubbing else {
            throw EraseOperationError.transportMustBeOverdubbing
        }
        guard sequenceIndex >= 0, sequenceIndex < project.sequences.count else {
            throw EraseOperationError.sequenceIndexOutOfRange
        }
        guard trackIndex >= 0, trackIndex < project.sequences[sequenceIndex].tracks.count else {
            throw EraseOperationError.trackIndexOutOfRange
        }
        guard heldRange.lowerBound >= 0, heldRange.lowerBound < heldRange.upperBound else {
            throw EraseOperationError.invalidTickLength
        }

        return project.sequences[sequenceIndex].tracks[trackIndex].eraseEvents(
            inRange: heldRange,
            filter: filter
        )
    }

    public mutating func turnOnEditLoop(
        sequenceIndex: Int,
        startBar: Int,
        barCount: Int
    ) throws {
        guard sequenceIndex >= 0, sequenceIndex < project.sequences.count else {
            throw EditLoopError.sequenceIndexOutOfRange
        }
        guard startBar > 0 else {
            throw EditLoopError.invalidStartBar
        }
        guard barCount > 0 else {
            throw EditLoopError.invalidBarCount
        }
        guard editLoopState == nil else {
            throw EditLoopError.alreadyActive
        }

        editLoopState = EditLoopState(
            sequenceIndex: sequenceIndex,
            startBar: startBar,
            barCount: barCount,
            sequenceSnapshot: project.sequences[sequenceIndex]
        )
        activeEditLoopSequenceIndex = sequenceIndex
    }

    public mutating func turnOffEditLoop() throws {
        guard editLoopState != nil else {
            throw EditLoopError.notActive
        }
        editLoopState = nil
        activeEditLoopSequenceIndex = nil
    }

    public mutating func undoAndTurnOffEditLoop() throws {
        guard let state = editLoopState else {
            throw EditLoopError.notActive
        }
        guard state.sequenceIndex >= 0, state.sequenceIndex < project.sequences.count else {
            throw EditLoopError.sequenceIndexOutOfRange
        }

        project.sequences[state.sequenceIndex] = state.sequenceSnapshot
        editLoopState = nil
        activeEditLoopSequenceIndex = nil
    }

    public mutating func armWaitForKey() {
        transport.mode = .stopped
        transport.isWaitingForKey = true
        transport.countInRemainingTicks = 0
        songPlayback = nil
        updateSongTransportIndicators(nil)
    }

    public mutating func armCountIn() {
        transport.mode = .recording
        transport.isWaitingForKey = false
        transport.countInRemainingTicks = countInBarTicks()
        songPlayback = nil
        updateSongTransportIndicators(nil)
    }

    @discardableResult
    public mutating func playSong(at songIndex: Int) -> Bool {
        guard let initialState = initialSongPlayback(songIndex: songIndex) else {
            stop()
            return false
        }

        transport.mode = .playing
        transport.isWaitingForKey = false
        transport.countInRemainingTicks = 0
        transport.tickPosition = 0
        songPlayback = initialState
        updateSongTransportIndicators(initialState)
        return true
    }

    public mutating func advanceTransport(by ticks: Int) {
        advanceTransport(by: ticks, loopLengthOverride: nil)
    }

    public mutating func advanceTransport(
        by ticks: Int,
        sequenceIndex: Int? = nil,
        emit: (ScheduledEvent) -> Void
    ) {
        guard ticks > 0 else {
            return
        }

        let resolvedSequenceIndex = resolvedSequenceIndexForScheduling(explicitSequenceIndex: sequenceIndex)
        guard songPlayback == nil,
              let resolvedSequenceIndex,
              resolvedSequenceIndex >= 0,
              resolvedSequenceIndex < project.sequences.count,
              transport.isRunning else {
            advanceTransport(by: ticks)
            return
        }

        let sequence = project.sequences[resolvedSequenceIndex]
        let sequenceLoopLength = sequence.loopLengthTicks()
        emitScheduledEvents(
            sequenceIndex: resolvedSequenceIndex,
            sequence: sequence,
            startTick: transport.tickPosition,
            duration: ticks,
            loopLength: sequenceLoopLength,
            emit: emit
        )
        advanceTransport(by: ticks, loopLengthOverride: sequenceLoopLength)
    }

    private mutating func advanceTransport(by ticks: Int, loopLengthOverride: Int?) {
        guard ticks > 0 else {
            return
        }

        if advanceSongTransport(by: ticks) {
            return
        }

        let resolvedLoopLength = loopLengthOverride ?? activeLoopLengthTicks()
        if transport.isRunning, let loopLength = resolvedLoopLength, loopLength > 0 {
            transport.tickPosition = (transport.tickPosition + ticks) % loopLength
        } else {
            transport.tickPosition += ticks
        }

        advanceCountIn(by: ticks)
    }

    /// Compatibility API that preserves prior array-returning behavior.
    /// Prefer `advanceTransport(by:sequenceIndex:emit:)` for realtime paths.
    public mutating func advanceTransportAndCollectScheduledEvents(
        by ticks: Int,
        sequenceIndex: Int? = nil
    ) -> [ScheduledEvent] {
        var scheduled: [ScheduledEvent] = []
        advanceTransport(by: ticks, sequenceIndex: sequenceIndex) { event in
            scheduled.append(event)
        }
        return scheduled
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

    public mutating func setRecordReady(_ enabled: Bool) {
        transport.isRecordReady = enabled
    }

    @discardableResult
    public mutating func punchIn(_ mode: PunchMode) -> Bool {
        guard transport.mode == .playing, transport.isRecordReady else {
            return false
        }

        switch mode {
        case .record:
            transport.mode = .recording
        case .overdub:
            transport.mode = .overdubbing
        }
        transport.countInRemainingTicks = 0
        songPlayback = nil
        updateSongTransportIndicators(nil)
        return true
    }

    @discardableResult
    public mutating func punchOut() -> Bool {
        guard transport.mode == .recording || transport.mode == .overdubbing else {
            return false
        }
        transport.mode = .playing
        transport.countInRemainingTicks = 0
        return true
    }

    public func convertSongToSequence(songIndex: Int, sequenceName: String? = nil) throws -> Sequence {
        guard let song = songIfExists(index: songIndex) else {
            throw SongConversionError.songIndexOutOfRange
        }

        var destinationTracks: [Track] = []
        var destinationPPQN: Int?
        var timelineCursor = 0
        var materializedStepCount = 0

        for (stepIndex, step) in song.steps.enumerated() {
            if step.repeats == 0 {
                break
            }

            guard step.sequenceIndex >= 0, step.sequenceIndex < project.sequences.count else {
                throw SongConversionError.sequenceIndexOutOfRange(
                    stepIndex: stepIndex,
                    sequenceIndex: step.sequenceIndex
                )
            }

            let sourceSequence = project.sequences[step.sequenceIndex]
            if destinationPPQN == nil {
                destinationPPQN = sourceSequence.ppqn
            }
            let stepLength = max(1, sourceSequence.loopLengthTicks() ?? (sourceSequence.ppqn * 4))

            for _ in 0..<step.repeats {
                for (trackIndex, sourceTrack) in sourceSequence.tracks.enumerated() {
                    ensureDestinationTrackExists(
                        at: trackIndex,
                        in: &destinationTracks,
                        sourceTrack: sourceTrack
                    )
                    destinationTracks[trackIndex].events.append(
                        contentsOf: sourceTrack.events.map { $0.shifted(by: timelineCursor) }
                    )
                }
                timelineCursor += stepLength
                materializedStepCount += 1
            }
        }

        guard materializedStepCount > 0 else {
            throw SongConversionError.noMaterializedSteps
        }

        return Sequence(
            name: sequenceName ?? "\(song.name) Flattened",
            ppqn: destinationPPQN ?? Sequence.defaultPPQN,
            trackCapacity: max(Sequence.minTrackCapacity, destinationTracks.count),
            loopMode: .noLoop,
            tracks: destinationTracks
        )
    }

    private func countInBarTicks() -> Int {
        let ppqn = project.sequences.first?.ppqn ?? Sequence.defaultPPQN
        return max(1, ppqn * 4)
    }

    private mutating func applyTappedTempo(_ bpm: Double) {
        if project.tempoSource == .master {
            project.setMasterTempoBPM(bpm)
            return
        }

        if let sequenceIndex = activeSequenceIndexForTempo() {
            project.sequences[sequenceIndex].setTempoBPM(bpm)
            return
        }

        project.setMasterTempoBPM(bpm)
    }

    private func mapEditError(_ error: Sequence.EditError) -> EditOperationError {
        switch error {
        case .invalidBar:
            return .invalidBar
        case .invalidBarCount:
            return .invalidBarCount
        case .invalidTicksPerBar:
            return .invalidTicksPerBar
        case .trackIndexOutOfRange:
            return .trackIndexOutOfRange
        case .invalidTickLength:
            return .invalidTickLength
        }
    }

    private func ensureDestinationTrackExists(
        at trackIndex: Int,
        in destinationTracks: inout [Track],
        sourceTrack: Track
    ) {
        guard trackIndex >= destinationTracks.count else {
            return
        }

        destinationTracks.append(
            Track(
                name: sourceTrack.name,
                kind: sourceTrack.kind,
                routing: sourceTrack.routing,
                events: []
            )
        )
    }

    private func activeLoopLengthTicks() -> Int? {
        project.sequences.first?.loopLengthTicks()
    }

    private func activeSequenceIndexForTempo() -> Int? {
        if let state = songPlayback,
           let song = songIfExists(index: state.songIndex),
           state.stepIndex >= 0,
           state.stepIndex < song.steps.count {
            let sequenceIndex = song.steps[state.stepIndex].sequenceIndex
            if sequenceIndex >= 0, sequenceIndex < project.sequences.count {
                return sequenceIndex
            }
        }

        if project.sequences.isEmpty == false {
            return 0
        }
        return nil
    }

    private func resolvedSequenceIndexForScheduling(explicitSequenceIndex: Int?) -> Int? {
        if let explicitSequenceIndex {
            return explicitSequenceIndex
        }
        if project.sequences.isEmpty == false {
            return 0
        }
        return nil
    }

    private mutating func emitScheduledEvents(
        sequenceIndex: Int,
        sequence: Sequence,
        startTick: Int,
        duration: Int,
        loopLength: Int?,
        emit: (ScheduledEvent) -> Void
    ) {
        let clampedStartTick = max(0, startTick)
        var remaining = max(0, duration)
        guard remaining > 0 else {
            return
        }

        let trackCount = sequence.tracks.count
        if schedulingMergeCursors.count < trackCount {
            schedulingMergeCursors.append(contentsOf: repeatElement(0, count: trackCount - schedulingMergeCursors.count))
        }

        var rangeStart = clampedStartTick
        var wrappedStart = loopLength.map { clampedStartTick % max(1, $0) } ?? clampedStartTick

        while remaining > 0 {
            let rangeEnd: Int
            if let loopLength, loopLength > 0 {
                let ticksUntilWrap = max(1, loopLength - wrappedStart)
                let consumed = min(remaining, ticksUntilWrap)
                rangeEnd = wrappedStart + consumed
                rangeStart = wrappedStart
                wrappedStart = (wrappedStart + consumed) % loopLength
                remaining -= consumed
            } else {
                rangeEnd = rangeStart + remaining
                remaining = 0
            }

            for trackIndex in sequence.tracks.indices {
                let track = sequence.tracks[trackIndex]
                schedulingMergeCursors[trackIndex] = firstEventIndex(in: track.events, atOrAfter: rangeStart)
            }

            while true {
                var bestTrackIndex = -1
                var bestEventIndex = 0
                var bestTick = Int.max

                for trackIndex in sequence.tracks.indices {
                    let track = sequence.tracks[trackIndex]
                    let eventIndex = schedulingMergeCursors[trackIndex]
                    guard eventIndex < track.events.count else {
                        continue
                    }
                    let event = track.events[eventIndex]
                    guard event.tick < rangeEnd else {
                        continue
                    }
                    if event.tick < bestTick ||
                        (event.tick == bestTick && (bestTrackIndex == -1 || trackIndex < bestTrackIndex)) {
                        bestTrackIndex = trackIndex
                        bestEventIndex = eventIndex
                        bestTick = event.tick
                    }
                }

                guard bestTrackIndex >= 0 else {
                    break
                }

                let track = sequence.tracks[bestTrackIndex]
                let event = track.events[bestEventIndex]
                emit(
                    ScheduledEvent(
                        sequenceIndex: sequenceIndex,
                        trackIndex: bestTrackIndex,
                        eventIndex: bestEventIndex,
                        event: event
                    )
                )
                schedulingMergeCursors[bestTrackIndex] = bestEventIndex + 1
            }

            if loopLength == nil {
                break
            }
        }
    }

    private func firstEventIndex(in events: [MIDIEvent], atOrAfter tick: Int) -> Int {
        var low = 0
        var high = events.count
        while low < high {
            let mid = (low + high) / 2
            if events[mid].tick < tick {
                low = mid + 1
            } else {
                high = mid
            }
        }
        return low
    }

    private mutating func advanceCountIn(by ticks: Int) {
        guard transport.countInRemainingTicks > 0 else {
            return
        }
        transport.countInRemainingTicks = max(0, transport.countInRemainingTicks - ticks)
    }

    private mutating func advanceSongTransport(by ticks: Int) -> Bool {
        guard transport.isRunning, var state = songPlayback else {
            return false
        }

        var remainingTicks = ticks
        while remainingTicks > 0 {
            guard let song = songIfExists(index: state.songIndex),
                  state.stepIndex < song.steps.count else {
                stopSongPlayback()
                return true
            }

            let step = song.steps[state.stepIndex]
            guard step.repeats > 0,
                  step.sequenceIndex >= 0,
                  let stepLength = songStepLengthTicks(sequenceIndex: step.sequenceIndex) else {
                if !transitionToNextSongStep(from: &state, song: song) {
                    stopSongPlayback()
                    return true
                }
                songPlayback = state
                updateSongTransportIndicators(state)
                return true
            }

            let remainingInRepeat = max(1, stepLength - state.tickInRepeat)
            let consumed = min(remainingTicks, remainingInRepeat)
            state.tickInRepeat += consumed
            remainingTicks -= consumed
            transport.tickPosition += consumed
            advanceCountIn(by: consumed)

            if state.tickInRepeat >= stepLength {
                state.tickInRepeat = 0
                if state.repeatIndex < (step.repeats - 1) {
                    state.repeatIndex += 1
                } else if !transitionToNextSongStep(from: &state, song: song) {
                    stopSongPlayback()
                    return true
                }
            }
        }

        songPlayback = state
        updateSongTransportIndicators(state)
        return true
    }

    private mutating func transitionToNextSongStep(from state: inout SongPlaybackState, song: Song) -> Bool {
        let nextStepIndex = state.stepIndex + 1
        return moveToSongStepOrEnd(song: song, from: &state, desiredStepIndex: nextStepIndex)
    }

    private mutating func moveToSongStepOrEnd(song: Song, from state: inout SongPlaybackState, desiredStepIndex: Int) -> Bool {
        guard desiredStepIndex < song.steps.count else {
            return handleSongEnd(song: song, state: &state)
        }

        let step = song.steps[desiredStepIndex]
        if step.repeats == 0 {
            return handleSongEnd(song: song, state: &state)
        }

        state.stepIndex = desiredStepIndex
        state.repeatIndex = 0
        state.tickInRepeat = 0
        return true
    }

    private mutating func handleSongEnd(song: Song, state: inout SongPlaybackState) -> Bool {
        switch song.endBehavior {
        case .stopAtEnd:
            return false
        case let .loopToStep(loopStep):
            guard loopStep >= 0,
                  loopStep < song.steps.count,
                  song.steps[loopStep].repeats > 0 else {
                return false
            }
            state.stepIndex = loopStep
            state.repeatIndex = 0
            state.tickInRepeat = 0
            return true
        }
    }

    private mutating func stopSongPlayback() {
        transport.mode = .stopped
        songPlayback = nil
        updateSongTransportIndicators(nil)
    }

    private func initialSongPlayback(songIndex: Int) -> SongPlaybackState? {
        guard let song = songIfExists(index: songIndex) else {
            return nil
        }

        var state = SongPlaybackState(songIndex: songIndex, stepIndex: 0, repeatIndex: 0, tickInRepeat: 0)
        if song.steps.isEmpty {
            return nil
        }

        if song.steps[0].repeats == 0 {
            switch song.endBehavior {
            case .stopAtEnd:
                return nil
            case let .loopToStep(loopStep):
                guard loopStep >= 0,
                      loopStep < song.steps.count,
                      song.steps[loopStep].repeats > 0 else {
                    return nil
                }
                state.stepIndex = loopStep
            }
        }

        guard songStepLengthTicks(sequenceIndex: song.steps[state.stepIndex].sequenceIndex) != nil else {
            return nil
        }
        return state
    }

    private func songIfExists(index: Int) -> Song? {
        guard index >= 0, index < project.songs.count else {
            return nil
        }
        return project.songs[index]
    }

    private func songStepLengthTicks(sequenceIndex: Int) -> Int? {
        guard sequenceIndex >= 0, sequenceIndex < project.sequences.count else {
            return nil
        }

        let sequence = project.sequences[sequenceIndex]
        if let loopLength = sequence.loopLengthTicks(), loopLength > 0 {
            return loopLength
        }
        return max(1, sequence.ppqn * 4)
    }

    private mutating func updateSongTransportIndicators(_ state: SongPlaybackState?) {
        transport.activeSongIndex = state?.songIndex
        transport.activeSongStepIndex = state?.stepIndex
        transport.activeSongRepeat = state.map { $0.repeatIndex + 1 }
    }
}
