import Foundation

extension SequencerEngine {
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
}
