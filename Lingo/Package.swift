// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Lingo",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Lingo", targets: ["Lingo"])
    ],
    dependencies: [
        // NLLB-200 fallback via swift-transformers (optional — comment out if not needed)
        // .package(url: "https://github.com/huggingface/swift-transformers", from: "0.1.13"),
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.10.0"),
    ],
    targets: [
        // Business logic library — testable without AppKit entrypoints
        .target(
            name: "LingoCore",
            dependencies: [],
            path: "Sources/LingoCore",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .executableTarget(
            name: "Lingo",
            dependencies: [
                "LingoCore",
                // Uncomment to enable NLLB fallback:
                // .product(name: "Transformers", package: "swift-transformers"),
            ],
            path: "Sources/Lingo",
            resources: [
                .copy("../../Resources/Assets.xcassets")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "LingoTests",
            dependencies: [
                "LingoCore",
                .product(name: "Testing", package: "swift-testing"),
            ],
            path: "Tests/LingoTests"
        )
    ]
)
