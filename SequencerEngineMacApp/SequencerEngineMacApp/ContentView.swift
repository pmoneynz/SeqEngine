import AVFoundation
import SequencerEngine
import SwiftUI

struct ContentView: View {
    @StateObject private var panel = SequencerPanelViewModel()

    var body: some View {
        GeometryReader { proxy in
            let panelSize = MPCLayout.panelSize
            let scale = min((proxy.size.width - 28) / panelSize.width, (proxy.size.height - 28) / panelSize.height)

            ZStack {
                Color(red: 0.9, green: 0.9, blue: 0.9).ignoresSafeArea()

                panelCanvas
                    .frame(width: panelSize.width, height: panelSize.height, alignment: .topLeading)
                    .scaleEffect(scale, anchor: .topLeading)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .frame(minWidth: 1280, minHeight: 860)
    }

    private var panelCanvas: some View {
        ZStack(alignment: .topLeading) {
            // Chassis shell
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color(red: 0.86, green: 0.86, blue: 0.86))
                .overlay(RoundedRectangle(cornerRadius: 26).stroke(.black.opacity(0.82), lineWidth: 1.5))
                .frame(width: MPCLayout.panelOuter.width, height: MPCLayout.panelOuter.height)
                .position(x: MPCLayout.panelOuter.midX, y: MPCLayout.panelOuter.midY)

            Rectangle()
                .fill(Color(red: 0.84, green: 0.84, blue: 0.84))
                .overlay(Rectangle().stroke(.black.opacity(0.78), lineWidth: 1.1))
                .frame(width: MPCLayout.baseLip.width, height: MPCLayout.baseLip.height)
                .position(x: MPCLayout.baseLip.midX, y: MPCLayout.baseLip.midY)

            Rectangle()
                .fill(Color(red: 0.88, green: 0.88, blue: 0.88))
                .overlay(Rectangle().stroke(.black.opacity(0.8), lineWidth: 1.2))
                .frame(width: MPCLayout.mainControl.width, height: MPCLayout.mainControl.height)
                .position(x: MPCLayout.mainControl.midX, y: MPCLayout.mainControl.midY)

            clusterFrame(MPCLayout.sideStrip) { sideStrip }
            clusterFrame(MPCLayout.branding) { brandingRow }
            clusterFrame(MPCLayout.displayBlock) { displayBlock }
            clusterFrame(MPCLayout.softKeys) { softKeysRow }
            clusterFrame(MPCLayout.padBlock) { padMatrixBlock }

            clusterFrame(MPCLayout.vents) { vents }
            clusterFrame(MPCLayout.dateEntry) { dateEntryCluster }
            clusterFrame(MPCLayout.commands) { commandsCluster }
            clusterFrame(MPCLayout.dataEntry) { dataEntryCluster }
            clusterFrame(MPCLayout.cursor) { cursorCluster }
            clusterFrame(MPCLayout.realtime) { realtimeCluster }
            clusterFrame(MPCLayout.transport) { transportCluster }
        }
        .foregroundStyle(.black)
    }

    private func clusterFrame<Content: View>(_ rect: CGRect, @ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(width: rect.width, height: rect.height, alignment: .topLeading)
            .position(x: rect.midX, y: rect.midY)
    }

    private var sideStrip: some View {
        VStack(alignment: .center, spacing: 9) {
            KnobView(label: "STEREO VOLUME")
            KnobView(label: "RECORD LEVEL")
            KnobView(label: "DISPLAY\nCONTRAST")
            Spacer(minLength: 4)
            SmallStackButton(title: "PAD BANK")
            SmallStackButton(title: "FULL LEVEL")
            SmallStackButton(title: "16 LEVELS")
            SmallStackButton(title: "NOTE VARIATION\nASSIGN")
            SmallStackButton(title: "AFTER")
            fader
        }
    }

    private var brandingRow: some View {
        HStack(alignment: .bottom, spacing: 10) {
            Text("AKAI").font(.system(size: 43, weight: .black))
            Text("professional").font(.system(size: 14, weight: .medium)).offset(y: -5)
            Text("Roger Linn")
                .font(.system(size: 18, weight: .regular, design: .serif))
                .italic()
                .offset(y: -5)
            Spacer()
            Text("INTEGRATED RHYTHM MACHINE\n16BIT DRUM SAMPLER/MIDI SEQUENCER")
                .multilineTextAlignment(.trailing)
                .font(.system(size: 10, weight: .bold))
        }
    }

    private var displayBlock: some View {
        VStack(spacing: 6) {
            HStack {
                Text("MIDI PRODUCTION CENTER").font(.system(size: 11, weight: .bold))
                Spacer()
                Text("M P C 3 0 0 0").font(.system(size: 39, weight: .black)).tracking(1.8)
            }
            RoundedRectangle(cornerRadius: 4)
                .stroke(.black.opacity(0.9), lineWidth: 1.2)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color(red: 0.82, green: 0.82, blue: 0.82)))
                .overlay(
                    ZStack {
                        RoundedRectangle(cornerRadius: 2).stroke(.black.opacity(0.8), lineWidth: 1).padding(16)
                        Text(panel.displayReadout)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 24)
                    }
                )
            HStack(spacing: 24) {
                ForEach(1...4, id: \.self) { i in
                    Text(panel.softKeyLabel(at: i - 1))
                        .font(.system(size: 9, weight: .bold))
                }
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 5).stroke(.black.opacity(0.88), lineWidth: 1.15))
    }

    private var softKeysRow: some View {
        HStack(spacing: 24) {
            ForEach(1...4, id: \.self) { i in
                VStack(spacing: 4) {
                    Text(panel.softKeyLabel(at: i - 1)).font(.system(size: 8, weight: .semibold))
                    PanelButton(title: "", width: 40, height: 15) {
                        panel.pressSoftKey(i - 1)
                    }
                }
            }
        }
    }

    private var padMatrixBlock: some View {
        VStack(spacing: 6) {
            Text("DRUMS").font(.system(size: 11, weight: .bold))
            let labels = ["CRASH", "CRASH2", "RIDE CYMBAL", "RIDE BELL", "HIGH TOM", "MID TOM", "LOW TOM", "FLOOR TOM", "ALT SNARE", "SNARE", "HHAT OPEN", "HHAT PEDAL", "SIDE STICK", "BASS", "HHAT CLOSED", "HHAT LOOSE"]
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(84), spacing: 10), count: 4), spacing: 9) {
                ForEach(labels.indices, id: \.self) { idx in
                    DrumPad(label: labels[idx], number: 16 - idx) {
                        panel.pressPad(number: 16 - idx)
                    }
                }
            }
            .padding(10)
            .background(Rectangle().stroke(.black.opacity(0.88), lineWidth: 1.15))
        }
    }

    private var dateEntryCluster: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("DATE ENTRY").font(.system(size: 9, weight: .bold))
            ForEach([["7", "8", "9"], ["4", "5", "6"], ["1", "2", "3"], ["0", ".", "ENTER"]], id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { key in
                        PanelButton(title: key, width: 38, height: 16, fontSize: 8) {
                            panel.pressDateKey(key)
                        }
                    }
                }
            }
        }
    }

    private var commandsCluster: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("COMMANDS").font(.system(size: 9, weight: .bold))
            ForEach([["DISK", "PROGRAM\nSOUNDS", "MIXER\nEFFECTS"], ["MIDI", "SONG", "OTHER"], ["SEQ EDIT", "STEP EDIT", "EDIT LOOP"], ["TEMPO/SYNC", "TRANSPOSE", "SIMUL SEQ"], ["AUTO PUNCH", "COUNT IN", "WAIT FOR KEY"]], id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { key in
                        PanelButton(
                            title: key,
                            width: 54,
                            height: 18,
                            fontSize: 7,
                            isActive: panel.isCommandActive(key)
                        ) {
                            panel.pressCommandKey(key)
                        }
                    }
                }
            }
        }
    }

    private var vents: some View {
        VStack(spacing: 6) {
            ForEach(0..<5, id: \.self) { _ in
                HStack(spacing: 9) {
                    ForEach(0..<4, id: \.self) { _ in
                        Capsule().fill(.black.opacity(0.88)).frame(width: 66, height: 4)
                    }
                }
            }
        }
    }

    private var dataEntryCluster: some View {
        VStack(spacing: 5) {
            HStack(spacing: 8) {
                PanelButton(title: "-", width: 28, height: 16, fontSize: 12) { panel.adjustDataEntry(by: -1) }
                PanelButton(title: "+", width: 28, height: 16, fontSize: 12) { panel.adjustDataEntry(by: 1) }
            }
            .font(.system(size: 14, weight: .black))
            Text("DATA ENTRY").font(.system(size: 8, weight: .bold))
            Circle()
                .fill(Color(red: 0.79, green: 0.79, blue: 0.79))
                .overlay(Circle().stroke(.black.opacity(0.9), lineWidth: 1.2))
                .frame(width: 74, height: 74)
        }
    }

    private var cursorCluster: some View {
        VStack(alignment: .center, spacing: 4) {
            Text("CURSOR").font(.system(size: 9, weight: .bold))
            PanelButton(title: "UP", width: 34, height: 14, fontSize: 7) { panel.pressCursor(.up) }
            HStack(spacing: 8) {
                PanelButton(title: "LEFT", width: 42, height: 14, fontSize: 7) { panel.pressCursor(.left) }
                PanelButton(title: "RIGHT", width: 42, height: 14, fontSize: 7) { panel.pressCursor(.right) }
            }
            PanelButton(title: "DOWN", width: 34, height: 14, fontSize: 7) { panel.pressCursor(.down) }
        }
    }

    private var realtimeCluster: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("REAL TIME").font(.system(size: 9, weight: .bold))
            HStack(spacing: 6) {
                ForEach(["ERASE", "TIMING CORRECT", "TAP TEMPO", "MAIN SCREEN", "HELP"], id: \.self) { key in
                    PanelButton(title: key, width: 54, height: 18, fontSize: 7, isActive: panel.isRealtimeActive(key)) {
                        panel.pressRealtimeKey(key)
                    }
                }
            }
        }
    }

    private var transportCluster: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PLAY / REC").font(.system(size: 10, weight: .heavy))
            HStack(spacing: 6) {
                ForEach(["<<", "<", "LOCATE", ">", ">>"], id: \.self) { key in
                    PanelButton(title: key, width: 58, height: 24, fontSize: 10) {
                        panel.pressTransportKey(key)
                    }
                }
            }
            HStack(spacing: 6) {
                ForEach(["REC", "OVER DUB", "STOP", "PLAY", "PLAY START"], id: \.self) { key in
                    PanelButton(title: key, width: 58, height: 24, fontSize: 8, isActive: panel.isTransportKeyActive(key)) {
                        panel.pressTransportKey(key)
                    }
                }
            }
        }
        .padding(10)
        .background(Rectangle().stroke(.black.opacity(0.9), lineWidth: 1.2))
    }

    private var fader: some View {
        VStack(spacing: 4) {
            Text("10")
            Rectangle().fill(.black.opacity(0.5)).frame(width: 2, height: 78)
                .overlay(RoundedRectangle(cornerRadius: 2).fill(Color(red: 0.78, green: 0.78, blue: 0.78)).frame(width: 22, height: 14))
            Text("0")
        }
        .font(.system(size: 8, weight: .bold))
    }
}

