import Foundation

public enum TempoSource: String, Sendable, Equatable, Codable {
    case sequence
    case master
}

public enum TapTempoAveragingMode: Int, Sendable, Equatable, CaseIterable, Codable {
    case taps2 = 2
    case taps3 = 3
    case taps4 = 4

    public var tapCount: Int {
        rawValue
    }
}

public struct Project: Sendable, Equatable, Codable {
    public static let maxSequences = 99
    public static let maxSongs = 20
    public static let defaultMasterTempoBPM = 120.0

    public enum CapacityError: Error, Equatable {
        case sequenceLimitReached
        case songLimitReached
    }

    public var sequences: [Sequence]
    public var songs: [Song]
    public var masterTempoBPM: Double
    public var tempoSource: TempoSource

    public init(
        sequences: [Sequence] = [],
        songs: [Song] = [],
        masterTempoBPM: Double = Project.defaultMasterTempoBPM,
        tempoSource: TempoSource = .sequence
    ) {
        self.sequences = Array(sequences.prefix(Self.maxSequences))
        self.songs = Array(songs.prefix(Self.maxSongs))
        self.masterTempoBPM = max(1.0, masterTempoBPM)
        self.tempoSource = tempoSource
    }

    public mutating func addSequence(_ sequence: Sequence) throws {
        guard sequences.count < Self.maxSequences else {
            throw CapacityError.sequenceLimitReached
        }
        sequences.append(sequence)
    }

    public mutating func addSong(_ song: Song) throws {
        guard songs.count < Self.maxSongs else {
            throw CapacityError.songLimitReached
        }
        songs.append(song)
    }

    public mutating func setMasterTempoBPM(_ bpm: Double) {
        masterTempoBPM = max(1.0, bpm)
    }

    public mutating func setTempoSource(_ source: TempoSource) {
        tempoSource = source
    }
}

public struct Sequence: Sendable, Equatable, Identifiable, Codable {
    public static let defaultPPQN = 96
    public static let minTrackCapacity = 32
    public static let maxTrackCapacity = 99
    public static let defaultBeatsPerBar = 4
    public static let defaultTempoBPM = 120.0

    public enum LoopMode: Sendable, Equatable, Codable {
        case noLoop
        case loopToBar(Int)
    }

    public enum CapacityError: Error, Equatable {
        case outOfRange
        case trackLimitReached
    }

    public enum EditError: Error, Equatable {
        case invalidBar
        case invalidBarCount
        case invalidTicksPerBar
        case trackIndexOutOfRange
        case invalidTickLength
    }

    public struct TempoChange: Sendable, Equatable, Identifiable, Codable {
        public var id: UUID
        public var tick: Int
        public var bpm: Double
        public var isEnabled: Bool

        public init(
            id: UUID = UUID(),
            tick: Int,
            bpm: Double,
            isEnabled: Bool = true
        ) {
            self.id = id
            self.tick = max(0, tick)
            self.bpm = max(1.0, bpm)
            self.isEnabled = isEnabled
        }
    }

    public var id: UUID
    public var name: String
    public var ppqn: Int
    public var tempoBPM: Double
    public private(set) var trackCapacity: Int
    public var loopMode: LoopMode
    public private(set) var tempoChanges: [TempoChange]
    public var tracks: [Track]

    public init(
        id: UUID = UUID(),
        name: String = "Sequence",
        ppqn: Int = Sequence.defaultPPQN,
        tempoBPM: Double = Sequence.defaultTempoBPM,
        trackCapacity: Int = Sequence.minTrackCapacity,
        loopMode: LoopMode = .noLoop,
        tempoChanges: [TempoChange] = [],
        tracks: [Track] = []
    ) {
        self.id = id
        self.name = name
        self.ppqn = max(1, ppqn)
        self.tempoBPM = max(1.0, tempoBPM)
        self.trackCapacity = min(
            max(trackCapacity, Self.minTrackCapacity),
            Self.maxTrackCapacity
        )
        self.loopMode = loopMode
        self.tempoChanges = Self.sortedTempoChanges(tempoChanges)
        self.tracks = Array(tracks.prefix(self.trackCapacity))
    }

