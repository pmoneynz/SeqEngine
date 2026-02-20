import Foundation
import Dispatch
import Atomics

public struct RealtimeCommandQueueStats: Sendable, Equatable {
    public var enqueued: UInt64
    public var dropped: UInt64

    public init(enqueued: UInt64 = 0, dropped: UInt64 = 0) {
        self.enqueued = enqueued
        self.dropped = dropped
    }
}

public final class RealtimeCommandQueue: @unchecked Sendable {
    private let queue: SPSCRingBuffer<RealtimeControlCommand>
    private let overflowPolicy: QueueOverflowPolicy
    private let producerQueue: DispatchQueue
    private let enqueuedCount = ManagedAtomic<UInt64>(0)
    private let droppedCount = ManagedAtomic<UInt64>(0)

    public init(capacity: Int, overflowPolicy: QueueOverflowPolicy) {
        self.queue = SPSCRingBuffer(capacity: capacity)
        self.overflowPolicy = overflowPolicy
        self.producerQueue = DispatchQueue(label: "SequencerEngineIO.CommandProducer")
    }

    @discardableResult
    public func enqueue(_ command: RealtimeControlCommand) -> Bool {
        let accepted = producerQueue.sync {
            queue.push(command, overflowPolicy: overflowPolicy)
        }
        if accepted {
            enqueuedCount.wrappingIncrement(ordering: .relaxed)
        } else {
            droppedCount.wrappingIncrement(ordering: .relaxed)
        }
        return accepted
    }

    public func drain(_ body: (RealtimeControlCommand) -> Void) {
        while let command = queue.pop() {
            body(command)
        }
    }

    public func dequeue() -> RealtimeControlCommand? {
        queue.pop()
    }

    public func snapshotStats() -> RealtimeCommandQueueStats {
        RealtimeCommandQueueStats(
            enqueued: enqueuedCount.load(ordering: .relaxed),
            dropped: droppedCount.load(ordering: .relaxed)
        )
    }
}
