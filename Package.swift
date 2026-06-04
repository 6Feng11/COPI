// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "Copy",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "CopyCore", targets: ["CopyCore"])
    ],
    targets: [
        .target(name: "CopyCore"),
        .testTarget(name: "CopyCoreTests", dependencies: ["CopyCore"])
    ]
)
