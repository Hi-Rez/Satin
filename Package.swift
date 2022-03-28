// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "Satin",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13)],
    products: [
        .library(
            name: "Satin",
            targets: ["Satin"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Satin",
            dependencies: ["SatinCore"],
            path: "Sources/Satin",
            resources: [.copy("Pipelines")]
        ),
        .target(
            name: "SatinCore",
            path: "Sources/SatinCore",
            publicHeadersPath: "include",
            cSettings: [.headerSearchPath("include")]
        ),
        .testTarget(
            name: "SatinTests",
            dependencies: ["Satin"]
        ),
        .testTarget(
            name: "SatinCoreTests",
            dependencies: ["SatinCore"]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
