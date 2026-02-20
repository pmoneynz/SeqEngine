# SequencerEngine 2-Week Remediation Execution Board

Owner: engineering  
Start date: 2026-02-20  
Duration: 10 working days (2 weeks)  
Priority order: **P0 first, then P1**  
Branch: `cursor/sequencer-engine-status-526a`

## Execution Status (live)

- [x] Board created and committed.
- [x] PR-01 implementation started and committed (`5284244`, `146b615`).
- [x] PR-02 CI gate implementation started and committed (`c7e8d60`).
- [x] PR-03 test hardening started and committed (`d45f9db`).
- [ ] Full validation run (`swift test`, `swift build -c release`) pending in an environment with Swift toolchain.

## Hard Rules

- [ ] No P1 implementation begins until all P0 PRs are merged and green.
- [ ] Every PR includes red->green tests, implementation, and docs updates.
- [ ] Merge gate must be green for:
  - [ ] `swift test` (full, unfiltered)
  - [ ] `swift build -c release`
  - [ ] architecture boundary check
  - [ ] API diff check

## Daily Command Pack (exact commands)

Run these every day before opening/updating a PR:

```bash
git status --short --branch
swift test
swift build -c release
bash harness/architecture/check-boundaries.sh "$PWD"
bash harness/quality/check-api-diff.sh "$PWD" "origin/main"
bash harness/review/self-review.sh "$PWD" --strict
bash harness/review/secondary-review.sh "$PWD"
bash harness/quality/evaluate-kill-criteria.sh "$PWD" --enforce
```

## Week 1 (P0)

### Day 1 - PR-01 start: song-mode emission path
- [x] Add failing tests for song-mode scheduled emission:
  - [x] emits events during active song step
  - [x] emits across step transition inside one scheduling window
  - [x] stops emission at `repeats=0` end marker
  - [x] loops emission under `loopToStep`
- [x] Implement song-aware emission in `advanceTransport(by:sequenceIndex:emit:)`.
- [ ] Open PR-01 with evidence bundle.

Test commands:

```bash
swift test --filter SongModeScheduling
swift test --filter SequencerEngineTests
swift build -c release
```

### Day 2 - PR-01 complete and merge
- [x] Add parity oracle tests:
  - [x] `playSong` streamed scheduling vs flattened sequence oracle fixture A
  - [x] fixture B
  - [x] fixture C
- [ ] Fix edge cases found in code review.
- [ ] Merge PR-01 only after green CI and review signoff.

Test commands:

```bash
swift test --filter SongModeScheduling
swift test --filter SongToSequence
swift test
swift build -c release
```

### Day 3 - PR-02: full-suite CI as required gate
- [x] Update workflow(s) to run mandatory full suite:
  - [x] `swift test` (unfiltered) in CI
  - [x] `swift build -c release` in CI
- [ ] Ensure these jobs are required checks.
- [ ] Open and merge PR-02 after green CI.

Test commands:

```bash
swift test
swift build -c release
gh run list --limit 20
```

### Day 4 - PR-03 start: determinism and stress hardening (song mode)
- [x] Add deterministic seeded fixture generator for song-mode scheduling.
- [x] Add stress test target for large multi-step songs.
- [x] Add repeated-run hash test for deterministic output.

Test commands:

```bash
swift test --filter SongModeDeterminism
swift test --filter Stress
swift test
```

### Day 5 - PR-03 complete and merge
- [ ] Validate deterministic parity over randomized corpus.
- [ ] Finalize P0 evidence and merge PR-03.
- [ ] Confirm all P0 items done before starting P1.

Measurable acceptance:
- [ ] 1,000 seeded fixtures: 0 mismatches
- [ ] >=60,000 scheduled song-mode events: 0 drops
- [ ] 20 repeated runs: identical deterministic output hash

Test commands:

```bash
swift test --filter SongModeDeterminism
swift test --filter OfflineStress
swift test
swift build -c release
```

## Week 2 (P1)

### Day 6 - PR-04 start: concurrency boundary
- [ ] Add actor-based concurrency facade for engine mutations.
- [ ] Add concurrent command tests.
- [ ] Keep existing API compatibility (no silent breaking changes).

Test commands:

```bash
swift test --filter Concurrent
swift test --filter ThreadSafety
swift test
```

### Day 7 - PR-04 complete and merge
- [ ] Harden race-prone call paths.
- [ ] Merge PR-04 after concurrency tests pass.

Measurable acceptance:
- [ ] 10,000 mixed concurrent commands: 0 crashes / 0 invariant violations
- [ ] API parity test: actor facade vs direct engine command outcomes match

Test commands:

```bash
swift test --filter Concurrent
swift test
swift build -c release
```

### Day 8 - PR-05: track controls (mute/solo/velocity scaling)
- [ ] Implement mute behavior in scheduler output path.
- [ ] Implement solo behavior across track set.
- [ ] Implement per-track velocity scaling with clamp.
- [ ] Add persistence coverage for new fields if added to models.

Test commands:

```bash
swift test --filter Mute
swift test --filter Solo
swift test --filter Velocity
swift test --filter Persistence
swift test
```

### Day 9 - PR-06 start: callback/observer surfaces
- [ ] Add callback hooks for:
  - [ ] transport state changes
  - [ ] timeline position updates
  - [ ] emitted MIDI events
  - [ ] record/overdub status changes
- [ ] Add deterministic callback ordering tests.

Test commands:

```bash
swift test --filter Callback
swift test --filter Observer
swift test
```

### Day 10 - PR-06 complete + docs/spec alignment + release closeout
- [ ] Remove unsupported claims or finish missing implementations.
- [ ] Update README and product/spec docs to match shipped behavior exactly.
- [ ] Generate final evidence bundle and close execution plan.

Measurable acceptance:
- [ ] Callback ordering hash stable across 100 repeated runs
- [ ] Docs-to-code claim audit: 0 unresolved mismatches
- [ ] All required CI gates green on final merge

Test commands:

```bash
swift test
swift build -c release
bash harness/architecture/check-boundaries.sh "$PWD"
bash harness/quality/check-api-diff.sh "$PWD" "origin/main"
bash harness/review/self-review.sh "$PWD" --strict
bash harness/review/secondary-review.sh "$PWD"
```

## PR Slice Index

- PR-01 (P0): Song-mode scheduled event emission correctness
- PR-02 (P0): Mandatory full-suite CI gates
- PR-03 (P0): Song-mode determinism and stress hardening
- PR-04 (P1): Concurrency safety boundary
- PR-05 (P1): Mute/solo/velocity scaling
- PR-06 (P1): Observer callbacks + docs/spec truth alignment

## Done Criteria (program-level)

- [ ] All P0 PRs merged and green.
- [ ] All P1 PRs merged and green.
- [ ] Full `swift test` and `swift build -c release` required in CI.
- [ ] Song-mode streamed scheduling parity and stress acceptance achieved.
- [ ] Concurrency boundary and tests in place.
- [ ] Spec/documentation claims match implementation exactly.
