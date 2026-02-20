import Foundation
import SequencerEngine
import SwiftUI
import AppKit

@main
struct SequencerEngineTestGUIApp: App {
    @StateObject private var model = HarnessViewModel()

    init() {
        // SwiftPM executables can launch as background-only processes unless
        // we explicitly opt into regular app activation on macOS.
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        WindowGroup("SequencerEngine Test GUI") {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 980, minHeight: 700)
                .onAppear {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
        }
    }
}

private struct ContentView: View {
    @EnvironmentObject private var model: HarnessViewModel

    private let grid = [
        GridItem(.adaptive(minimum: 210, maximum: 280), spacing: 10)
    ]

    var body: some View {
        VStack(spacing: 12) {
            Text("SequencerEngine Test Harness")
                .font(.title2)
                .bold()

            GroupBox("Transport Snapshot") {
                let transport = model.engine.transport
                HStack(spacing: 16) {
                    Text("mode: \(String(describing: transport.mode))")
                    Text("tick: \(transport.tickPosition)")
                    Text("recordReady: \(transport.isRecordReady.description)")
                    Text("waitingForKey: \(transport.isWaitingForKey.description)")
                    Text("countIn: \(transport.countInRemainingTicks)")
                    Text("seqs: \(model.engine.project.sequences.count)")
                    Text("songs: \(model.engine.project.songs.count)")
                }
                .font(.system(.body, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            ScrollView {
                LazyVGrid(columns: grid, spacing: 10) {
                    actionButton("Reset Seed Project", action: model.resetEngine)
                    actionButton("Run All API Smoke Tests", action: model.runAllSmokeTests)

                    actionButton("Tempo + Tap Tempo", action: model.runTempoTests)
                    actionButton("Transport + Punch", action: model.runTransportTests)
                    actionButton("Step Edit + Region Ops", action: model.runStepAndEditTests)
                    actionButton("Edit Loop + Song", action: model.runSongAndLoopTests)
                    actionButton("Persistence + SMF", action: model.runPersistenceAndSMFTests)
                    actionButton("Timeline + Utility Types", action: model.runUtilityTypeTests)
                }
                .padding(.bottom, 8)
            }

            GroupBox("Log") {
                ScrollView {
                    Text(model.logText)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: .infinity)
            }
        }
        .padding(14)
    }

    private func actionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.borderedProminent)
    }
}

@MainActor
private final class HarnessViewModel: ObservableObject {
    @Published private(set) var engine: SequencerEngine = .init(project: HarnessViewModel.seedProject())
    @Published private(set) var logText: String = "Ready.\n"

    private let tempDirectory = FileManager.default.temporaryDirectory

    func resetEngine() {
        engine.load(project: Self.seedProject())
        log("reset", "engine loaded with seed project")
    }

    func runAllSmokeTests() {
        resetEngine()
        runTempoTests()
        runTransportTests()
        runStepAndEditTests()
        runSongAndLoopTests()
        runPersistenceAndSMFTests()
        runUtilityTypeTests()
        log("all", "smoke test run complete")
    }

    func runTempoTests() {
        run("setTempoSource(.master)") {
            engine.setTempoSource(.master)
        }
        run("setTempoSource(.sequence)") {
            engine.setTempoSource(.sequence)
        }
        run("setMasterTempoBPM(132)") {
            engine.setMasterTempoBPM(132)
            assert(engine.project.masterTempoBPM == 132)
        }
        run("setSequenceTempoBPM(140, at:0)") {
            let success = engine.setSequenceTempoBPM(140, at: 0)
            assert(success)
        }
        run("insert/list/enable/delete tempo change") {
            guard let inserted = engine.insertTempoChange(sequenceIndex: 0, tick: 96, bpm: 150, isEnabled: true) else {
                throw HarnessError.failed("insertTempoChange returned nil")
            }
            let listed = engine.listTempoChanges(sequenceIndex: 0, includeDisabled: true)
            assert(listed.contains(where: { $0.id == inserted.id }))
            assert(engine.setTempoChangeEnabled(sequenceIndex: 0, tempoChangeID: inserted.id, false))
            assert(engine.deleteTempoChange(sequenceIndex: 0, tempoChangeID: inserted.id))
        }
        run("effectiveTempoBPM + clearTapTempoHistory") {
            _ = engine.effectiveTempoBPM()
            _ = engine.effectiveTempoBPM(sequenceIndex: 0, tick: 0)
            engine.clearTapTempoHistory()
        }
        run("registerTapTempoTap(mode:at:)") {
            let t0 = 1000.0
            _ = engine.registerTapTempoTap(mode: .taps2, at: t0)
            let bpm = engine.registerTapTempoTap(mode: .taps2, at: t0 + 0.5)
            assert(bpm != nil)
        }
        run("registerTapTempoTap(mode:)") {
            _ = engine.registerTapTempoTap(mode: .taps3)
        }
    }

