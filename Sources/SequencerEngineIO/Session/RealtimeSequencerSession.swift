import Foundation
import SequencerEngine

public enum RealtimeSequencerSessionError: Error {
    case outputInitializationFailed(Error)
    case inputInitializationFailed(Error)
}

public final class RealtimeSequencerSession: RealtimeSessioning, @unchecked Sendable {
    public let scheduler: RealtimeScheduler
    public let midiOutput: CoreMIDIOutputAdapter?
    public let midiInput: CoreMIDIInputAdapter?

    private let protocolMIDIOutput: (any MIDIOutput)?
    private let protocolMIDIInput: (any MIDIInput)?

    public var output: (any MIDIOutput)? {
        protocolMIDIOutput ?? midiOutput
    }

    public var input: (any MIDIInput)? {
        protocolMIDIInput ?? midiInput
    }

    public init(
        scheduler: RealtimeScheduler,
        midiOutput: (any MIDIOutput)? = nil,
        midiInput: (any MIDIInput)? = nil
    ) {
        self.scheduler = scheduler
        self.protocolMIDIOutput = midiOutput
        self.protocolMIDIInput = midiInput
        self.midiOutput = midiOutput as? CoreMIDIOutputAdapter
        self.midiInput = midiInput as? CoreMIDIInputAdapter
        self.scheduler.setPacketSink(output)
        bindInputCallback()
    }

    /// Provisional convenience initializer that directly wires CoreMIDI adapters.
    /// Prefer `init(scheduler:midiOutput:midiInput:)` for stable protocol-based composition.
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
        self.protocolMIDIOutput = nil
        self.protocolMIDIInput = nil
        self.scheduler = RealtimeScheduler(
            engine: engine,
            configuration: configuration,
            clock: clock,
            packetSink: output
        )
        bindInputCallback()
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
        input?.pollEvents { [weak self] event in
            _ = self?.scheduler.submit(.incomingMIDI(event))
        }
    }

    public func drainScheduledPackets(_ body: (RealtimeScheduledPacket) -> Void) {
        scheduler.drainOutput(body)
    }

    private func bindInputCallback() {
        input?.setOnEvent { [weak scheduler] event in
            _ = scheduler?.submit(.incomingMIDI(event))
        }
    }
}
