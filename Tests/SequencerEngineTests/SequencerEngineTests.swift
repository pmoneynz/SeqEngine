import XCTest
@testable import SequencerEngine

final class SequencerEngineTests: XCTestCase {
    func testEngineDefaultProject() {
        let engine = SequencerEngine()
        XCTAssertTrue(engine.project.sequences.isEmpty)
        XCTAssertTrue(engine.project.songs.isEmpty)
        XCTAssertEqual(engine.transport.mode, .stopped)
        XCTAssertEqual(engine.transport.tickPosition, 0)
    }

    func testTransportPlayStopLocateBehaviors() {
        var engine = SequencerEngine()

        engine.play()
        XCTAssertEqual(engine.transport.mode, .playing)
        XCTAssertTrue(engine.transport.isRunning)

        engine.locate(tick: 960)
        XCTAssertEqual(engine.transport.tickPosition, 960)

        engine.locate(tick: -42)
        XCTAssertEqual(engine.transport.tickPosition, 0)

        engine.stop()
        XCTAssertEqual(engine.transport.mode, .stopped)
        XCTAssertFalse(engine.transport.isRunning)
    }

    func testTransportRecordAndOverdubBehaviors() {
        var engine = SequencerEngine()

        engine.record()
        XCTAssertEqual(engine.transport.mode, .recording)
        XCTAssertTrue(engine.transport.isRunning)

        engine.overdub()
        XCTAssertEqual(engine.transport.mode, .overdubbing)
        XCTAssertTrue(engine.transport.isRunning)

        engine.play()
        XCTAssertEqual(engine.transport.mode, .playing)
        XCTAssertTrue(engine.transport.isRunning)

        engine.stop()
        XCTAssertEqual(engine.transport.mode, .stopped)
        XCTAssertFalse(engine.transport.isRunning)
    }

    func testRecordReadyDefaultsDisabled() {
        let engine = SequencerEngine()
        XCTAssertFalse(engine.transport.isRecordReady)
    }

    func testPunchInRequiresPlayAndRecordReady() {
        var engine = SequencerEngine()

        engine.play()
        XCTAssertFalse(engine.punchIn(.record))
        XCTAssertEqual(engine.transport.mode, .playing)

        engine.stop()
        engine.setRecordReady(true)
        XCTAssertFalse(engine.punchIn(.record))
        XCTAssertEqual(engine.transport.mode, .stopped)
    }

    func testPunchInTransitionsWhenRecordReady() {
        var engine = SequencerEngine()
        engine.setRecordReady(true)
        engine.play()

        XCTAssertTrue(engine.punchIn(.record))
        XCTAssertEqual(engine.transport.mode, .recording)

        XCTAssertTrue(engine.punchOut())
        XCTAssertEqual(engine.transport.mode, .playing)

        XCTAssertTrue(engine.punchIn(.overdub))
        XCTAssertEqual(engine.transport.mode, .overdubbing)

        XCTAssertTrue(engine.punchOut())
        XCTAssertEqual(engine.transport.mode, .playing)
    }

    func testWaitForKeyArmsWithoutStartingPlaybackOrRecord() {
        var engine = SequencerEngine()

        engine.armWaitForKey()

        XCTAssertEqual(engine.transport.mode, .stopped)
        XCTAssertTrue(engine.transport.isWaitingForKey)
        XCTAssertFalse(engine.transport.isRunning)
    }

    func testWaitForKeyStartsRecordingOnFirstKeyPressAndSkipsTriggerKey() {
        var engine = SequencerEngine()
        engine.armWaitForKey()

        let trigger = MIDIEvent.noteOn(channel: 0, note: 60, velocity: 100, tick: 0)
        XCTAssertNil(engine.handleIncomingMIDI(trigger))
        XCTAssertEqual(engine.transport.mode, .recording)
        XCTAssertFalse(engine.transport.isWaitingForKey)

        let captured = MIDIEvent.noteOn(channel: 0, note: 64, velocity: 110, tick: 24)
        XCTAssertEqual(engine.handleIncomingMIDI(captured), captured)
    }

    func testWaitForKeyIgnoresNonKeyMessagesBeforeTrigger() {
        var engine = SequencerEngine()
        engine.armWaitForKey()

        let cc = MIDIEvent.controlChange(channel: 0, controller: 1, value: 127, tick: 0)
        XCTAssertNil(engine.handleIncomingMIDI(cc))
        XCTAssertTrue(engine.transport.isWaitingForKey)
        XCTAssertEqual(engine.transport.mode, .stopped)
    }

    func testCountInArmsSingleBarPreRollAtNinetySixPPQN() {
        var engine = SequencerEngine()

        engine.armCountIn()

        XCTAssertEqual(engine.transport.mode, .recording)
        XCTAssertTrue(engine.transport.isCountInActive)
        XCTAssertEqual(engine.transport.countInRemainingTicks, 384)
        XCTAssertTrue(engine.transport.isRunning)
    }

    func testCountInSuppressesRecordingUntilPreRollCompletes() {
        var engine = SequencerEngine()
        engine.armCountIn()

        let duringCountIn = MIDIEvent.noteOn(channel: 0, note: 60, velocity: 100, tick: 0)
        XCTAssertNil(engine.handleIncomingMIDI(duringCountIn))

        engine.advanceTransport(by: 383)
        XCTAssertTrue(engine.transport.isCountInActive)
        XCTAssertNil(engine.handleIncomingMIDI(duringCountIn))

        engine.advanceTransport(by: 1)
        XCTAssertFalse(engine.transport.isCountInActive)

        let captured = MIDIEvent.noteOn(channel: 0, note: 64, velocity: 100, tick: 384)
        XCTAssertEqual(engine.handleIncomingMIDI(captured), captured)
    }

    func testTransportLoopsToConfiguredBarWhenRunning() {
        var loopingSequence = Sequence()
        loopingSequence.setLoopToBar(4)
        let project = Project(sequences: [loopingSequence])
        var engine = SequencerEngine(project: project)

        engine.play()
        engine.locate(tick: 1_520)
        engine.advanceTransport(by: 40)

        XCTAssertEqual(engine.transport.tickPosition, 24)
    }

    func testTransportDoesNotLoopWhenNoLoopModeIsSet() {
        let project = Project(sequences: [Sequence()])
        var engine = SequencerEngine(project: project)

        engine.play()
        engine.locate(tick: 1_520)
        engine.advanceTransport(by: 40)

        XCTAssertEqual(engine.transport.tickPosition, 1_560)
    }

    func testSchedulingAndTransportUseResolvedSequenceLoopLengthWhenSequenceIndexProvided() {
        var first = Sequence(name: "Long")
        first.setLoopToBar(3) // 1,152 ticks at default PPQN.

        var second = Sequence(name: "Short")
        second.setLoopToBar(2) // 768 ticks at default PPQN.
        second.tracks = [
            Track(
                kind: .midi,
                events: [
                    .noteOn(channel: 0, note: 60, velocity: 100, tick: 0)
                ]
            )
        ]

        let project = Project(sequences: [first, second])
        var engine = SequencerEngine(project: project)
        engine.play()
        engine.locate(tick: 760)

        _ = engine.advanceTransportAndCollectScheduledEvents(by: 20, sequenceIndex: 1)

        XCTAssertEqual(engine.transport.tickPosition, 12)
    }

    func testTempoSourceDefaultsToSequenceTempo() {
        let sequence = Sequence(tempoBPM: 98.0)
        let project = Project(sequences: [sequence], masterTempoBPM: 132.0)
        let engine = SequencerEngine(project: project)

        XCTAssertEqual(engine.effectiveTempoBPM(), 98.0)
    }

    func testTempoSourceCanSelectMasterTempo() {
        let sequence = Sequence(tempoBPM: 96.0)
        let project = Project(sequences: [sequence], masterTempoBPM: 128.0, tempoSource: .master)
        let engine = SequencerEngine(project: project)

        XCTAssertEqual(engine.effectiveTempoBPM(), 128.0)
    }

    func testTempoSourceCanSelectMasterAtRuntime() {
        let sequence = Sequence(tempoBPM: 104.0)
        let project = Project(sequences: [sequence], masterTempoBPM: 140.0)
        var engine = SequencerEngine(project: project)

        XCTAssertEqual(engine.effectiveTempoBPM(), 104.0)
        engine.setTempoSource(.master)
        XCTAssertEqual(engine.effectiveTempoBPM(), 140.0)
    }

    func testEffectiveTempoUsesExplicitSequenceIndexWhenProvided() {
        let first = Sequence(name: "A", tempoBPM: 90.0)
        let second = Sequence(name: "B", tempoBPM: 123.0)
        let project = Project(sequences: [first, second], masterTempoBPM: 150.0, tempoSource: .sequence)
        let engine = SequencerEngine(project: project)

        XCTAssertEqual(engine.effectiveTempoBPM(sequenceIndex: 1), 123.0)
    }

    func testEffectiveTempoFallsBackToMasterWhenNoSequenceExists() {
        let project = Project(sequences: [], songs: [], masterTempoBPM: 111.0, tempoSource: .sequence)
        let engine = SequencerEngine(project: project)

        XCTAssertEqual(engine.effectiveTempoBPM(), 111.0)
    }

