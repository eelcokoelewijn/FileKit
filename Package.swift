// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FileKit",
    products: [
        .library(name: "FileKit", targets: ["FileKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/nicklockwood/SwiftFormat.git", from: "0.35.8")
    ],
    targets: [
        .target(name: "FileKit", dependencies: []),
        .testTarget(name: "FileKitTests", dependencies: ["FileKit"])
    ]
)
