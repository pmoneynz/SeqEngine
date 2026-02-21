# SequencerEngine

Deterministic multi-track MIDI sequencer engine for iOS and macOS.

## Installation

Add this package in Xcode using `Package.swift` or **File -> Add Packages...**, then:

```swift
import SequencerEngine
```

## API Stability and Deprecation Policy

This package follows Semantic Versioning for `SequencerEngine` and `SequencerEngineIO`:

- Patch releases contain non-breaking fixes.
- Minor releases contain backward-compatible additions.
- Major releases may contain breaking changes.

Public APIs are deprecated for at least one minor release before removal, except for urgent security/correctness fixes. The stable realtime integration boundary is protocol-based (`MIDIInput`, `MIDIOutput`, `RealtimeSessioning`), while concrete CoreMIDI adapters remain provisional implementations behind that facade.

Run `swift package diagnose-api-breaking-changes` against `origin/main` in CI to detect public API breakage. See `docs/api-stability.md` for details.

## Minimal Integration (4-bar playback)

```swift
import SequencerEngine

let bars = 4
let ppqn = Sequence.defaultPPQN
let ticksPerBar = ppqn * 4

var track = Track(name: "Pattern Track", kind: .midi)
for bar in 0..<bars {
    let startTick = bar * ticksPerBar
    track.events.append(.noteOn(channel: 1, note: 60, velocity: 100, tick: startTick))
    track.events.append(.noteOff(channel: 1, note: 60, velocity: 0, tick: startTick + ppqn))
}

let sequence = Sequence(
    name: "Pattern A",
    ppqn: ppqn,
    loopMode: .loopToBar(bars),
    tracks: [track]
)
var engine = SequencerEngine(project: Project(sequences: [sequence]))

engine.play()
let scheduled = engine.advanceTransportAndCollectScheduledEvents(
    by: bars * ticksPerBar,
    sequenceIndex: 0
)
print("Scheduled events: \(scheduled.count)")
```

## Public API Reference (all callable functions)

This list is generated from the current public source in `Sources/SequencerEngine`.

### `SequencerEngine.ScheduledEvent`

- `init(sequenceIndex:trackIndex:eventIndex:event:)`

### `SequencerEngine.TransportState`

- `init(mode:tickPosition:isRecordReady:isWaitingForKey:countInRemainingTicks:activeSongIndex:activeSongStepIndex:activeSongRepeat:)`

### `SequencerEngine`

- `init(project:)`
- `load(project:)`
- `setTempoSource(_:)`
- `setMasterTempoBPM(_:)`
- `setSequenceTempoBPM(_:at:)`
- `insertTempoChange(sequenceIndex:tick:bpm:isEnabled:)`
- `listTempoChanges(sequenceIndex:includeDisabled:)`
- `setTempoChangeEnabled(sequenceIndex:tempoChangeID:_:)`
- `deleteTempoChange(sequenceIndex:tempoChangeID:)`
- `effectiveTempoBPM(sequenceIndex:tick:)`
- `clearTapTempoHistory()`
- `registerTapTempoTap(mode:at:)`
- `registerTapTempoTap(mode:)`
- `play()`
- `stop()`
- `locate(tick:)`
- `record()`
- `overdub()`
- `stepEditInsertEvent(sequenceIndex:trackIndex:eventIndex:event:)`
- `stepEditUpdateEvent(sequenceIndex:trackIndex:eventIndex:event:)`
- `stepEditDeleteEvent(sequenceIndex:trackIndex:eventIndex:)`
- `insertBars(sequenceIndex:atBar:count:beatsPerBar:)`
- `deleteBars(sequenceIndex:startingAt:count:beatsPerBar:)`
- `copyBars(sequenceIndex:from:count:to:mode:beatsPerBar:)`
- `copyEvents(sequenceIndex:trackIndex:sourceStartTick:length:destinationStartTick:mode:)`
- `eraseRegion(sequenceIndex:trackIndex:startTick:length:filter:)`
- `eraseOverdubHold(sequenceIndex:trackIndex:heldRange:filter:)`
- `turnOnEditLoop(sequenceIndex:startBar:barCount:)`
- `turnOffEditLoop()`
- `undoAndTurnOffEditLoop()`
- `armWaitForKey()`
- `armCountIn()`
- `playSong(at:)`
- `advanceTransport(by:)`
- `advanceTransportAndCollectScheduledEvents(by:sequenceIndex:)`
- `handleIncomingMIDI(_:)`
- `setRecordReady(_:)`
- `punchIn(_:)`
- `punchOut()`
- `convertSongToSequence(songIndex:sequenceName:)`

