import Foundation

public enum TimelineError: Error, Sendable, Equatable {
    case invalidBeat
    case invalidTick
    case beatOutOfRange(maxBeat: Int, provided: Int)
    case tickOutOfRange(maxTickExclusive: Int, provided: Int)
    case emptySegments
}

public struct TimeSignature: Sendable, Equatable {
    public var numerator: Int
    public var denominator: Int

    public init(numerator: Int = 4, denominator: Int = 4) {
        self.numerator = max(1, numerator)
        self.denominator = Self.isPowerOfTwo(denominator) ? denominator : 4
    }

    private static func isPowerOfTwo(_ value: Int) -> Bool {
        value > 0 && (value & (value - 1)) == 0
    }
}

public struct TimeSignatureChange: Sendable, Equatable {
    public var bar: Int
    public var signature: TimeSignature

    public init(bar: Int, signature: TimeSignature) {
        self.bar = max(1, bar)
        self.signature = signature
    }
}

public struct BarBeatTick: Sendable, Equatable {
    public var bar: Int
    public var beat: Int
    public var tick: Int

    public init(bar: Int, beat: Int, tick: Int) {
        self.bar = max(1, bar)
        self.beat = max(1, beat)
        self.tick = max(0, tick)
    }
}

public struct TimelineMapper: Sendable {
    public let ppqn: Int
    public let changes: [TimeSignatureChange]

    public init(ppqn: Int = Sequence.defaultPPQN, changes: [TimeSignatureChange] = []) {
        self.ppqn = max(1, ppqn)
        self.changes = Self.normalize(changes: changes)
    }

    public func ticksPerBeat(for signature: TimeSignature) -> Int {
        (ppqn * 4) / signature.denominator
    }

    public func ticksPerBar(for signature: TimeSignature) -> Int {
        ticksPerBeat(for: signature) * signature.numerator
    }

    public func toTick(_ position: BarBeatTick) -> Int {
        guard let tick = try? toTickValidated(position) else {
            return 0
        }
        return tick
    }

    public func toTickValidated(_ position: BarBeatTick) throws -> Int {
        guard position.beat > 0 else {
            throw TimelineError.invalidBeat
        }
        guard position.tick >= 0 else {
            throw TimelineError.invalidTick
        }

        var totalTicks = 0
        let segments = makeSegments()
        guard segments.isEmpty == false else {
            throw TimelineError.emptySegments
        }

        for (index, segment) in segments.enumerated() {
            let nextBar = index + 1 < segments.count ? segments[index + 1].startBar : nil

            if let nextBar, position.bar >= nextBar {
                totalTicks += (nextBar - segment.startBar) * ticksPerBar(for: segment.signature)
                continue
            }

            guard position.beat <= segment.signature.numerator else {
                throw TimelineError.beatOutOfRange(
                    maxBeat: segment.signature.numerator,
                    provided: position.beat
                )
            }
            let beatTicks = ticksPerBeat(for: segment.signature)
            guard position.tick < beatTicks else {
                throw TimelineError.tickOutOfRange(
                    maxTickExclusive: beatTicks,
                    provided: position.tick
                )
            }

            totalTicks += (position.bar - segment.startBar) * ticksPerBar(for: segment.signature)
            totalTicks += (position.beat - 1) * beatTicks
            totalTicks += position.tick
            return totalTicks
        }

        throw TimelineError.emptySegments
    }

    public func toBarBeatTick(tick absoluteTick: Int) -> BarBeatTick {
        guard let position = try? toBarBeatTickValidated(tick: absoluteTick) else {
            return BarBeatTick(bar: 1, beat: 1, tick: 0)
        }
        return position
    }

    public func toBarBeatTickValidated(tick absoluteTick: Int) throws -> BarBeatTick {
        guard absoluteTick >= 0 else {
            throw TimelineError.invalidTick
        }
        var remaining = absoluteTick
        let segments = makeSegments()
        guard segments.isEmpty == false else {
            throw TimelineError.emptySegments
        }

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

        throw TimelineError.emptySegments
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
