import Foundation
import SequencerEngine

public enum RealtimeSequencerSessionError: Error {
    case outputInitializationFailed(Error)
    case inputInitializationFailed(Error)
}

public final class RealtimeSequencerSession: @unchecked Sendable {
    public let scheduler: RealtimeScheduler
    public let midiOutput: CoreMIDIOutputAdapter?
    public let midiInput: CoreMIDIInputAdapter?

    public init(
        engine: SequencerEngine = SequencerEngine(),
        configuration: RealtimeSchedulerConfiguration = RealtimeSchedulerConfiguration(),
        clock: RealtimeClock = SystemMonotonicClock(),
        outputDestinationName: String? = nil,
        inputSourceName: String? = nil,
        enableMIDIOutput: Bool = true,
        enableMIDIInput: Bool = true
    ) throws {
        let output: CoreMIDIOutputAdapter?
        if enableMIDIOutput {
            do {
                output = try CoreMIDIOutputAdapter(destinationName: outputDestinationName)
            } catch {
                throw RealtimeSequencerSessionError.outputInitializationFailed(error)
            }
        } else {
            output = nil
        }

        let input: CoreMIDIInputAdapter?
        if enableMIDIInput {
            do {
                input = try CoreMIDIInputAdapter(sourceName: inputSourceName)
            } catch {
                throw RealtimeSequencerSessionError.inputInitializationFailed(error)
            }
        } else {
            input = nil
        }

        self.midiOutput = output
        self.midiInput = input
        self.scheduler = RealtimeScheduler(
            engine: engine,
            configuration: configuration,
            clock: clock,
            packetSink: output
        )

        self.midiInput?.setOnEvent { [weak scheduler] event in
            _ = scheduler?.submit(.incomingMIDI(event))
        }
    }

    public func start() {
        scheduler.start()
    }

    public func stop() {
        scheduler.stop()
    }

    @discardableResult
    public func submit(_ command: RealtimeControlCommand) -> Bool {
        scheduler.submit(command)
    }

    public func snapshot() -> RealtimeSchedulerSnapshot {
        scheduler.snapshot()
    }

    public func pollIncomingMIDI() {
        midiInput?.pollEvents { [weak self] event in
            _ = self?.scheduler.submit(.incomingMIDI(event))
        }
    }

    public func drainScheduledPackets(_ body: (RealtimeScheduledPacket) -> Void) {
        scheduler.drainOutput(body)
    }
}
