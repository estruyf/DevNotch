// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DevNotch",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "DevNotch",
            targets: ["DevNotch"]
        )
    ],
    targets: [
        .executableTarget(
            name: "DevNotch",
            path: "DevNotch",
            resources: [
                .process("Assets.xcassets"),
                .process("copilot-32.png")
            ]
        )
    ]
)
