import Foundation

extension SequencerEngine {
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

    mutating func applyTappedTempo(_ bpm: Double) {
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

    func activeSequenceIndexForTempo() -> Int? {
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
}
