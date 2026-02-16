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
        .library(
            name: "SVGSwiftUIDynamic",
            type: .dynamic,
            targets: ["SVGSwiftUI"]
        ),
    ],
    targets: [
        .target(
            name: "SVGSwiftUI"
        ),
        .testTarget(
            name: "SVGSwiftUITests",
            dependencies: ["SVGSwiftUI"],
            resources: [
                .process("Fixtures"),
                .process("W3C"),
                .process("WebKit")
            ]
        ),
    ]
)