private enum MPCLayout {
    // Panel-local coordinate space (0,0 is top-left of chassis).
    static let panelSize = CGSize(width: 1484, height: 1312)
    static let panelOuter = CGRect(x: 0, y: 0, width: 1484, height: 1312)
    static let mainControl = CGRect(x: 40, y: 218, width: 1404, height: 878)
    static let baseLip = CGRect(x: 0, y: 1158, width: 1484, height: 154)

    // Pixel-locked cluster frames measured from the panel-local reference.
    static let sideStrip = CGRect(x: 60, y: 234, width: 84, height: 780)
    static let branding = CGRect(x: 170, y: 68, width: 680, height: 80)
    static let displayBlock = CGRect(x: 224, y: 156, width: 626, height: 268)
    static let softKeys = CGRect(x: 346, y: 428, width: 382, height: 58)
    static let padBlock = CGRect(x: 244, y: 494, width: 604, height: 500)

    static let vents = CGRect(x: 898, y: 62, width: 300, height: 98)
    static let dateEntry = CGRect(x: 894, y: 172, width: 150, height: 220)
    static let commands = CGRect(x: 1062, y: 166, width: 196, height: 278)
    static let dataEntry = CGRect(x: 908, y: 490, width: 120, height: 130)
    static let cursor = CGRect(x: 1086, y: 482, width: 132, height: 124)
    static let realtime = CGRect(x: 904, y: 664, width: 360, height: 62)
    static let transport = CGRect(x: 854, y: 754, width: 470, height: 170)
}

