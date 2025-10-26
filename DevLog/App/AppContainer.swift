//
//  AppContainer.swift
//  DevLog
//
//  Created by opfic on 6/5/25.
//

import Foundation

@MainActor
final class AppContainer: ObservableObject {
    static let shared = AppContainer()
    private init() {}

    // 코어 서비스
    private let appleSvc = AppleSignInService()
    private let githubSvc = GithubSignInService()
    private let googleSvc = GoogleSignInService()
    private let webPageSvc = WebPageService()
    private let todoSvc = TodoService()
    private let userSvc = UserService()
    private let notiSvc = NotificationService()
    lazy var networkSvc = NetworkActivityService()
    
    // 의존 서비스
    lazy var authSvc = AuthService(appleSvc: appleSvc, githubSvc: githubSvc, googleSvc: googleSvc)
    private lazy var authState = AuthState(authRepository: authRepo)
    private lazy var authRepo = AuthRepositoryImpl(
        authService: authSvc,
        appleSignInService: appleSvc,
        googleSignInService: googleSvc,
        githubSignInService: githubSvc
    )
    private lazy var userRepo = UserRepositoryImpl(userService: userSvc)
    private lazy var updatePushNotificationSettings = UpdatePushNotificationSettings(
        authRepository: authRepo, userRepository: userRepo
    )
    private lazy var fetchPushNotificationSettings = FetchPushNotificationSettings(
        authRepository: authRepo, userRepository: userRepo
    )
    private lazy var updateAppTheme  = UpdateAppTheme(authRepository: authRepo, userRepository: userRepo)
    private lazy var signOut = SignOut(authRepository: authRepo)
    private lazy var deleteAuth = DeleteAuth(authRepository: authRepo)
    private lazy var linkProvider = LinkProvider(authRepository: authRepo)
    private lazy var unlinkProvider = UnlinkProvider(authRepository: authRepo)
    private let network = NetworkRepositoryImpl()

    // 캐싱된 뷰모델
    lazy var loginVM: LoginViewModel = {
        LoginViewModel(authSvc: authSvc, networkSvc: networkSvc, userSvc: userSvc)
    }()

    lazy var searchVM: SearchViewModel = {
        SearchViewModel(authSvc: authSvc, networkSvc: networkSvc, webPageSvc: webPageSvc)
    }()
    
    private(set) lazy var settingViewModel = SettingViewModel(
        authState: authState,
        updatePushNotificationSettings: updatePushNotificationSettings,
        fetchPushNotificationSettings: fetchPushNotificationSettings,
        updateAppTheme: updateAppTheme,
        signOut: signOut,
        deleteAuth: deleteAuth,
        linkProvider: linkProvider,
        unlinkProvider: unlinkProvider,
        network: network
    )

    // kind 라는 변수에 따라 뷰모델이 생성될 필요성에 의해 캐싱을 시도하지 않음
    func todoVM(kind: TodoKind) -> TodoViewModel {
        TodoViewModel(authSvc: authSvc, networkSvc: networkSvc, todoSvc: todoSvc, kind: kind)
    }
    
    lazy var profileVM: ProfileViewModel = {
        ProfileViewModel(authSvc: authSvc, userSvc: userSvc)
    }()
    
    lazy var homeVM: HomeViewModel = {
        HomeViewModel(authSvc: authSvc, networkSvc: networkSvc, todoSvc: todoSvc)
    }()
    
    lazy var notiVM: NotificationViewModel = {
        NotificationViewModel(authSvc: authSvc, networkSvc: networkSvc, notiSvc: notiSvc)
    }()
}
