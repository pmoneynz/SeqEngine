import Foundation

extension SequencerEngine {
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

    func mapEditError(_ error: Sequence.EditError) -> EditOperationError {
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
}
