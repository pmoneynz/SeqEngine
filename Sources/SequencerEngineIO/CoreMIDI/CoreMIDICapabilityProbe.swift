import Foundation

#if os(macOS)
import CoreMIDI

public struct CoreMIDICapabilityReport: Sendable, Equatable {
    public var platformSupported: Bool
    public var sourceCount: Int
    public var destinationCount: Int
    public var sourceNames: [String]
    public var destinationNames: [String]
    public var canCreateClient: Bool
    public var diagnostics: [String]

    public init(
        platformSupported: Bool,
        sourceCount: Int,
        destinationCount: Int,
        sourceNames: [String],
        destinationNames: [String],
        canCreateClient: Bool,
        diagnostics: [String]
    ) {
        self.platformSupported = platformSupported
        self.sourceCount = sourceCount
        self.destinationCount = destinationCount
        self.sourceNames = sourceNames
        self.destinationNames = destinationNames
        self.canCreateClient = canCreateClient
        self.diagnostics = diagnostics
    }

    public var canExerciseLoopback: Bool {
        platformSupported && canCreateClient
    }
}

public enum CoreMIDICapabilityProbe {
    public static func probe() -> CoreMIDICapabilityReport {
        var diagnostics: [String] = []
        let sourceCount = Int(MIDIGetNumberOfSources())
        let destinationCount = Int(MIDIGetNumberOfDestinations())
        let sourceNames = endpointNames(count: sourceCount, endpointAt: MIDIGetSource)
        let destinationNames = endpointNames(count: destinationCount, endpointAt: MIDIGetDestination)

        var clientRef = MIDIClientRef()
        let clientStatus = MIDIClientCreateWithBlock("SequencerEngineIO.Probe" as CFString, &clientRef) { _ in }
        let canCreateClient = clientStatus == noErr
        if canCreateClient {
            MIDIClientDispose(clientRef)
        } else {
            diagnostics.append("MIDIClientCreateWithBlock failed: \(clientStatus)")
        }
        diagnostics.append("Detected sources: \(sourceCount)")
        diagnostics.append("Detected destinations: \(destinationCount)")

        return CoreMIDICapabilityReport(
            platformSupported: true,
            sourceCount: sourceCount,
            destinationCount: destinationCount,
            sourceNames: sourceNames,
            destinationNames: destinationNames,
            canCreateClient: canCreateClient,
            diagnostics: diagnostics
        )
    }

    private static func endpointNames(
        count: Int,
        endpointAt: (Int) -> MIDIEndpointRef
    ) -> [String] {
        guard count > 0 else {
            return []
        }
        var names: [String] = []
        names.reserveCapacity(count)
        for index in 0..<count {
            let endpoint = endpointAt(index)
            guard endpoint != 0 else {
                continue
            }
            var unmanagedName: Unmanaged<CFString>?
            let status = MIDIObjectGetStringProperty(endpoint, kMIDIPropertyDisplayName, &unmanagedName)
            if status == noErr, let name = unmanagedName?.takeRetainedValue() as String? {
                names.append(name)
            } else {
                names.append("unresolved-endpoint-\(index)-status-\(status)")
            }
        }
        return names
    }
}

#else

public struct CoreMIDICapabilityReport: Sendable, Equatable {
    public var platformSupported: Bool
    public var sourceCount: Int
    public var destinationCount: Int
    public var sourceNames: [String]
    public var destinationNames: [String]
    public var canCreateClient: Bool
    public var diagnostics: [String]

    public init(
        platformSupported: Bool,
        sourceCount: Int,
        destinationCount: Int,
        sourceNames: [String],
        destinationNames: [String],
        canCreateClient: Bool,
        diagnostics: [String]
    ) {
        self.platformSupported = platformSupported
        self.sourceCount = sourceCount
        self.destinationCount = destinationCount
        self.sourceNames = sourceNames
        self.destinationNames = destinationNames
        self.canCreateClient = canCreateClient
        self.diagnostics = diagnostics
    }

    public var canExerciseLoopback: Bool { false }
}

public enum CoreMIDICapabilityProbe {
    public static func probe() -> CoreMIDICapabilityReport {
        CoreMIDICapabilityReport(
            platformSupported: false,
            sourceCount: 0,
            destinationCount: 0,
            sourceNames: [],
            destinationNames: [],
            canCreateClient: false,
            diagnostics: ["CoreMIDI unavailable on this platform."]
        )
    }
}

#endif
