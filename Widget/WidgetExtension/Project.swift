import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "WidgetExtension",
    options: .options(
        disableBundleAccessors: true,
        disableSynthesizedResourceAccessors: true
    ),
    settings: .devlogProject(versionXcconfigPath: "../../Application/Shared/Version.xcconfig"),
    targets: [
        .target(
            name: "WidgetExtension",
            destinations: .iOS,
            product: .appExtension,
            bundleId: "opfic.DevLog.Widget",
            infoPlist: .file(path: "Resource/Info.plist"),
            sources: [
                .glob(
                    "**/*.swift",
                    excluding: [
                        "Derived/**",
                        "Project.swift"
                    ]
                )
            ],
            resources: [
                "Resource/Assets.xcassets",
                "../../Application/Shared/Resources/ColorPalette.xcassets",
                "Resource/Localizable.xcstrings"
            ],
            entitlements: .file(path: "Resource/DevLogWidget.entitlements"),
            scripts: [
                DevLogScripts.swiftLint(sourcePath: ".")
            ],
            dependencies: [
                .project(target: "WidgetCore", path: "../WidgetCore")
            ],
            settings: .devlog(
                versionXcconfigPath: "../../Application/Shared/Version.xcconfig",
                base: [
                    "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
                    "CODE_SIGN_STYLE": "Automatic",
                    "ENABLE_USER_SCRIPT_SANDBOXING": "NO"
                ]
            )
        )
    ]
)
