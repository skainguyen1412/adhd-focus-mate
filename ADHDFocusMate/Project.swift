import ProjectDescription

let project = Project(
    name: "ADHDFocusMate",
    targets: [
        .target(
            name: "ADHDFocusMate",
            destinations: .macOS,
            product: .app,
            bundleId: "com.adhdfocusmate.app",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "ADHD Focus Mate",
                "CFBundleName": "ADHD Focus Mate",
                "CFBundleIconName": "AppIcon",
                "CFBundleIconFile": "AppIcon",
            ]),
            buildableFolders: [
                "ADHDFocusMate/Sources",
                "ADHDFocusMate/Resources",
            ],
            entitlements: .file(path: "ADHDFocusMate/Resources/ADHDFocusMate.entitlements"),
            dependencies: [],
            settings: .settings(base: [
                "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                "PRODUCT_NAME": "ADHD Focus Mate",
                "INFOPLIST_KEY_CFBundleDisplayName": "ADHD Focus Mate",
            ])
        ),
        .target(
            name: "ADHDFocusMateTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "dev.tuist.ADHDFocusMateTests",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .default,
            buildableFolders: [
                "ADHDFocusMate/Tests"
            ],
            dependencies: [.target(name: "ADHDFocusMate")]
        ),
    ]
)
