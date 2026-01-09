// swift-tools-version:6.1

import PackageDescription

let package = Package(
    name: "vincenty",
    products: [
        .library(
            name: "vincenty",
            targets: ["vincenty"]),
    ],
    dependencies: [
        .package(url: "https://github.com/dastrobu/geodesic.git", from: "1.4.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "vincenty",
            dependencies: []),
        .testTarget(
            name: "vincentyTests",
            dependencies: [
                "vincenty",
                .product(name: "geodesic", package: "geodesic"),
            ]),
    ]
)