### `Project`

- `init(sequences:songs:masterTempoBPM:tempoSource:)`
- `addSequence(_:)`
- `addSong(_:)`
- `setMasterTempoBPM(_:)`
- `setTempoSource(_:)`

### `Sequence.TempoChange`

- `init(id:tick:bpm:isEnabled:)`

### `Sequence`

- `init(id:name:ppqn:tempoBPM:trackCapacity:loopMode:tempoChanges:tracks:)`
- `setTrackCapacity(_:)`
- `setTempoBPM(_:)`
- `insertTempoChange(atTick:bpm:isEnabled:)`
- `listedTempoChanges(includeDisabled:)`
- `setTempoChangeEnabled(id:_:)`
- `deleteTempoChange(id:)`
- `tempoBPM(atTick:)`
- `addTrack(_:)`
- `insertBars(atBar:count:beatsPerBar:)`
- `deleteBars(startingAt:count:beatsPerBar:)`
- `copyBars(from:count:to:mode:beatsPerBar:)`
- `copyEvents(trackIndex:sourceStartTick:length:destinationStartTick:mode:)`
- `setNoLoop()`
- `setLoopToBar(_:)`
- `loopLengthTicks(beatsPerBar:)`

### `QuantizationMode`

- `intervalTicks(ppqn:)`

### `Swing`

- `init(percent:)`
- `appliedTick(_:quantizationMode:ppqn:)`

### `ShiftTiming`

- `init(direction:ticks:)`
- `appliedTick(_:quantizationMode:ppqn:)`

### `NoteRepeat.HeldNote`

- `init(channel:note:velocity:)`

### `NoteRepeat`

- `init(quantizationMode:ppqn:gateTicks:)`
- `retriggerEvents(heldNotes:heldRange:)`

### `Track.Routing`

- `init(primary:auxiliary:)`

### `Track`

- `init(id:name:kind:routing:events:)`
- `transpose(semitones:)`
- `setPrimaryRouting(port:channel:)`
- `setAuxiliaryRouting(_:)`
- `insertStepEvent(_:at:)`
- `updateStepEvent(at:with:)`
- `deleteStepEvent(at:)`
- `insertBars(atBar:count:ticksPerBar:)`
- `deleteBars(startingAtBar:count:ticksPerBar:)`
- `copyBars(fromBar:count:toBar:ticksPerBar:mode:)`
- `copyEvents(fromRange:toStartTick:mode:)`
- `eraseEvents(inRange:filter:)`

### `MIDIDestination`

- `init(port:channel:)`

### `Song`

- `init(id:name:steps:endBehavior:)`
- `addStep(_:)`

### `SongStep`

- `init(sequenceIndex:repeats:)`

### `MIDIEvent` (Codable)

- `encode(to:)`
- `init(from:)`

### Persistence (`SequencerEngine` extension)

- `saveProjectJSONData(prettyPrinted:)`
- `loadProjectJSONData(_:)`
- `saveProjectJSON(to:prettyPrinted:)`
- `loadProjectJSON(from:)`

### SMF (`SequencerEngine` extension)

- `exportSMFData(sequenceIndex:format:)`
- `importSMFData(_:sequenceName:)`
- `static importSMFSequence(_:sequenceName:)`

