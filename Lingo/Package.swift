// swift-tools-version: 5.9
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
    ],
    targets: [
        .executableTarget(
            name: "Lingo",
            dependencies: [
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
        )
    ]
)
