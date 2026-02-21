import Foundation
import XCTest
@testable import SequencerEngine
@testable import SequencerEngineIO

final class RealtimeSchedulerTests: XCTestCase {
    private final class TestClock: RealtimeClock, @unchecked Sendable {
        private let lock = NSLock()
        private var now: UInt64

        init(startNanoseconds: UInt64 = 0) {
            now = startNanoseconds
        }

        func nowNanoseconds() -> UInt64 {
            lock.lock()
            defer { lock.unlock() }
            return now
        }

        func advance(by delta: UInt64) {
            lock.lock()
            now += delta
            lock.unlock()
        }
    }

    private final class PacketSink: RealtimePacketSink, @unchecked Sendable {
        private let lock = NSLock()
        private(set) var packets: [RealtimeScheduledPacket] = []

        func consume(_ packet: RealtimeScheduledPacket) {
            lock.lock()
            packets.append(packet)
            lock.unlock()
        }
    }

    func testProcessCycleSchedulesEventsDeterministically() {
        let ppqn = Sequence.defaultPPQN
        var track = Track(name: "Main", kind: .midi)
        track.events = [
            .noteOn(channel: 1, note: 60, velocity: 100, tick: 0),
            .noteOff(channel: 1, note: 60, velocity: 0, tick: ppqn / 4)
        ]
        var sequence = Sequence(name: "S", ppqn: ppqn, tracks: [track])
        sequence.setLoopToBar(1)
        let engine = SequencerEngine(project: Project(sequences: [sequence]))

        let clock = TestClock(startNanoseconds: 0)
        let sink = PacketSink()
        let scheduler = RealtimeScheduler(
            engine: engine,
            configuration: RealtimeSchedulerConfiguration(
                ppqn: ppqn,
                sequenceIndex: 0,
                runnerIntervalNanoseconds: 1_000_000
            ),
            clock: clock,
            packetSink: sink
        )

        XCTAssertTrue(scheduler.submit(.play))
        scheduler.processCycleForTesting()

        clock.advance(by: 200_000_000) // ~38 ticks at 120 bpm, 96 PPQN.
        scheduler.processCycleForTesting()

        let snapshot = scheduler.snapshot()
        XCTAssertEqual(snapshot.transport.mode, .playing)
        XCTAssertGreaterThan(snapshot.transport.tickPosition, 0)
        XCTAssertEqual(sink.packets.first?.event, .noteOn(channel: 1, note: 60, velocity: 100, tick: 0))
        XCTAssertGreaterThanOrEqual(sink.packets.count, 2)
        XCTAssertGreaterThan(sink.packets[1].hostTimeNanoseconds, sink.packets[0].hostTimeNanoseconds)
    }

    func testOutputQueueOverflowTracksDrops() {
        var sequence = Sequence()
        sequence.tracks = [
            Track(
                kind: .midi,
                events: [
                    .noteOn(channel: 1, note: 60, velocity: 100, tick: 0),
                    .noteOn(channel: 1, note: 61, velocity: 100, tick: 1),
                    .noteOn(channel: 1, note: 62, velocity: 100, tick: 2)
                ]
            )
        ]
        let engine = SequencerEngine(project: Project(sequences: [sequence]))
        let clock = TestClock(startNanoseconds: 0)
        let scheduler = RealtimeScheduler(
            engine: engine,
            configuration: RealtimeSchedulerConfiguration(
                sequenceIndex: 0,
                outputQueueCapacity: 1,
                overflowPolicy: .dropNewest
            ),
            clock: clock
        )

        XCTAssertTrue(scheduler.submit(.play))
        scheduler.processCycleForTesting()

        clock.advance(by: 100_000_000)
        scheduler.processCycleForTesting()

        let snapshot = scheduler.snapshot()
        XCTAssertGreaterThan(snapshot.outputOverflowCount, 0)
    }

    func testCommandQueueOverflowDropsWhenConfigured() {
        let scheduler = RealtimeScheduler(
            configuration: RealtimeSchedulerConfiguration(
                commandQueueCapacity: 1,
                overflowPolicy: .dropNewest
            )
        )

        let first = scheduler.submit(.play)
        let second = scheduler.submit(.stop)
        XCTAssertTrue(first)
        XCTAssertFalse(second)
    }

