import Foundation

extension SequencerEngine {
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
}
