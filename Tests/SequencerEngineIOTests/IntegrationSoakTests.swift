import Foundation
import XCTest
@testable import SequencerEngine
@testable import SequencerEngineIO

final class IntegrationSoakTests: XCTestCase {
    private enum SoakTier: String {
        case short
        case medium
        case long
    }

    func testSoakShortSongModeDeterministicReplayHash() {
        let project = makeSongProject()
        let runA = runSongReplayHash(project: project, windowTicks: 37)
        let runB = runSongReplayHash(project: project, windowTicks: 37)

        XCTAssertEqual(runA.hash, runB.hash)
        XCTAssertEqual(runA.eventCount, runB.eventCount)
        XCTAssertGreaterThan(runA.eventCount, 0)
    }

    func testSoakShortTempoSwitchingMaintainsMonotonicPacketTimes() {
        final class TestClock: RealtimeClock, @unchecked Sendable {
            private let lock = NSLock()
            private var now: UInt64 = 0

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

        var sequence = Sequence(name: "Tempo Switch")
        sequence.setLoopToBar(4)
        sequence.tracks = [
            Track(
                kind: .midi,
                events: stride(from: 0, to: 1_536, by: 12).map {
                    .noteOn(channel: 0, note: 60, velocity: 100, tick: $0)
                }
            )
        ]

        let clock = TestClock()
        let scheduler = RealtimeScheduler(
            engine: SequencerEngine(project: Project(sequences: [sequence])),
            configuration: RealtimeSchedulerConfiguration(
                sequenceIndex: 0,
                runnerIntervalNanoseconds: 1_000_000,
                outputQueueCapacity: 32_768
            ),
            clock: clock
        )

        XCTAssertTrue(scheduler.submit(.setTempoSource(.master)))
        XCTAssertTrue(scheduler.submit(.setMasterTempoBPM(110)))
        XCTAssertTrue(scheduler.submit(.play))
        scheduler.processCycleForTesting()

        var lastHostTime: UInt64 = 0
        for cycle in 0..<8_000 {
            if cycle == 2_000 {
                XCTAssertTrue(scheduler.submit(.setMasterTempoBPM(140)))
            } else if cycle == 4_000 {
                XCTAssertTrue(scheduler.submit(.setMasterTempoBPM(96)))
            } else if cycle == 6_000 {
                XCTAssertTrue(scheduler.submit(.setMasterTempoBPM(124)))
            }

            clock.advance(by: 6_000_000)
            scheduler.processCycleForTesting()
            scheduler.drainOutput { packet in
                XCTAssertGreaterThanOrEqual(packet.hostTimeNanoseconds, lastHostTime)
                lastHostTime = packet.hostTimeNanoseconds
            }
        }

        let snapshot = scheduler.snapshot()
        XCTAssertGreaterThan(snapshot.scheduledPackets, 0)
        XCTAssertEqual(snapshot.droppedPackets, 0)
        XCTAssertEqual(snapshot.outputOverflowCount, 0)
    }

    func testSoakMediumSongModeReplayStabilityAtScale() throws {
        try requireTier(.medium)
        let project = makeSongProject(stepCount: 24, repeats: 8)
        let runA = runSongReplayHash(project: project, windowTicks: 53)
        let runB = runSongReplayHash(project: project, windowTicks: 53)
        XCTAssertEqual(runA.hash, runB.hash)
        XCTAssertEqual(runA.eventCount, runB.eventCount)
        XCTAssertGreaterThan(runA.eventCount, 5_000)
    }

    private func runSongReplayHash(project: Project, windowTicks: Int) -> (hash: UInt64, eventCount: Int) {
        var engine = SequencerEngine(project: project)
        XCTAssertTrue(engine.playSong(at: 0))

        var hash: UInt64 = 14_695_981_039_346_656_037
        let prime: UInt64 = 1_099_511_628_211
        var eventCount = 0
        var safetyCycles = 0

        while engine.transport.mode != .stopped {
            let events = engine.advanceTransportAndCollectScheduledEvents(by: max(1, windowTicks))
            for event in events {
                for byte in eventIdentity(event.event).utf8 {
                    hash ^= UInt64(byte)
                    hash &*= prime
                }
                eventCount += 1
            }
            safetyCycles += 1
            XCTAssertLessThan(safetyCycles, 100_000, "Song replay soak did not converge.")
        }

        return (hash: hash, eventCount: eventCount)
    }

    private func makeSongProject(stepCount: Int = 8, repeats: Int = 4) -> Project {
        let ppqn = Sequence.defaultPPQN
        let ticksPerBar = ppqn * 4

        var sequences: [Sequence] = []
        for index in 0..<4 {
            var sequence = Sequence(name: "Sequence \(index)")
            sequence.setLoopToBar(1)
            var track = Track(name: "Track \(index)", kind: .midi)
            for tick in stride(from: 0, to: ticksPerBar, by: 24) {
                let note = UInt8(48 + ((tick / 24 + index) % 24))
                track.events.append(.noteOn(channel: UInt8(index), note: note, velocity: 100, tick: tick))
                track.events.append(.noteOff(channel: UInt8(index), note: note, velocity: 0, tick: tick + 12))
            }
            sequence.tracks = [track]
            sequences.append(sequence)
        }

        var steps: [SongStep] = []
        for index in 0..<stepCount {
            steps.append(SongStep(sequenceIndex: index % sequences.count, repeats: repeats))
        }
        steps.append(SongStep(sequenceIndex: 0, repeats: 0))

        let song = Song(name: "Soak Song", steps: steps, endBehavior: .stopAtEnd)
        return Project(sequences: sequences, songs: [song])
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