    public mutating func setTrackCapacity(_ newCapacity: Int) throws {
        guard (Self.minTrackCapacity...Self.maxTrackCapacity).contains(newCapacity) else {
            throw CapacityError.outOfRange
        }
        trackCapacity = newCapacity
        if tracks.count > trackCapacity {
            tracks = Array(tracks.prefix(trackCapacity))
        }
    }

    public mutating func setTempoBPM(_ bpm: Double) {
        tempoBPM = max(1.0, bpm)
    }

    @discardableResult
    public mutating func insertTempoChange(
        atTick tick: Int,
        bpm: Double,
        isEnabled: Bool = true
    ) -> TempoChange {
        let change = TempoChange(tick: tick, bpm: bpm, isEnabled: isEnabled)
        tempoChanges.append(change)
        tempoChanges = Self.sortedTempoChanges(tempoChanges)
        return change
    }

    public func listedTempoChanges(includeDisabled: Bool = true) -> [TempoChange] {
        if includeDisabled {
            return tempoChanges
        }
        return tempoChanges.filter(\.isEnabled)
    }

    @discardableResult
    public mutating func setTempoChangeEnabled(id: UUID, _ isEnabled: Bool) -> Bool {
        guard let index = tempoChanges.firstIndex(where: { $0.id == id }) else {
            return false
        }
        tempoChanges[index].isEnabled = isEnabled
        return true
    }

    @discardableResult
    public mutating func deleteTempoChange(id: UUID) -> Bool {
        guard let index = tempoChanges.firstIndex(where: { $0.id == id }) else {
            return false
        }
        tempoChanges.remove(at: index)
        return true
    }

    public func tempoBPM(atTick tick: Int) -> Double {
        let clampedTick = max(0, tick)
        var resolvedTempo = tempoBPM

        for change in tempoChanges where change.isEnabled && change.tick <= clampedTick {
            resolvedTempo = change.bpm
        }
        return resolvedTempo
    }

    public mutating func addTrack(_ track: Track) throws {
        guard tracks.count < trackCapacity else {
            throw CapacityError.trackLimitReached
        }
        tracks.append(track)
    }

    public mutating func insertBars(
        atBar bar: Int,
        count: Int,
        beatsPerBar: Int = Self.defaultBeatsPerBar
    ) throws {
        guard bar > 0 else {
            throw EditError.invalidBar
        }
        guard count > 0 else {
            throw EditError.invalidBarCount
        }
        guard ppqn > 0, beatsPerBar > 0 else {
            throw EditError.invalidTicksPerBar
        }

        let ticksPerBar = ppqn * beatsPerBar
        for index in tracks.indices {
            tracks[index].insertBars(atBar: bar, count: count, ticksPerBar: ticksPerBar)
        }
    }

    public mutating func deleteBars(
        startingAt bar: Int,
        count: Int,
        beatsPerBar: Int = Self.defaultBeatsPerBar
    ) throws {
        guard bar > 0 else {
            throw EditError.invalidBar
        }
        guard count > 0 else {
            throw EditError.invalidBarCount
        }
        guard ppqn > 0, beatsPerBar > 0 else {
            throw EditError.invalidTicksPerBar
        }

        let ticksPerBar = ppqn * beatsPerBar
        for index in tracks.indices {
            tracks[index].deleteBars(startingAtBar: bar, count: count, ticksPerBar: ticksPerBar)
        }
    }

    public mutating func copyBars(
        from sourceBar: Int,
        count: Int,
        to destinationBar: Int,
        mode: Track.EventCopyMode = .merge,
        beatsPerBar: Int = Self.defaultBeatsPerBar
    ) throws {
        guard sourceBar > 0, destinationBar > 0 else {
            throw EditError.invalidBar
        }
        guard count > 0 else {
            throw EditError.invalidBarCount
        }
        guard ppqn > 0, beatsPerBar > 0 else {
            throw EditError.invalidTicksPerBar
        }

        let ticksPerBar = ppqn * beatsPerBar
        for index in tracks.indices {
            tracks[index].copyBars(
                fromBar: sourceBar,
                count: count,
                toBar: destinationBar,
                ticksPerBar: ticksPerBar,
                mode: mode
            )
        }
    }