    func runTransportTests() {
        run("play / advanceTransport / stop") {
            engine.play()
            engine.advanceTransport(by: 48)
            engine.stop()
            assert(engine.transport.mode == .stopped)
        }
        run("locate(24)") {
            engine.locate(tick: 24)
            assert(engine.transport.tickPosition == 24)
        }
        run("record + handleIncomingMIDI") {
            engine.record()
            let echoed = engine.handleIncomingMIDI(.noteOn(channel: 0, note: 60, velocity: 100, tick: 0))
            assert(echoed != nil)
        }
        run("overdub") {
            engine.overdub()
            assert(engine.transport.mode == .overdubbing)
        }
        run("armWaitForKey + handleIncomingMIDI") {
            engine.armWaitForKey()
            let ignored = engine.handleIncomingMIDI(.controlChange(channel: 0, controller: 1, value: 64, tick: 0))
            assert(ignored == nil)
            _ = engine.handleIncomingMIDI(.noteOn(channel: 0, note: 48, velocity: 90, tick: 0))
            assert(engine.transport.mode == .recording)
        }
        run("armCountIn + handleIncomingMIDI") {
            engine.armCountIn()
            let ignored = engine.handleIncomingMIDI(.noteOn(channel: 0, note: 62, velocity: 100, tick: 0))
            assert(ignored == nil)
            engine.advanceTransport(by: 10_000)
        }
        run("advanceTransportAndCollectScheduledEvents") {
            engine.play()
            engine.locate(tick: 0)
            let scheduled = engine.advanceTransportAndCollectScheduledEvents(by: 192, sequenceIndex: 0)
            guard scheduled.isEmpty == false else {
                throw HarnessError.failed("expected scheduled events in 0..<192 window")
            }
        }
        run("setRecordReady / punchIn / punchOut") {
            engine.stop()
            engine.play()
            engine.setRecordReady(true)
            assert(engine.punchIn(.record))
            assert(engine.punchOut())
            assert(engine.punchIn(.overdub))
            assert(engine.punchOut())
        }
    }

    func runStepAndEditTests() {
        run("stepEditInsertEvent") {
            try engine.stepEditInsertEvent(
                sequenceIndex: 0,
                trackIndex: 0,
                eventIndex: 0,
                event: .programChange(channel: 0, program: 12, tick: 0)
            )
        }
        run("stepEditUpdateEvent") {
            try engine.stepEditUpdateEvent(
                sequenceIndex: 0,
                trackIndex: 0,
                eventIndex: 0,
                event: .controlChange(channel: 0, controller: 10, value: 100, tick: 0)
            )
        }
        run("stepEditDeleteEvent") {
            _ = try engine.stepEditDeleteEvent(sequenceIndex: 0, trackIndex: 0, eventIndex: 0)
        }
        run("insertBars / deleteBars / copyBars") {
            try engine.insertBars(sequenceIndex: 0, atBar: 2, count: 1)
            try engine.deleteBars(sequenceIndex: 0, startingAt: 2, count: 1)
            try engine.copyBars(sequenceIndex: 0, from: 1, count: 1, to: 2, mode: .merge)
        }
        run("copyEvents") {
            try engine.copyEvents(
                sequenceIndex: 0,
                trackIndex: 0,
                sourceStartTick: 0,
                length: 96,
                destinationStartTick: 192,
                mode: .merge
            )
        }
        run("eraseRegion") {
            engine.stop()
            let erased = try engine.eraseRegion(
                sequenceIndex: 0,
                trackIndex: 0,
                startTick: 0,
                length: 24,
                filter: .all
            )
            assert(erased >= 0)
        }
        run("eraseOverdubHold") {
            engine.overdub()
            let erased = try engine.eraseOverdubHold(
                sequenceIndex: 0,
                trackIndex: 0,
                heldRange: 0..<48,
                filter: .only([.note, .controlChange])
            )
            assert(erased >= 0)
        }
    }