    func testMidSequenceTempoChangesCanBeInsertedAndListedInTickOrder() {
        let sequence = Sequence(tempoBPM: 100.0)
        var engine = SequencerEngine(project: Project(sequences: [sequence]))

        let late = engine.insertTempoChange(sequenceIndex: 0, tick: 192, bpm: 130.0)
        let early = engine.insertTempoChange(sequenceIndex: 0, tick: 96, bpm: 110.0)
        let clamped = engine.insertTempoChange(sequenceIndex: 0, tick: -12, bpm: 0.5)

        XCTAssertNotNil(late)
        XCTAssertNotNil(early)
        XCTAssertNotNil(clamped)

        let listed = engine.listTempoChanges(sequenceIndex: 0)
        XCTAssertEqual(listed.map(\.tick), [0, 96, 192])
        XCTAssertEqual(listed.map(\.bpm), [1.0, 110.0, 130.0])
    }

    func testMidSequenceTempoChangeToggleOnOffAffectsEffectiveTempo() {
        let sequence = Sequence(tempoBPM: 100.0)
        var engine = SequencerEngine(project: Project(sequences: [sequence]))

        let first = engine.insertTempoChange(sequenceIndex: 0, tick: 96, bpm: 115.0)
        let second = engine.insertTempoChange(sequenceIndex: 0, tick: 192, bpm: 140.0)

        XCTAssertEqual(engine.effectiveTempoBPM(sequenceIndex: 0, tick: 200), 140.0)
        XCTAssertTrue(engine.setTempoChangeEnabled(sequenceIndex: 0, tempoChangeID: second!.id, false))
        XCTAssertEqual(engine.effectiveTempoBPM(sequenceIndex: 0, tick: 200), 115.0)
        XCTAssertTrue(engine.setTempoChangeEnabled(sequenceIndex: 0, tempoChangeID: first!.id, false))
        XCTAssertEqual(engine.effectiveTempoBPM(sequenceIndex: 0, tick: 200), 100.0)
        XCTAssertTrue(engine.setTempoChangeEnabled(sequenceIndex: 0, tempoChangeID: first!.id, true))
        XCTAssertEqual(engine.effectiveTempoBPM(sequenceIndex: 0, tick: 200), 115.0)
    }

    func testMidSequenceTempoChangeCanBeDeleted() {
        let sequence = Sequence(tempoBPM: 100.0)
        var engine = SequencerEngine(project: Project(sequences: [sequence]))

        let first = engine.insertTempoChange(sequenceIndex: 0, tick: 96, bpm: 115.0)!
        let second = engine.insertTempoChange(sequenceIndex: 0, tick: 192, bpm: 140.0)!

        XCTAssertEqual(engine.listTempoChanges(sequenceIndex: 0).count, 2)
        XCTAssertTrue(engine.deleteTempoChange(sequenceIndex: 0, tempoChangeID: first.id))
        XCTAssertEqual(engine.listTempoChanges(sequenceIndex: 0).map(\.id), [second.id])
        XCTAssertFalse(engine.deleteTempoChange(sequenceIndex: 0, tempoChangeID: first.id))
    }

    func testListTempoChangesCanExcludeDisabledEntries() {
        let sequence = Sequence(tempoBPM: 100.0)
        var engine = SequencerEngine(project: Project(sequences: [sequence]))

        let enabled = engine.insertTempoChange(sequenceIndex: 0, tick: 96, bpm: 115.0)!
        let disabled = engine.insertTempoChange(sequenceIndex: 0, tick: 192, bpm: 140.0, isEnabled: false)!

        XCTAssertEqual(engine.listTempoChanges(sequenceIndex: 0, includeDisabled: true).map(\.id), [enabled.id, disabled.id])
        XCTAssertEqual(engine.listTempoChanges(sequenceIndex: 0, includeDisabled: false).map(\.id), [enabled.id])
    }

    func testTapTempoTwoTapAverageAppliesToActiveSequenceTempo() {
        let sequence = Sequence(tempoBPM: 90.0)
        var engine = SequencerEngine(project: Project(sequences: [sequence], tempoSource: .sequence))

        XCTAssertNil(engine.registerTapTempoTap(mode: .taps2, at: 0.0))
        let bpm = engine.registerTapTempoTap(mode: .taps2, at: 0.5)
        XCTAssertNotNil(bpm)
        XCTAssertEqual(bpm!, 120.0, accuracy: 0.0001)
        XCTAssertEqual(engine.effectiveTempoBPM(sequenceIndex: 0), 120.0, accuracy: 0.0001)
    }

    func testTapTempoThreeTapAverageUsesTwoIntervals() {
        let sequence = Sequence(tempoBPM: 80.0)
        var engine = SequencerEngine(project: Project(sequences: [sequence], tempoSource: .sequence))

        XCTAssertNil(engine.registerTapTempoTap(mode: .taps3, at: 0.0))
        XCTAssertNil(engine.registerTapTempoTap(mode: .taps3, at: 0.5))
        let bpm = engine.registerTapTempoTap(mode: .taps3, at: 1.0)
        XCTAssertNotNil(bpm)
        XCTAssertEqual(bpm!, 120.0, accuracy: 0.0001)
        XCTAssertEqual(engine.effectiveTempoBPM(sequenceIndex: 0), 120.0, accuracy: 0.0001)
    }

    func testTapTempoFourTapAverageUsesThreeIntervals() {
        var engine = SequencerEngine(project: Project(masterTempoBPM: 95.0, tempoSource: .master))

        XCTAssertNil(engine.registerTapTempoTap(mode: .taps4, at: 0.0))
        XCTAssertNil(engine.registerTapTempoTap(mode: .taps4, at: 0.48))
        XCTAssertNil(engine.registerTapTempoTap(mode: .taps4, at: 0.98))
        let bpm = engine.registerTapTempoTap(mode: .taps4, at: 1.5)
        XCTAssertNotNil(bpm)
        XCTAssertEqual(bpm!, 120.0, accuracy: 0.0001)
        XCTAssertEqual(engine.effectiveTempoBPM(), 120.0, accuracy: 0.0001)
    }

    func testTapTempoRequiresMonotonicTapTimesAndCanResetHistory() {
        let sequence = Sequence(tempoBPM: 100.0)
        var engine = SequencerEngine(project: Project(sequences: [sequence], tempoSource: .sequence))

        XCTAssertNil(engine.registerTapTempoTap(mode: .taps2, at: 1.0))
        XCTAssertNil(engine.registerTapTempoTap(mode: .taps2, at: 0.9))
        let resetWindowBPM = engine.registerTapTempoTap(mode: .taps2, at: 1.3)
        XCTAssertNotNil(resetWindowBPM)
        XCTAssertEqual(resetWindowBPM!, 150.0, accuracy: 0.0001)
        let twoTapBPM = engine.registerTapTempoTap(mode: .taps2, at: 1.8)
        XCTAssertNotNil(twoTapBPM)
        XCTAssertEqual(twoTapBPM!, 120.0, accuracy: 0.0001)

        engine.clearTapTempoHistory()
        XCTAssertNil(engine.registerTapTempoTap(mode: .taps3, at: 2.0))
        XCTAssertNil(engine.registerTapTempoTap(mode: .taps3, at: 2.5))
        let threeTapBPM = engine.registerTapTempoTap(mode: .taps3, at: 3.0)
        XCTAssertNotNil(threeTapBPM)
        XCTAssertEqual(threeTapBPM!, 120.0, accuracy: 0.0001)
    }

    func testSequenceConstants() {
        XCTAssertEqual(Sequence.defaultPPQN, 96)
        XCTAssertEqual(Sequence.minTrackCapacity, 32)
        XCTAssertEqual(Sequence.maxTrackCapacity, 99)
    }

    func testSequenceDefaultTrackCapacity() {
        let sequence = Sequence()
        XCTAssertEqual(sequence.trackCapacity, 32)
    }

    func testSequenceLoopDefaultsToNoLoopMode() {
        let sequence = Sequence()
        XCTAssertEqual(sequence.loopMode, .noLoop)
        XCTAssertNil(sequence.loopLengthTicks())
    }

    func testSequenceLoopToBarUsesNinetySixPPQNBarLength() {
        var sequence = Sequence(ppqn: 96)
        sequence.setLoopToBar(4)

        XCTAssertEqual(sequence.loopMode, .loopToBar(4))
        XCTAssertEqual(sequence.loopLengthTicks(), 1_536)
    }

    func testSequencePPQNIsClampedToPositiveValueAtInitialization() {
        var zero = Sequence(ppqn: 0)
        zero.setLoopToBar(1)
        XCTAssertEqual(zero.ppqn, 1)
        XCTAssertEqual(zero.loopLengthTicks(), 4)

        var negative = Sequence(ppqn: -24)
        negative.setLoopToBar(1)
        XCTAssertEqual(negative.ppqn, 1)
        XCTAssertEqual(negative.loopLengthTicks(), 4)
    }