### Timeline

#### `TimeSignature`
- `init(numerator:denominator:)`

#### `TimeSignatureChange`
- `init(bar:signature:)`

#### `BarBeatTick`
- `init(bar:beat:tick:)`

#### `TimelineMapper`
- `init(ppqn:changes:)`
- `ticksPerBeat(for:)`
- `ticksPerBar(for:)`
- `toTick(_:)`
- `toBarBeatTick(tick:)`

## Public SDK Surface (enums, errors, constants, properties)

This section lists the public non-function API surface.

### Public enums and errors

#### Engine enums/errors
- `SequencerEngine.PunchMode`: `.record`, `.overdub`
- `SequencerEngine.SongConversionError`: `.songIndexOutOfRange`, `.sequenceIndexOutOfRange(stepIndex:sequenceIndex:)`, `.noMaterializedSteps`
- `SequencerEngine.StepEditError`: `.sequenceIndexOutOfRange`, `.trackIndexOutOfRange`, `.eventIndexOutOfRange`
- `SequencerEngine.EditOperationError`: `.sequenceIndexOutOfRange`, `.trackIndexOutOfRange`, `.invalidBar`, `.invalidBarCount`, `.invalidTicksPerBar`, `.invalidTickLength`
- `SequencerEngine.EraseOperationError`: `.sequenceIndexOutOfRange`, `.trackIndexOutOfRange`, `.invalidTickLength`, `.transportMustBeStopped`, `.transportMustBeOverdubbing`
- `SequencerEngine.EditLoopError`: `.sequenceIndexOutOfRange`, `.invalidStartBar`, `.invalidBarCount`, `.alreadyActive`, `.notActive`
- `SequencerEngine.TransportState.Mode`: `.stopped`, `.playing`, `.recording`, `.overdubbing`

#### Model enums/errors
- `TempoSource`: `.sequence`, `.master`
- `TapTempoAveragingMode`: `.taps2`, `.taps3`, `.taps4`
- `Project.CapacityError`: `.sequenceLimitReached`, `.songLimitReached`
- `Sequence.LoopMode`: `.noLoop`, `.loopToBar(Int)`
- `Sequence.CapacityError`: `.outOfRange`, `.trackLimitReached`
- `Sequence.EditError`: `.invalidBar`, `.invalidBarCount`, `.invalidTicksPerBar`, `.trackIndexOutOfRange`, `.invalidTickLength`
- `QuantizationMode`: `.off`, `.eighth`, `.eighthTriplet`, `.sixteenth`, `.sixteenthTriplet`, `.thirtySecond`, `.thirtySecondTriplet`
- `Swing.ConfigurationError`: `.outOfRange`
- `ShiftTiming.Direction`: `.earlier`, `.later`
- `ShiftTiming.ConfigurationError`: `.ticksMustBePositive`
- `Track.StepEditError`: `.eventIndexOutOfRange`
- `Track.Kind`: `.drum`, `.midi`
- `Track.EventCopyMode`: `.replace`, `.merge`
- `Track.EventType`: `.note`, `.programChange`, `.pitchBend`, `.channelPressure`, `.polyPressure`, `.controlChange`, `.sysEx`
- `Track.EventTypeFilter`: `.all`, `.only([Track.EventType])`, `.allExcept([Track.EventType])`
- `Song.EndBehavior`: `.stopAtEnd`, `.loopToStep(Int)`
- `Song.CapacityError`: `.stepLimitReached`
- `MIDIEvent`: `.noteOn`, `.noteOff`, `.programChange`, `.pitchBend`, `.channelPressure`, `.polyPressure`, `.controlChange`, `.sysEx`

