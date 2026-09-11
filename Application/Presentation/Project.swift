import ProjectDescription
import ProjectDescriptionHelpers

let versionXcconfigPath = Path("../Shared/Version.xcconfig")
let frameworkInfoPlistPath = Path("../Shared/InfoPlists/Framework-Info.plist")
let testsInfoPlistPath = Path("../Shared/InfoPlists/UnitTests-Info.plist")

let frameworkBuildSettings = Settings.devlog(
    versionXcconfigPath: versionXcconfigPath,
    base: [
        "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
        "OTHER_LIBTOOLFLAGS": "$(inherited) -no_warning_for_no_symbols"
    ]
)

let presentationSharedBuildSettings = {
    var settings = frameworkBuildSettings
    settings.base["ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS"] = "NO"
    return settings
}()

let thirdPartyDependency: TargetDependency = .project(
    target: "ThirdParty",
    path: "../../Libraries/ThirdParty"
)

let project = Project(
    name: "Presentation",
    options: .options(
        disableBundleAccessors: true,
        disableSynthesizedResourceAccessors: true
    ),
    packages: [],
    settings: .devlogProject(versionXcconfigPath: versionXcconfigPath),
    targets: [
        .target(
            name: "PresentationShared",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.opfic.DevLog.PresentationShared",
            infoPlist: .file(path: frameworkInfoPlistPath),
            sources: ["PresentationShared/Sources/**/*.swift"],
            resources: [
                "PresentationShared/Resources/Assets.xcassets",
                "../Shared/Resources/ColorPalette.xcassets",
                "PresentationShared/Resources/Localizable.xcstrings",
            ],
            scripts: [
                DevLogScripts.swiftLint(
                    sourcePath: "PresentationShared/Sources",
                    configPath: "PresentationShared/Sources/.swiftlint.yml"
                )
            ],
            dependencies: [
                .project(target: "Domain", path: "../Domain"),
                .project(target: "Core", path: "../Core"),
                .project(
                    target: "MarkdownRenderer",
                    path: "../../Libraries/MarkdownRenderer"
                ),
                thirdPartyDependency,
            ],
            settings: presentationSharedBuildSettings
        ),
        .target(
            name: "PresentationSharedTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.opfic.DevLog.PresentationSharedTests",
            infoPlist: .file(path: testsInfoPlistPath),
            sources: ["PresentationShared/Tests/**/*.swift"],
            scripts: [
                DevLogScripts.swiftLint(
                    sourcePath: "PresentationShared/Tests",
                    configPath: "PresentationShared/Tests/.swiftlint.yml"
                )
            ],
            dependencies: [
                .project(target: "Domain", path: "../Domain"),
                .project(target: "Core", path: "../Core"),
                .target(name: "PresentationShared"),
                thirdPartyDependency,
            ],
            settings: .devlog(
                base: [
                    "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                    "TEST_TARGET_NAME": "PresentationShared"
                ]
            )
        ),
        .target(
            name: "HomeTab",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "com.opfic.DevLog.HomeTab",
            infoPlist: .file(path: frameworkInfoPlistPath),
            sources: ["HomeTab/Sources/**/*.swift"],
            scripts: [
                DevLogScripts.swiftLint(
                    sourcePath: "HomeTab/Sources",
                    configPath: "HomeTab/Sources/.swiftlint.yml"
                )
            ],
            dependencies: [
                .project(target: "Domain", path: "../Domain"),
                .project(target: "Core", path: "../Core"),
                .target(name: "PresentationShared")
            ],
            settings: frameworkBuildSettings
        ),
        .target(
            name: "HomeTabTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.opfic.DevLog.HomeTabTests",
            infoPlist: .file(path: testsInfoPlistPath),
            sources: ["HomeTab/Tests/**/*.swift"],
            scripts: [
                DevLogScripts.swiftLint(
                    sourcePath: "HomeTab/Tests",
                    configPath: "HomeTab/Tests/.swiftlint.yml"
                )
            ],
            dependencies: [
                .target(name: "HomeTab"),
                .target(name: "PresentationShared"),
                thirdPartyDependency,
            ],
            settings: .devlog(
                base: [
                    "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                    "TEST_TARGET_NAME": "HomeTab"
                ]
            )
        ),
        .target(
            name: "TodayTab",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "com.opfic.DevLog.TodayTab",
            infoPlist: .file(path: frameworkInfoPlistPath),
            sources: ["TodayTab/Sources/**/*.swift"],
            scripts: [
                DevLogScripts.swiftLint(
                    sourcePath: "TodayTab/Sources",
                    configPath: "TodayTab/Sources/.swiftlint.yml"
                )
            ],
            dependencies: [
                .project(target: "Domain", path: "../Domain"),
                .project(target: "Core", path: "../Core"),
                .target(name: "PresentationShared")
            ],
            settings: frameworkBuildSettings
        ),
        .target(
            name: "TodayTabTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.opfic.DevLog.TodayTabTests",
            infoPlist: .file(path: testsInfoPlistPath),
            sources: ["TodayTab/Tests/**/*.swift"],
            scripts: [
                DevLogScripts.swiftLint(
                    sourcePath: "TodayTab/Tests",
                    configPath: "TodayTab/Tests/.swiftlint.yml"
                )
            ],
            dependencies: [
                .target(name: "TodayTab"),
                .target(name: "PresentationShared"),
                thirdPartyDependency,
            ],
            settings: .devlog(
                base: [
                    "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                    "TEST_TARGET_NAME": "TodayTab"
                ]
            )
        ),
        .target(
            name: "NotificationTab",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "com.opfic.DevLog.NotificationTab",
            infoPlist: .file(path: frameworkInfoPlistPath),
            sources: ["NotificationTab/Sources/**/*.swift"],
            scripts: [
                DevLogScripts.swiftLint(
                    sourcePath: "NotificationTab/Sources",
                    configPath: "NotificationTab/Sources/.swiftlint.yml"
                )
            ],
            dependencies: [
                .project(target: "Domain", path: "../Domain"),
                .project(target: "Core", path: "../Core"),
                .target(name: "PresentationShared")
            ],
            settings: frameworkBuildSettings
        ),
        .target(
            name: "NotificationTabTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.opfic.DevLog.NotificationTabTests",
            infoPlist: .file(path: testsInfoPlistPath),
            sources: ["NotificationTab/Tests/**/*.swift"],
            scripts: [
                DevLogScripts.swiftLint(
                    sourcePath: "NotificationTab/Tests",
                    configPath: "NotificationTab/Tests/.swiftlint.yml"
                )
            ],
            dependencies: [
                .project(target: "Domain", path: "../Domain"),
                .project(target: "Core", path: "../Core"),
                .target(name: "NotificationTab"),
                .target(name: "PresentationShared"),
                thirdPartyDependency,
            ],
            settings: .devlog(
                base: [
                    "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                    "TEST_TARGET_NAME": "NotificationTab"
                ]
            )
        ),
        .target(
            name: "ProfileTab",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "com.opfic.DevLog.ProfileTab",
            infoPlist: .file(path: frameworkInfoPlistPath),
            sources: ["ProfileTab/Sources/**/*.swift"],
            scripts: [
                DevLogScripts.swiftLint(
                    sourcePath: "ProfileTab/Sources",
                    configPath: "ProfileTab/Sources/.swiftlint.yml"
                )
            ],
            dependencies: [
                .project(target: "Domain", path: "../Domain"),
                .project(target: "Core", path: "../Core"),
                .target(name: "PresentationShared")
            ],
            settings: frameworkBuildSettings
        ),
        .target(
            name: "ProfileTabTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.opfic.DevLog.ProfileTabTests",
            infoPlist: .file(path: testsInfoPlistPath),
            sources: ["ProfileTab/Tests/**/*.swift"],
            scripts: [
                DevLogScripts.swiftLint(
                    sourcePath: "ProfileTab/Tests",
                    configPath: "ProfileTab/Tests/.swiftlint.yml"
                )
            ],
            dependencies: [
                .project(target: "Domain", path: "../Domain"),
                .project(target: "Core", path: "../Core"),
                .target(name: "ProfileTab"),
                .target(name: "PresentationShared"),
                thirdPartyDependency,
            ],
            settings: .devlog(
                base: [
                    "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                    "TEST_TARGET_NAME": "ProfileTab"
                ]
            )
        ),
        .target(
            name: "Entry",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "com.opfic.DevLog.Entry",
            infoPlist: .file(path: frameworkInfoPlistPath),
            sources: ["Entry/Sources/**/*.swift"],
            scripts: [
                DevLogScripts.swiftLint(
                    sourcePath: "Entry/Sources",
                    configPath: "Entry/Sources/.swiftlint.yml"
                )
            ],
            dependencies: [
                .project(target: "Domain", path: "../Domain"),
                .project(target: "Core", path: "../Core"),
                .target(name: "HomeTab"),
                .target(name: "TodayTab"),
                .target(name: "NotificationTab"),
                .target(name: "ProfileTab"),
                .target(name: "PresentationShared")
            ],
            settings: frameworkBuildSettings
        ),
        .target(
            name: "EntryTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.opfic.DevLog.EntryTests",
            infoPlist: .file(path: testsInfoPlistPath),
            sources: ["Entry/Tests/**/*.swift"],
            scripts: [
                DevLogScripts.swiftLint(
                    sourcePath: "Entry/Tests",
                    configPath: "Entry/Tests/.swiftlint.yml"
                )
            ],
            dependencies: [
                .project(target: "Domain", path: "../Domain"),
                .project(target: "Core", path: "../Core"),
                .target(name: "Entry"),
                .target(name: "PresentationShared"),
                thirdPartyDependency,
            ],
            settings: .devlog(
                base: [
                    "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                    "TEST_TARGET_NAME": "Entry"
                ]
            )
        ),
        .target(
            name: "Presentation",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "com.opfic.DevLog.Presentation",
            infoPlist: .file(path: frameworkInfoPlistPath),
            sources: ["Sources/**/*.swift"],
            scripts: [
                DevLogScripts.swiftLint(
                    sourcePath: "Sources",
                    configPath: "Sources/.swiftlint.yml"
                )
            ],
            dependencies: [
                .target(name: "Entry"),
                .target(name: "PresentationShared")
            ],
            settings: frameworkBuildSettings
        )
    ]
)