    func testSequenceCanRaiseCapacityToNinetyNineTracks() throws {
        var sequence = Sequence()
        try sequence.setTrackCapacity(99)

        for i in 1...99 {
            try sequence.addTrack(Track(name: "Track \(i)"))
        }

        XCTAssertEqual(sequence.trackCapacity, 99)
        XCTAssertEqual(sequence.tracks.count, 99)
        XCTAssertThrowsError(try sequence.addTrack(Track(name: "Overflow"))) { error in
            XCTAssertEqual(error as? Sequence.CapacityError, .trackLimitReached)
        }
    }

    func testSequenceRejectsOutOfRangeCapacity() {
        var sequence = Sequence()
        XCTAssertThrowsError(try sequence.setTrackCapacity(31)) { error in
            XCTAssertEqual(error as? Sequence.CapacityError, .outOfRange)
        }
        XCTAssertThrowsError(try sequence.setTrackCapacity(100)) { error in
            XCTAssertEqual(error as? Sequence.CapacityError, .outOfRange)
        }
    }

    func testProjectSupportsNinetyNineSequencesAndRejectsOverflow() throws {
        var project = Project()

        for i in 1...Project.maxSequences {
            try project.addSequence(Sequence(name: "Sequence \(i)"))
        }

        XCTAssertEqual(project.sequences.count, Project.maxSequences)
        XCTAssertThrowsError(try project.addSequence(Sequence(name: "Overflow"))) { error in
            XCTAssertEqual(error as? Project.CapacityError, .sequenceLimitReached)
        }
    }

    func testProjectSupportsTwentySongsAndRejectsOverflow() throws {
        var project = Project()

        for i in 1...Project.maxSongs {
            try project.addSong(Song(name: "Song \(i)"))
        }

        XCTAssertEqual(project.songs.count, Project.maxSongs)
        XCTAssertThrowsError(try project.addSong(Song(name: "Overflow"))) { error in
            XCTAssertEqual(error as? Project.CapacityError, .songLimitReached)
        }
    }

    func testSongSupportsTwoHundredFiftyStepsAndRejectsOverflow() throws {
        var song = Song()

        for i in 0..<Song.maxSteps {
            try song.addStep(SongStep(sequenceIndex: i, repeats: 1))
        }

        XCTAssertEqual(song.steps.count, Song.maxSteps)
        XCTAssertThrowsError(try song.addStep(SongStep(sequenceIndex: 999, repeats: 1))) { error in
            XCTAssertEqual(error as? Song.CapacityError, .stepLimitReached)
        }
    }

    func testSongModeRespectsStepRepetitionsBeforeAdvancing() {
        var firstSequence = Sequence(name: "A")
        firstSequence.setLoopToBar(1)
        var secondSequence = Sequence(name: "B")
        secondSequence.setLoopToBar(1)

        let song = Song(
            steps: [
                SongStep(sequenceIndex: 0, repeats: 2),
                SongStep(sequenceIndex: 1, repeats: 1)
            ],
            endBehavior: .stopAtEnd
        )
        let project = Project(sequences: [firstSequence, secondSequence], songs: [song])
        var engine = SequencerEngine(project: project)

        XCTAssertTrue(engine.playSong(at: 0))
        XCTAssertEqual(engine.transport.activeSongStepIndex, 0)
        XCTAssertEqual(engine.transport.activeSongRepeat, 1)

        engine.advanceTransport(by: 384)
        XCTAssertEqual(engine.transport.activeSongStepIndex, 0)
        XCTAssertEqual(engine.transport.activeSongRepeat, 2)

        engine.advanceTransport(by: 384)
        XCTAssertEqual(engine.transport.activeSongStepIndex, 1)
        XCTAssertEqual(engine.transport.activeSongRepeat, 1)
    }

    func testSongModeHonorsZeroRepeatsAsEndMarkerAndStops() {
        var sequence = Sequence(name: "A")
        sequence.setLoopToBar(1)
        let song = Song(
            steps: [
                SongStep(sequenceIndex: 0, repeats: 1),
                SongStep(sequenceIndex: 0, repeats: 0)
            ],
            endBehavior: .stopAtEnd
        )
        let project = Project(sequences: [sequence], songs: [song])
        var engine = SequencerEngine(project: project)

        XCTAssertTrue(engine.playSong(at: 0))
        engine.advanceTransport(by: 384)

        XCTAssertEqual(engine.transport.mode, .stopped)
        XCTAssertNil(engine.transport.activeSongIndex)
        XCTAssertNil(engine.transport.activeSongStepIndex)
    }

    func testSongModeLoopsToConfiguredStepAtEndMarker() {
        var sequence = Sequence(name: "A")
        sequence.setLoopToBar(1)
        let song = Song(
            steps: [
                SongStep(sequenceIndex: 0, repeats: 1),
                SongStep(sequenceIndex: 0, repeats: 1),
                SongStep(sequenceIndex: 0, repeats: 0)
            ],
            endBehavior: .loopToStep(1)
        )
        let project = Project(sequences: [sequence], songs: [song])
        var engine = SequencerEngine(project: project)

        XCTAssertTrue(engine.playSong(at: 0))
        engine.advanceTransport(by: 384)
        XCTAssertEqual(engine.transport.activeSongStepIndex, 1)

        engine.advanceTransport(by: 384)
        XCTAssertEqual(engine.transport.mode, .playing)
        XCTAssertEqual(engine.transport.activeSongStepIndex, 1)
        XCTAssertEqual(engine.transport.activeSongRepeat, 1)
    }

    func testSongModeStopsAfterLastStepWhenStopAtEndEnabled() {
        var sequence = Sequence(name: "A")
        sequence.setLoopToBar(1)
        let song = Song(
            steps: [SongStep(sequenceIndex: 0, repeats: 1)],
            endBehavior: .stopAtEnd
        )
        let project = Project(sequences: [sequence], songs: [song])
        var engine = SequencerEngine(project: project)

        XCTAssertTrue(engine.playSong(at: 0))
        engine.advanceTransport(by: 384)

        XCTAssertEqual(engine.transport.mode, .stopped)
        XCTAssertNil(engine.transport.activeSongIndex)
    }

    func testSongToSequenceConversionProducesContiguousTimelineAndPreservesOrdering() throws {
        var first = Sequence(name: "Verse")
        first.setLoopToBar(1)
        first.tracks = [
            Track(
                name: "Lead",
                kind: .midi,
                events: [
                    .controlChange(channel: 0, controller: 1, value: 64, tick: 24),
                    .noteOn(channel: 0, note: 60, velocity: 100, tick: 24),
                    .noteOff(channel: 0, note: 60, velocity: 0, tick: 120)
                ]
            )
        ]

        var second = Sequence(name: "Fill")
        second.setLoopToBar(1)
        second.tracks = [
            Track(
                name: "Lead",
                kind: .midi,
                events: [
                    .noteOn(channel: 0, note: 67, velocity: 100, tick: 12),
                    .noteOff(channel: 0, note: 67, velocity: 0, tick: 60)
                ]
            )
        ]

        let song = Song(
            name: "Arrangement",
            steps: [
                SongStep(sequenceIndex: 0, repeats: 2),
                SongStep(sequenceIndex: 1, repeats: 1)
            ],
            endBehavior: .stopAtEnd
        )

        let project = Project(sequences: [first, second], songs: [song])
        let engine = SequencerEngine(project: project)

        let flattened = try engine.convertSongToSequence(songIndex: 0)

        XCTAssertEqual(flattened.name, "Arrangement Flattened")
        XCTAssertEqual(flattened.tracks.count, 1)
        XCTAssertEqual(
            flattened.tracks[0].events,
            [
                .controlChange(channel: 0, controller: 1, value: 64, tick: 24),
                .noteOn(channel: 0, note: 60, velocity: 100, tick: 24),
                .noteOff(channel: 0, note: 60, velocity: 0, tick: 120),
                .controlChange(channel: 0, controller: 1, value: 64, tick: 408),
                .noteOn(channel: 0, note: 60, velocity: 100, tick: 408),
                .noteOff(channel: 0, note: 60, velocity: 0, tick: 504),
                .noteOn(channel: 0, note: 67, velocity: 100, tick: 780),
                .noteOff(channel: 0, note: 67, velocity: 0, tick: 828)
            ]
        )
    }

    func testSongToSequenceConversionStopsAtZeroRepeatEndMarker() throws {
        var sequence = Sequence(name: "A")
        sequence.setLoopToBar(1)
        sequence.tracks = [
            Track(
                events: [
                    .noteOn(channel: 0, note: 60, velocity: 100, tick: 0),
                    .noteOff(channel: 0, note: 60, velocity: 0, tick: 96)
                ]
            )
        ]

        let song = Song(
            steps: [
                SongStep(sequenceIndex: 0, repeats: 1),
                SongStep(sequenceIndex: 0, repeats: 0),
                SongStep(sequenceIndex: 0, repeats: 99)
            ]
        )

        let engine = SequencerEngine(project: Project(sequences: [sequence], songs: [song]))
        let flattened = try engine.convertSongToSequence(songIndex: 0)

        XCTAssertEqual(flattened.tracks[0].events.count, 2)
        XCTAssertEqual(flattened.tracks[0].events[0].tick, 0)
        XCTAssertEqual(flattened.tracks[0].events[1].tick, 96)
    }

