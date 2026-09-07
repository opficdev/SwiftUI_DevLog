import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.devlogFramework(
    name: "Data",
    bundleId: "com.opfic.DevLog.Data",
    versionXcconfigPath: "../Shared/Version.xcconfig",
    frameworkInfoPlistPath: "../Shared/InfoPlists/Framework-Info.plist",
    testsInfoPlistPath: "../Shared/InfoPlists/UnitTests-Info.plist",
    packages: [],
    dependencies: [
        .project(target: "Domain", path: "../Domain"),
        .project(target: "Core", path: "../Core"),
        .project(target: "ThirdParty", path: "../../Libraries/ThirdParty"),
    ],
    hasTests: true
)