    func runSongAndLoopTests() {
        run("turnOnEditLoop / turnOffEditLoop") {
            try engine.turnOnEditLoop(sequenceIndex: 0, startBar: 1, barCount: 2)
            try engine.turnOffEditLoop()
        }
        run("turnOnEditLoop / undoAndTurnOffEditLoop") {
            try engine.turnOnEditLoop(sequenceIndex: 0, startBar: 1, barCount: 2)
            try engine.insertBars(sequenceIndex: 0, atBar: 2, count: 1)
            try engine.undoAndTurnOffEditLoop()
        }
        run("playSong(at:)") {
            assert(engine.playSong(at: 0))
            engine.advanceTransport(by: 96)
        }
        run("convertSongToSequence(songIndex:)") {
            let sequence = try engine.convertSongToSequence(songIndex: 0, sequenceName: "Flattened Test")
            assert(sequence.tracks.isEmpty == false)
        }
    }

    func runPersistenceAndSMFTests() {
        run("save/load project JSON data") {
            let data = try engine.saveProjectJSONData(prettyPrinted: true)
            try engine.loadProjectJSONData(data)
            assert(data.isEmpty == false)
        }
        run("save/load project JSON file") {
            let url = tempDirectory.appendingPathComponent("sequencer-engine-harness-project.json")
            try engine.saveProjectJSON(to: url, prettyPrinted: true)
            try engine.loadProjectJSON(from: url)
        }
        run("exportSMFData + static importSMFSequence") {
            let smf = try engine.exportSMFData(sequenceIndex: 0, format: .type1)
            let imported = try SequencerEngine.importSMFSequence(smf, sequenceName: "Static Import")
            assert(imported.tracks.isEmpty == false)
        }
        run("importSMFData into current project") {
            let smf = try engine.exportSMFData(sequenceIndex: 0, format: .type0)
            let index = try engine.importSMFData(smf, sequenceName: "Imported In Place")
            assert(index >= 0)
        }
    }

    func runUtilityTypeTests() {
        run("TimelineMapper conversion") {
            let mapper = TimelineMapper(
                ppqn: 96,
                changes: [
                    TimeSignatureChange(bar: 1, signature: TimeSignature(numerator: 4, denominator: 4)),
                    TimeSignatureChange(bar: 5, signature: TimeSignature(numerator: 3, denominator: 4))
                ]
            )
            _ = mapper.ticksPerBeat(for: TimeSignature(numerator: 4, denominator: 4))
            _ = mapper.ticksPerBar(for: TimeSignature(numerator: 3, denominator: 4))
            let tick = mapper.toTick(BarBeatTick(bar: 5, beat: 1, tick: 0))
            let bbt = mapper.toBarBeatTick(tick: tick)
            assert(bbt.bar >= 1)
        }
        run("QuantizationMode utilities") {
            let names = QuantizationMode.allCases.map(\.displayName)
            let ticks = QuantizationMode.allCases.compactMap { $0.intervalTicks(ppqn: 96) }
            assert(names.isEmpty == false)
            assert(ticks.isEmpty == false)
        }
        run("Swing + ShiftTiming") {
            let swing = try Swing(percent: 58)
            _ = swing.appliedTick(120, quantizationMode: .sixteenth, ppqn: 96)
            let shift = try ShiftTiming(direction: .earlier, ticks: 3)
            _ = shift.appliedTick(120, quantizationMode: .sixteenth, ppqn: 96)
        }
        run("NoteRepeat retriggerEvents") {
            let repeater = NoteRepeat(quantizationMode: .eighth, ppqn: 96, gateTicks: 24)
            let events = repeater.retriggerEvents(
                heldNotes: [.init(channel: 0, note: 60, velocity: 100)],
                heldRange: 0..<192
            )
            assert(events.isEmpty == false)
        }
        run("Project / Sequence / Track / Song mutators") {
            var project = Project()
            var sequence = Sequence(name: "Model API")
            var track = Track(name: "Model Track", kind: .midi)
            track.setPrimaryRouting(port: "busA", channel: 3)
            track.setAuxiliaryRouting(MIDIDestination(port: "busB", channel: 4))
            try track.insertStepEvent(.noteOn(channel: 0, note: 64, velocity: 100, tick: 0), at: 0)
            try track.updateStepEvent(at: 0, with: .noteOff(channel: 0, note: 64, velocity: 0, tick: 48))
            _ = try track.deleteStepEvent(at: 0)
            track.events = Self.seedTrackEvents(ppqn: 96)
            track.transpose(semitones: 2)
            track.insertBars(atBar: 2, count: 1, ticksPerBar: 384)
            track.deleteBars(startingAtBar: 2, count: 1, ticksPerBar: 384)
            track.copyBars(fromBar: 1, count: 1, toBar: 2, ticksPerBar: 384, mode: .merge)
            track.copyEvents(fromRange: 0..<96, toStartTick: 192, mode: .replace)
            _ = track.eraseEvents(inRange: 0..<24, filter: .allExcept([.sysEx]))
            try sequence.addTrack(track)
            try sequence.setTrackCapacity(40)
            sequence.setTempoBPM(123)
            let tc = sequence.insertTempoChange(atTick: 96, bpm: 128, isEnabled: true)
            _ = sequence.listedTempoChanges(includeDisabled: true)
            _ = sequence.setTempoChangeEnabled(id: tc.id, false)
            _ = sequence.deleteTempoChange(id: tc.id)
            _ = sequence.tempoBPM(atTick: 192)
            try sequence.insertBars(atBar: 2, count: 1)
            try sequence.deleteBars(startingAt: 2, count: 1)
            try sequence.copyBars(from: 1, count: 1, to: 2, mode: .merge)
            try sequence.copyEvents(trackIndex: 0, sourceStartTick: 0, length: 96, destinationStartTick: 192, mode: .merge)
            sequence.setLoopToBar(4)
            _ = sequence.loopLengthTicks()
            sequence.setNoLoop()
            try project.addSequence(sequence)
            project.setMasterTempoBPM(111)
            project.setTempoSource(.master)
            var song = Song(name: "Model Song")
            try song.addStep(SongStep(sequenceIndex: 0, repeats: 2))
            try project.addSong(song)
            assert(project.sequences.count == 1 && project.songs.count == 1)
        }
    }

