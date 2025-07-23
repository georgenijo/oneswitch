// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "QuickToggle",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(
            name: "QuickToggle",
            targets: ["QuickToggle"]),
    ],
    dependencies: [
    ],
    targets: [
        .executableTarget(
            name: "QuickToggle",
            dependencies: [],
            path: ".",
            exclude: ["Info.plist", "QuickToggle.entitlements", "Tests"],
            sources: [
                "QuickToggleApp.swift",
                "Core/",
                "Controllers/",
                "Models/",
                "ViewModels/",
                "Views/",
                "Services/",
                "Utilities/"
            ]
        ),
        .testTarget(
            name: "QuickToggleTests",
            dependencies: ["QuickToggle"],
            path: "Tests"
        ),
    ]
)