    func testStreamingSchedulingMatchesCompatibilityWrapperOrdering() {
        let ppqn = Sequence.defaultPPQN
        var trackA = Track(name: "A", kind: .midi)
        trackA.events = [
            .noteOn(channel: 1, note: 60, velocity: 100, tick: 0),
            .noteOff(channel: 1, note: 60, velocity: 0, tick: ppqn / 4),
            .noteOn(channel: 1, note: 62, velocity: 100, tick: ppqn / 2)
        ]
        var trackB = Track(name: "B", kind: .midi)
        trackB.events = [
            .noteOn(channel: 2, note: 65, velocity: 90, tick: ppqn / 4),
            .noteOff(channel: 2, note: 65, velocity: 0, tick: ppqn / 2),
            .noteOn(channel: 2, note: 67, velocity: 90, tick: (ppqn * 3) / 4)
        ]
        var sequence = Sequence(name: "Parity", ppqn: ppqn, tracks: [trackA, trackB])
        sequence.setLoopToBar(1)
        let project = Project(sequences: [sequence])

        var wrapperEngine = SequencerEngine(project: project)
        var streamingEngine = SequencerEngine(project: project)
        wrapperEngine.play()
        streamingEngine.play()

        let ticks = ppqn
        let wrapped = wrapperEngine.advanceTransportAndCollectScheduledEvents(by: ticks, sequenceIndex: 0)
        var streamed: [SequencerEngine.ScheduledEvent] = []
        streamingEngine.advanceTransport(by: ticks, sequenceIndex: 0) { event in
            streamed.append(event)
        }

        XCTAssertEqual(streamed, wrapped)
    }

    func testScheduledPacketHostTimesMatchExpectedTickSpacingWithinTolerance() {
        let ppqn = Sequence.defaultPPQN
        var track = Track(name: "Timing", kind: .midi)
        track.events = [
            .noteOn(channel: 1, note: 60, velocity: 100, tick: 0),
            .noteOn(channel: 1, note: 62, velocity: 100, tick: 12),
            .noteOn(channel: 1, note: 64, velocity: 100, tick: 24)
        ]
        let sequence = Sequence(name: "Timing Sequence", ppqn: ppqn, tracks: [track])
        let engine = SequencerEngine(project: Project(sequences: [sequence]))

        let tempoBPM = 120.0
        let ticksPerSecond = (tempoBPM / 60.0) * Double(ppqn) // 192.0 at 120 BPM, 96 PPQN
        let expectedNanosecondsPerTick = 1_000_000_000.0 / ticksPerSecond
        let toleranceNanoseconds: UInt64 = 4_000

        let clock = TestClock(startNanoseconds: 0)
        let sink = PacketSink()
        let scheduler = RealtimeScheduler(
            engine: engine,
            configuration: RealtimeSchedulerConfiguration(
                ppqn: ppqn,
                sequenceIndex: 0,
                runnerIntervalNanoseconds: 1_000_000
            ),
            clock: clock,
            packetSink: sink
        )

        XCTAssertTrue(scheduler.submit(.setTempoSource(.master)))
        XCTAssertTrue(scheduler.submit(.setMasterTempoBPM(tempoBPM)))
        XCTAssertTrue(scheduler.submit(.play))

        scheduler.processCycleForTesting() // Establish baseline and apply commands.

        // Use one larger cycle so all events are emitted from the same scheduling window.
        clock.advance(by: 200_000_000) // ~38 ticks at 120 BPM / 96 PPQN.
        scheduler.processCycleForTesting()

        XCTAssertGreaterThanOrEqual(sink.packets.count, 3)
        let firstThree = Array(sink.packets.prefix(3))
        XCTAssertEqual(
            firstThree.map(\.event),
            [
                .noteOn(channel: 1, note: 60, velocity: 100, tick: 0),
                .noteOn(channel: 1, note: 62, velocity: 100, tick: 12),
                .noteOn(channel: 1, note: 64, velocity: 100, tick: 24)
            ]
        )

        let delta1 = Int64(firstThree[1].hostTimeNanoseconds) - Int64(firstThree[0].hostTimeNanoseconds)
        let delta2 = Int64(firstThree[2].hostTimeNanoseconds) - Int64(firstThree[1].hostTimeNanoseconds)
        let expectedDelta = UInt64((Double(12) * expectedNanosecondsPerTick).rounded())

        let error1 = UInt64(abs(delta1 - Int64(expectedDelta)))
        let error2 = UInt64(abs(delta2 - Int64(expectedDelta)))
        XCTAssertLessThanOrEqual(error1, toleranceNanoseconds)
        XCTAssertLessThanOrEqual(error2, toleranceNanoseconds)
    }
}
