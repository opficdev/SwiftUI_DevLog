import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "App",
    options: .options(
        disableBundleAccessors: true,
        disableSynthesizedResourceAccessors: true
    ),
    packages: [],
    settings: .devlogProject(versionXcconfigPath: "../Shared/Version.xcconfig"),
    targets: [
        .target(
            name: "App",
            destinations: .iOS,
            product: .app,
            productName: "DevLog",
            bundleId: "opfic.DevLog",
            infoPlist: .file(path: "Sources/Resource/Info.plist"),
            sources: ["Sources/**/*.swift"],
            resources: [
                "Sources/Resource/Assets.xcassets",
                "../Shared/Resources/ColorPalette.xcassets",
                "Sources/Resource/GoogleService-Info.plist",
                "../Presentation/PresentationShared/Resources/Localizable.xcstrings",
            ],
            entitlements: .file(path: "Sources/Resource/DevLog.entitlements"),
            scripts: [
                DevLogScripts.swiftLint(
                    sourcePath: "Sources",
                    configPath: "Sources/.swiftlint.yml"
                ),
            ],
            dependencies: [
                .project(target: "Presentation", path: "../Presentation"),
                .project(target: "ThirdParty", path: "../../Libraries/ThirdParty"),
                .project(target: "Persistence", path: "../Persistence"),
                .project(target: "Infra", path: "../Infra"),
                .project(target: "Widget", path: "../Widget"),
                .project(target: "Data", path: "../Data"),
                .project(target: "Domain", path: "../Domain"),
                .project(target: "Core", path: "../Core"),
                .project(target: "WidgetCore", path: "../../Widget/WidgetCore"),
                .project(target: "WidgetExtension", path: "../../Widget/WidgetExtension"),
            ],
            settings: .devlog(
                versionXcconfigPath: "Sources/Resource/App.xcconfig",
                base: [
                    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                    "CODE_SIGN_STYLE": "Automatic",
                    "CRASHLYTICS_COLLECTION_ENABLED": "0",
                    "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                    "INFOPLIST_PREPROCESS": "YES",
                    "INFOPLIST_PREPROCESSOR_DEFINITIONS": "$(inherited) CRASHLYTICS_COLLECTION_ENABLED=$(CRASHLYTICS_COLLECTION_ENABLED)",
                    "PRODUCT_MODULE_NAME": "App",
                ],
                debug: [
                    "APP_ENVIRONMENT": "staging",
                    "APS_ENVIRONMENT": "development",
                    "FIRESTORE_DATABASE_ID": "(default)",
                ],
                staging: [
                    "APP_ENVIRONMENT": "staging",
                    "APS_ENVIRONMENT": "production",
                    "FIRESTORE_DATABASE_ID": "(default)",
                ],
                release: [
                    "APP_ENVIRONMENT": "prod",
                    "APS_ENVIRONMENT": "production",
                    "FIRESTORE_DATABASE_ID": "(default)",
                ]
            )
        ),
        .target(
            name: "AppTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "opfic.AppTests",
            infoPlist: .file(path: "../Shared/InfoPlists/UnitTests-Info.plist"),
            sources: ["Tests/**/*.swift"],
            scripts: [
                DevLogScripts.swiftLint(
                    sourcePath: "Tests",
                    configPath: "Tests/.swiftlint.yml"
                ),
            ],
            dependencies: [
                .target(name: "App"),
            ],
            settings: .devlog(
                base: [
                    "BUNDLE_LOADER": "$(TEST_HOST)",
                    "CODE_SIGN_STYLE": "Automatic",
                    "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                    "TEST_HOST": "$(BUILT_PRODUCTS_DIR)/DevLog.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/DevLog",
                    "TEST_TARGET_NAME": "App",
                ]
            )
        ),
    ]
)
