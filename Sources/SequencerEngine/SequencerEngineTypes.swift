import Foundation

extension SequencerEngine {
    public struct ScheduledEvent: Sendable, Equatable {
        public var sequenceIndex: Int
        public var trackIndex: Int
        public var eventIndex: Int
        public var event: MIDIEvent
        public var windowOffsetTicks: Int

        public init(
            sequenceIndex: Int,
            trackIndex: Int,
            eventIndex: Int,
            event: MIDIEvent,
            windowOffsetTicks: Int = 0
        ) {
            self.sequenceIndex = sequenceIndex
            self.trackIndex = trackIndex
            self.eventIndex = eventIndex
            self.event = event
            self.windowOffsetTicks = max(0, windowOffsetTicks)
        }
    }

    struct SongPlaybackState: Sendable, Equatable {
        var songIndex: Int
        var stepIndex: Int
        var repeatIndex: Int
        var tickInRepeat: Int
    }

    struct EditLoopState: Sendable, Equatable {
        var sequenceIndex: Int
        var startBar: Int
        var barCount: Int
        var sequenceSnapshot: Sequence
    }

    public enum PunchMode: Sendable, Equatable {
        case record
        case overdub
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
}
