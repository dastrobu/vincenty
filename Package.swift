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
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "vincenty",
            dependencies: []),
        .testTarget(
            name: "vincentyTests",
            dependencies: ["vincenty"]),
    ]
)
