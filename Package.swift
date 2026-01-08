// swift-tools-version:6.0

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
