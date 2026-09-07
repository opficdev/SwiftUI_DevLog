import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.devlogFramework(
    name: "Widget",
    bundleId: "com.opfic.DevLog.Widget",
    versionXcconfigPath: "../Shared/Version.xcconfig",
    frameworkInfoPlistPath: "../Shared/InfoPlists/Framework-Info.plist",
    testsInfoPlistPath: "../Shared/InfoPlists/UnitTests-Info.plist",
    packages: [],
    dependencies: [
        .project(target: "Data", path: "../Data"),
        .project(target: "Core", path: "../Core"),
        .project(target: "WidgetCore", path: "../../Widget/WidgetCore"),
        .project(target: "ThirdParty", path: "../../Libraries/ThirdParty"),
    ],
    hasTests: true
)