private struct PanelButton: View {
    let title: String
    var width: CGFloat = 52
    var height: CGFloat = 20
    var fontSize: CGFloat = 8
    var isActive: Bool = false
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(isActive ? Color(red: 0.73, green: 0.82, blue: 0.73) : Color(red: 0.85, green: 0.85, blue: 0.85))
                RoundedRectangle(cornerRadius: 3)
                    .stroke(.black.opacity(0.92), lineWidth: 1.05)
                Text(title)
                    .font(.system(size: fontSize, weight: .bold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 2)
                    .lineLimit(2)
            }
            .frame(width: width, height: height)
        }
        .buttonStyle(.plain)
    }
}

private struct DrumPad: View {
    let label: String
    let number: Int
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(label)
                    Spacer()
                    Text("\(number)")
                }
                .font(.system(size: 7, weight: .bold))

                Rectangle()
                    .fill(Color(red: 0.74, green: 0.74, blue: 0.74))
                    .overlay(Rectangle().stroke(.black.opacity(0.94), lineWidth: 1.1))
                    .frame(height: 74)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct KnobView: View {
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 7, weight: .bold))
                .multilineTextAlignment(.center)

            Circle()
                .fill(Color(red: 0.81, green: 0.81, blue: 0.81))
                .overlay(Circle().stroke(.black.opacity(0.92), lineWidth: 1.1))
                .frame(width: 34, height: 34)
                .overlay(
                    Capsule()
                        .fill(.black.opacity(0.7))
                        .frame(width: 1.5, height: 10)
                        .offset(y: -7)
                )
        }
    }
}

private struct SmallStackButton: View {
    let title: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 7, weight: .bold))
                .multilineTextAlignment(.center)
            PanelButton(title: "", width: 34, height: 14) {}
        }
    }
}

@MainActor
private final class SequencerPanelViewModel: ObservableObject {
    enum Screen: String {
        case main
        case seqEdit
        case stepEdit
        case erase
        case tempo
        case editLoop
    }

    enum CursorTarget: CaseIterable {
        case sequence
        case track
        case locate
        case tempo
    }

    enum CursorDirection {
        case up
        case down
        case left
        case right
    }

    @Published private(set) var engine: SequencerEngine
    @Published private(set) var screen: Screen = .main
    @Published private(set) var cursorTarget: CursorTarget = .locate
    @Published private(set) var selectedSequenceIndex = 0
    @Published private(set) var selectedTrackIndex = 0
    @Published private(set) var locateTick = 0
    @Published private(set) var dateEntryBuffer = ""
    @Published private(set) var swingPercent = 50
    @Published private(set) var lastMessage = "Ready."
    @Published private(set) var padAssignmentSummary = "Pads 1-4: unassigned"
    @Published private(set) var waitForKeyEnabled = false
    @Published private(set) var countInEnabled = false
    @Published private(set) var recordReady = false