    private func run(_ name: String, _ block: () throws -> Void) {
        do {
            try block()
            log("pass", name)
        } catch {
            log("fail", "\(name) -> \(error)")
        }
    }

    private func log(_ kind: String, _ message: String) {
        let line = "[\(timestamp())] \(kind.uppercased()): \(message)"
        logText += line + "\n"
    }

    private func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }

    private static func seedProject() -> Project {
        let ppqn = Sequence.defaultPPQN
        let trackA = Track(name: "Track A", kind: .midi, events: seedTrackEvents(ppqn: ppqn))
        let trackB = Track(
            name: "Track B",
            kind: .drum,
            events: [
                .controlChange(channel: 9, controller: 1, value: 50, tick: ppqn / 2),
                .controlChange(channel: 9, controller: 1, value: 40, tick: ppqn + (ppqn / 2))
            ]
        )
        let sequenceA = Sequence(
            name: "Seq A",
            ppqn: ppqn,
            tempoBPM: 120,
            trackCapacity: 32,
            loopMode: .loopToBar(4),
            tempoChanges: [.init(tick: 192, bpm: 126)],
            tracks: [trackA, trackB]
        )
        let sequenceB = Sequence(
            name: "Seq B",
            ppqn: ppqn,
            tempoBPM: 128,
            trackCapacity: 32,
            loopMode: .loopToBar(2),
            tracks: [
                Track(
                    name: "Track C",
                    kind: .midi,
                    events: [
                        .noteOn(channel: 0, note: 67, velocity: 95, tick: 0),
                        .noteOff(channel: 0, note: 67, velocity: 0, tick: ppqn)
                    ]
                )
            ]
        )
        let song = Song(
            name: "Song 1",
            steps: [
                SongStep(sequenceIndex: 0, repeats: 2),
                SongStep(sequenceIndex: 1, repeats: 1)
            ],
            endBehavior: .loopToStep(0)
        )
        return Project(
            sequences: [sequenceA, sequenceB],
            songs: [song],
            masterTempoBPM: 120,
            tempoSource: .sequence
        )
    }

    private static func seedTrackEvents(ppqn: Int) -> [MIDIEvent] {
        [
            .noteOn(channel: 0, note: 60, velocity: 100, tick: 0),
            .noteOff(channel: 0, note: 60, velocity: 0, tick: ppqn),
            .noteOn(channel: 0, note: 64, velocity: 100, tick: ppqn * 2),
            .noteOff(channel: 0, note: 64, velocity: 0, tick: (ppqn * 3)),
            .pitchBend(channel: 0, value: 8_192, tick: ppqn / 2),
            .channelPressure(channel: 0, pressure: 80, tick: ppqn / 3),
            .polyPressure(channel: 0, note: 64, pressure: 80, tick: ppqn / 4),
            .programChange(channel: 0, program: 10, tick: 0),
            .sysEx(data: [0x7E, 0x7F, 0x09, 0x01], tick: ppqn * 2)
        ]
    }
}

private enum HarnessError: Error {
    case failed(String)
}
