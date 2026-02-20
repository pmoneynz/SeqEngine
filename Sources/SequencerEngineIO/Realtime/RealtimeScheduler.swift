import Foundation
import Dispatch
import SequencerEngine

public final class RealtimeScheduler: @unchecked Sendable {
    private struct TimingAccumulator {
        var fractionalTicks: Double = 0
        var samples: UInt64 = 0
        var totalDrift: Double = 0
        var maxDrift: UInt64 = 0
    }

    public let configuration: RealtimeSchedulerConfiguration
    public let commandQueue: RealtimeCommandQueue
    public let outputQueue: RealtimeOutputQueue

    private let clock: RealtimeClock
    private let runnerQueue: DispatchQueue
    private var timer: DispatchSourceTimer?
    private var engine: SequencerEngine
    private var packetSink: RealtimePacketSink?

    private var isRunning = false
    private var lastTickNanoseconds: UInt64 = 0
    private var hasTickBaseline = false
    private var timing = TimingAccumulator()
    private var commandOverflowCount: UInt64 = 0
    private var outputOverflowCount: UInt64 = 0
    private var scheduledPacketsCount: UInt64 = 0

    public init(
        engine: SequencerEngine = SequencerEngine(),
        configuration: RealtimeSchedulerConfiguration = RealtimeSchedulerConfiguration(),
        clock: RealtimeClock = SystemMonotonicClock(),
        packetSink: RealtimePacketSink? = nil,
        queueLabel: String = "SequencerEngineIO.RealtimeScheduler"
    ) {
        self.engine = engine
        self.configuration = configuration
        self.clock = clock
        self.packetSink = packetSink
        self.commandQueue = RealtimeCommandQueue(
            capacity: configuration.commandQueueCapacity,
            overflowPolicy: configuration.overflowPolicy
        )
        self.outputQueue = RealtimeOutputQueue(
            capacity: configuration.outputQueueCapacity,
            overflowPolicy: configuration.overflowPolicy
        )
        self.runnerQueue = DispatchQueue(
            label: queueLabel,
            qos: .userInteractive
        )
    }

    deinit {
        stop()
    }

    public func setPacketSink(_ sink: RealtimePacketSink?) {
        runnerQueue.async { [weak self] in
            self?.packetSink = sink
        }
    }

    public func start() {
        runnerQueue.async { [weak self] in
            guard let self else { return }
            guard self.isRunning == false else { return }

            let timer = DispatchSource.makeTimerSource(queue: self.runnerQueue)
            timer.schedule(
                deadline: .now(),
                repeating: .nanoseconds(Int(self.configuration.runnerIntervalNanoseconds)),
                leeway: .microseconds(100)
            )
            timer.setEventHandler { [weak self] in
                self?.runOneCycle()
            }
            self.lastTickNanoseconds = self.clock.nowNanoseconds()
            self.hasTickBaseline = false
            self.isRunning = true
            self.timer = timer
            timer.resume()
        }
    }

    public func stop() {
        runnerQueue.sync {
            guard isRunning else {
                return
            }
            timer?.cancel()
            timer = nil
            isRunning = false
            timing = TimingAccumulator()
            hasTickBaseline = false
            commandOverflowCount = commandQueue.snapshotStats().dropped
        }
    }

    @discardableResult
    public func submit(_ command: RealtimeControlCommand) -> Bool {
        commandQueue.enqueue(command)
    }

    public func snapshot() -> RealtimeSchedulerSnapshot {
        runnerQueue.sync {
            let averageDrift = timing.samples > 0 ? timing.totalDrift / Double(timing.samples) : 0
            return RealtimeSchedulerSnapshot(
                transport: engine.transport,
                scheduledPackets: scheduledPacketsCount,
                droppedPackets: outputOverflowCount,
                commandOverflowCount: commandOverflowCount,
                outputOverflowCount: outputOverflowCount,
                averageDriftNanoseconds: averageDrift,
                maxDriftNanoseconds: timing.maxDrift,
                lastRunnerTickNanoseconds: lastTickNanoseconds
            )
        }
    }