    public mutating func copyEvents(
        trackIndex: Int,
        sourceStartTick: Int,
        length: Int,
        destinationStartTick: Int,
        mode: Track.EventCopyMode
    ) throws {
        guard trackIndex >= 0, trackIndex < tracks.count else {
            throw EditError.trackIndexOutOfRange
        }
        guard sourceStartTick >= 0 else {
            throw EditError.invalidTickLength
        }
        guard length > 0 else {
            throw EditError.invalidTickLength
        }

        tracks[trackIndex].copyEvents(
            fromRange: sourceStartTick..<(sourceStartTick + length),
            toStartTick: destinationStartTick,
            mode: mode
        )
    }

    public mutating func setNoLoop() {
        loopMode = .noLoop
    }

    public mutating func setLoopToBar(_ bar: Int) {
        loopMode = .loopToBar(max(1, bar))
    }

    public func loopLengthTicks(beatsPerBar: Int = Self.defaultBeatsPerBar) -> Int? {
        guard ppqn > 0, beatsPerBar > 0 else {
            return nil
        }

        guard case let .loopToBar(loopBar) = loopMode else {
            return nil
        }
        return loopBar * ppqn * beatsPerBar
    }

    private static func sortedTempoChanges(_ tempoChanges: [TempoChange]) -> [TempoChange] {
        tempoChanges.sorted { lhs, rhs in
            if lhs.tick != rhs.tick {
                return lhs.tick < rhs.tick
            }
            return lhs.id.uuidString < rhs.id.uuidString
        }
    }
}

public enum QuantizationMode: String, Sendable, Equatable, CaseIterable, Codable {
    case off
    case eighth
    case eighthTriplet
    case sixteenth
    case sixteenthTriplet
    case thirtySecond
    case thirtySecondTriplet

    public var displayName: String {
        switch self {
        case .off:
            return "off"
        case .eighth:
            return "1/8"
        case .eighthTriplet:
            return "1/8 triplet"
        case .sixteenth:
            return "1/16"
        case .sixteenthTriplet:
            return "1/16 triplet"
        case .thirtySecond:
            return "1/32"
        case .thirtySecondTriplet:
            return "1/32 triplet"
        }
    }

    public func intervalTicks(ppqn: Int = Sequence.defaultPPQN) -> Int? {
        guard ppqn > 0 else {
            return nil
        }

        switch self {
        case .off:
            return nil
        case .eighth:
            return ppqn / 2
        case .eighthTriplet:
            return ppqn / 3
        case .sixteenth:
            return ppqn / 4
        case .sixteenthTriplet:
            return ppqn / 6
        case .thirtySecond:
            return ppqn / 8
        case .thirtySecondTriplet:
            return ppqn / 12
        }
    }
}

public struct Swing: Sendable, Equatable, Codable {
    public static let minimumPercent = 50
    public static let maximumPercent = 75

    public enum ConfigurationError: Error, Equatable {
        case outOfRange
    }

    public let percent: Int

    public init(percent: Int) throws {
        guard (Self.minimumPercent...Self.maximumPercent).contains(percent) else {
            throw ConfigurationError.outOfRange
        }
        self.percent = percent
    }

    public func appliedTick(
        _ tick: Int,
        quantizationMode: QuantizationMode,
        ppqn: Int = Sequence.defaultPPQN
    ) -> Int {
        guard let interval = quantizationMode.intervalTicks(ppqn: ppqn), interval > 0 else {
            return tick
        }

        let subdivisionIndex = tick / interval
        guard subdivisionIndex.isMultiple(of: 2) == false else {
            return tick
        }

        let offset = Int(round((Double(percent - Self.minimumPercent) / 25.0) * Double(interval) / 2.0))
        return tick + offset
    }
}

