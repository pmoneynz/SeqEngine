---
task: "Build a production Swift SequencerEngine module (iOS/macOS) with deterministic multi-track MIDI sequencing, pattern/song workflows, and a stable importable API."
test_command: "swift test && swift build -c release"
---

# Task: SequencerEngine Swift Module (macOS + iOS)

Build a complete, reusable Swift module that can be imported into apps to provide a fully functional multi-track, MIDI-enabled, pattern-based sequencer.

This task is based on `RogerLinn.md` and `sequencerManual.md` and uses only requirements that are explicit in those sources.

## Source-Backed Product Spec

### Proven Requirements from Source Docs

- Sequencer timing resolution must be 96 PPQN (ticks per quarter note); 48 PPQN is historical minimum, 96 PPQN is preferred.
- Quantization ("timing correct") must support note values: `1/8`, `1/8 triplet`, `1/16`, `1/16 triplet`, `1/32`, `1/32 triplet`, and `off`.
- Swing must be deterministic, applied to even subdivisions, and support `50%` through `75%`.
- Shift timing must support earlier/later movement in tick units when quantization is active.
- Note repeat must retrigger held notes at the quantization interval.
- Sequencing model must be pattern/sequence-first and support song arrangement as a list of sequence steps with repeat counts.
- The sequence model in the manual supports up to 99 sequences; song mode supports 20 songs and up to 250 steps per song.
- MIDI support must include note, velocity, program change, pitch bend, channel pressure, poly pressure, CC, and SysEx event data.
- Drum and MIDI track behaviors must be distinct (e.g., transpose affects MIDI tracks, not drum tracks).
- Tempo model must support sequence tempo, master tempo, and optional mid-sequence tempo changes.
- Tap tempo must support averaging behavior (2/3/4 taps).
- Track output routing must support channel + port assignment, including optional dual destination routing.
- Recording workflow helpers must include wait-for-key and one-bar count-in behavior.
- Erase workflow must support real-time erase in overdub and region/type filtered erase while stopped.

### Scope Decisions (Explicitly Declared)

Because the source docs represent multiple hardware generations with different limits, this task defines implementation targets that preserve behavior while keeping the engine practical:

- Capacity target: minimum 32 tracks per sequence (Roger Linn workstation baseline), configurable up to 99 tracks for parity with manual behavior.
- Note-capacity target: validate data structures and scheduling with at least 60,000 note events.
- Song target: support up to 250 song steps and loop-to-step behavior.
- Sequence container target: support up to 99 sequences per project.
- Song container target: support up to 20 songs per project.

## In Scope

- Swift Package named `SequencerEngine` with library products for iOS and macOS.
- Core timing engine with deterministic 96 PPQN scheduling.
- Multi-track sequence model with pattern/loop playback.
- Song mode with ordered sequence steps, repeat counts, and loop/end behavior.
- Real-time and offline quantization, swing, shift timing, and note repeat.
- Event model for major MIDI message classes used by the manuals.
- Transport controls (`play`, `stop`, `locate`, `record`, `overdub`) and record-ready semantics.
- Recording helpers: `waitForKey` and `countIn` (including count-in recording rules).
- Track-level controls: mute/on-off, solo, velocity scaling, transpose (MIDI tracks only), routing.
- Sequence editing operations:
  - insert/delete/copy bars
  - copy events (replace/merge)
  - step edit insert/delete/update
  - edit loop with undo-and-off behavior
  - erase operations (real-time and stopped-region modes)
- Tempo system:
  - sequence vs master tempo source
  - optional mid-sequence tempo change list (on/off)
  - tap tempo averaging (2/3/4 taps)
- Persistence:
  - JSON project save/load for internal format
  - SMF import/export (Type 0 and Type 1) for interoperability
- Public API surface that is straightforward to integrate in external apps.
- Unit and integration tests proving deterministic behavior and API correctness.

## Out of Scope

- Audio sample playback engine, synthesis engine, DSP effects, or mixer DSP.
- UI screens, pad graphics, or app-level UX implementation.
- Cloud sync or collaboration features.
- Plugin formats (AUv3/VST) in this iteration.
- Hardware-specific MIDI drivers beyond CoreMIDI usage.

## Public API Requirements

- Provide one primary facade type (`SequencerEngine`) for host apps.
- Provide explicit domain models for `Project`, `Sequence`, `Track`, `Song`, `SongStep`, and `MIDIEvent`.
- Provide async-safe transport control and mutation APIs.
- Provide callback/observer hooks for:
  - transport state changes
  - current timeline position (bar.beat.tick)
  - emitted MIDI events
  - record/overdub status
- API must allow:
  - creating sequences/tracks/songs
  - recording and editing events
  - non-destructive edit operations
  - saving/loading project files
  - exporting/importing SMF

## Non-Functional Requirements

- Deterministic timing under load is mandatory; jitter consistency is prioritized.
- No dropped events in deterministic offline render simulation tests.
- Thread-safe public API for concurrent host interactions.
- Zero UI framework dependency inside core module.
- Build and test must pass on current stable Xcode + Swift toolchain for macOS and iOS targets.

## Build Plan

### Phase 1 - Package + Architecture Foundation

- Create Swift package layout (`Sources`, `Tests`, `Fixtures`, `Docs`).
- Define domain types and event enums.
- Implement timeline math (`Tick`, `BarBeatTick`, signature-aware conversions).
- Implement deterministic scheduler abstraction with injectable clock for tests.

### Phase 2 - Sequencing Core

- Implement transport state machine and playback cursor.
- Implement sequence/track storage with ordered events.
- Implement recording and overdub write paths.
- Implement wait-for-key and count-in assisted recording behavior.
- Implement track muting, solo, and per-track velocity scaling.

