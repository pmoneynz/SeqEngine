# API Stability Policy

## Semantic Versioning

`SequencerEngine` and `SequencerEngineIO` follow Semantic Versioning:

- Patch (`x.y.Z`): bug fixes and non-breaking internal changes.
- Minor (`x.Y.z`): backward-compatible API additions and behavior improvements.
- Major (`X.y.z`): breaking API changes.

## Deprecation Window

Public APIs are deprecated for at least one minor release before removal, except for urgent security or correctness issues that cannot safely be deferred.

## Integration Boundary

The protocol facades `MIDIInput`, `MIDIOutput`, and `RealtimeSessioning` are the stable integration boundary for realtime IO composition. Concrete CoreMIDI adapters are supported as provisional implementations behind that boundary.

## Breaking Change Gate

API breakage is checked in CI with:

- `harness/quality/check-api-diff.sh`

This gate runs `swift package diagnose-api-breaking-changes` against a baseline treeish (default `origin/main`) for `SequencerEngine` and `SequencerEngineIO`.
