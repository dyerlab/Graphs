// swift-tools-version: 6.0
//                      _                 _       _
//                   __| |_   _  ___ _ __| | __ _| |__
//                  / _` | | | |/ _ \ '__| |/ _` | '_ \
//                 | (_| | |_| |  __/ |  | | (_| | |_) |
//                  \__,_|\__, |\___|_|  |_|\__,_|_.__/
//                        |_ _/
//
//         Making Population Genetic Software That Doesn't Suck
//
//  Copyright (c) 2021-2026 Administravia LLC.  All Rights Reserved.
//

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
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.3.0"),
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
