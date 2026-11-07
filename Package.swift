// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OpenLid",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "OpenLid", targets: ["OpenLid"]),
        .executable(name: "OpenLidCLI", targets: ["OpenLidCLI"]),
        .library(name: "OpenLidCore", targets: ["OpenLidCore"])
    ],
    targets: [
        .target(
            name: "OpenLidCore",
            dependencies: [],
            path: "Sources/OpenLidCore"
        ),
        .executableTarget(
            name: "OpenLid",
            dependencies: ["OpenLidCore"],
            path: "Sources/OpenLid"
        ),
        .executableTarget(
            name: "OpenLidCLI",
            dependencies: ["OpenLidCore"],
            path: "Sources/OpenLidCLI"
        ),
        .testTarget(
            name: "OpenLidCoreTests",
            dependencies: ["OpenLidCore"],
            path: "Tests/OpenLidCoreTests"
        )
    ]
)
