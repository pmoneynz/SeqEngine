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
        .library(
            name: "SequencerEngineIO",
            targets: ["SequencerEngineIO"]
        ),
        .executable(
            name: "SequencerEngineTestGUI",
            targets: ["SequencerEngineTestGUI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-atomics.git", from: "1.2.0")
    ],
    targets: [
        .target(
            name: "SequencerEngine"
        ),
        .target(
            name: "SequencerEngineIO",
            dependencies: [
                "SequencerEngine",
                .product(name: "Atomics", package: "swift-atomics")
            ]
        ),
        .executableTarget(
            name: "SequencerEngineTestGUI",
            dependencies: ["SequencerEngine"]
        ),
        .testTarget(
            name: "SequencerEngineTests",
            dependencies: ["SequencerEngine"]
        ),
        .testTarget(
            name: "SequencerEngineIOTests",
            dependencies: ["SequencerEngineIO", "SequencerEngine"]
        )
    ]
)