    func testSongToSequenceConversionThrowsForInvalidSongOrStepSequenceReference() {
        let song = Song(steps: [SongStep(sequenceIndex: 4, repeats: 1)])
        let engine = SequencerEngine(project: Project(sequences: [Sequence()], songs: [song]))

        XCTAssertThrowsError(try engine.convertSongToSequence(songIndex: 1)) { error in
            XCTAssertEqual(error as? SequencerEngine.SongConversionError, .songIndexOutOfRange)
        }
        XCTAssertThrowsError(try engine.convertSongToSequence(songIndex: 0)) { error in
            XCTAssertEqual(
                error as? SequencerEngine.SongConversionError,
                .sequenceIndexOutOfRange(stepIndex: 0, sequenceIndex: 4)
            )
        }
    }

    func testSongToSequenceConversionThrowsWhenNoStepIsMaterialized() {
        let song = Song(steps: [SongStep(sequenceIndex: 0, repeats: 0)])
        let engine = SequencerEngine(project: Project(sequences: [Sequence()], songs: [song]))

        XCTAssertThrowsError(try engine.convertSongToSequence(songIndex: 0)) { error in
            XCTAssertEqual(error as? SequencerEngine.SongConversionError, .noMaterializedSteps)
        }
    }

    func testTimelineFixedSignatureRoundTrip() {
        let mapper = TimelineMapper(ppqn: Sequence.defaultPPQN)
        let target = BarBeatTick(bar: 2, beat: 3, tick: 12)
        let tick = mapper.toTick(target)

        XCTAssertEqual(tick, 588)
        XCTAssertEqual(mapper.toBarBeatTick(tick: tick), target)
    }

    func testTimelineSignatureChangeConversions() {
        let mapper = TimelineMapper(
            ppqn: Sequence.defaultPPQN,
            changes: [
                TimeSignatureChange(bar: 3, signature: TimeSignature(numerator: 3, denominator: 4))
            ]
        )

        XCTAssertEqual(mapper.toTick(BarBeatTick(bar: 1, beat: 1, tick: 0)), 0)
        XCTAssertEqual(mapper.toTick(BarBeatTick(bar: 2, beat: 1, tick: 0)), 384)
        XCTAssertEqual(mapper.toTick(BarBeatTick(bar: 3, beat: 1, tick: 0)), 768)
        XCTAssertEqual(mapper.toTick(BarBeatTick(bar: 3, beat: 3, tick: 95)), 1055)
        XCTAssertEqual(mapper.toTick(BarBeatTick(bar: 4, beat: 1, tick: 0)), 1056)

        XCTAssertEqual(mapper.toBarBeatTick(tick: 767), BarBeatTick(bar: 2, beat: 4, tick: 95))
        XCTAssertEqual(mapper.toBarBeatTick(tick: 768), BarBeatTick(bar: 3, beat: 1, tick: 0))
        XCTAssertEqual(mapper.toBarBeatTick(tick: 1056), BarBeatTick(bar: 4, beat: 1, tick: 0))
    }

    func testTimelineDenominatorAffectsBeatResolution() {
        let mapper = TimelineMapper(
            ppqn: Sequence.defaultPPQN,
            changes: [TimeSignatureChange(bar: 1, signature: TimeSignature(numerator: 6, denominator: 8))]
        )

        XCTAssertEqual(mapper.ticksPerBeat(for: TimeSignature(numerator: 6, denominator: 8)), 48)
        XCTAssertEqual(mapper.toTick(BarBeatTick(bar: 1, beat: 2, tick: 0)), 48)
        XCTAssertEqual(mapper.toBarBeatTick(tick: 287), BarBeatTick(bar: 1, beat: 6, tick: 47))
    }

    func testMidiTrackTransposeAffectsNoteEventsOnly() {
        var track = Track(
            kind: .midi,
            events: [
                .noteOn(channel: 0, note: 60, velocity: 100, tick: 0),
                .polyPressure(channel: 0, note: 61, pressure: 64, tick: 24),
                .controlChange(channel: 0, controller: 1, value: 127, tick: 48),
                .noteOff(channel: 0, note: 60, velocity: 0, tick: 96)
            ]
        )

        track.transpose(semitones: 2)

        XCTAssertEqual(
            track.events,
            [
                .noteOn(channel: 0, note: 62, velocity: 100, tick: 0),
                .polyPressure(channel: 0, note: 63, pressure: 64, tick: 24),
                .controlChange(channel: 0, controller: 1, value: 127, tick: 48),
                .noteOff(channel: 0, note: 62, velocity: 0, tick: 96)
            ]
        )
    }

    func testDrumTrackTransposeIsNoOp() {
        let originalEvents: [MIDIEvent] = [
            .noteOn(channel: 9, note: 36, velocity: 100, tick: 0),
            .noteOff(channel: 9, note: 36, velocity: 0, tick: 24)
        ]
        var track = Track(kind: .drum, events: originalEvents)

        track.transpose(semitones: 12)

        XCTAssertEqual(track.events, originalEvents)
    }

    func testMidiTrackTransposeClampsNoteRange() {
        var track = Track(
            kind: .midi,
            events: [
                .noteOn(channel: 0, note: 1, velocity: 100, tick: 0),
                .noteOff(channel: 0, note: 126, velocity: 0, tick: 24)
            ]
        )

        track.transpose(semitones: -10)
        track.transpose(semitones: 20)

        XCTAssertEqual(
            track.events,
            [
                .noteOn(channel: 0, note: 20, velocity: 100, tick: 0),
                .noteOff(channel: 0, note: 127, velocity: 0, tick: 24)
            ]
        )
    }

    func testTrackRoutingDefaultsToPrimaryDestinationOnly() {
        let track = Track()

        XCTAssertEqual(track.routing.primary, MIDIDestination(port: "main", channel: 1))
        XCTAssertNil(track.routing.auxiliary)
    }

    func testTrackRoutingSupportsPrimaryAndAuxiliaryDestinations() {
        var track = Track()

        track.setPrimaryRouting(port: "din-a", channel: 10)
        track.setAuxiliaryRouting(MIDIDestination(port: "usb-1", channel: 2))

        XCTAssertEqual(track.routing.primary, MIDIDestination(port: "din-a", channel: 10))
        XCTAssertEqual(track.routing.auxiliary, MIDIDestination(port: "usb-1", channel: 2))
    }

    func testTrackRoutingNormalizesOutOfRangeChannelAssignments() {
        var track = Track()

        track.setPrimaryRouting(port: "din-a", channel: 0)
        XCTAssertEqual(track.routing.primary.channel, 1)

        track.setAuxiliaryRouting(MIDIDestination(port: "usb-1", channel: 19))
        XCTAssertEqual(track.routing.auxiliary?.channel, 16)
    }

    func testStepEditSupportsAllRequiredMIDIEventTypes() throws {
        let editableEvents: [MIDIEvent] = [
            .noteOn(channel: 0, note: 60, velocity: 100, tick: 0),
            .noteOff(channel: 0, note: 60, velocity: 0, tick: 24),
            .programChange(channel: 0, program: 42, tick: 48),
            .pitchBend(channel: 0, value: 2_048, tick: 72),
            .channelPressure(channel: 0, pressure: 88, tick: 96),
            .polyPressure(channel: 0, note: 64, pressure: 77, tick: 120),
            .controlChange(channel: 0, controller: 74, value: 99, tick: 144),
            .sysEx(data: [0x7D, 0x01, 0x02], tick: 168)
        ]

        var sequence = Sequence()
        sequence.tracks = [Track(kind: .midi, events: [])]
        var engine = SequencerEngine(project: Project(sequences: [sequence]))

        for (index, event) in editableEvents.enumerated() {
            try engine.stepEditInsertEvent(
                sequenceIndex: 0,
                trackIndex: 0,
                eventIndex: index,
                event: event
            )
        }

        XCTAssertEqual(engine.project.sequences[0].tracks[0].events, editableEvents)
    }

    func testStepEditUpdateAndDeleteBehaviors() throws {
        var sequence = Sequence()
        sequence.tracks = [
            Track(
                kind: .midi,
                events: [
                    .noteOn(channel: 0, note: 60, velocity: 100, tick: 0),
                    .controlChange(channel: 0, controller: 10, value: 64, tick: 24)
                ]
            )
        ]
        var engine = SequencerEngine(project: Project(sequences: [sequence]))

        let replacement = MIDIEvent.pitchBend(channel: 0, value: -1_024, tick: 24)
        try engine.stepEditUpdateEvent(
            sequenceIndex: 0,
            trackIndex: 0,
            eventIndex: 1,
            event: replacement
        )
        XCTAssertEqual(engine.project.sequences[0].tracks[0].events[1], replacement)

        let removed = try engine.stepEditDeleteEvent(sequenceIndex: 0, trackIndex: 0, eventIndex: 0)
        XCTAssertEqual(removed, .noteOn(channel: 0, note: 60, velocity: 100, tick: 0))
        XCTAssertEqual(engine.project.sequences[0].tracks[0].events, [replacement])
    }