public struct ShiftTiming: Sendable, Equatable, Codable {
    public enum Direction: String, Sendable, Equatable, Codable {
        case earlier
        case later
    }

    public enum ConfigurationError: Error, Equatable {
        case ticksMustBePositive
    }

    public let direction: Direction
    public let ticks: Int

    public init(direction: Direction, ticks: Int) throws {
        guard ticks > 0 else {
            throw ConfigurationError.ticksMustBePositive
        }
        self.direction = direction
        self.ticks = ticks
    }

    public func appliedTick(
        _ tick: Int,
        quantizationMode: QuantizationMode,
        ppqn: Int = Sequence.defaultPPQN
    ) -> Int {
        guard let interval = quantizationMode.intervalTicks(ppqn: ppqn), interval > 0 else {
            return tick
        }

        let boundedTicks = min(ticks, max(0, interval - 1))
        let signedOffset = direction == .earlier ? -boundedTicks : boundedTicks
        return max(0, tick + signedOffset)
    }
}

public struct NoteRepeat: Sendable, Equatable, Codable {
    public struct HeldNote: Sendable, Equatable, Codable {
        public var channel: UInt8
        public var note: UInt8
        public var velocity: UInt8

        public init(channel: UInt8, note: UInt8, velocity: UInt8) {
            self.channel = channel
            self.note = note
            self.velocity = velocity
        }
    }

    public var quantizationMode: QuantizationMode
    public var ppqn: Int
    public var gateTicks: Int?

    public init(
        quantizationMode: QuantizationMode,
        ppqn: Int = Sequence.defaultPPQN,
        gateTicks: Int? = nil
    ) {
        self.quantizationMode = quantizationMode
        self.ppqn = ppqn
        self.gateTicks = gateTicks
    }

    public func retriggerEvents(
        heldNotes: [HeldNote],
        heldRange: Range<Int>
    ) -> [MIDIEvent] {
        guard let interval = quantizationMode.intervalTicks(ppqn: ppqn), interval > 0 else {
            return []
        }
        guard heldRange.lowerBound < heldRange.upperBound, heldNotes.isEmpty == false else {
            return []
        }

        let effectiveGate = min(max(1, gateTicks ?? (interval / 2)), interval)
        let orderedNotes = heldNotes.sorted {
            if $0.channel != $1.channel {
                return $0.channel < $1.channel
            }
            return $0.note < $1.note
        }

        var events: [MIDIEvent] = []
        var tick = heldRange.lowerBound

        while tick < heldRange.upperBound {
            let noteOffTick = min(tick + effectiveGate, heldRange.upperBound)

            for held in orderedNotes {
                events.append(
                    .noteOn(
                        channel: held.channel,
                        note: held.note,
                        velocity: held.velocity,
                        tick: tick
                    )
                )
            }
            for held in orderedNotes {
                events.append(
                    .noteOff(
                        channel: held.channel,
                        note: held.note,
                        velocity: 0,
                        tick: noteOffTick
                    )
                )
            }

            tick += interval
        }

        return events
    }
}

public struct Track: Sendable, Equatable, Identifiable, Codable {
    public enum StepEditError: Error, Equatable {
        case eventIndexOutOfRange
    }

    public enum Kind: String, Sendable, Equatable, Codable {
        case drum
        case midi
    }

    public enum EventCopyMode: String, Sendable, Equatable, Codable {
        case replace
        case merge
    }

    public enum EventType: String, Sendable, Equatable, CaseIterable, Codable {
        case note
        case programChange
        case pitchBend
        case channelPressure
        case polyPressure
        case controlChange
        case sysEx
    }

    public enum EventTypeFilter: Sendable, Equatable {
        case all
        case only([EventType])
        case allExcept([EventType])

