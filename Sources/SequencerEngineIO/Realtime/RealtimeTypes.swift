import Foundation
import SequencerEngine

public protocol RealtimeClock: Sendable {
    func nowNanoseconds() -> UInt64
}

public struct SystemMonotonicClock: RealtimeClock {
    public init() {}

    public func nowNanoseconds() -> UInt64 {
        DispatchTime.now().uptimeNanoseconds
    }
}

public enum QueueOverflowPolicy: Sendable {
    case dropNewest
    case dropOldest
}

public struct RealtimeSchedulerConfiguration: Sendable {
    public var ppqn: Int
    public var sequenceIndex: Int?
    public var runnerIntervalNanoseconds: UInt64
    public var commandQueueCapacity: Int
    public var outputQueueCapacity: Int
    public var overflowPolicy: QueueOverflowPolicy

    public init(
        ppqn: Int = Sequence.defaultPPQN,
        sequenceIndex: Int? = 0,
        runnerIntervalNanoseconds: UInt64 = 1_000_000,
        commandQueueCapacity: Int = 2_048,
        outputQueueCapacity: Int = 8_192,
        overflowPolicy: QueueOverflowPolicy = .dropOldest
    ) {
        self.ppqn = max(1, ppqn)
        self.sequenceIndex = sequenceIndex
        self.runnerIntervalNanoseconds = max(100_000, runnerIntervalNanoseconds)
        self.commandQueueCapacity = max(1, commandQueueCapacity)
        self.outputQueueCapacity = max(1, outputQueueCapacity)
        self.overflowPolicy = overflowPolicy
    }
}

public enum RealtimeControlCommand: Sendable {
    case play
    case stop
    case locate(tick: Int)
    case record
    case overdub
    case setRecordReady(Bool)
    case armWaitForKey
    case armCountIn
    case incomingMIDI(MIDIEvent)
    case setTempoSource(TempoSource)
    case setMasterTempoBPM(Double)
    case setSequenceTempoBPM(sequenceIndex: Int, bpm: Double)
}

public struct RealtimeScheduledPacket: Sendable, Equatable {
    public var hostTimeNanoseconds: UInt64
    public var event: MIDIEvent
    public var sequenceIndex: Int
    public var trackIndex: Int
    public var eventIndex: Int

    public init(
        hostTimeNanoseconds: UInt64,
        event: MIDIEvent,
        sequenceIndex: Int,
        trackIndex: Int,
        eventIndex: Int
    ) {
        self.hostTimeNanoseconds = hostTimeNanoseconds
        self.event = event
        self.sequenceIndex = sequenceIndex
        self.trackIndex = trackIndex
        self.eventIndex = eventIndex
    }
}

public struct RealtimeSchedulerSnapshot: Sendable, Equatable {
    public var transport: SequencerEngine.TransportState
    public var scheduledPackets: UInt64
    public var droppedPackets: UInt64
    public var commandOverflowCount: UInt64
    public var outputOverflowCount: UInt64
    public var averageDriftNanoseconds: Double
    public var maxDriftNanoseconds: UInt64
    public var lastRunnerTickNanoseconds: UInt64

    public init(
        transport: SequencerEngine.TransportState = SequencerEngine.TransportState(),
        scheduledPackets: UInt64 = 0,
        droppedPackets: UInt64 = 0,
        commandOverflowCount: UInt64 = 0,
        outputOverflowCount: UInt64 = 0,
        averageDriftNanoseconds: Double = 0,
        maxDriftNanoseconds: UInt64 = 0,
        lastRunnerTickNanoseconds: UInt64 = 0
    ) {
        self.transport = transport
        self.scheduledPackets = scheduledPackets
        self.droppedPackets = droppedPackets
        self.commandOverflowCount = commandOverflowCount
        self.outputOverflowCount = outputOverflowCount
        self.averageDriftNanoseconds = averageDriftNanoseconds
        self.maxDriftNanoseconds = maxDriftNanoseconds
        self.lastRunnerTickNanoseconds = lastRunnerTickNanoseconds
    }
}

public protocol RealtimePacketSink: Sendable {
    func consume(_ packet: RealtimeScheduledPacket)
}