    func testStepEditRejectsOutOfRangeSequenceTrackAndEventIndexes() {
        var sequence = Sequence()
        sequence.tracks = [Track(kind: .midi, events: [])]
        var engine = SequencerEngine(project: Project(sequences: [sequence]))
        let event = MIDIEvent.programChange(channel: 0, program: 1, tick: 0)

        XCTAssertThrowsError(
            try engine.stepEditInsertEvent(sequenceIndex: 99, trackIndex: 0, eventIndex: 0, event: event)
        ) { error in
            XCTAssertEqual(error as? SequencerEngine.StepEditError, .sequenceIndexOutOfRange)
        }

        XCTAssertThrowsError(
            try engine.stepEditInsertEvent(sequenceIndex: 0, trackIndex: 2, eventIndex: 0, event: event)
        ) { error in
            XCTAssertEqual(error as? SequencerEngine.StepEditError, .trackIndexOutOfRange)
        }

        XCTAssertThrowsError(
            try engine.stepEditInsertEvent(sequenceIndex: 0, trackIndex: 0, eventIndex: 1, event: event)
        ) { error in
            XCTAssertEqual(error as? SequencerEngine.StepEditError, .eventIndexOutOfRange)
        }
    }

    func testInsertBarsShiftsEventsAtOrAfterInsertionPointAcrossTracks() throws {
        let sequence = Sequence(ppqn: 96, tracks: [
            Track(
                kind: .midi,
                events: [
                    .noteOn(channel: 0, note: 60, velocity: 100, tick: 0),
                    .noteOn(channel: 0, note: 61, velocity: 100, tick: 384),
                    .noteOff(channel: 0, note: 61, velocity: 0, tick: 480)
                ]
            ),
            Track(
                kind: .drum,
                events: [
                    .noteOn(channel: 9, note: 36, velocity: 110, tick: 383),
                    .noteOn(channel: 9, note: 38, velocity: 120, tick: 384)
                ]
            )
        ])
        var engine = SequencerEngine(project: Project(sequences: [sequence]))

        try engine.insertBars(sequenceIndex: 0, atBar: 2, count: 1)

        XCTAssertEqual(
            engine.project.sequences[0].tracks[0].events,
            [
                .noteOn(channel: 0, note: 60, velocity: 100, tick: 0),
                .noteOn(channel: 0, note: 61, velocity: 100, tick: 768),
                .noteOff(channel: 0, note: 61, velocity: 0, tick: 864)
            ]
        )
        XCTAssertEqual(
            engine.project.sequences[0].tracks[1].events,
            [
                .noteOn(channel: 9, note: 36, velocity: 110, tick: 383),
                .noteOn(channel: 9, note: 38, velocity: 120, tick: 768)
            ]
        )
    }

    func testDeleteBarsRemovesRegionAndCompactsFollowingEvents() throws {
        let sequence = Sequence(ppqn: 96, tracks: [
            Track(
                kind: .midi,
                events: [
                    .noteOn(channel: 0, note: 60, velocity: 100, tick: 0),
                    .controlChange(channel: 0, controller: 1, value: 10, tick: 100),
                    .noteOff(channel: 0, note: 60, velocity: 0, tick: 383),
                    .programChange(channel: 0, program: 5, tick: 384),
                    .pitchBend(channel: 0, value: 500, tick: 760),
                    .channelPressure(channel: 0, pressure: 90, tick: 800)
                ]
            )
        ])
        var engine = SequencerEngine(project: Project(sequences: [sequence]))

        try engine.deleteBars(sequenceIndex: 0, startingAt: 2, count: 1)

        XCTAssertEqual(
            engine.project.sequences[0].tracks[0].events,
            [
                .noteOn(channel: 0, note: 60, velocity: 100, tick: 0),
                .controlChange(channel: 0, controller: 1, value: 10, tick: 100),
                .noteOff(channel: 0, note: 60, velocity: 0, tick: 383),
                .channelPressure(channel: 0, pressure: 90, tick: 416)
            ]
        )
    }

    func testCopyBarsMergePreservesDestinationEvents() throws {
        let sequence = Sequence(ppqn: 96, tracks: [
            Track(
                kind: .midi,
                events: [
                    .noteOn(channel: 0, note: 60, velocity: 100, tick: 0),
                    .noteOff(channel: 0, note: 60, velocity: 0, tick: 96),
                    .controlChange(channel: 0, controller: 74, value: 99, tick: 400)
                ]
            )
        ])
        var engine = SequencerEngine(project: Project(sequences: [sequence]))

        try engine.copyBars(
            sequenceIndex: 0,
            from: 1,
            count: 1,
            to: 2,
            mode: .merge
        )

        XCTAssertEqual(
            engine.project.sequences[0].tracks[0].events,
            [
                .noteOn(channel: 0, note: 60, velocity: 100, tick: 0),
                .noteOff(channel: 0, note: 60, velocity: 0, tick: 96),
                .noteOn(channel: 0, note: 60, velocity: 100, tick: 384),
                .controlChange(channel: 0, controller: 74, value: 99, tick: 400),
                .noteOff(channel: 0, note: 60, velocity: 0, tick: 480)
            ]
        )
    }

    func testCopyEventsReplaceClearsDestinationWindowBeforePaste() throws {
        let sequence = Sequence(ppqn: 96, tracks: [
            Track(
                kind: .midi,
                events: [
                    .noteOn(channel: 0, note: 60, velocity: 100, tick: 0),
                    .noteOff(channel: 0, note: 60, velocity: 0, tick: 96),
                    .controlChange(channel: 0, controller: 7, value: 80, tick: 384),
                    .programChange(channel: 0, program: 20, tick: 420),
                    .pitchBend(channel: 0, value: 512, tick: 500)
                ]
            )
        ])
        var engine = SequencerEngine(project: Project(sequences: [sequence]))

        try engine.copyEvents(
            sequenceIndex: 0,
            trackIndex: 0,
            sourceStartTick: 0,
            length: 192,
            destinationStartTick: 384,
            mode: .replace
        )

        XCTAssertEqual(
            engine.project.sequences[0].tracks[0].events,
            [
                .noteOn(channel: 0, note: 60, velocity: 100, tick: 0),
                .noteOff(channel: 0, note: 60, velocity: 0, tick: 96),
                .noteOn(channel: 0, note: 60, velocity: 100, tick: 384),
                .noteOff(channel: 0, note: 60, velocity: 0, tick: 480)
            ]
        )
    }

    func testCopyEventsRejectsOutOfRangeTrackAndInvalidLength() {
        let sequence = Sequence(ppqn: 96, tracks: [Track(kind: .midi, events: [])])
        var engine = SequencerEngine(project: Project(sequences: [sequence]))

        XCTAssertThrowsError(
            try engine.copyEvents(
                sequenceIndex: 0,
                trackIndex: 2,
                sourceStartTick: 0,
                length: 96,
                destinationStartTick: 384,
                mode: .merge
            )
        ) { error in
            XCTAssertEqual(error as? SequencerEngine.EditOperationError, .trackIndexOutOfRange)
        }

        XCTAssertThrowsError(
            try engine.copyEvents(
                sequenceIndex: 0,
                trackIndex: 0,
                sourceStartTick: 0,
                length: 0,
                destinationStartTick: 384,
                mode: .merge
            )
        ) { error in
            XCTAssertEqual(error as? SequencerEngine.EditOperationError, .invalidTickLength)
        }
    }

    func testCopyEventsRejectsNegativeSourceStartTick() {
        let sequence = Sequence(ppqn: 96, tracks: [
            Track(
                kind: .midi,
                events: [
                    .noteOn(channel: 0, note: 60, velocity: 100, tick: 0),
                    .noteOff(channel: 0, note: 60, velocity: 0, tick: 24)
                ]
            )
        ])
        var engine = SequencerEngine(project: Project(sequences: [sequence]))

        XCTAssertThrowsError(
            try engine.copyEvents(
                sequenceIndex: 0,
                trackIndex: 0,
                sourceStartTick: -1,
                length: 24,
                destinationStartTick: 96,
                mode: .merge
            )
        ) { error in
            XCTAssertEqual(error as? SequencerEngine.EditOperationError, .invalidTickLength)
        }
    }

    func testStoppedRegionEraseRemovesAllEventTypesInRange() throws {
        let sequence = Sequence(ppqn: 96, tracks: [
            Track(
                kind: .midi,
                events: [
                    .noteOn(channel: 0, note: 60, velocity: 100, tick: 10),
                    .controlChange(channel: 0, controller: 1, value: 64, tick: 20),
                    .programChange(channel: 0, program: 12, tick: 30),
                    .noteOff(channel: 0, note: 60, velocity: 0, tick: 40)
                ]
            )
        ])
        var engine = SequencerEngine(project: Project(sequences: [sequence]))

        let erased = try engine.eraseRegion(
            sequenceIndex: 0,
            trackIndex: 0,
            startTick: 15,
            length: 20,
            filter: .all
        )

        XCTAssertEqual(erased, 2)
        XCTAssertEqual(
            engine.project.sequences[0].tracks[0].events,
            [
                .noteOn(channel: 0, note: 60, velocity: 100, tick: 10),
                .noteOff(channel: 0, note: 60, velocity: 0, tick: 40)
            ]
        )
    }