        fileprivate func includes(_ type: EventType) -> Bool {
            switch self {
            case .all:
                return true
            case let .only(types):
                return Set(types).contains(type)
            case let .allExcept(types):
                return Set(types).contains(type) == false
            }
        }
    }

    public var id: UUID
    public var name: String
    public var kind: Kind
    public var routing: Routing
    public var events: [MIDIEvent]

    public init(
        id: UUID = UUID(),
        name: String = "Track",
        kind: Kind = .midi,
        routing: Routing = Routing(),
        events: [MIDIEvent] = []
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.routing = routing
        self.events = events
    }

    public mutating func transpose(semitones: Int) {
        guard kind == .midi, semitones != 0 else {
            return
        }
        events = events.map { $0.transposed(by: semitones) }
    }

    public mutating func setPrimaryRouting(port: String, channel: UInt8) {
        routing.primary = MIDIDestination(port: port, channel: channel)
    }

    public mutating func setAuxiliaryRouting(_ destination: MIDIDestination?) {
        routing.auxiliary = destination
    }

    public mutating func insertStepEvent(_ event: MIDIEvent, at index: Int) throws {
        guard index >= 0, index <= events.count else {
            throw StepEditError.eventIndexOutOfRange
        }
        events.insert(event, at: index)
    }

    public mutating func updateStepEvent(at index: Int, with event: MIDIEvent) throws {
        guard index >= 0, index < events.count else {
            throw StepEditError.eventIndexOutOfRange
        }
        events[index] = event
    }

    @discardableResult
    public mutating func deleteStepEvent(at index: Int) throws -> MIDIEvent {
        guard index >= 0, index < events.count else {
            throw StepEditError.eventIndexOutOfRange
        }
        return events.remove(at: index)
    }

    public mutating func insertBars(atBar bar: Int, count: Int, ticksPerBar: Int) {
        guard bar > 0, count > 0, ticksPerBar > 0 else {
            return
        }
        let insertionTick = (bar - 1) * ticksPerBar
        let offset = count * ticksPerBar

        events = events.map { event in
            guard event.tick >= insertionTick else {
                return event
            }
            return event.shifted(by: offset)
        }
    }

    public mutating func deleteBars(startingAtBar bar: Int, count: Int, ticksPerBar: Int) {
        guard bar > 0, count > 0, ticksPerBar > 0 else {
            return
        }
        let deleteStartTick = (bar - 1) * ticksPerBar
        let deleteLength = count * ticksPerBar
        let deleteEndTick = deleteStartTick + deleteLength

        events = events.compactMap { event in
            let tick = event.tick
            if tick >= deleteStartTick, tick < deleteEndTick {
                return nil
            }
            if tick >= deleteEndTick {
                return event.shifted(by: -deleteLength)
            }
            return event
        }
    }

    public mutating func copyBars(
        fromBar sourceBar: Int,
        count: Int,
        toBar destinationBar: Int,
        ticksPerBar: Int,
        mode: EventCopyMode
    ) {
        guard sourceBar > 0, destinationBar > 0, count > 0, ticksPerBar > 0 else {
            return
        }
        let sourceStartTick = (sourceBar - 1) * ticksPerBar
        let destinationStartTick = (destinationBar - 1) * ticksPerBar
        let length = count * ticksPerBar

        copyEvents(
            fromRange: sourceStartTick..<(sourceStartTick + length),
            toStartTick: destinationStartTick,
            mode: mode
        )
    }

    public mutating func copyEvents(
        fromRange sourceRange: Range<Int>,
        toStartTick destinationStartTick: Int,
        mode: EventCopyMode
    ) {
        guard sourceRange.lowerBound >= 0,
              sourceRange.lowerBound < sourceRange.upperBound,
              destinationStartTick >= 0 else {
            return
        }

        let tickOffset = destinationStartTick - sourceRange.lowerBound
        let copiedEvents = events.enumerated()
            .filter { sourceRange.contains($0.element.tick) }
            .map { $0.element.shifted(by: tickOffset) }

        guard copiedEvents.isEmpty == false else {
            return
        }

        let destinationRange = destinationStartTick..<(destinationStartTick + sourceRange.count)
        let existingEvents: [MIDIEvent]
        switch mode {
        case .replace:
            existingEvents = events.filter { destinationRange.contains($0.tick) == false }
        case .merge:
            existingEvents = events
        }

        events = deterministicSort(existingEvents: existingEvents, copiedEvents: copiedEvents)
    }

