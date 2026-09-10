import ProjectDescription
import ProjectDescriptionHelpers

let deploymentSettings: SettingsDictionary = [
    "IPHONEOS_DEPLOYMENT_TARGET": "18.0",
    "MARKETING_VERSION": "1.0.0",
]

let project = Project(
    name: "MarkdownRenderer",
    options: .options(
        disableBundleAccessors: true,
        disableSynthesizedResourceAccessors: true
    ),
    packages: [],
    settings: .devlogProject(additionalBase: deploymentSettings),
    targets: [
        .target(
            name: "MarkdownRenderer",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.opfic.DevLog.MarkdownRenderer",
            infoPlist: .extendingDefault(
                with: ["CFBundlePackageType": "FMWK"]
            ),
            sources: ["Sources/**/*.swift"],
            resources: [
                "Resources/MarkdownRenderer/index.html",
                "Resources/MarkdownRenderer/renderer.css",
                "Resources/MarkdownRenderer/renderer.js",
            ],
            scripts: [
                DevLogScripts.swiftLint(
                    sourcePath: "Sources",
                    configPath: "Sources/.swiftlint.yml"
                ),
            ],
            dependencies: [],
            settings: .devlog(
                base: deploymentSettings.merging(
                    [
                        "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                    ]
                ) { _, new in new }
            )
        ),
        .target(
            name: "MarkdownRendererTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.opfic.DevLog.MarkdownRendererTests",
            infoPlist: .extendingDefault(
                with: ["CFBundlePackageType": "BNDL"]
            ),
            sources: ["Tests/**/*.swift"],
            scripts: [
                DevLogScripts.swiftLint(
                    sourcePath: "Tests",
                    configPath: "Tests/.swiftlint.yml"
                ),
            ],
            dependencies: [
                .target(name: "MarkdownRenderer"),
            ],
            settings: .devlog(
                base: deploymentSettings.merging(
                    [
                        "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                        "TEST_TARGET_NAME": "MarkdownRenderer",
                    ]
                ) { _, new in new }
            )
        ),
    ]
)
