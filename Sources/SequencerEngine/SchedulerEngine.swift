import Foundation

extension SequencerEngine {
    public mutating func advanceTransport(by ticks: Int) {
        advanceTransport(by: ticks, loopLengthOverride: nil)
    }

    public mutating func advanceTransport(
        by ticks: Int,
        sequenceIndex: Int? = nil,
        emit: @escaping (ScheduledEvent) -> Void
    ) {
        guard ticks > 0 else {
            return
        }

        if songPlayback != nil, transport.isRunning {
            _ = advanceSongTransport(by: ticks, emit: emit)
            return
        }

        let resolvedSequenceIndex = resolvedSequenceIndexForScheduling(explicitSequenceIndex: sequenceIndex)
        guard let resolvedSequenceIndex,
              resolvedSequenceIndex >= 0,
              resolvedSequenceIndex < project.sequences.count,
              transport.isRunning else {
            advanceTransport(by: ticks)
            return
        }

        let sequence = project.sequences[resolvedSequenceIndex]
        let sequenceLoopLength = sequence.loopLengthTicks()
        emitScheduledEvents(
            sequenceIndex: resolvedSequenceIndex,
            sequence: sequence,
            startTick: transport.tickPosition,
            duration: ticks,
            loopLength: sequenceLoopLength,
            emit: emit
        )
        advanceTransport(by: ticks, loopLengthOverride: sequenceLoopLength)
    }

    mutating func advanceTransport(by ticks: Int, loopLengthOverride: Int?) {
        guard ticks > 0 else {
            return
        }

        if advanceSongTransport(by: ticks, emit: nil) {
            return
        }

        let resolvedLoopLength = loopLengthOverride ?? activeLoopLengthTicks()
        if transport.isRunning, let loopLength = resolvedLoopLength, loopLength > 0 {
            transport.tickPosition = (transport.tickPosition + ticks) % loopLength
        } else {
            transport.tickPosition += ticks
        }

        advanceCountIn(by: ticks)
    }

    /// Compatibility API that preserves prior array-returning behavior.
    /// Prefer `advanceTransport(by:sequenceIndex:emit:)` for realtime paths.
    public mutating func advanceTransportAndCollectScheduledEvents(
        by ticks: Int,
        sequenceIndex: Int? = nil
    ) -> [ScheduledEvent] {
        var scheduled: [ScheduledEvent] = []
        advanceTransport(by: ticks, sequenceIndex: sequenceIndex) { event in
            scheduled.append(event)
        }
        return scheduled
    }

    func activeLoopLengthTicks() -> Int? {
        project.sequences.first?.loopLengthTicks()
    }

    func resolvedSequenceIndexForScheduling(explicitSequenceIndex: Int?) -> Int? {
        if let explicitSequenceIndex {
            return explicitSequenceIndex
        }
        if project.sequences.isEmpty == false {
            return 0
        }
        return nil
    }

    mutating func emitScheduledEvents(
        sequenceIndex: Int,
        sequence: Sequence,
        startTick: Int,
        duration: Int,
        loopLength: Int?,
        emit: (ScheduledEvent) -> Void
    ) {
        let clampedStartTick = max(0, startTick)
        var remaining = max(0, duration)
        guard remaining > 0 else {
            return
        }

        let trackCount = sequence.tracks.count
        if schedulingMergeCursors.count < trackCount {
            schedulingMergeCursors.append(contentsOf: repeatElement(0, count: trackCount - schedulingMergeCursors.count))
        }

        var rangeStart = clampedStartTick
        var wrappedStart = loopLength.map { clampedStartTick % max(1, $0) } ?? clampedStartTick
        var consumedBeforeCurrentRange = 0

        while remaining > 0 {
            let rangeEnd: Int
            let segmentDuration: Int
            if let loopLength, loopLength > 0 {
                let ticksUntilWrap = max(1, loopLength - wrappedStart)
                let consumed = min(remaining, ticksUntilWrap)
                rangeEnd = wrappedStart + consumed
                segmentDuration = consumed
                rangeStart = wrappedStart
                wrappedStart = (wrappedStart + consumed) % loopLength
                remaining -= consumed
            } else {
                rangeEnd = rangeStart + remaining
                segmentDuration = remaining
                remaining = 0
            }

            for trackIndex in sequence.tracks.indices {
                guard trackIndex < schedulingMergeCursors.count else {
                    continue
                }
                let track = sequence.tracks[trackIndex]
                schedulingMergeCursors[trackIndex] = firstEventIndex(in: track.events, atOrAfter: rangeStart)
            }

            while true {
                var bestTrackIndex = -1
                var bestEventIndex = 0
                var bestTick = Int.max

                for trackIndex in sequence.tracks.indices {
                    guard trackIndex < schedulingMergeCursors.count else {
                        continue
                    }
                    let track = sequence.tracks[trackIndex]
                    let eventIndex = schedulingMergeCursors[trackIndex]
                    guard eventIndex < track.events.count else {
                        continue
                    }
                    let event = track.events[eventIndex]
                    guard event.tick < rangeEnd else {
                        continue
                    }
                    if event.tick < bestTick ||
                        (event.tick == bestTick && (bestTrackIndex == -1 || trackIndex < bestTrackIndex)) {
                        bestTrackIndex = trackIndex
                        bestEventIndex = eventIndex
                        bestTick = event.tick
                    }
                }

                guard bestTrackIndex >= 0 else {
                    break
                }
                guard bestTrackIndex < sequence.tracks.count else {
                    break
                }

                let track = sequence.tracks[bestTrackIndex]
                guard bestEventIndex < track.events.count else {
                    schedulingMergeCursors[bestTrackIndex] = track.events.count
                    continue
                }
                let event = track.events[bestEventIndex]
                emit(
                    ScheduledEvent(
                        sequenceIndex: sequenceIndex,
                        trackIndex: bestTrackIndex,
                        eventIndex: bestEventIndex,
                        event: event,
                        windowOffsetTicks: consumedBeforeCurrentRange + max(0, event.tick - rangeStart)
                    )
                )
                schedulingMergeCursors[bestTrackIndex] = bestEventIndex + 1
            }

            if loopLength == nil {
                break
            }
            consumedBeforeCurrentRange += segmentDuration
        }
    }

    func firstEventIndex(in events: [MIDIEvent], atOrAfter tick: Int) -> Int {
        var low = 0
        var high = events.count
        while low < high {
            let mid = (low + high) / 2
            if events[mid].tick < tick {
                low = mid + 1
            } else {
                high = mid
            }
        }
        return low
    }
}
