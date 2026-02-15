// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ReadableSwift",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
    ],
    products: [
        .library(name: "ReadableSwift", targets: ["ReadableSwift"])
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0")
    ],
    targets: [
        .target(
            name: "ReadableSwift",
            dependencies: [
                .product(name: "SwiftSoup", package: "SwiftSoup")
            ]
        ),
        .testTarget(
            name: "ReadableSwiftTests",
            dependencies: ["ReadableSwift"]
        ),
    ]
)