    func testStoppedRegionEraseSupportsOnlyAndAllExceptTypeFilters() throws {
        let sequence = Sequence(ppqn: 96, tracks: [
            Track(
                kind: .midi,
                events: [
                    .noteOn(channel: 0, note: 60, velocity: 100, tick: 0),
                    .controlChange(channel: 0, controller: 1, value: 80, tick: 0),
                    .programChange(channel: 0, program: 5, tick: 0),
                    .noteOff(channel: 0, note: 60, velocity: 0, tick: 24)
                ]
            )
        ])
        var engine = SequencerEngine(project: Project(sequences: [sequence]))

        let onlyErased = try engine.eraseRegion(
            sequenceIndex: 0,
            trackIndex: 0,
            startTick: 0,
            length: 48,
            filter: .only([.controlChange, .programChange])
        )
        XCTAssertEqual(onlyErased, 2)
        XCTAssertEqual(
            engine.project.sequences[0].tracks[0].events,
            [
                .noteOn(channel: 0, note: 60, velocity: 100, tick: 0),
                .noteOff(channel: 0, note: 60, velocity: 0, tick: 24)
            ]
        )

        let allExceptErased = try engine.eraseRegion(
            sequenceIndex: 0,
            trackIndex: 0,
            startTick: 0,
            length: 48,
            filter: .allExcept([.note])
        )
        XCTAssertEqual(allExceptErased, 0)
        XCTAssertEqual(
            engine.project.sequences[0].tracks[0].events,
            [
                .noteOn(channel: 0, note: 60, velocity: 100, tick: 0),
                .noteOff(channel: 0, note: 60, velocity: 0, tick: 24)
            ]
        )
    }

    func testOverdubHoldEraseRequiresOverdubAndErasesHeldRange() throws {
        let sequence = Sequence(ppqn: 96, tracks: [
            Track(
                kind: .midi,
                events: [
                    .noteOn(channel: 0, note: 60, velocity: 100, tick: 8),
                    .controlChange(channel: 0, controller: 74, value: 99, tick: 16),
                    .noteOff(channel: 0, note: 60, velocity: 0, tick: 24),
                    .pitchBend(channel: 0, value: 700, tick: 40)
                ]
            )
        ])
        var engine = SequencerEngine(project: Project(sequences: [sequence]))

        XCTAssertThrowsError(
            try engine.eraseOverdubHold(
                sequenceIndex: 0,
                trackIndex: 0,
                heldRange: 8..<30,
                filter: .all
            )
        ) { error in
            XCTAssertEqual(error as? SequencerEngine.EraseOperationError, .transportMustBeOverdubbing)
        }

        engine.overdub()
        let erased = try engine.eraseOverdubHold(
            sequenceIndex: 0,
            trackIndex: 0,
            heldRange: 8..<30,
            filter: .allExcept([.controlChange])
        )

        XCTAssertEqual(erased, 2)
        XCTAssertEqual(
            engine.project.sequences[0].tracks[0].events,
            [
                .controlChange(channel: 0, controller: 74, value: 99, tick: 16),
                .pitchBend(channel: 0, value: 700, tick: 40)
            ]
        )
    }

    func testEditLoopTurnOffKeepsEditsMadeWhileActive() throws {
        let originalSequence = Sequence(ppqn: 96, tracks: [
            Track(
                kind: .midi,
                events: [
                    .noteOn(channel: 0, note: 60, velocity: 100, tick: 0),
                    .noteOff(channel: 0, note: 60, velocity: 0, tick: 96)
                ]
            )
        ])
        var engine = SequencerEngine(project: Project(sequences: [originalSequence]))

        try engine.turnOnEditLoop(sequenceIndex: 0, startBar: 1, barCount: 1)
        XCTAssertEqual(engine.activeEditLoopSequenceIndex, 0)

        try engine.stepEditInsertEvent(
            sequenceIndex: 0,
            trackIndex: 0,
            eventIndex: 2,
            event: .controlChange(channel: 0, controller: 74, value: 99, tick: 48)
        )
        try engine.turnOffEditLoop()

        XCTAssertNil(engine.activeEditLoopSequenceIndex)
        XCTAssertEqual(
            engine.project.sequences[0].tracks[0].events,
            [
                .noteOn(channel: 0, note: 60, velocity: 100, tick: 0),
                .noteOff(channel: 0, note: 60, velocity: 0, tick: 96),
                .controlChange(channel: 0, controller: 74, value: 99, tick: 48)
            ]
        )
    }

    func testEditLoopUndoAndOffRollsBackSequenceToSnapshot() throws {
        let originalSequence = Sequence(ppqn: 96, tracks: [
            Track(
                kind: .midi,
                events: [
                    .noteOn(channel: 0, note: 60, velocity: 100, tick: 0),
                    .noteOff(channel: 0, note: 60, velocity: 0, tick: 96),
                    .controlChange(channel: 0, controller: 1, value: 64, tick: 140)
                ]
            )
        ])
        var engine = SequencerEngine(project: Project(sequences: [originalSequence]))

        try engine.turnOnEditLoop(sequenceIndex: 0, startBar: 2, barCount: 1)
        try engine.deleteBars(sequenceIndex: 0, startingAt: 1, count: 1)
        try engine.undoAndTurnOffEditLoop()

        XCTAssertNil(engine.activeEditLoopSequenceIndex)
        XCTAssertEqual(engine.project.sequences[0], originalSequence)
    }

    func testEditLoopRequiresActiveStateAndRejectsNestedActivation() throws {
        var engine = SequencerEngine(project: Project(sequences: [Sequence()]))

        XCTAssertThrowsError(try engine.turnOffEditLoop()) { error in
            XCTAssertEqual(error as? SequencerEngine.EditLoopError, .notActive)
        }
        XCTAssertThrowsError(try engine.undoAndTurnOffEditLoop()) { error in
            XCTAssertEqual(error as? SequencerEngine.EditLoopError, .notActive)
        }

        try engine.turnOnEditLoop(sequenceIndex: 0, startBar: 1, barCount: 1)
        XCTAssertThrowsError(try engine.turnOnEditLoop(sequenceIndex: 0, startBar: 1, barCount: 1)) { error in
            XCTAssertEqual(error as? SequencerEngine.EditLoopError, .alreadyActive)
        }
    }

    func testQuantizationModeSupportsAllSourceBackedValues() {
        XCTAssertEqual(
            QuantizationMode.allCases.map(\.displayName),
            [
                "off",
                "1/8",
                "1/8 triplet",
                "1/16",
                "1/16 triplet",
                "1/32",
                "1/32 triplet"
            ]
        )
    }

    func testQuantizationModeIntervalTicksAtNinetySixPPQN() {
        XCTAssertNil(QuantizationMode.off.intervalTicks(ppqn: 96))
        XCTAssertEqual(QuantizationMode.eighth.intervalTicks(ppqn: 96), 48)
        XCTAssertEqual(QuantizationMode.eighthTriplet.intervalTicks(ppqn: 96), 32)
        XCTAssertEqual(QuantizationMode.sixteenth.intervalTicks(ppqn: 96), 24)
        XCTAssertEqual(QuantizationMode.sixteenthTriplet.intervalTicks(ppqn: 96), 16)
        XCTAssertEqual(QuantizationMode.thirtySecond.intervalTicks(ppqn: 96), 12)
        XCTAssertEqual(QuantizationMode.thirtySecondTriplet.intervalTicks(ppqn: 96), 8)
    }

    func testSwingRejectsOutOfRangeValues() {
        XCTAssertThrowsError(try Swing(percent: 49)) { error in
            XCTAssertEqual(error as? Swing.ConfigurationError, .outOfRange)
        }
        XCTAssertThrowsError(try Swing(percent: 76)) { error in
            XCTAssertEqual(error as? Swing.ConfigurationError, .outOfRange)
        }
    }

    func testSwingAtFiftyPercentLeavesGridUnchanged() throws {
        let swing = try Swing(percent: 50)

        XCTAssertEqual(swing.appliedTick(0, quantizationMode: .sixteenth), 0)
        XCTAssertEqual(swing.appliedTick(24, quantizationMode: .sixteenth), 24)
        XCTAssertEqual(swing.appliedTick(48, quantizationMode: .sixteenth), 48)
    }

    func testSwingDelaysEvenSubdivisionsDeterministically() throws {
        let swing = try Swing(percent: 75)

        XCTAssertEqual(swing.appliedTick(0, quantizationMode: .sixteenth), 0)
        XCTAssertEqual(swing.appliedTick(24, quantizationMode: .sixteenth), 36)
        XCTAssertEqual(swing.appliedTick(48, quantizationMode: .sixteenth), 48)
        XCTAssertEqual(swing.appliedTick(72, quantizationMode: .sixteenth), 84)
    }

    func testSwingWithQuantizationOffDoesNothing() throws {
        let swing = try Swing(percent: 70)
        XCTAssertEqual(swing.appliedTick(24, quantizationMode: .off), 24)
    }

    func testShiftTimingRejectsNonPositiveTickValues() {
        XCTAssertThrowsError(try ShiftTiming(direction: .earlier, ticks: 0)) { error in
            XCTAssertEqual(error as? ShiftTiming.ConfigurationError, .ticksMustBePositive)
        }
    }

