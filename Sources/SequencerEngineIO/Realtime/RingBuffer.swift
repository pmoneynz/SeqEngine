import Foundation
import Atomics

/// Lock-free single-producer/single-consumer ring buffer.
/// The producer may optionally drop oldest entries when full.
final class SPSCRingBuffer<Element>: @unchecked Sendable {
    private let maxElements: Int
    private let capacity: Int
    private let storage: UnsafeMutablePointer<Element?>
    private let head: ManagedAtomic<Int>
    private let tail: ManagedAtomic<Int>

    init(capacity: Int) {
        self.maxElements = max(1, capacity)
        self.capacity = self.maxElements + 1
        self.storage = UnsafeMutablePointer<Element?>.allocate(capacity: self.capacity)
        self.storage.initialize(repeating: nil, count: self.capacity)
        self.head = ManagedAtomic(0)
        self.tail = ManagedAtomic(0)
    }

    deinit {
        storage.deinitialize(count: capacity)
        storage.deallocate()
    }

    var isEmpty: Bool {
        let localHead = head.load(ordering: .acquiring)
        let localTail = tail.load(ordering: .acquiring)
        return localHead == localTail
    }

    var currentCount: Int {
        let localHead = head.load(ordering: .acquiring)
        let localTail = tail.load(ordering: .acquiring)
        if localTail >= localHead {
            return localTail - localHead
        }
        return capacity - (localHead - localTail)
    }

    @discardableResult
    func push(_ element: Element, overflowPolicy: QueueOverflowPolicy) -> Bool {
        while true {
            let localTail = tail.load(ordering: .acquiring)
            let localHead = head.load(ordering: .acquiring)
            let nextTail = increment(localTail)

            if nextTail == localHead {
                switch overflowPolicy {
                case .dropNewest:
                    return false
                case .dropOldest:
                    let newHead = increment(localHead)
                    let advanced = head.compareExchange(
                        expected: localHead,
                        desired: newHead,
                        ordering: .acquiringAndReleasing
                    )
                    if advanced.exchanged == false {
                        continue
                    }
                }
            }

            storage[localTail] = element
            tail.store(nextTail, ordering: .releasing)
            return true
        }
    }

    func pop() -> Element? {
        let localHead = head.load(ordering: .acquiring)
        let localTail = tail.load(ordering: .acquiring)
        guard localHead != localTail else {
            return nil
        }

        let value = storage[localHead]
        storage[localHead] = nil
        head.store(increment(localHead), ordering: .releasing)
        return value
    }

    private func increment(_ index: Int) -> Int {
        let next = index + 1
        if next == capacity {
            return 0
        }
        return next
    }
}
