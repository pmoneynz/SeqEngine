import Foundation

public struct TimeSignature: Sendable, Equatable {
    public var numerator: Int
    public var denominator: Int

    public init(numerator: Int = 4, denominator: Int = 4) {
        precondition(numerator > 0, "Time signature numerator must be > 0.")
        precondition(denominator > 0, "Time signature denominator must be > 0.")
        precondition((denominator & (denominator - 1)) == 0, "Time signature denominator must be a power of two.")

        self.numerator = numerator
        self.denominator = denominator
    }
}

public struct TimeSignatureChange: Sendable, Equatable {
    public var bar: Int
    public var signature: TimeSignature

    public init(bar: Int, signature: TimeSignature) {
        precondition(bar > 0, "Time signature change bar must be >= 1.")
        self.bar = bar
        self.signature = signature
    }
}

public struct BarBeatTick: Sendable, Equatable {
    public var bar: Int
    public var beat: Int
    public var tick: Int

    public init(bar: Int, beat: Int, tick: Int) {
        precondition(bar > 0, "Bar must be >= 1.")
        precondition(beat > 0, "Beat must be >= 1.")
        precondition(tick >= 0, "Tick must be >= 0.")
        self.bar = bar
        self.beat = beat
        self.tick = tick
    }
}

public struct TimelineMapper: Sendable {
    public let ppqn: Int
    public let changes: [TimeSignatureChange]

    public init(ppqn: Int = Sequence.defaultPPQN, changes: [TimeSignatureChange] = []) {
        precondition(ppqn > 0, "PPQN must be > 0.")
        self.ppqn = ppqn
        self.changes = Self.normalize(changes: changes)
    }

    public func ticksPerBeat(for signature: TimeSignature) -> Int {
        (ppqn * 4) / signature.denominator
    }

    public func ticksPerBar(for signature: TimeSignature) -> Int {
        ticksPerBeat(for: signature) * signature.numerator
    }

    public func toTick(_ position: BarBeatTick) -> Int {
        var totalTicks = 0
        let segments = makeSegments()

        for (index, segment) in segments.enumerated() {
            let nextBar = index + 1 < segments.count ? segments[index + 1].startBar : nil

            if let nextBar, position.bar >= nextBar {
                totalTicks += (nextBar - segment.startBar) * ticksPerBar(for: segment.signature)
                continue
            }

            precondition(position.beat <= segment.signature.numerator, "Beat out of range for current bar signature.")
            let beatTicks = ticksPerBeat(for: segment.signature)
            precondition(position.tick < beatTicks, "Tick out of range for beat resolution.")

            totalTicks += (position.bar - segment.startBar) * ticksPerBar(for: segment.signature)
            totalTicks += (position.beat - 1) * beatTicks
            totalTicks += position.tick
            return totalTicks
        }

        fatalError("Unreachable timeline conversion state.")
    }

    public func toBarBeatTick(tick absoluteTick: Int) -> BarBeatTick {
        precondition(absoluteTick >= 0, "Absolute tick must be >= 0.")

        var remaining = absoluteTick
        let segments = makeSegments()

        for (index, segment) in segments.enumerated() {
            let barTicks = ticksPerBar(for: segment.signature)
            let beatTicks = ticksPerBeat(for: segment.signature)
            let nextBar = index + 1 < segments.count ? segments[index + 1].startBar : nil

            if let nextBar {
                let segmentTicks = (nextBar - segment.startBar) * barTicks
                if remaining >= segmentTicks {
                    remaining -= segmentTicks
                    continue
                }
            }

            let barOffset = remaining / barTicks
            let withinBar = remaining % barTicks
            let beatOffset = withinBar / beatTicks
            let tickInBeat = withinBar % beatTicks

            return BarBeatTick(
                bar: segment.startBar + barOffset,
                beat: beatOffset + 1,
                tick: tickInBeat
            )
        }

        fatalError("Unreachable timeline conversion state.")
    }

    private func makeSegments() -> [(startBar: Int, signature: TimeSignature)] {
        var result: [(startBar: Int, signature: TimeSignature)] = []
        for change in changes {
            if let last = result.last, last.startBar == change.bar {
                result[result.count - 1] = (change.bar, change.signature)
            } else {
                result.append((change.bar, change.signature))
            }
        }
        return result
    }

    private static func normalize(changes: [TimeSignatureChange]) -> [TimeSignatureChange] {
        let ordered = changes.enumerated().sorted { lhs, rhs in
            if lhs.element.bar == rhs.element.bar {
                return lhs.offset < rhs.offset
            }
            return lhs.element.bar < rhs.element.bar
        }
        .map(\.element)

        var normalized: [TimeSignatureChange] = []
        for change in ordered {
            if normalized.last?.bar == change.bar {
                normalized[normalized.count - 1] = change
            } else {
                normalized.append(change)
            }
        }

        if normalized.first?.bar != 1 {
            normalized.insert(TimeSignatureChange(bar: 1, signature: TimeSignature()), at: 0)
        }

        return normalized
    }
}
