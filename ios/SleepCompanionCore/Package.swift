// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SleepCompanionCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SleepCompanionCore",
            targets: ["SleepCompanionCore"]
        )
    ],
    targets: [
        .target(
            name: "SleepCompanionCore"
        ),
        .testTarget(
            name: "SleepCompanionCoreTests",
            dependencies: ["SleepCompanionCore"]
        )
    ]
)
