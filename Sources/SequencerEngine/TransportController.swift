import Foundation

extension SequencerEngine {
    public mutating func play() {
        transport.mode = .playing
        transport.isWaitingForKey = false
        transport.countInRemainingTicks = 0
        songPlayback = nil
        updateSongTransportIndicators(nil)
    }

    public mutating func stop() {
        transport.mode = .stopped
        transport.countInRemainingTicks = 0
        songPlayback = nil
        updateSongTransportIndicators(nil)
    }

    public mutating func locate(tick: Int) {
        transport.tickPosition = max(0, tick)
    }

    public mutating func record() {
        transport.mode = .recording
        transport.isWaitingForKey = false
        transport.countInRemainingTicks = 0
        songPlayback = nil
        updateSongTransportIndicators(nil)
    }

    public mutating func overdub() {
        transport.mode = .overdubbing
        transport.isWaitingForKey = false
        transport.countInRemainingTicks = 0
        songPlayback = nil
        updateSongTransportIndicators(nil)
    }

    public mutating func armWaitForKey() {
        transport.mode = .stopped
        transport.isWaitingForKey = true
        transport.countInRemainingTicks = 0
        songPlayback = nil
        updateSongTransportIndicators(nil)
    }

    public mutating func armCountIn() {
        transport.mode = .recording
        transport.isWaitingForKey = false
        transport.countInRemainingTicks = countInBarTicks()
        songPlayback = nil
        updateSongTransportIndicators(nil)
    }

    public mutating func setRecordReady(_ enabled: Bool) {
        transport.isRecordReady = enabled
    }

    @discardableResult
    public mutating func punchIn(_ mode: PunchMode) -> Bool {
        guard transport.mode == .playing, transport.isRecordReady else {
            return false
        }

        switch mode {
        case .record:
            transport.mode = .recording
        case .overdub:
            transport.mode = .overdubbing
        }
        transport.countInRemainingTicks = 0
        songPlayback = nil
        updateSongTransportIndicators(nil)
        return true
    }

    @discardableResult
    public mutating func punchOut() -> Bool {
        guard transport.mode == .recording || transport.mode == .overdubbing else {
            return false
        }
        transport.mode = .playing
        transport.countInRemainingTicks = 0
        return true
    }

    func countInBarTicks() -> Int {
        let ppqn = project.sequences.first?.ppqn ?? Sequence.defaultPPQN
        return max(1, ppqn * 4)
    }

    mutating func advanceCountIn(by ticks: Int) {
        guard transport.countInRemainingTicks > 0 else {
            return
        }
        transport.countInRemainingTicks = max(0, transport.countInRemainingTicks - ticks)
    }
}
