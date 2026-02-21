import Foundation
import XCTest
@testable import SequencerEngine
@testable import SequencerEngineIO

final class RealtimeSchedulerSoakTests: XCTestCase {
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

    private enum SoakTier: String {
        case short
        case medium
        case long
    }

    func testSoakShortRealtimeSchedulerDeterministicAndNoDrops() {
        let runA = runRealtimeSoak(
            cycleCount: 8_000,
            elapsedPerCycleNanoseconds: 8_000_000
        )
        let runB = runRealtimeSoak(
            cycleCount: 8_000,
            elapsedPerCycleNanoseconds: 8_000_000
        )

        XCTAssertEqual(runA.eventHash, runB.eventHash)
        XCTAssertGreaterThan(runA.scheduledPackets, 0)
        XCTAssertEqual(runA.droppedPackets, 0)
        XCTAssertEqual(runA.outputOverflowCount, 0)
        XCTAssertLessThanOrEqual(runA.maxDriftNanoseconds, 3_000_000)
    }

    func testSoakMediumRealtimeSchedulerSustainedDriftBounds() throws {
        try requireTier(.medium)
        let run = runRealtimeSoak(
            cycleCount: 40_000,
            elapsedPerCycleNanoseconds: 8_000_000
        )

        XCTAssertGreaterThan(run.scheduledPackets, 20_000)
        XCTAssertEqual(run.droppedPackets, 0)
        XCTAssertEqual(run.outputOverflowCount, 0)
        XCTAssertLessThanOrEqual(run.maxDriftNanoseconds, 4_000_000)
        XCTAssertLessThanOrEqual(run.averageDriftNanoseconds, 3_000_000)
    }

    func testSoakLongRealtimeSchedulerExtendedStability() throws {
        try requireTier(.long)
        let run = runRealtimeSoak(
            cycleCount: 120_000,
            elapsedPerCycleNanoseconds: 8_000_000
        )

        XCTAssertGreaterThan(run.scheduledPackets, 500_000)
        XCTAssertEqual(run.droppedPackets, 0)
        XCTAssertEqual(run.outputOverflowCount, 0)
        XCTAssertLessThanOrEqual(run.maxDriftNanoseconds, 6_000_000)
    }

    private func runRealtimeSoak(
        cycleCount: Int,
        elapsedPerCycleNanoseconds: UInt64
    ) -> (eventHash: UInt64, scheduledPackets: UInt64, droppedPackets: UInt64, outputOverflowCount: UInt64, averageDriftNanoseconds: Double, maxDriftNanoseconds: UInt64) {
        var sequence = Sequence(name: "Soak", ppqn: Sequence.defaultPPQN)
        sequence.setLoopToBar(4)

        var track = Track(name: "Dense", kind: .midi)
        for tick in stride(from: 0, to: 1_536, by: 6) {
            let note = UInt8(36 + ((tick / 6) % 48))
            track.events.append(.noteOn(channel: 0, note: note, velocity: 100, tick: tick))
            track.events.append(.noteOff(channel: 0, note: note, velocity: 0, tick: tick + 3))
        }
        sequence.tracks = [track]

        let clock = TestClock(startNanoseconds: 0)
        let scheduler = RealtimeScheduler(
            engine: SequencerEngine(project: Project(sequences: [sequence])),
            configuration: RealtimeSchedulerConfiguration(
                ppqn: Sequence.defaultPPQN,
                sequenceIndex: 0,
                runnerIntervalNanoseconds: 1_000_000,
                commandQueueCapacity: 16_384,
                outputQueueCapacity: 65_536,
                overflowPolicy: .dropNewest
            ),
            clock: clock
        )

        XCTAssertTrue(scheduler.submit(.setTempoSource(.master)))
        XCTAssertTrue(scheduler.submit(.setMasterTempoBPM(120)))
        XCTAssertTrue(scheduler.submit(.play))
        scheduler.processCycleForTesting() // baseline + command application

        var hash: UInt64 = 14_695_981_039_346_656_037
        let prime: UInt64 = 1_099_511_628_211

        for _ in 0..<cycleCount {
            clock.advance(by: elapsedPerCycleNanoseconds)
            scheduler.processCycleForTesting()
            scheduler.drainOutput { packet in
                for byte in eventIdentity(packet.event).utf8 {
                    hash ^= UInt64(byte)
                    hash &*= prime
                }
                hash ^= packet.hostTimeNanoseconds
                hash &*= prime
            }
        }

        let snapshot = scheduler.snapshot()
        return (
            eventHash: hash,
            scheduledPackets: snapshot.scheduledPackets,
            droppedPackets: snapshot.droppedPackets,
            outputOverflowCount: snapshot.outputOverflowCount,
            averageDriftNanoseconds: snapshot.averageDriftNanoseconds,
            maxDriftNanoseconds: snapshot.maxDriftNanoseconds
        )
    }

    private func eventIdentity(_ event: MIDIEvent) -> String {
        switch event {
        case let .noteOn(channel, note, velocity, tick):
            return "noteOn:\(channel):\(note):\(velocity):\(tick)"
        case let .noteOff(channel, note, velocity, tick):
            return "noteOff:\(channel):\(note):\(velocity):\(tick)"
        case let .programChange(channel, program, tick):
            return "programChange:\(channel):\(program):\(tick)"
        case let .pitchBend(channel, value, tick):
            return "pitchBend:\(channel):\(value):\(tick)"
        case let .channelPressure(channel, pressure, tick):
            return "channelPressure:\(channel):\(pressure):\(tick)"
        case let .polyPressure(channel, note, pressure, tick):
            return "polyPressure:\(channel):\(note):\(pressure):\(tick)"
        case let .controlChange(channel, controller, value, tick):
            return "controlChange:\(channel):\(controller):\(value):\(tick)"
        case let .sysEx(data, tick):
            return "sysEx:\(data.map(String.init).joined(separator: "-")):\(tick)"
        }
    }

    private func requireTier(_ minimumTier: SoakTier) throws {
        let current = currentTier()
        let rank: [SoakTier: Int] = [.short: 0, .medium: 1, .long: 2]
        if (rank[current] ?? 0) < (rank[minimumTier] ?? 0) {
            throw XCTSkip("Skipping \(minimumTier.rawValue) soak test for tier \(current.rawValue).")
        }
    }

    private func currentTier() -> SoakTier {
        let value = (ProcessInfo.processInfo.environment["SEQUENCER_SOAK_TIER"] ?? "short").lowercased()
        return SoakTier(rawValue: value) ?? .short
    }
}
