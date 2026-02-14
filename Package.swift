// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SVGSwiftUI",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "SVGSwiftUI",
            targets: ["SVGSwiftUI"]
        ),
    ],
    targets: [
        .target(
            name: "SVGSwiftUI"
        ),
        .testTarget(
            name: "SVGSwiftUITests",
            dependencies: ["SVGSwiftUI"]
        ),
    ]
)