### Phase 3 - Timing Intelligence

- Implement quantization grid and offline "move existing" operation.
- Implement deterministic swing (50-75%) on even subdivisions.
- Implement shift timing (earlier/later, bounded by note value).
- Implement note repeat tied to current quantization note value.

### Phase 4 - Editing and Arrangement

- Implement bar operations (insert/delete/copy).
- Implement event copy (replace/merge) with region targeting.
- Implement step edit operations for all supported MIDI event types.
- Implement erase operations for overdub-hold and stopped-region filtered erase.
- Implement song mode (steps, reps, loop/end, convert-to-sequence).
- Implement edit-loop behavior with `turnOff` vs `undoAndOff`.

### Phase 5 - MIDI + Persistence + API Stabilization

- Implement CoreMIDI bridge adapters (in/out routing per track).
- Implement SMF import/export Type 0/1.
- Implement JSON project serializer/deserializer with schema versioning.
- Freeze and document public API (`README` + usage snippets + migration notes).

### Phase 6 - Validation and Hardening

- Add deterministic timing regression tests.
- Add property tests for timeline/quantization invariants.
- Add integration tests for arrangement, loop, and tempo-change transitions.
- Benchmark and document event throughput and jitter stats.

## Success Criteria

1. [x] `swift test && swift build -c release` exits 0 on the target development machine.
2. [x] Swift package exposes importable module `SequencerEngine` for iOS and macOS.
3. [x] Engine supports 96 PPQN timeline math and correct bar.beat.tick conversion for changing time signatures.
4. [x] Sequence supports at least 32 tracks; configuration supports raising to 99 tracks.
5. [x] Each track can be typed as drum or MIDI, and transpose affects only MIDI tracks.
6. [x] Track routing supports primary MIDI channel/port and optional auxiliary destination.
7. [x] Quantization supports the 7 source-backed note-value modes (including `off`).
8. [x] Swing is configurable 50-75% and delays even subdivisions deterministically.
9. [x] Shift timing supports earlier/later tick offsets when quantization is active.
10. [x] Note repeat retriggers held notes at the current quantize interval.
11. [x] Transport supports play/stop/locate plus record and overdub behaviors.
12. [x] Record-ready behavior is implemented and tested for punch-in transitions.
13. [x] Wait-for-key mode starts playback/record only after first MIDI key press, and the trigger key is not recorded.
14. [x] Count-in mode inserts exactly one pre-roll bar and enforces no event recording during count-in.
15. [x] Sequence loop behavior supports loop-to-bar semantics and no-loop mode.
16. [x] Project supports 99 sequences and 20 songs with per-song up to 250 steps.
17. [x] Song mode supports `reps`, `0=end` semantics, loop-to-step, and stop-at-end behavior.
18. [x] Song-to-sequence conversion produces contiguous event data and preserves ordering.
19. [x] Tempo system supports sequence tempo and master tempo source selection.
20. [x] Mid-sequence tempo changes can be inserted, listed, toggled ON/OFF, and deleted.
21. [x] Tap tempo supports averaging modes for 2, 3, and 4 taps.
22. [x] Event model and step edit support: note, program change, pitch bend, channel pressure, poly pressure, CC, and SysEx.
23. [x] Edit operations are implemented: insert/delete/copy bars and copy events replace/merge.
24. [x] Erase operations support overdub hold-erase and stopped-region erase with ALL/ONLY/ALL EXCEPT event-type filters.
25. [x] Edit loop supports `turn off` and `undo & off` with tested rollback semantics.
26. [x] Project persistence supports JSON save/load with schema versioning.
27. [x] SMF import/export works for at least one fixture per type (0 and 1) with round-trip assertions.
28. [x] Deterministic timing tests verify stable event scheduling under synthetic CPU load.
29. [x] Engine passes a stress test sequence containing at least 60,000 note events without dropped scheduled events in deterministic offline validation.
30. [x] Public API documentation includes a minimal integration example that can play a 4-bar pattern.

## Constraints

- Use Swift and Apple platform APIs only; no cross-language runtime dependencies.
- Keep core engine free of AppKit/UIKit/SwiftUI dependencies.
- Do not introduce placeholder implementations or TODO stubs in shipped paths.
- Preserve deterministic ordering for simultaneous events (stable sort + deterministic tie-breakers).
- Keep algorithmic complexity explicit for scheduling and edit operations.
- Any behavior not proven in source docs must be labeled as an implementation decision in code/docs.
- Any intentional deviation from manual-era hard limits (or behavior) must be documented with rationale.

## Validation Evidence Required

- `swift test` output summary with pass counts.
- `swift build -c release` output summary.
- Timing determinism test output (including jitter/variance metrics from test harness).
- Changed files list grouped by domain (`core`, `timing`, `editing`, `midi`, `persistence`, `tests`).
- Short edge-case report covering:
  - sequence boundary events
  - swing + shift interactions
  - song step transitions with tempo or program changes
  - drum-vs-MIDI transpose behavior
  - wait-for-key and count-in recording boundary behavior

## Phased Criteria

- [x] Phase 1 complete: package and architecture foundation in place <!-- group: 1 -->
- [x] Phase 2 complete: transport + sequence/track core functional <!-- group: 2 -->
- [x] Phase 3 complete: quantize/swing/shift/note-repeat functional <!-- group: 3 -->
- [x] Phase 4 complete: editing + arrangement features functional <!-- group: 4 -->
- [x] Phase 5 complete: MIDI + persistence + API stabilization complete <!-- group: 5 -->
- [x] Phase 6 complete: full validation, hardening, and docs complete <!-- group: 6 -->