    public func replaceEngine(_ newEngine: SequencerEngine) {
        runnerQueue.async { [weak self] in
            guard let self else { return }
            self.engine = newEngine
            self.timing = TimingAccumulator()
            self.lastTickNanoseconds = self.clock.nowNanoseconds()
            self.hasTickBaseline = false
            self.commandOverflowCount = 0
            self.outputOverflowCount = 0
            self.scheduledPacketsCount = 0
        }
    }

    public func drainOutput(_ body: (RealtimeScheduledPacket) -> Void) {
        outputQueue.drain(body)
    }

    public func processCycleForTesting() {
        runnerQueue.sync {
            runOneCycle()
        }
    }

    private func runOneCycle() {
        let now = clock.nowNanoseconds()
        if hasTickBaseline == false {
            lastTickNanoseconds = now
            hasTickBaseline = true
            applyQueuedCommands()
            return
        }
        let elapsed = now > lastTickNanoseconds ? now - lastTickNanoseconds : 0
        lastTickNanoseconds = now

        applyQueuedCommands()
        guard engine.transport.isRunning else {
            return
        }

        let tempo = max(1.0, engine.effectiveTempoBPM(sequenceIndex: configuration.sequenceIndex))
        let ticksPerSecond = (tempo / 60.0) * Double(max(1, configuration.ppqn))
        let idealTicks = (Double(elapsed) / 1_000_000_000.0) * ticksPerSecond
        timing.fractionalTicks += idealTicks
        let wholeTicks = Int(timing.fractionalTicks)
        timing.fractionalTicks -= Double(wholeTicks)

        guard wholeTicks > 0 else {
            return
        }

        let expectedElapsedNanos = UInt64((Double(wholeTicks) / ticksPerSecond) * 1_000_000_000.0)
        let drift = elapsed > expectedElapsedNanos ? elapsed - expectedElapsedNanos : expectedElapsedNanos - elapsed
        timing.samples += 1
        timing.totalDrift += Double(drift)
        timing.maxDrift = max(timing.maxDrift, drift)

        let scheduled = engine.advanceTransportAndCollectScheduledEvents(
            by: wholeTicks,
            sequenceIndex: configuration.sequenceIndex
        )
        for event in scheduled {
            let packet = RealtimeScheduledPacket(
                hostTimeNanoseconds: now &+ configuration.runnerIntervalNanoseconds,
                event: event.event,
                sequenceIndex: event.sequenceIndex,
                trackIndex: event.trackIndex,
                eventIndex: event.eventIndex
            )
            let accepted = outputQueue.enqueue(packet)
            if accepted {
                scheduledPacketsCount &+= 1
                packetSink?.consume(packet)
            } else {
                outputOverflowCount &+= 1
            }
        }
    }

    private func applyQueuedCommands() {
        while let command = commandQueue.dequeue() {
            switch command {
            case .play:
                engine.play()
            case .stop:
                engine.stop()
            case let .locate(tick):
                engine.locate(tick: tick)
            case .record:
                engine.record()
            case .overdub:
                engine.overdub()
            case let .setRecordReady(enabled):
                engine.setRecordReady(enabled)
            case .armWaitForKey:
                engine.armWaitForKey()
            case .armCountIn:
                engine.armCountIn()
            case let .incomingMIDI(event):
                _ = engine.handleIncomingMIDI(event)
            case let .setTempoSource(source):
                engine.setTempoSource(source)
            case let .setMasterTempoBPM(bpm):
                engine.setMasterTempoBPM(bpm)
            case let .setSequenceTempoBPM(sequenceIndex, bpm):
                _ = engine.setSequenceTempoBPM(bpm, at: sequenceIndex)
            }
        }
        commandOverflowCount = commandQueue.snapshotStats().dropped
    }
}
