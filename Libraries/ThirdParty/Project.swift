import ProjectDescription
import ProjectDescriptionHelpers

let deploymentSettings: SettingsDictionary = [
    "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
    "MARKETING_VERSION": "1.0.0",
]

let project = Project(
    name: "ThirdParty",
    packages: [
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk",
            .exact("11.15.0")
        ),
        .package(
            url: "https://github.com/google/GoogleSignIn-iOS",
            .exact("9.2.0")
        ),
        .package(
            url: "https://github.com/opficdev/Nexa",
            .upToNextMinor(from: "1.1.1")
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            .exact("1.25.5")
        ),
        .package(
            url: "https://github.com/apple/swift-collections.git",
            .exact("1.3.0")
        ),
        .package(
            url: "https://github.com/opficdev/Cradle.git",
            .exact("1.2.0")
        ),
    ],
    settings: .devlogProject(additionalBase: deploymentSettings),
    targets: [
        .target(
            name: "ThirdParty",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.opfic.DevLog.ThirdParty",
            infoPlist: .extendingDefault(
                with: [
                    "CFBundlePackageType": "FMWK",
                ]
            ),
            sources: [
                "Sources/**/*.swift",
            ],
            scripts: [
                DevLogScripts.swiftLint(
                    sourcePath: "Sources",
                    configPath: "Sources/.swiftlint.yml"
                ),
            ],
            dependencies: [
                .package(product: "FirebaseAnalyticsCore"),
                .package(product: "FirebaseCore"),
                .package(product: "FirebaseFunctions"),
                .package(product: "FirebaseAuth"),
                .package(product: "FirebaseCrashlytics"),
                .package(product: "FirebaseMessaging"),
                .package(product: "FirebaseFirestore"),
                .package(product: "GoogleSignIn"),
                .package(product: "Nexa"),
                .package(product: "ComposableArchitecture"),
                .package(product: "OrderedCollections"),
                .package(product: "Cradle"),
            ],
            settings: .devlog(
                base: deploymentSettings
            )
        ),
    ]
)
