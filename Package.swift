// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "Copy",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "CopyCore", targets: ["CopyCore"]),
        .executable(name: "CopyApp", targets: ["CopyApp"])
    ],
    targets: [
        .target(name: "CopyCore"),
        .executableTarget(name: "CopyApp", dependencies: ["CopyCore"]),
        .testTarget(name: "CopyCoreTests", dependencies: ["CopyCore"])
    ]
)
