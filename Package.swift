// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NetworkSwitchGetter",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "NetworkSwitchGetter",
            targets: ["NetworkSwitchGetter"]
        ),
    ],
    targets: [
        .target(
            name: "NetworkSwitchGetter",
            path: "NetworkSwitchGetter",
            sources: [
                "SwitchModel.swift",
                "NetworkAnalyticsCore.swift",
                "NetworkLogger.swift"
            ]
        ),
        .testTarget(
            name: "NetworkSwitchGetterTests",
            dependencies: ["NetworkSwitchGetter"],
            path: "Tests"
        ),
    ]
)
