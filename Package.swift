// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ListCollectionLayout",
    platforms: [.iOS(.v11)],
    products: [
        .library(
            name: "ListCollectionLayout",
            targets: ["ListCollectionLayout"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ListCollectionLayout"
        ),
        .target(
            name: "ListCollectionView",
            dependencies: ["ListCollectionLayout"]
        )
    ],
    swiftLanguageVersions: [.v5]
)