    @discardableResult
    public mutating func eraseEvents(
        inRange eraseRange: Range<Int>,
        filter: EventTypeFilter
    ) -> Int {
        guard eraseRange.lowerBound >= 0, eraseRange.lowerBound < eraseRange.upperBound else {
            return 0
        }

        let originalCount = events.count
        events.removeAll { event in
            eraseRange.contains(event.tick) && filter.includes(event.eventType)
        }
        return originalCount - events.count
    }

    private func deterministicSort(existingEvents: [MIDIEvent], copiedEvents: [MIDIEvent]) -> [MIDIEvent] {
        let rankedExisting = existingEvents.enumerated().map { (rank: 0, order: $0.offset, event: $0.element) }
        let rankedCopied = copiedEvents.enumerated().map { (rank: 1, order: $0.offset, event: $0.element) }
        return (rankedExisting + rankedCopied).sorted { lhs, rhs in
            if lhs.event.tick != rhs.event.tick {
                return lhs.event.tick < rhs.event.tick
            }
            if lhs.rank != rhs.rank {
                return lhs.rank < rhs.rank
            }
            return lhs.order < rhs.order
        }.map(\.event)
    }

    public struct Routing: Sendable, Equatable, Codable {
        public var primary: MIDIDestination
        public var auxiliary: MIDIDestination?

        public init(
            primary: MIDIDestination = MIDIDestination(port: "main", channel: 1),
            auxiliary: MIDIDestination? = nil
        ) {
            self.primary = primary
            self.auxiliary = auxiliary
        }
    }
}

public struct MIDIDestination: Sendable, Equatable, Codable {
    public var port: String
    public var channel: UInt8

    public init(port: String, channel: UInt8) {
        self.port = port
        self.channel = min(16, max(1, channel))
    }
}

public struct Song: Sendable, Equatable, Identifiable, Codable {
    public static let maxSteps = 250

    public enum EndBehavior: Sendable, Equatable, Codable {
        case stopAtEnd
        case loopToStep(Int)
    }

    public enum CapacityError: Error, Equatable {
        case stepLimitReached
    }

    public var id: UUID
    public var name: String
    public var steps: [SongStep]
    public var endBehavior: EndBehavior

    public init(
        id: UUID = UUID(),
        name: String = "Song",
        steps: [SongStep] = [],
        endBehavior: EndBehavior = .stopAtEnd
    ) {
        self.id = id
        self.name = name
        self.steps = Array(steps.prefix(Self.maxSteps))
        self.endBehavior = endBehavior
    }

    public mutating func addStep(_ step: SongStep) throws {
        guard steps.count < Self.maxSteps else {
            throw CapacityError.stepLimitReached
        }
        steps.append(step)
    }
}

public struct SongStep: Sendable, Equatable, Codable {
    public var sequenceIndex: Int
    public var repeats: Int

    public init(sequenceIndex: Int, repeats: Int) {
        self.sequenceIndex = sequenceIndex
        self.repeats = max(0, repeats)
    }
}

public enum MIDIEvent: Sendable, Equatable, Codable {
    case noteOn(channel: UInt8, note: UInt8, velocity: UInt8, tick: Int)
    case noteOff(channel: UInt8, note: UInt8, velocity: UInt8, tick: Int)
    case programChange(channel: UInt8, program: UInt8, tick: Int)
    case pitchBend(channel: UInt8, value: Int, tick: Int)
    case channelPressure(channel: UInt8, pressure: UInt8, tick: Int)
    case polyPressure(channel: UInt8, note: UInt8, pressure: UInt8, tick: Int)
    case controlChange(channel: UInt8, controller: UInt8, value: UInt8, tick: Int)
    case sysEx(data: [UInt8], tick: Int)

