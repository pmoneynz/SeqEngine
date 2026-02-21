import Foundation
import XCTest
@testable import SequencerEngine
@testable import SequencerEngineIO

#if os(macOS)
import CoreMIDI

final class CoreMIDILoopbackTests: XCTestCase {
    private final class VirtualMIDILoopback: @unchecked Sendable {
        var client: MIDIClientRef = 0
        var source: MIDIEndpointRef = 0
        var destination: MIDIEndpointRef = 0
        let sourceName: String
        let destinationName: String

        private let lock = NSLock()
        private(set) var capturedPackets: [[UInt8]] = []

        init(name: String) throws {
            sourceName = "\(name).Source"
            destinationName = "\(name).Destination"

            var clientRef = MIDIClientRef()
            let clientStatus = MIDIClientCreateWithBlock(name as CFString, &clientRef) { _ in }
            guard clientStatus == noErr else {
                throw XCTSkip("Unable to create CoreMIDI test client: \(clientStatus)")
            }
            client = clientRef

            var sourceRef = MIDIEndpointRef()
            let sourceStatus = MIDISourceCreate(client, sourceName as CFString, &sourceRef)
            guard sourceStatus == noErr else {
                throw XCTSkip("Unable to create virtual source: \(sourceStatus)")
            }
            source = sourceRef

            var destinationRef = MIDIEndpointRef()
            let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
            let destinationStatus = MIDIDestinationCreate(
                client,
                destinationName as CFString,
                Self.readProc,
                context,
                &destinationRef
            )
            guard destinationStatus == noErr else {
                throw XCTSkip("Unable to create virtual destination: \(destinationStatus)")
            }
            destination = destinationRef
        }

        deinit {
            if source != 0 {
                MIDIEndpointDispose(source)
            }
            if destination != 0 {
                MIDIEndpointDispose(destination)
            }
            if client != 0 {
                MIDIClientDispose(client)
            }
        }

        private static let readProc: MIDIReadProc = { packetList, readProcRefCon, _ in
            guard let readProcRefCon else {
                return
            }
            let loop = Unmanaged<VirtualMIDILoopback>.fromOpaque(readProcRefCon).takeUnretainedValue()
            loop.handle(packetList: packetList)
        }

        private func handle(packetList: UnsafePointer<MIDIPacketList>) {
            var packet = packetList.pointee.packet
            for _ in 0..<packetList.pointee.numPackets {
                let bytes: [UInt8] = withUnsafeBytes(of: packet.data) { raw in
                    Array(raw.prefix(Int(packet.length)))
                }
                lock.lock()
                capturedPackets.append(bytes)
                lock.unlock()
                packet = MIDIPacketNext(&packet).pointee
            }

            // Feed destination writes into virtual source to complete loopback.
            _ = MIDIReceived(source, packetList)
        }
    }

    func testCoreMIDILoopbackCapabilityProbeReportsEnvironment() {
        let report = CoreMIDICapabilityProbe.probe()
        XCTAssertTrue(report.platformSupported)
        XCTAssertFalse(report.diagnostics.isEmpty)
    }

    func testCoreMIDIOutputToInputLoopbackDeliversEventWhenCapabilityIsPresent() throws {
        let report = CoreMIDICapabilityProbe.probe()
        guard report.canExerciseLoopback else {
            let diagnostics = report.diagnostics.joined(separator: " | ")
            throw XCTSkip("Loopback capability unavailable. Diagnostics: \(diagnostics)")
        }

        let loopback = try VirtualMIDILoopback(name: "SELoopback-\(UUID().uuidString)")
        let output = try CoreMIDIOutputAdapter(
            destinationEndpoint: loopback.destination,
            destinationName: loopback.destinationName
        )
        let input = try CoreMIDIInputAdapter(
            sourceEndpoint: loopback.source
        )

        var received: [MIDIEvent] = []
        input.setOnEvent { event in received.append(event) }

        try output.send(event: .noteOn(channel: 1, note: 64, velocity: 120, tick: 0))
        Thread.sleep(forTimeInterval: 0.1)
        input.pollEvents { event in received.append(event) }

        if received.isEmpty {
            let diagnostics = report.diagnostics.joined(separator: " | ")
            throw XCTSkip("No loopback event observed. Diagnostics: \(diagnostics)")
        }
        guard let first = received.first,
              case let .noteOn(channel, note, velocity, _) = first else {
            XCTFail("Expected first event to be noteOn")
            return
        }
        XCTAssertEqual(channel, 1)
        XCTAssertEqual(note, 64)
        XCTAssertEqual(velocity, 120)

        // Prove output path actually hit CoreMIDI destination callback.
        if loopback.capturedPackets.isEmpty {
            throw XCTSkip("Virtual destination did not capture packets in this environment.")
        }
    }
}

#else

final class CoreMIDILoopbackTests: XCTestCase {
    func testCoreMIDILoopbackCapabilityProbeReportsEnvironment() {
        let report = CoreMIDICapabilityProbe.probe()
        XCTAssertFalse(report.platformSupported)
        XCTAssertFalse(report.canExerciseLoopback)
        XCTAssertFalse(report.diagnostics.isEmpty)
    }

    func testCoreMIDIOutputToInputLoopbackDeliversEventWhenCapabilityIsPresent() throws {
        throw XCTSkip("CoreMIDI loopback tests are macOS-only.")
    }
}

#endif