    private var stepCursor = 0
    private var tapMode: TapTempoAveragingMode = .taps2
    private var lastTempoChangeID: UUID?
    private var padNoteMap: [Int: UInt8] = [:]
    private var transportTimer: Timer?
    private var lastTransportUpdate: Date?
    private var transportTickAccumulator = 0.0
    private let samplePlayback = PadSamplePlayback()
    private let sampleDirectoryURL = URL(fileURLWithPath: "/Users/peterwadams/Desktop/test_samples", isDirectory: true)
    private var lastSavedURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("sequencer-panel-project.json")

    init() {
        self.engine = SequencerEngine(project: Self.seedProject())
        for pad in 1...16 {
            padNoteMap[pad] = UInt8(35 + (pad - 1))
        }
        assignSamplesToPads()
    }

    var displayReadout: String {
        let mode = String(describing: engine.transport.mode).replacingOccurrences(of: "Mode.", with: "")
        let seqCount = engine.project.sequences.count
        let songCount = engine.project.songs.count
        let tempo = String(format: "%.1f", engine.effectiveTempoBPM(sequenceIndex: selectedSequenceIndex, tick: engine.transport.tickPosition))
        let target = cursorTargetLabel(cursorTarget)
        return """
        Screen: \(screen.rawValue.uppercased())  Target: \(target)
        Seq:\(selectedSequenceIndex + 1) Trk:\(selectedTrackIndex + 1) Tick:\(engine.transport.tickPosition)
        BPM:\(tempo) \(engine.project.tempoSource == .master ? "(MASTER)" : "(SEQ)")
        Mode:\(mode) Rdy:\(engine.transport.isRecordReady ? "ON" : "OFF") Wait:\(engine.transport.isWaitingForKey ? "ON" : "OFF")
        Date:\(dateEntryBuffer.isEmpty ? "-" : dateEntryBuffer)  Msg:\(lastMessage)
        \(padAssignmentSummary)
        Seqs:\(seqCount) Songs:\(songCount)
        """
    }

    func softKeyLabel(at index: Int) -> String {
        guard (0..<4).contains(index) else { return "SOFT KEY" }
        switch screen {
        case .main:
            return ["TK ON/OFF", "SOLO", "TRK-", "TRK+"][index]
        case .seqEdit:
            return ["INS BARS", "DEL BARS", "CPY BARS", "CPY EVTS"][index]
        case .stepEdit:
            return ["INSERT", "UPDATE", "DELETE", "NEXT EVT"][index]
        case .erase:
            return ["ERASE REG", "ERASE ODB", "CLR TAP", "ALL EVTS"][index]
        case .tempo:
            return ["SRC TOG", "BPM -", "BPM +", "TAP MODE"][index]
        case .editLoop:
            return ["LOOP ON", "LOOP OFF", "UNDO LOOP", "TO SONG"][index]
        }
    }

    func pressSoftKey(_ index: Int) {
        switch screen {
        case .main:
            switch index {
            case 0:
                toggleTrackRouting()
            case 1:
                log("solo monitor toggled")
            case 2:
                selectTrack(selectedTrackIndex - 1)
            case 3:
                selectTrack(selectedTrackIndex + 1)
            default:
                break
            }
        case .seqEdit:
            runSeqEditKey(index)
        case .stepEdit:
            runStepEditKey(index)
        case .erase:
            runEraseKey(index)
        case .tempo:
            runTempoKey(index)
        case .editLoop:
            runEditLoopKey(index)
        }
        syncTransportClockState()
    }

    func pressTransportKey(_ key: String) {
        let ppqn = currentPPQN()
        let oneBar = ppqn * 4
        switch key {
        case "<<":
            locate(by: -oneBar)
        case "<":
            locate(by: -ppqn)
        case "LOCATE":
            engine.locate(tick: max(0, locateTick))
            log("locate -> \(max(0, locateTick))")
        case ">":
            locate(by: ppqn)
        case ">>":
            locate(by: oneBar)
        case "STOP":
            engine.stop()
            waitForKeyEnabled = false
            countInEnabled = false
            log("transport stopped")
        case "PLAY":
            engine.play()
            log("play from current location")
        case "PLAY START":
            engine.locate(tick: 0)
            engine.play()
            locateTick = 0
            log("play from start")
        case "REC":
            if engine.transport.mode == .recording {
                _ = engine.punchOut()
                log("punch out from record")
            } else if engine.transport.mode == .playing {
                setRecordReady(true)
                _ = engine.punchIn(.record)
                log("punch in record")
            } else {
                engine.record()
                log("record mode armed")
            }
        case "OVER DUB":
            if engine.transport.mode == .overdubbing {
                _ = engine.punchOut()
                log("punch out from overdub")
            } else if engine.transport.mode == .playing {
                setRecordReady(true)
                _ = engine.punchIn(.overdub)
                log("punch in overdub")
            } else {
                engine.overdub()
                log("overdub mode armed")
            }
        default:
            break
        }
        syncTransportClockState()
    }

    func pressRealtimeKey(_ key: String) {
        switch key {
        case "ERASE":
            screen = .erase
            log("erase screen")
        case "TIMING CORRECT":
            swingPercent = swingPercent >= 75 ? 50 : swingPercent + 1
            log("timing correct swing -> \(swingPercent)%")
        case "TAP TEMPO":
            if let bpm = engine.registerTapTempoTap(mode: tapMode) {
                log("tap tempo -> \(String(format: "%.2f", bpm)) BPM")
            } else {
                log("tap tempo waiting (\(tapMode.tapCount) taps)")
            }
        case "MAIN SCREEN":
            screen = .main
            log("main screen")
        case "HELP":
            log("help: date entry + ENTER sets locate tick")
        default:
            break
        }
    }