    var tick: Int {
        switch self {
        case let .noteOn(_, _, _, tick),
             let .noteOff(_, _, _, tick),
             let .programChange(_, _, tick),
             let .pitchBend(_, _, tick),
             let .channelPressure(_, _, tick),
             let .polyPressure(_, _, _, tick),
             let .controlChange(_, _, _, tick),
             let .sysEx(_, tick):
            return tick
        }
    }

    var isKeyPress: Bool {
        if case let .noteOn(_, _, velocity, _) = self {
            return velocity > 0
        }
        return false
    }

    var eventType: Track.EventType {
        switch self {
        case .noteOn, .noteOff:
            return .note
        case .programChange:
            return .programChange
        case .pitchBend:
            return .pitchBend
        case .channelPressure:
            return .channelPressure
        case .polyPressure:
            return .polyPressure
        case .controlChange:
            return .controlChange
        case .sysEx:
            return .sysEx
        }
    }

    fileprivate func transposed(by semitones: Int) -> MIDIEvent {
        switch self {
        case let .noteOn(channel, note, velocity, tick):
            return .noteOn(channel: channel, note: Self.clampNote(note, offset: semitones), velocity: velocity, tick: tick)
        case let .noteOff(channel, note, velocity, tick):
            return .noteOff(channel: channel, note: Self.clampNote(note, offset: semitones), velocity: velocity, tick: tick)
        case let .polyPressure(channel, note, pressure, tick):
            return .polyPressure(channel: channel, note: Self.clampNote(note, offset: semitones), pressure: pressure, tick: tick)
        case .programChange,
             .pitchBend,
             .channelPressure,
             .controlChange,
             .sysEx:
            return self
        }
    }

    func shifted(by tickOffset: Int) -> MIDIEvent {
        switch self {
        case let .noteOn(channel, note, velocity, tick):
            return .noteOn(channel: channel, note: note, velocity: velocity, tick: tick + tickOffset)
        case let .noteOff(channel, note, velocity, tick):
            return .noteOff(channel: channel, note: note, velocity: velocity, tick: tick + tickOffset)
        case let .programChange(channel, program, tick):
            return .programChange(channel: channel, program: program, tick: tick + tickOffset)
        case let .pitchBend(channel, value, tick):
            return .pitchBend(channel: channel, value: value, tick: tick + tickOffset)
        case let .channelPressure(channel, pressure, tick):
            return .channelPressure(channel: channel, pressure: pressure, tick: tick + tickOffset)
        case let .polyPressure(channel, note, pressure, tick):
            return .polyPressure(channel: channel, note: note, pressure: pressure, tick: tick + tickOffset)
        case let .controlChange(channel, controller, value, tick):
            return .controlChange(channel: channel, controller: controller, value: value, tick: tick + tickOffset)
        case let .sysEx(data, tick):
            return .sysEx(data: data, tick: tick + tickOffset)
        }
    }

    private static func clampNote(_ note: UInt8, offset: Int) -> UInt8 {
        let shifted = Int(note) + offset
        return UInt8(min(127, max(0, shifted)))
    }
}

