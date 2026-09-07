import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.devlogFramework(
    name: "Domain",
    bundleId: "com.opfic.DevLog.Domain",
    versionXcconfigPath: "../Shared/Version.xcconfig",
    frameworkInfoPlistPath: "../Shared/InfoPlists/Framework-Info.plist",
    testsInfoPlistPath: "../Shared/InfoPlists/UnitTests-Info.plist",
    packages: [],
    dependencies: [
        .project(target: "Core", path: "../Core"),
        .project(target: "ThirdParty", path: "../../Libraries/ThirdParty"),
    ],
    hasTests: true
)
