import Foundation
import XCTest
@testable import SequencerEngine
@testable import SequencerEngineIO

#if os(macOS)
import Darwin

final class RealtimeSchedulerAllocationTests: XCTestCase {
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

    func testSchedulerSteadyStateAllocationMetrics() {
        let ppqn = Sequence.defaultPPQN
        var track = Track(name: "Dense", kind: .midi)
        for tick in stride(from: 0, to: ppqn * 8, by: max(1, ppqn / 8)) {
            track.events.append(.noteOn(channel: 1, note: UInt8((tick / 2) % 127), velocity: 100, tick: tick))
            track.events.append(.noteOff(channel: 1, note: UInt8((tick / 2) % 127), velocity: 0, tick: tick + 1))
        }
        var sequence = Sequence(name: "Perf", ppqn: ppqn, tracks: [track])
        sequence.setLoopToBar(2)
        let engine = SequencerEngine(project: Project(sequences: [sequence]))

        let clock = TestClock(startNanoseconds: 0)
        let scheduler = RealtimeScheduler(
            engine: engine,
            configuration: RealtimeSchedulerConfiguration(
                ppqn: ppqn,
                sequenceIndex: 0,
                runnerIntervalNanoseconds: 1_000_000
            ),
            clock: clock
        )
        XCTAssertTrue(scheduler.submit(.play))
        scheduler.processCycleForTesting()

        // Warm-up allows one-time storage growth to settle before strict sampling.
        for _ in 0..<2_000 {
            clock.advance(by: 1_000_000)
            scheduler.processCycleForTesting()
        }

        let chunkCycles = 500
        let chunkCount = 8
        var inUseSamples: [size_t] = []
        inUseSamples.reserveCapacity(chunkCount + 1)
        inUseSamples.append(Self.currentHeapInUse())

        for _ in 0..<chunkCount {
            for _ in 0..<chunkCycles {
                clock.advance(by: 1_000_000)
                scheduler.processCycleForTesting()
            }
            inUseSamples.append(Self.currentHeapInUse())
        }

        let deltas = zip(inUseSamples.dropFirst(), inUseSamples).map { Int64($0) - Int64($1) }
        // malloc statistics can move in small allocator quantum increments.
        let strictNoGrowth = deltas.allSatisfy { $0 <= 64 }
        let first = Int64(inUseSamples.first ?? 0)
        let last = Int64(inUseSamples.last ?? 0)
        let bytesPerCycle = Double(last - first) / Double(chunkCycles * chunkCount)
        let fallbackNoPositiveTrend = bytesPerCycle <= 1.0

        XCTAssertTrue(fallbackNoPositiveTrend, "Observed positive per-cycle heap trend: \(bytesPerCycle) bytes/cycle")
        XCTAssertTrue(strictNoGrowth, "Strict no-growth check failed. chunk deltas: \(deltas)")
    }

    private static func currentHeapInUse() -> size_t {
        var stats = malloc_statistics_t()
        malloc_zone_statistics(nil, &stats)
        return stats.size_in_use
    }
}

#else

final class RealtimeSchedulerAllocationTests: XCTestCase {
    func testSchedulerSteadyStateAllocationMetrics() throws {
        throw XCTSkip("Allocation metrics use Darwin malloc statistics and are macOS-only.")
    }
}

#endif