    func testShiftTimingMovesTicksEarlierOrLaterWhenQuantizationIsActive() throws {
        let earlier = try ShiftTiming(direction: .earlier, ticks: 5)
        let later = try ShiftTiming(direction: .later, ticks: 7)

        XCTAssertEqual(earlier.appliedTick(24, quantizationMode: .sixteenth), 19)
        XCTAssertEqual(later.appliedTick(24, quantizationMode: .sixteenth), 31)
    }

    func testShiftTimingDoesNothingWhenQuantizationIsOff() throws {
        let shift = try ShiftTiming(direction: .later, ticks: 8)
        XCTAssertEqual(shift.appliedTick(24, quantizationMode: .off), 24)
    }

    func testShiftTimingBoundsOffsetToCurrentQuantizationInterval() throws {
        let shift = try ShiftTiming(direction: .later, ticks: 99)

        // 1/16 at 96 PPQN is 24 ticks, so max effective shift is 23 ticks.
        XCTAssertEqual(shift.appliedTick(48, quantizationMode: .sixteenth), 71)
    }

    func testNoteRepeatRetriggersHeldNotesAtQuantizationInterval() {
        let repeatEngine = NoteRepeat(quantizationMode: .sixteenth)
        let heldNotes = [NoteRepeat.HeldNote(channel: 0, note: 60, velocity: 100)]

        let events = repeatEngine.retriggerEvents(heldNotes: heldNotes, heldRange: 0..<72)

        XCTAssertEqual(
            events,
            [
                .noteOn(channel: 0, note: 60, velocity: 100, tick: 0),
                .noteOff(channel: 0, note: 60, velocity: 0, tick: 12),
                .noteOn(channel: 0, note: 60, velocity: 100, tick: 24),
                .noteOff(channel: 0, note: 60, velocity: 0, tick: 36),
                .noteOn(channel: 0, note: 60, velocity: 100, tick: 48),
                .noteOff(channel: 0, note: 60, velocity: 0, tick: 60)
            ]
        )
    }

    func testNoteRepeatWithQuantizationOffEmitsNoRetriggerEvents() {
        let repeatEngine = NoteRepeat(quantizationMode: .off)
        let heldNotes = [NoteRepeat.HeldNote(channel: 0, note: 60, velocity: 100)]

        XCTAssertTrue(repeatEngine.retriggerEvents(heldNotes: heldNotes, heldRange: 0..<96).isEmpty)
    }

    func testNoteRepeatOrdersSimultaneousRetriggersDeterministically() {
        let repeatEngine = NoteRepeat(
            quantizationMode: .eighthTriplet,
            ppqn: Sequence.defaultPPQN,
            gateTicks: 8
        )
        let heldNotes = [
            NoteRepeat.HeldNote(channel: 2, note: 64, velocity: 90),
            NoteRepeat.HeldNote(channel: 1, note: 67, velocity: 96),
            NoteRepeat.HeldNote(channel: 1, note: 60, velocity: 110)
        ]

        let events = repeatEngine.retriggerEvents(heldNotes: heldNotes, heldRange: 0..<32)

        XCTAssertEqual(
            events,
            [
                .noteOn(channel: 1, note: 60, velocity: 110, tick: 0),
                .noteOn(channel: 1, note: 67, velocity: 96, tick: 0),
                .noteOn(channel: 2, note: 64, velocity: 90, tick: 0),
                .noteOff(channel: 1, note: 60, velocity: 0, tick: 8),
                .noteOff(channel: 1, note: 67, velocity: 0, tick: 8),
                .noteOff(channel: 2, note: 64, velocity: 0, tick: 8)
            ]
        )
    }

    func testAdvanceTransportSchedulingUsesDeterministicTieBreakers() {
        let sequence = Sequence(
            tracks: [
                Track(
                    kind: .midi,
                    events: [
                        .controlChange(channel: 0, controller: 1, value: 64, tick: 0),
                        .noteOn(channel: 0, note: 60, velocity: 100, tick: 0),
                        .noteOff(channel: 0, note: 60, velocity: 0, tick: 24)
                    ]
                ),
                Track(
                    kind: .drum,
                    events: [
                        .noteOn(channel: 9, note: 36, velocity: 120, tick: 0),
                        .noteOff(channel: 9, note: 36, velocity: 0, tick: 24)
                    ]
                )
            ]
        )
        var engine = SequencerEngine(project: Project(sequences: [sequence]))
        engine.play()

        let scheduled = engine.advanceTransportAndCollectScheduledEvents(by: 1)

        XCTAssertEqual(
            scheduled.map(\.event),
            [
                .controlChange(channel: 0, controller: 1, value: 64, tick: 0),
                .noteOn(channel: 0, note: 60, velocity: 100, tick: 0),
                .noteOn(channel: 9, note: 36, velocity: 120, tick: 0)
            ]
        )
    }

    func testDeterministicTimingRemainsStableUnderSyntheticCPULoad() {
        let sequence = Sequence(
            tracks: [
                Track(kind: .midi, events: Self.syntheticTimingEvents(channel: 0, noteStart: 60, count: 48)),
                Track(kind: .midi, events: Self.syntheticTimingEvents(channel: 1, noteStart: 72, count: 48)),
                Track(
                    kind: .drum,
                    events: [
                        .controlChange(channel: 9, controller: 1, value: 100, tick: 96),
                        .controlChange(channel: 9, controller: 7, value: 110, tick: 192),
                        .controlChange(channel: 9, controller: 10, value: 64, tick: 288)
                    ]
                )
            ]
        )

        let project = Project(sequences: [sequence])
        let baseline = runSyntheticScheduling(
            engineTemplate: SequencerEngine(project: project),
            totalTicks: 1_536,
            stepTicks: 17,
            loadIterations: 0
        )
        let moderateLoad = runSyntheticScheduling(
            engineTemplate: SequencerEngine(project: project),
            totalTicks: 1_536,
            stepTicks: 17,
            loadIterations: 30_000
        )
        let heavyLoad = runSyntheticScheduling(
            engineTemplate: SequencerEngine(project: project),
            totalTicks: 1_536,
            stepTicks: 17,
            loadIterations: 60_000
        )

        XCTAssertEqual(moderateLoad.events, baseline.events)
        XCTAssertEqual(heavyLoad.events, baseline.events)
        XCTAssertEqual(moderateLoad.maxJitterTicks, baseline.maxJitterTicks)
        XCTAssertEqual(heavyLoad.maxJitterTicks, baseline.maxJitterTicks)
        XCTAssertEqual(moderateLoad.jitterVariance, baseline.jitterVariance, accuracy: 0.0000001)
        XCTAssertEqual(heavyLoad.jitterVariance, baseline.jitterVariance, accuracy: 0.0000001)
    }

    func testOfflineStressSchedulingHandlesSixtyThousandNoteEventsWithoutDrops() {
        let eventCount = 30_000
        let stressEvents = Self.syntheticTimingEvents(channel: 0, noteStart: 60, count: eventCount)
        XCTAssertEqual(stressEvents.count, 60_000)

        let sequence = Sequence(
            tracks: [
                Track(kind: .midi, events: stressEvents)
            ]
        )
        var engine = SequencerEngine(project: Project(sequences: [sequence]))
        engine.play()

        let totalTicks = (stressEvents.last?.tick ?? 0) + 1
        let stepTicks = 137
        var advanced = 0
        var scheduled: [SequencerEngine.ScheduledEvent] = []

        while advanced < totalTicks {
            let consumed = min(stepTicks, totalTicks - advanced)
            scheduled.append(contentsOf: engine.advanceTransportAndCollectScheduledEvents(by: consumed))
            advanced += consumed
        }

        XCTAssertEqual(scheduled.count, stressEvents.count)
        XCTAssertEqual(scheduled.map(\.event), stressEvents)
    }

    func testProjectJSONPersistenceRoundTripsWithSchemaVersion() throws {
        var sequence = Sequence(
            name: "Persist Me",
            ppqn: 96,
            tempoBPM: 124.0,
            loopMode: .loopToBar(2),
            tracks: [
                Track(
                    name: "All Events",
                    kind: .midi,
                    routing: Track.Routing(
                        primary: MIDIDestination(port: "primary", channel: 10),
                        auxiliary: MIDIDestination(port: "aux", channel: 11)
                    ),
                    events: [
                        .noteOn(channel: 0, note: 60, velocity: 100, tick: 0),
                        .noteOff(channel: 0, note: 60, velocity: 0, tick: 24),
                        .programChange(channel: 0, program: 8, tick: 48),
                        .pitchBend(channel: 0, value: 1024, tick: 72),
                        .channelPressure(channel: 0, pressure: 90, tick: 96),
                        .polyPressure(channel: 0, note: 60, pressure: 70, tick: 120),
                        .controlChange(channel: 0, controller: 74, value: 99, tick: 144),
                        .sysEx(data: [0x7E, 0x7F, 0x09, 0x01], tick: 168)
                    ]
                )
            ]
        )
        _ = sequence.insertTempoChange(atTick: 192, bpm: 132.0, isEnabled: true)

        let song = Song(
            name: "Song A",
            steps: [SongStep(sequenceIndex: 0, repeats: 2)],
            endBehavior: .loopToStep(1)
        )
        var engine = SequencerEngine(project: Project(
            sequences: [sequence],
            songs: [song],
            masterTempoBPM: 118.0,
            tempoSource: .sequence
        ))

        let data = try engine.saveProjectJSONData()
        let header = try JSONDecoder().decode(PersistenceHeader.self, from: data)
        XCTAssertEqual(header.schemaVersion, SequencerEngine.currentProjectSchemaVersion)

        engine.play()
        engine.locate(tick: 240)
        try engine.loadProjectJSONData(data)

        XCTAssertEqual(engine.project.sequences.count, 1)
        XCTAssertEqual(engine.project.songs.count, 1)
        XCTAssertEqual(engine.project, Project(
            sequences: [sequence],
            songs: [song],
            masterTempoBPM: 118.0,
            tempoSource: .sequence
        ))
        XCTAssertEqual(engine.transport.mode, .playing)
        XCTAssertEqual(engine.transport.tickPosition, 240)
    }