extension MIDIEvent {
    private enum EventKind: String, Codable {
        case noteOn
        case noteOff
        case programChange
        case pitchBend
        case channelPressure
        case polyPressure
        case controlChange
        case sysEx
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case channel
        case note
        case velocity
        case tick
        case program
        case value
        case pressure
        case controller
        case data
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .noteOn(channel, note, velocity, tick):
            try container.encode(EventKind.noteOn, forKey: .type)
            try container.encode(channel, forKey: .channel)
            try container.encode(note, forKey: .note)
            try container.encode(velocity, forKey: .velocity)
            try container.encode(tick, forKey: .tick)
        case let .noteOff(channel, note, velocity, tick):
            try container.encode(EventKind.noteOff, forKey: .type)
            try container.encode(channel, forKey: .channel)
            try container.encode(note, forKey: .note)
            try container.encode(velocity, forKey: .velocity)
            try container.encode(tick, forKey: .tick)
        case let .programChange(channel, program, tick):
            try container.encode(EventKind.programChange, forKey: .type)
            try container.encode(channel, forKey: .channel)
            try container.encode(program, forKey: .program)
            try container.encode(tick, forKey: .tick)
        case let .pitchBend(channel, value, tick):
            try container.encode(EventKind.pitchBend, forKey: .type)
            try container.encode(channel, forKey: .channel)
            try container.encode(value, forKey: .value)
            try container.encode(tick, forKey: .tick)
        case let .channelPressure(channel, pressure, tick):
            try container.encode(EventKind.channelPressure, forKey: .type)
            try container.encode(channel, forKey: .channel)
            try container.encode(pressure, forKey: .pressure)
            try container.encode(tick, forKey: .tick)
        case let .polyPressure(channel, note, pressure, tick):
            try container.encode(EventKind.polyPressure, forKey: .type)
            try container.encode(channel, forKey: .channel)
            try container.encode(note, forKey: .note)
            try container.encode(pressure, forKey: .pressure)
            try container.encode(tick, forKey: .tick)
        case let .controlChange(channel, controller, value, tick):
            try container.encode(EventKind.controlChange, forKey: .type)
            try container.encode(channel, forKey: .channel)
            try container.encode(controller, forKey: .controller)
            try container.encode(value, forKey: .value)
            try container.encode(tick, forKey: .tick)
        case let .sysEx(data, tick):
            try container.encode(EventKind.sysEx, forKey: .type)
            try container.encode(data, forKey: .data)
            try container.encode(tick, forKey: .tick)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(EventKind.self, forKey: .type)

        switch kind {
        case .noteOn:
            self = try .noteOn(
                channel: container.decode(UInt8.self, forKey: .channel),
                note: container.decode(UInt8.self, forKey: .note),
                velocity: container.decode(UInt8.self, forKey: .velocity),
                tick: container.decode(Int.self, forKey: .tick)
            )
        case .noteOff:
            self = try .noteOff(
                channel: container.decode(UInt8.self, forKey: .channel),
                note: container.decode(UInt8.self, forKey: .note),
                velocity: container.decode(UInt8.self, forKey: .velocity),
                tick: container.decode(Int.self, forKey: .tick)
            )
        case .programChange:
            self = try .programChange(
                channel: container.decode(UInt8.self, forKey: .channel),
                program: container.decode(UInt8.self, forKey: .program),
                tick: container.decode(Int.self, forKey: .tick)
            )
        case .pitchBend:
            self = try .pitchBend(
                channel: container.decode(UInt8.self, forKey: .channel),
                value: container.decode(Int.self, forKey: .value),
                tick: container.decode(Int.self, forKey: .tick)
            )
        case .channelPressure:
            self = try .channelPressure(
                channel: container.decode(UInt8.self, forKey: .channel),
                pressure: container.decode(UInt8.self, forKey: .pressure),
                tick: container.decode(Int.self, forKey: .tick)
            )
        case .polyPressure:
            self = try .polyPressure(
                channel: container.decode(UInt8.self, forKey: .channel),
                note: container.decode(UInt8.self, forKey: .note),
                pressure: container.decode(UInt8.self, forKey: .pressure),
                tick: container.decode(Int.self, forKey: .tick)
            )
        case .controlChange:
            self = try .controlChange(
                channel: container.decode(UInt8.self, forKey: .channel),
                controller: container.decode(UInt8.self, forKey: .controller),
                value: container.decode(UInt8.self, forKey: .value),
                tick: container.decode(Int.self, forKey: .tick)
            )
        case .sysEx:
            self = try .sysEx(
                data: container.decode([UInt8].self, forKey: .data),
                tick: container.decode(Int.self, forKey: .tick)
            )
        }
    }
}
