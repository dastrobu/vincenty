// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "vincenty",
    products: [
        .library(
            name: "vincenty",
            targets: ["vincenty"]),
    ],
    dependencies: [
        .package(url: "https://github.com/dastrobu/geodesic.git", from: "1.2.0"),
    ],
    targets: [
        .target(
            name: "vincenty",
            dependencies: []),
        .testTarget(
            name: "vincentyTests",
            dependencies: [
                "vincenty",
                "geodesic",
            ]),
    ]
)
