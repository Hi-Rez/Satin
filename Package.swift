// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "Satin",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13)],
    products: [
        .library(
            name: "Satin",
            targets: ["SatinC", "SatinSwift"],
            exclude: ["Example", "Images"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Satin",
            dependencies: []
        ),
        .target(name: "SatinC",
                path: "Sources/SatinC"
        ),
        .target(name: "SatinSwift",
                path: "Sources/SatinSwift",
                exclude: ["Pipelines"]
        )
    ]
)




