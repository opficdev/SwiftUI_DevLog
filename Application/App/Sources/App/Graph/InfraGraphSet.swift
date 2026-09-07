//
//  InfraGraphSet.swift
//  App
//
//  Created by opfic on 9/7/26.
//

import Data
import Infra

final class InfraGraphSet {
    let firebaseAppServiceGraph = {
        let graph = FirebaseAppServiceGraph()
        graph.firebaseAppService.configure()
        return graph
    }()
    let appStoreVersionServiceGraph = AppStoreVersionServiceGraph()
    let analyticsServiceGraph = AnalyticsServiceGraph()
    let pushMessagingServiceGraph = PushMessagingServiceGraph()
    let appleAuthenticationServiceGraph = AppleAuthenticationServiceGraph()
    let githubAuthenticationServiceGraph = GithubAuthenticationServiceGraph()
    let googleAuthenticationServiceGraph = GoogleAuthenticationServiceGraph()
    let authServiceGraph = AuthServiceGraph()
    let todoQueryServiceGraph = TodoQueryServiceGraph()
    let todoCommandServiceGraph = TodoCommandServiceGraph()
    let developmentGoalServiceGraph = DevelopmentGoalServiceGraph()
    let developmentRecordServiceGraph = DevelopmentRecordServiceGraph()
    let todoCategoryServiceGraph = TodoCategoryServiceGraph()
    let userServiceGraph = UserServiceGraph()
    let profileImageDataServiceGraph = ProfileImageDataServiceGraph()
    let pushNotificationServiceGraph = PushNotificationServiceGraph()
    let webPageServiceGraph = WebPageServiceGraph()
    let webPageMetadataServiceGraph: WebPageMetadataServiceGraph
    let networkConnectivityProviderGraph = NWPathConnectivityProviderGraph()

    init(webPageImageStore: WebPageImageStore) {
        self.webPageMetadataServiceGraph = WebPageMetadataServiceGraph(
            input: WebPageMetadataServiceGraphInput(
                webPageImageStore: webPageImageStore
            )
        )
    }
}
