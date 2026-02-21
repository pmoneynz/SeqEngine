import Foundation

public protocol RealtimeSessioning: Sendable {
    var scheduler: RealtimeScheduler { get }
    func start()
    func stop()
    @discardableResult
    func submit(_ command: RealtimeControlCommand) -> Bool
    func snapshot() -> RealtimeSchedulerSnapshot
    func pollIncomingMIDI()
    func drainScheduledPackets(_ body: (RealtimeScheduledPacket) -> Void)
}