    func testProjectJSONPersistenceRejectsUnsupportedSchemaVersion() throws {
        let engine = SequencerEngine(project: Project(sequences: [Sequence(name: "A")]))
        let originalData = try engine.saveProjectJSONData()

        let rawObject = try XCTUnwrap(try JSONSerialization.jsonObject(with: originalData) as? [String: Any])
        var mutatedObject = rawObject
        mutatedObject["schemaVersion"] = SequencerEngine.currentProjectSchemaVersion + 1
        let mutatedData = try JSONSerialization.data(withJSONObject: mutatedObject, options: [])

        var decodingEngine = SequencerEngine()
        XCTAssertThrowsError(try decodingEngine.loadProjectJSONData(mutatedData)) { error in
            XCTAssertEqual(
                error as? ProjectPersistenceError,
                .unsupportedSchemaVersion(SequencerEngine.currentProjectSchemaVersion + 1)
            )
        }
    }

    func testSMFType0FixtureRoundTripImportExport() throws {
        let fixtureData = Data(Self.smfType0FixtureBytes)

        let imported = try SequencerEngine.importSMFSequence(fixtureData, sequenceName: "Type0 Fixture")
        XCTAssertEqual(imported.ppqn, 96)
        XCTAssertEqual(imported.tracks.count, 1)
        XCTAssertEqual(
            imported.tracks[0].events,
            [
                .noteOn(channel: 0, note: 60, velocity: 100, tick: 0),
                .noteOff(channel: 0, note: 60, velocity: 0, tick: 24),
                .programChange(channel: 0, program: 8, tick: 36),
                .pitchBend(channel: 0, value: 1024, tick: 48),
                .channelPressure(channel: 0, pressure: 90, tick: 60),
                .polyPressure(channel: 0, note: 60, pressure: 70, tick: 72),
                .controlChange(channel: 0, controller: 74, value: 99, tick: 84),
                .sysEx(data: [0x7E, 0x7F, 0x09, 0x01], tick: 96)
            ]
        )

        let project = Project(sequences: [imported])
        let engine = SequencerEngine(project: project)
        let exported = try engine.exportSMFData(sequenceIndex: 0, format: .type0)
        let roundTripped = try SequencerEngine.importSMFSequence(exported, sequenceName: "Round Tripped Type0")

        XCTAssertEqual(roundTripped.ppqn, imported.ppqn)
        XCTAssertEqual(roundTripped.tracks.count, imported.tracks.count)
        XCTAssertEqual(roundTripped.tracks[0].events, imported.tracks[0].events)
    }

    func testSMFType1FixtureRoundTripImportExport() throws {
        let fixtureData = Data(Self.smfType1FixtureBytes)

        let imported = try SequencerEngine.importSMFSequence(fixtureData, sequenceName: "Type1 Fixture")
        XCTAssertEqual(imported.ppqn, 96)
        XCTAssertEqual(imported.tracks.count, 2)
        XCTAssertEqual(
            imported.tracks[0].events,
            [
                .noteOn(channel: 0, note: 60, velocity: 100, tick: 0),
                .noteOff(channel: 0, note: 60, velocity: 0, tick: 24)
            ]
        )
        XCTAssertEqual(
            imported.tracks[1].events,
            [
                .programChange(channel: 1, program: 40, tick: 0),
                .controlChange(channel: 1, controller: 1, value: 64, tick: 0),
                .pitchBend(channel: 1, value: 8192, tick: 24)
            ]
        )

        let project = Project(sequences: [imported])
        let engine = SequencerEngine(project: project)
        let exported = try engine.exportSMFData(sequenceIndex: 0, format: .type1)
        let roundTripped = try SequencerEngine.importSMFSequence(exported, sequenceName: "Round Tripped Type1")

        XCTAssertEqual(roundTripped.ppqn, imported.ppqn)
        XCTAssertEqual(roundTripped.tracks.count, imported.tracks.count)
        XCTAssertEqual(roundTripped.tracks.map(\.events), imported.tracks.map(\.events))
    }

    private struct PersistenceHeader: Decodable {
        let schemaVersion: Int
    }

    private struct SchedulingRunResult {
        let events: [SequencerEngine.ScheduledEvent]
        let maxJitterTicks: Int
        let jitterVariance: Double
    }

    private func runSyntheticScheduling(
        engineTemplate: SequencerEngine,
        totalTicks: Int,
        stepTicks: Int,
        loadIterations: Int
    ) -> SchedulingRunResult {
        var engine = engineTemplate
        engine.play()

        var events: [SequencerEngine.ScheduledEvent] = []
        var jitters: [Double] = []
        var advanced = 0

        while advanced < totalTicks {
            syntheticCPULoad(iterations: loadIterations + ((advanced % 5) * 2_000))

            let windowStart = engine.transport.tickPosition
            let consumed = min(stepTicks, totalTicks - advanced)
            let windowEnd = windowStart + consumed
            let scheduled = engine.advanceTransportAndCollectScheduledEvents(by: consumed)
            events.append(contentsOf: scheduled)

            for event in scheduled {
                jitters.append(Double(max(0, windowEnd - event.event.tick)))
            }
            advanced += consumed
        }

        let maxJitter = Int(jitters.max() ?? 0)
        let mean = jitters.reduce(0, +) / Double(max(1, jitters.count))
        let variance = jitters.reduce(0, { partial, value in
            let delta = value - mean
            return partial + (delta * delta)
        }) / Double(max(1, jitters.count))

        return SchedulingRunResult(events: events, maxJitterTicks: maxJitter, jitterVariance: variance)
    }

    private func syntheticCPULoad(iterations: Int) {
        guard iterations > 0 else {
            return
        }

        var accumulator = 0
        for i in 0..<iterations {
            accumulator = accumulator &+ ((i &* 31) ^ (accumulator >> 1))
            accumulator = accumulator &* 1664525 &+ 1013904223
        }
        if accumulator == Int.min {
            XCTFail("Synthetic load sentinel should be unreachable.")
        }
    }

    private static func syntheticTimingEvents(channel: UInt8, noteStart: UInt8, count: Int) -> [MIDIEvent] {
        var events: [MIDIEvent] = []
        for index in 0..<count {
            let tick = index * 24
            let note = UInt8(Int(noteStart) + (index % 12))
            events.append(.noteOn(channel: channel, note: note, velocity: 100, tick: tick))
            events.append(.noteOff(channel: channel, note: note, velocity: 0, tick: tick + 12))
        }
        return events
    }

    private static let smfType0FixtureBytes: [UInt8] = [
        0x4D, 0x54, 0x68, 0x64,
        0x00, 0x00, 0x00, 0x06,
        0x00, 0x00,
        0x00, 0x01,
        0x00, 0x60,
        0x4D, 0x54, 0x72, 0x6B,
        0x00, 0x00, 0x00, 0x25,
        0x00, 0x90, 0x3C, 0x64,
        0x18, 0x80, 0x3C, 0x00,
        0x0C, 0xC0, 0x08,
        0x0C, 0xE0, 0x00, 0x08,
        0x0C, 0xD0, 0x5A,
        0x0C, 0xA0, 0x3C, 0x46,
        0x0C, 0xB0, 0x4A, 0x63,
        0x0C, 0xF0, 0x04, 0x7E, 0x7F, 0x09, 0x01,
        0x00, 0xFF, 0x2F, 0x00
    ]

    private static let smfType1FixtureBytes: [UInt8] = [
        0x4D, 0x54, 0x68, 0x64,
        0x00, 0x00, 0x00, 0x06,
        0x00, 0x01,
        0x00, 0x02,
        0x00, 0x60,
        0x4D, 0x54, 0x72, 0x6B,
        0x00, 0x00, 0x00, 0x0C,
        0x00, 0x90, 0x3C, 0x64,
        0x18, 0x80, 0x3C, 0x00,
        0x00, 0xFF, 0x2F, 0x00,
        0x4D, 0x54, 0x72, 0x6B,
        0x00, 0x00, 0x00, 0x0F,
        0x00, 0xC1, 0x28,
        0x00, 0xB1, 0x01, 0x40,
        0x18, 0xE1, 0x00, 0x40,
        0x00, 0xFF, 0x2F, 0x00
    ]
}