    func pressCommandKey(_ key: String) {
        switch key {
        case "DISK":
            do {
                try engine.saveProjectJSON(to: lastSavedURL, prettyPrinted: true)
                try engine.loadProjectJSON(from: lastSavedURL)
                log("disk save/load ok")
            } catch {
                log("disk error: \(error)")
            }
        case "PROGRAM\nSOUNDS":
            assignSamplesToPads()
            log("pad samples assigned from \(sampleDirectoryURL.path)")
        case "MIXER\nEFFECTS":
            let nextTempo = effectiveTempo() + 4
            if let inserted = engine.insertTempoChange(
                sequenceIndex: selectedSequenceIndex,
                tick: max(0, engine.transport.tickPosition),
                bpm: nextTempo,
                isEnabled: true
            ) {
                lastTempoChangeID = inserted.id
                log("tempo change inserted @\(inserted.tick)")
            } else {
                log("tempo change insert failed")
            }
        case "MIDI":
            let firstFour = (1...4).compactMap { pad -> String? in
                guard let note = padNoteMap[pad] else { return nil }
                return "P\(pad)->\(note)"
            }.joined(separator: " ")
            log("midi map \(firstFour)")
        case "SONG":
            if engine.playSong(at: 0) {
                log("song playback started")
            } else {
                log("song playback failed")
            }
        case "OTHER":
            do {
                if let changeID = lastTempoChangeID {
                    _ = engine.setTempoChangeEnabled(
                        sequenceIndex: selectedSequenceIndex,
                        tempoChangeID: changeID,
                        false
                    )
                    _ = engine.deleteTempoChange(sequenceIndex: selectedSequenceIndex, tempoChangeID: changeID)
                    lastTempoChangeID = nil
                }
                let flattened = try engine.convertSongToSequence(songIndex: 0, sequenceName: "Flattened Song")
                var project = engine.project
                try project.addSequence(flattened)
                engine.load(project: project)
                log("song converted to sequence (and last tempo change removed)")
            } catch {
                log("other error: \(error)")
            }
        case "SEQ EDIT":
            screen = .seqEdit
            log("sequence edit screen")
        case "STEP EDIT":
            screen = .stepEdit
            log("step edit screen")
        case "EDIT LOOP":
            screen = .editLoop
            log("edit loop screen")
        case "TEMPO/SYNC":
            screen = .tempo
            log("tempo/sync screen")
        case "TRANSPOSE":
            transposeTrack(by: 1)
            log("transpose +1 semitone")
        case "SIMUL SEQ":
            log("simul seq not implemented in engine")
        case "AUTO PUNCH":
            setRecordReady(!recordReady)
        case "COUNT IN":
            countInEnabled.toggle()
            if countInEnabled {
                engine.armCountIn()
                log("count in enabled")
            } else {
                engine.stop()
                log("count in disabled")
            }
        case "WAIT FOR KEY":
            waitForKeyEnabled.toggle()
            if waitForKeyEnabled {
                engine.armWaitForKey()
                log("wait for key enabled")
            } else {
                engine.play()
                engine.stop()
                log("wait for key disabled")
            }
        default:
            break
        }
        syncTransportClockState()
    }

    func pressDateKey(_ key: String) {
        switch key {
        case "ENTER":
            applyDateEntry()
        case ".":
            dateEntryBuffer.append(".")
        default:
            if key.allSatisfy(\.isNumber) {
                dateEntryBuffer.append(key)
            }
        }
    }

    func adjustDataEntry(by delta: Int) {
        switch cursorTarget {
        case .sequence:
            selectSequence(selectedSequenceIndex + delta)
        case .track:
            selectTrack(selectedTrackIndex + delta)
        case .locate:
            locateTick = max(0, locateTick + (delta * currentPPQN()))
            engine.locate(tick: locateTick)
            log("locate tick -> \(locateTick)")
        case .tempo:
            let newTempo = effectiveTempo() + Double(delta)
            if engine.project.tempoSource == .master {
                engine.setMasterTempoBPM(newTempo)
            } else {
                _ = engine.setSequenceTempoBPM(newTempo, at: selectedSequenceIndex)
            }
            log("tempo -> \(String(format: "%.1f", effectiveTempo()))")
        }
    }

    func pressCursor(_ direction: CursorDirection) {
        let all = CursorTarget.allCases
        guard let index = all.firstIndex(of: cursorTarget) else { return }
        switch direction {
        case .left:
            cursorTarget = all[(index - 1 + all.count) % all.count]
        case .right:
            cursorTarget = all[(index + 1) % all.count]
        case .up:
            adjustDataEntry(by: 1)
        case .down:
            adjustDataEntry(by: -1)
        }
    }

    func pressPad(number: Int) {
        guard number >= 1, number <= 16 else { return }
        let note = padNoteMap[number] ?? UInt8(35 + (number - 1))
        let tick = engine.transport.tickPosition
        let velocity: UInt8 = 110
        samplePlayback.trigger(note: note, velocity: velocity)

        let noteOn = MIDIEvent.noteOn(channel: 9, note: note, velocity: velocity, tick: tick)
        let noteOff = MIDIEvent.noteOff(channel: 9, note: note, velocity: 0, tick: tick + max(1, currentPPQN() / 8))

        let insertedOn = recordIncomingEventIfArmed(noteOn)
        let insertedOff = recordIncomingEventIfArmed(noteOff)
        if insertedOn || insertedOff {
            log("pad \(number) recorded note \(note)")
        } else {
            log("pad \(number) triggered sample")
        }
    }

