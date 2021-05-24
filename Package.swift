// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swm-hfk",
    products: [
        .library(
            name: "SwmHFK",
            targets: ["SwmHFK"]
        ),
    ],
    dependencies: [
        .package(
			url: "https://github.com/taketo1024/swm-core.git",
			from:"1.0.1"
		),
        .package(
            url: "https://github.com/taketo1024/swm-knots.git",
            from: "1.0.0"
        ),
        .package(
			url: "https://github.com/taketo1024/swm-homology.git",
			from: "1.0.0"
		),
    ],
    targets: [
        .target(
            name: "SwmHFK",
            dependencies: [
                .product(name: "SwmCore", package: "swm-core"),
                .product(name: "SwmKnots", package: "swm-knots"),
                .product(name: "SwmHomology", package: "swm-homology"),
			]
		),
        .testTarget(
            name: "SwmHFKTests",
            dependencies: ["SwmHFK"]
		),
    ]
)
