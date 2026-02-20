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
}