    private func recordIncomingEventIfArmed(_ event: MIDIEvent) -> Bool {
        guard let recordedEvent = engine.handleIncomingMIDI(event) else {
            return false
        }
        do {
            try engine.stepEditInsertEvent(
                sequenceIndex: selectedSequenceIndex,
                trackIndex: selectedTrackIndex,
                eventIndex: selectedTrackEventCount(),
                event: recordedEvent
            )
            return true
        } catch {
            log("pad record error: \(error)")
            return false
        }
    }

    private func syncTransportClockState() {
        if engine.transport.isRunning {
            startTransportClockIfNeeded()
        } else {
            stopTransportClock()
        }
    }

    private func startTransportClockIfNeeded() {
        guard transportTimer == nil else { return }
        lastTransportUpdate = Date()
        transportTickAccumulator = 0
        transportTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 120.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.transportClockFired()
        }
    }

    private func stopTransportClock() {
        transportTimer?.invalidate()
        transportTimer = nil
        lastTransportUpdate = nil
        transportTickAccumulator = 0
    }

    private func transportClockFired() {
        guard engine.transport.isRunning else {
            stopTransportClock()
            return
        }
        let now = Date()
        guard let lastUpdate = lastTransportUpdate else {
            lastTransportUpdate = now
            return
        }
        lastTransportUpdate = now

        let deltaSeconds = now.timeIntervalSince(lastUpdate)
        guard deltaSeconds > 0 else { return }

        let bpm = max(1.0, engine.effectiveTempoBPM(sequenceIndex: selectedSequenceIndex, tick: engine.transport.tickPosition))
        let ppqn = Double(currentPPQN())
        let ticksPerSecond = (bpm / 60.0) * ppqn

        transportTickAccumulator += ticksPerSecond * deltaSeconds
        let ticksToAdvance = Int(transportTickAccumulator.rounded(.down))
        guard ticksToAdvance > 0 else { return }
        transportTickAccumulator -= Double(ticksToAdvance)

        let scheduled = engine.advanceTransportAndCollectScheduledEvents(
            by: ticksToAdvance,
            sequenceIndex: selectedSequenceIndex
        )
        playScheduledEvents(scheduled)
    }

    private func playScheduledEvents(_ scheduled: [SequencerEngine.ScheduledEvent]) {
        guard scheduled.isEmpty == false else { return }
        for item in scheduled {
            if case let .noteOn(_, note, velocity, _) = item.event, velocity > 0 {
                samplePlayback.trigger(note: note, velocity: velocity)
            }
        }
    }

    private func assignSamplesToPads() {
        let assignments = samplePlayback.assignSamples(
            from: sampleDirectoryURL,
            padToNote: padNoteMap,
            pads: [1, 2, 3, 4]
        )

        if assignments.isEmpty {
            padAssignmentSummary = "Pads 1-4: no audio files found"
            return
        }

        let text = assignments
            .sorted { $0.pad < $1.pad }
            .map { "P\($0.pad)->N\($0.note):\($0.sampleName)" }
            .joined(separator: "  ")
        padAssignmentSummary = text
    }

    func isTransportKeyActive(_ key: String) -> Bool {
        switch key {
        case "REC":
            return engine.transport.mode == .recording
        case "OVER DUB":
            return engine.transport.mode == .overdubbing
        case "PLAY", "PLAY START":
            return engine.transport.mode == .playing
        case "STOP":
            return engine.transport.mode == .stopped
        default:
            return false
        }
    }

    func isCommandActive(_ key: String) -> Bool {
        switch key {
        case "AUTO PUNCH":
            return recordReady
        case "COUNT IN":
            return countInEnabled
        case "WAIT FOR KEY":
            return waitForKeyEnabled
        case "SEQ EDIT":
            return screen == .seqEdit
        case "STEP EDIT":
            return screen == .stepEdit
        case "EDIT LOOP":
            return screen == .editLoop
        case "TEMPO/SYNC":
            return screen == .tempo
        default:
            return false
        }
    }

    func isRealtimeActive(_ key: String) -> Bool {
        switch key {
        case "ERASE":
            return screen == .erase
        case "MAIN SCREEN":
            return screen == .main
        default:
            return false
        }
    }

    private func runSeqEditKey(_ index: Int) {
        do {
            switch index {
            case 0:
                try engine.insertBars(sequenceIndex: selectedSequenceIndex, atBar: 2, count: 1)
                log("seq edit: insert bars")
            case 1:
                try engine.deleteBars(sequenceIndex: selectedSequenceIndex, startingAt: 2, count: 1)
                log("seq edit: delete bars")
            case 2:
                try engine.copyBars(sequenceIndex: selectedSequenceIndex, from: 1, count: 1, to: 2, mode: .merge)
                log("seq edit: copy bars")
            case 3:
                try engine.copyEvents(
                    sequenceIndex: selectedSequenceIndex,
                    trackIndex: selectedTrackIndex,
                    sourceStartTick: 0,
                    length: currentPPQN(),
                    destinationStartTick: currentPPQN() * 2,
                    mode: .merge
                )
                log("seq edit: copy events")
            default:
                break
            }
        } catch {
            log("seq edit error: \(error)")
        }
    }

    private func runStepEditKey(_ index: Int) {
        let tick = engine.transport.tickPosition
        do {
            switch index {
            case 0:
                let event = MIDIEvent.noteOn(channel: 0, note: 60, velocity: 100, tick: tick)
                try engine.stepEditInsertEvent(
                    sequenceIndex: selectedSequenceIndex,
                    trackIndex: selectedTrackIndex,
                    eventIndex: selectedTrackEventCount(),
                    event: event
                )
                log("step edit: insert event")
            case 1:
                let event = MIDIEvent.controlChange(channel: 0, controller: 1, value: 80, tick: tick)
                try engine.stepEditUpdateEvent(
                    sequenceIndex: selectedSequenceIndex,
                    trackIndex: selectedTrackIndex,
                    eventIndex: max(0, stepCursor),
                    event: event
                )
                log("step edit: update event \(stepCursor + 1)")
            case 2:
                _ = try engine.stepEditDeleteEvent(
                    sequenceIndex: selectedSequenceIndex,
                    trackIndex: selectedTrackIndex,
                    eventIndex: max(0, stepCursor)
                )
                stepCursor = max(0, stepCursor - 1)
                log("step edit: delete event")
            case 3:
                stepCursor = min(max(0, selectedTrackEventCount() - 1), stepCursor + 1)
                log("step edit: next event \(stepCursor + 1)")
            default:
                break
            }
        } catch {
            log("step edit error: \(error)")
        }
    }

    private func runEraseKey(_ index: Int) {
        do {
            switch index {
            case 0:
                engine.stop()
                _ = try engine.eraseRegion(
                    sequenceIndex: selectedSequenceIndex,
                    trackIndex: selectedTrackIndex,
                    startTick: 0,
                    length: currentPPQN(),
                    filter: .all
                )
                log("erase: region")
            case 1:
                engine.overdub()
                _ = try engine.eraseOverdubHold(
                    sequenceIndex: selectedSequenceIndex,
                    trackIndex: selectedTrackIndex,
                    heldRange: 0..<currentPPQN(),
                    filter: .all
                )
                log("erase: overdub hold")
            case 2:
                engine.clearTapTempoHistory()
                log("erase: tap history cleared")
            case 3:
                engine.stop()
                _ = try engine.eraseRegion(
                    sequenceIndex: selectedSequenceIndex,
                    trackIndex: selectedTrackIndex,
                    startTick: 0,
                    length: currentPPQN() * 16,
                    filter: .all
                )
                log("erase: all events in first 16 beats")
            default:
                break
            }
        } catch {
            log("erase error: \(error)")
        }
    }

    private func runTempoKey(_ index: Int) {
        switch index {
        case 0:
            let source: TempoSource = engine.project.tempoSource == .master ? .sequence : .master
            engine.setTempoSource(source)
            log("tempo source -> \(source.rawValue)")
        case 1:
            adjustDataEntry(by: -1)
        case 2:
            adjustDataEntry(by: 1)
        case 3:
            tapMode = tapMode == .taps2 ? .taps3 : (tapMode == .taps3 ? .taps4 : .taps2)
            log("tap mode -> \(tapMode.tapCount) taps")
        default:
            break
        }
    }

    private func runEditLoopKey(_ index: Int) {
        do {
            switch index {
            case 0:
                try engine.turnOnEditLoop(sequenceIndex: selectedSequenceIndex, startBar: 1, barCount: 2)
                log("edit loop on")
            case 1:
                try engine.turnOffEditLoop()
                log("edit loop off")
            case 2:
                try engine.undoAndTurnOffEditLoop()
                log("edit loop undo + off")
            case 3:
                _ = engine.playSong(at: 0)
                log("song play")
            default:
                break
            }
        } catch {
            log("edit loop error: \(error)")
        }
    }

    private func applyDateEntry() {
        let raw = dateEntryBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard raw.isEmpty == false else {
            return
        }

        let parts = raw.split(separator: ".").compactMap { Int($0) }
        if let first = parts.first {
            locateTick = max(0, first)
            engine.locate(tick: locateTick)
            log("date entry locate -> \(locateTick)")
        }
        dateEntryBuffer = ""
    }

    private func locate(by deltaTicks: Int) {
        let next = max(0, engine.transport.tickPosition + deltaTicks)
        locateTick = next
        engine.locate(tick: next)
        log("locate -> \(next)")
    }

    private func setRecordReady(_ enabled: Bool) {
        recordReady = enabled
        engine.setRecordReady(enabled)
        log("record ready \(enabled ? "on" : "off")")
    }

    private func effectiveTempo() -> Double {
        engine.effectiveTempoBPM(sequenceIndex: selectedSequenceIndex, tick: engine.transport.tickPosition)
    }

    private func selectSequence(_ index: Int) {
        guard engine.project.sequences.isEmpty == false else { return }
        selectedSequenceIndex = min(max(0, index), engine.project.sequences.count - 1)
        selectedTrackIndex = 0
        log("sequence -> \(selectedSequenceIndex + 1)")
    }

    private func selectTrack(_ index: Int) {
        guard let trackCount = engine.project.sequences[safe: selectedSequenceIndex]?.tracks.count, trackCount > 0 else {
            selectedTrackIndex = 0
            return
        }
        selectedTrackIndex = min(max(0, index), trackCount - 1)
        log("track -> \(selectedTrackIndex + 1)")
    }

    private func selectedTrackEventCount() -> Int {
        engine.project.sequences[safe: selectedSequenceIndex]?.tracks[safe: selectedTrackIndex]?.events.count ?? 0
    }

    private func currentPPQN() -> Int {
        engine.project.sequences[safe: selectedSequenceIndex]?.ppqn ?? Sequence.defaultPPQN
    }

    private func transposeTrack(by semitones: Int) {
        guard engine.project.sequences.indices.contains(selectedSequenceIndex),
              engine.project.sequences[selectedSequenceIndex].tracks.indices.contains(selectedTrackIndex) else {
            return
        }
        var project = engine.project
        project.sequences[selectedSequenceIndex].tracks[selectedTrackIndex].transpose(semitones: semitones)
        engine.load(project: project)
    }

    private func toggleTrackRouting() {
        guard engine.project.sequences.indices.contains(selectedSequenceIndex),
              engine.project.sequences[selectedSequenceIndex].tracks.indices.contains(selectedTrackIndex) else {
            return
        }
        var project = engine.project
        var track = project.sequences[selectedSequenceIndex].tracks[selectedTrackIndex]
        if track.routing.auxiliary == nil {
            track.setAuxiliaryRouting(MIDIDestination(port: "aux", channel: 2))
            log("track aux routing on")
        } else {
            track.setAuxiliaryRouting(nil)
            log("track aux routing off")
        }
        project.sequences[selectedSequenceIndex].tracks[selectedTrackIndex] = track
        engine.load(project: project)
    }

    private func cursorTargetLabel(_ target: CursorTarget) -> String {
        switch target {
        case .sequence:
            return "SEQ"
        case .track:
            return "TRK"
        case .locate:
            return "LOC"
        case .tempo:
            return "TEMPO"
        }
    }

    private func log(_ message: String) {
        lastMessage = message
    }

    private static func seedProject() -> Project {
        let ppqn = Sequence.defaultPPQN
        let trackA = Track(
            name: "Track A",
            kind: .midi,
            events: [
                .noteOn(channel: 0, note: 60, velocity: 100, tick: 0),
                .noteOff(channel: 0, note: 60, velocity: 0, tick: ppqn),
                .noteOn(channel: 0, note: 64, velocity: 100, tick: ppqn * 2),
                .noteOff(channel: 0, note: 64, velocity: 0, tick: ppqn * 3)
            ]
        )
        let sequenceA = Sequence(
            name: "Seq A",
            ppqn: ppqn,
            tempoBPM: 120,
            loopMode: .loopToBar(4),
            tracks: [trackA]
        )
        let sequenceB = Sequence(
            name: "Seq B",
            ppqn: ppqn,
            tempoBPM: 128,
            loopMode: .loopToBar(2),
            tracks: [Track(name: "Track B", kind: .drum)]
        )
        let song = Song(
            name: "Song 1",
            steps: [SongStep(sequenceIndex: 0, repeats: 2), SongStep(sequenceIndex: 1, repeats: 1)],
            endBehavior: .loopToStep(0)
        )
        return Project(sequences: [sequenceA, sequenceB], songs: [song], tempoSource: .sequence)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}

