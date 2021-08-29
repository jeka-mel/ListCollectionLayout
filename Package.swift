// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let layoutName = "ListCollectionLayout"

let package = Package(
    name: layoutName,
    platforms: [.iOS(.v11)],
    products: [
        .library(
            name: layoutName,
            targets: [layoutName]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: layoutName
        ),
        .target(
            name: "ListCollectionView",
            dependencies: ["ListCollectionLayout"],
            path: "Sources/ListCollectionView"
        )
    ],
    swiftLanguageVersions: [.v5]
)
