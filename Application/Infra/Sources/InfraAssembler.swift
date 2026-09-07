//
//  InfraAssembler.swift
//  Infra
//
//  Created by 최윤진 on 12/7/25.
//

import Core
import Data

public final class InfraAssembler: Assembler {
    public init() { }

    public func assemble(_ container: any DIContainer) {
        container.register(FirebaseAppService.self) {
            FirebaseAppServiceImpl()
        }

        container.register(AppStoreVersionService.self) {
            ITunesAppVersionServiceImpl()
        }

        container.register(AnalyticsService.self) {
            FirebaseAnalyticsServiceImpl()
        }

        container.register(PushMessagingService.self) {
            PushMessagingServiceImpl()
        }

        container.register(
            AppleAuthenticationService.self,
            name: "AppleAuthenticationService"
        ) {
            AppleAuthenticationServiceImpl()
        }

        container.register(
            GithubAuthenticationService.self,
            name: "GithubAuthenticationService"
        ) {
            GithubAuthenticationServiceImpl()
        }

        container.register(
            GoogleAuthenticationService.self,
            name: "GoogleAuthenticationService"
        ) {
            GoogleAuthenticationServiceImpl()
        }

        container.register(AuthService.self) {
            AuthServiceImpl()
        }

        container.register(TodoQueryService.self) {
            TodoQueryServiceImpl()
        }

        container.register(TodoCommandService.self) {
            TodoCommandServiceImpl()
        }

        container.register(DevelopmentGoalService.self) {
            DevelopmentGoalServiceImpl()
        }

        container.register(DevelopmentRecordService.self) {
            DevelopmentRecordServiceImpl()
        }

        container.register(TodoCategoryService.self) {
            TodoCategoryServiceImpl()
        }

        container.register(UserService.self) {
            UserServiceImpl()
        }

        container.register(ProfileImageDataService.self) {
            ProfileImageDataServiceImpl()
        }

        container.register(PushNotificationService.self) {
            PushNotificationServiceImpl()
        }

        container.register(WebPageService.self) {
            WebPageServiceImpl()
        }

        container.register(WebPageMetadataService.self) {
            WebPageMetadataServiceImpl(
                store: container.resolve(WebPageImageStore.self)
            )
        }

        container.register(NWPathConnectivityProvider.self) {
            NWPathConnectivityProviderImpl()
        }
    }
}
