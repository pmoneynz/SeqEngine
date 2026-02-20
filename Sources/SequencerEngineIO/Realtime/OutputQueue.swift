import Foundation
import Atomics

public struct RealtimeOutputQueueStats: Sendable, Equatable {
    public var enqueued: UInt64
    public var dropped: UInt64
    public var dequeued: UInt64

    public init(enqueued: UInt64 = 0, dropped: UInt64 = 0, dequeued: UInt64 = 0) {
        self.enqueued = enqueued
        self.dropped = dropped
        self.dequeued = dequeued
    }
}

public final class RealtimeOutputQueue: @unchecked Sendable {
    private let queue: SPSCRingBuffer<RealtimeScheduledPacket>
    private let overflowPolicy: QueueOverflowPolicy
    private let enqueuedCount = ManagedAtomic<UInt64>(0)
    private let droppedCount = ManagedAtomic<UInt64>(0)
    private let dequeuedCount = ManagedAtomic<UInt64>(0)

    public init(capacity: Int, overflowPolicy: QueueOverflowPolicy) {
        self.queue = SPSCRingBuffer(capacity: capacity)
        self.overflowPolicy = overflowPolicy
    }

    @discardableResult
    public func enqueue(_ packet: RealtimeScheduledPacket) -> Bool {
        let accepted = queue.push(packet, overflowPolicy: overflowPolicy)
        if accepted {
            enqueuedCount.wrappingIncrement(ordering: .relaxed)
        } else {
            droppedCount.wrappingIncrement(ordering: .relaxed)
        }
        return accepted
    }

    public func dequeue() -> RealtimeScheduledPacket? {
        let packet = queue.pop()
        if packet != nil {
            dequeuedCount.wrappingIncrement(ordering: .relaxed)
        }
        return packet
    }

    public func drain(_ body: (RealtimeScheduledPacket) -> Void) {
        while let packet = dequeue() {
            body(packet)
        }
    }

    public func snapshotStats() -> RealtimeOutputQueueStats {
        RealtimeOutputQueueStats(
            enqueued: enqueuedCount.load(ordering: .relaxed),
            dropped: droppedCount.load(ordering: .relaxed),
            dequeued: dequeuedCount.load(ordering: .relaxed)
        )
    }
}