#### Persistence / SMF enums/errors
- `ProjectPersistenceError`: `.unsupportedSchemaVersion(Int)`
- `SMFFileFormat`: `.type0`, `.type1`
- `SMFError`: `.sequenceIndexOutOfRange`, `.sequenceLimitReached`, `.invalidHeader`, `.unsupportedFormat(UInt16)`, `.unsupportedTimeDivision(UInt16)`, `.missingTrackChunk`, `.truncated`, `.invalidVariableLengthQuantity`, `.invalidRunningStatus`, `.unsupportedEventStatus(UInt8)`

### Public constants

- `Project.maxSequences`
- `Project.maxSongs`
- `Project.defaultMasterTempoBPM`
- `Sequence.defaultPPQN`
- `Sequence.minTrackCapacity`
- `Sequence.maxTrackCapacity`
- `Sequence.defaultBeatsPerBar`
- `Sequence.defaultTempoBPM`
- `Swing.minimumPercent`
- `Swing.maximumPercent`
- `Song.maxSteps`
- `SequencerEngine.currentProjectSchemaVersion`

### Public properties

#### Engine properties
- `SequencerEngine.project` (`public private(set)`)
- `SequencerEngine.transport` (`public private(set)`)
- `SequencerEngine.activeEditLoopSequenceIndex` (`public private(set)`)
- `SequencerEngine.ScheduledEvent.sequenceIndex`
- `SequencerEngine.ScheduledEvent.trackIndex`
- `SequencerEngine.ScheduledEvent.eventIndex`
- `SequencerEngine.ScheduledEvent.event`
- `SequencerEngine.TransportState.mode`
- `SequencerEngine.TransportState.tickPosition`
- `SequencerEngine.TransportState.isRecordReady`
- `SequencerEngine.TransportState.isWaitingForKey`
- `SequencerEngine.TransportState.countInRemainingTicks`
- `SequencerEngine.TransportState.activeSongIndex`
- `SequencerEngine.TransportState.activeSongStepIndex`
- `SequencerEngine.TransportState.activeSongRepeat`
- `SequencerEngine.TransportState.isCountInActive` (computed)
- `SequencerEngine.TransportState.isRunning` (computed)

#### Core model properties
- `TapTempoAveragingMode.tapCount` (computed)
- `Project.sequences`
- `Project.songs`
- `Project.masterTempoBPM`
- `Project.tempoSource`
- `Sequence.TempoChange.id`
- `Sequence.TempoChange.tick`
- `Sequence.TempoChange.bpm`
- `Sequence.TempoChange.isEnabled`
- `Sequence.id`
- `Sequence.name`
- `Sequence.ppqn`
- `Sequence.tempoBPM`
- `Sequence.trackCapacity` (`public private(set)`)
- `Sequence.loopMode`
- `Sequence.tempoChanges` (`public private(set)`)
- `Sequence.tracks`
- `QuantizationMode.displayName` (computed)
- `Swing.percent`
- `ShiftTiming.direction`
- `ShiftTiming.ticks`
- `NoteRepeat.HeldNote.channel`
- `NoteRepeat.HeldNote.note`
- `NoteRepeat.HeldNote.velocity`
- `NoteRepeat.quantizationMode`
- `NoteRepeat.ppqn`
- `NoteRepeat.gateTicks`
- `Track.id`
- `Track.name`
- `Track.kind`
- `Track.routing`
- `Track.events`
- `Track.Routing.primary`
- `Track.Routing.auxiliary`
- `MIDIDestination.port`
- `MIDIDestination.channel`
- `Song.id`
- `Song.name`
- `Song.steps`
- `Song.endBehavior`
- `SongStep.sequenceIndex`
- `SongStep.repeats`

#### Timeline properties
- `TimeSignature.numerator`
- `TimeSignature.denominator`
- `TimeSignatureChange.bar`
- `TimeSignatureChange.signature`
- `BarBeatTick.bar`
- `BarBeatTick.beat`
- `BarBeatTick.tick`
- `TimelineMapper.ppqn`
- `TimelineMapper.changes`
