// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Graphs",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "Graphs",
            targets: ["Graphs"]
        ),
    ],
    targets: [
        .target(
            name: "Graphs",
            resources: [
                .copy("Data")
            ]
        ),
        .testTarget(
            name: "GraphsTests",
            dependencies: ["Graphs"]
        ),
    ]
)
