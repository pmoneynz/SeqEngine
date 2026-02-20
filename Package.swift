// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "SequencerEngine",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "SequencerEngine",
            targets: ["SequencerEngine"]
        ),
        .executable(
            name: "SequencerEngineTestGUI",
            targets: ["SequencerEngineTestGUI"]
        )
    ],
    targets: [
        .target(
            name: "SequencerEngine"
        ),
        .executableTarget(
            name: "SequencerEngineTestGUI",
            dependencies: ["SequencerEngine"]
        ),
        .testTarget(
            name: "SequencerEngineTests",
            dependencies: ["SequencerEngine"]
        )
    ]
)
