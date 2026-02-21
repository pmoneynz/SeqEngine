import Foundation

extension SequencerEngine {
    @discardableResult
    public mutating func playSong(at songIndex: Int) -> Bool {
        guard let initialState = initialSongPlayback(songIndex: songIndex) else {
            stop()
            return false
        }

        transport.mode = .playing
        transport.isWaitingForKey = false
        transport.countInRemainingTicks = 0
        transport.tickPosition = 0
        songPlayback = initialState
        updateSongTransportIndicators(initialState)
        return true
    }

    public func convertSongToSequence(songIndex: Int, sequenceName: String? = nil) throws -> Sequence {
        guard let song = songIfExists(index: songIndex) else {
            throw SongConversionError.songIndexOutOfRange
        }

        var destinationTracks: [Track] = []
        var destinationPPQN: Int?
        var timelineCursor = 0
        var materializedStepCount = 0

        for (stepIndex, step) in song.steps.enumerated() {
            if step.repeats == 0 {
                break
            }

            guard step.sequenceIndex >= 0, step.sequenceIndex < project.sequences.count else {
                throw SongConversionError.sequenceIndexOutOfRange(
                    stepIndex: stepIndex,
                    sequenceIndex: step.sequenceIndex
                )
            }

            let sourceSequence = project.sequences[step.sequenceIndex]
            if destinationPPQN == nil {
                destinationPPQN = sourceSequence.ppqn
            }
            let stepLength = max(1, sourceSequence.loopLengthTicks() ?? (sourceSequence.ppqn * 4))

            for _ in 0..<step.repeats {
                for (trackIndex, sourceTrack) in sourceSequence.tracks.enumerated() {
                    ensureDestinationTrackExists(
                        at: trackIndex,
                        in: &destinationTracks,
                        sourceTrack: sourceTrack
                    )
                    destinationTracks[trackIndex].events.append(
                        contentsOf: sourceTrack.events.map { $0.shifted(by: timelineCursor) }
                    )
                }
                timelineCursor += stepLength
                materializedStepCount += 1
            }
        }

        guard materializedStepCount > 0 else {
            throw SongConversionError.noMaterializedSteps
        }

        return Sequence(
            name: sequenceName ?? "\(song.name) Flattened",
            ppqn: destinationPPQN ?? Sequence.defaultPPQN,
            trackCapacity: max(Sequence.minTrackCapacity, destinationTracks.count),
            loopMode: .noLoop,
            tracks: destinationTracks
        )
    }

    func ensureDestinationTrackExists(
        at trackIndex: Int,
        in destinationTracks: inout [Track],
        sourceTrack: Track
    ) {
        guard trackIndex >= destinationTracks.count else {
            return
        }

        destinationTracks.append(
            Track(
                name: sourceTrack.name,
                kind: sourceTrack.kind,
                routing: sourceTrack.routing,
                events: []
            )
        )
    }

    mutating func advanceSongTransport(
        by ticks: Int,
        emit: ((ScheduledEvent) -> Void)?
    ) -> Bool {
        guard transport.isRunning, var state = songPlayback else {
            return false
        }

        var remainingTicks = ticks
        while remainingTicks > 0 {
            guard let song = songIfExists(index: state.songIndex),
                  state.stepIndex < song.steps.count else {
                stopSongPlayback()
                return true
            }

            let step = song.steps[state.stepIndex]
            guard step.repeats > 0,
                  step.sequenceIndex >= 0,
                  let stepLength = songStepLengthTicks(sequenceIndex: step.sequenceIndex) else {
                if !transitionToNextSongStep(from: &state, song: song) {
                    stopSongPlayback()
                    return true
                }
                songPlayback = state
                updateSongTransportIndicators(state)
                return true
            }

            let remainingInRepeat = max(1, stepLength - state.tickInRepeat)
            let consumed = min(remainingTicks, remainingInRepeat)

            if let emit {
                let sequence = project.sequences[step.sequenceIndex]
                emitScheduledEvents(
                    sequenceIndex: step.sequenceIndex,
                    sequence: sequence,
                    startTick: state.tickInRepeat,
                    duration: consumed,
                    loopLength: sequence.loopLengthTicks(),
                    emit: emit
                )
            }

            state.tickInRepeat += consumed
            remainingTicks -= consumed
            transport.tickPosition += consumed
            advanceCountIn(by: consumed)

            if state.tickInRepeat >= stepLength {
                state.tickInRepeat = 0
                if state.repeatIndex < (step.repeats - 1) {
                    state.repeatIndex += 1
                } else if !transitionToNextSongStep(from: &state, song: song) {
                    stopSongPlayback()
                    return true
                }
            }
        }

        songPlayback = state
        updateSongTransportIndicators(state)
        return true
    }