private struct PadSampleAssignment {
    let pad: Int
    let note: UInt8
    let sampleName: String
}

private final class PadSamplePlayback: NSObject, AVAudioPlayerDelegate {
    private var noteToSampleURL: [UInt8: URL] = [:]
    private var activePlayers: [ObjectIdentifier: AVAudioPlayer] = [:]

    func assignSamples(
        from directoryURL: URL,
        padToNote: [Int: UInt8],
        pads: [Int]
    ) -> [PadSampleAssignment] {
        let files = Self.audioFiles(in: directoryURL)
        noteToSampleURL.removeAll(keepingCapacity: true)

        var assignments: [PadSampleAssignment] = []
        for (index, pad) in pads.sorted().enumerated() {
            guard index < files.count, let note = padToNote[pad] else {
                continue
            }
            let url = files[index]
            noteToSampleURL[note] = url
            assignments.append(
                PadSampleAssignment(
                    pad: pad,
                    note: note,
                    sampleName: url.lastPathComponent
                )
            )
        }
        return assignments
    }

    func trigger(note: UInt8, velocity: UInt8) {
        guard let url = noteToSampleURL[note] else {
            return
        }
        playSample(url: url, velocity: velocity)
    }

    private func playSample(url: URL, velocity: UInt8) {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.volume = max(0.1, min(1.0, Float(velocity) / 127.0))
            player.prepareToPlay()
            if player.play() {
                activePlayers[ObjectIdentifier(player)] = player
            }
        } catch {
            // Keep sample playback failures non-fatal to avoid breaking sequencing.
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully _: Bool) {
        activePlayers.removeValue(forKey: ObjectIdentifier(player))
    }

    private static func audioFiles(in directoryURL: URL) -> [URL] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: directoryURL.path) else {
            return []
        }

        let allowedExtensions = Set(["wav", "aif", "aiff", "caf", "mp3", "m4a", "flac"])
        guard let enumerator = fm.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var result: [URL] = []
        for case let fileURL as URL in enumerator {
            let ext = fileURL.pathExtension.lowercased()
            guard allowedExtensions.contains(ext) else {
                continue
            }
            result.append(fileURL)
        }

        return result.sorted { $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending }
    }
}