    mutating func transitionToNextSongStep(from state: inout SongPlaybackState, song: Song) -> Bool {
        let nextStepIndex = state.stepIndex + 1
        return moveToSongStepOrEnd(song: song, from: &state, desiredStepIndex: nextStepIndex)
    }

    mutating func moveToSongStepOrEnd(song: Song, from state: inout SongPlaybackState, desiredStepIndex: Int) -> Bool {
        guard desiredStepIndex < song.steps.count else {
            return handleSongEnd(song: song, state: &state)
        }

        let step = song.steps[desiredStepIndex]
        if step.repeats == 0 {
            return handleSongEnd(song: song, state: &state)
        }

        state.stepIndex = desiredStepIndex
        state.repeatIndex = 0
        state.tickInRepeat = 0
        return true
    }

    mutating func handleSongEnd(song: Song, state: inout SongPlaybackState) -> Bool {
        switch song.endBehavior {
        case .stopAtEnd:
            return false
        case let .loopToStep(loopStep):
            guard loopStep >= 0,
                  loopStep < song.steps.count,
                  song.steps[loopStep].repeats > 0 else {
                return false
            }
            state.stepIndex = loopStep
            state.repeatIndex = 0
            state.tickInRepeat = 0
            return true
        }
    }

    mutating func stopSongPlayback() {
        transport.mode = .stopped
        songPlayback = nil
        updateSongTransportIndicators(nil)
    }

    func initialSongPlayback(songIndex: Int) -> SongPlaybackState? {
        guard let song = songIfExists(index: songIndex) else {
            return nil
        }

        var state = SongPlaybackState(songIndex: songIndex, stepIndex: 0, repeatIndex: 0, tickInRepeat: 0)
        if song.steps.isEmpty {
            return nil
        }

        if song.steps[0].repeats == 0 {
            switch song.endBehavior {
            case .stopAtEnd:
                return nil
            case let .loopToStep(loopStep):
                guard loopStep >= 0,
                      loopStep < song.steps.count,
                      song.steps[loopStep].repeats > 0 else {
                    return nil
                }
                state.stepIndex = loopStep
            }
        }

        guard songStepLengthTicks(sequenceIndex: song.steps[state.stepIndex].sequenceIndex) != nil else {
            return nil
        }
        return state
    }

    func songIfExists(index: Int) -> Song? {
        guard index >= 0, index < project.songs.count else {
            return nil
        }
        return project.songs[index]
    }

    func songStepLengthTicks(sequenceIndex: Int) -> Int? {
        guard sequenceIndex >= 0, sequenceIndex < project.sequences.count else {
            return nil
        }

        let sequence = project.sequences[sequenceIndex]
        if let loopLength = sequence.loopLengthTicks(), loopLength > 0 {
            return loopLength
        }
        return max(1, sequence.ppqn * 4)
    }

    mutating func updateSongTransportIndicators(_ state: SongPlaybackState?) {
        transport.activeSongIndex = state?.songIndex
        transport.activeSongStepIndex = state?.stepIndex
        transport.activeSongRepeat = state.map { $0.repeatIndex + 1 }
    }
}
