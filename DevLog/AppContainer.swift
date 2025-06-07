//
//  AppContainer.swift
//  DevLog
//
//  Created by opfic on 6/5/25.
//

import Foundation

@MainActor
class AppContainer: ObservableObject {
    static let shared = AppContainer()
    
    // 코어 서비스
    private let appleSvc = AppleSignInService()
    private let githubSvc = GithubSignInService()
    private let googleSvc = GoogleSignInService()
    private let webPageSvc = WebPageService()
    private let todoSvc = TodoService()
    
    // 의존 서비스
    lazy var authSvc = AuthService(appleSvc: appleSvc, githubSvc: githubSvc, googleSvc: googleSvc, userSvc: userSvc)
    lazy var networkSvc = NetworkActivityService()
    lazy var userSvc = UserService(appleSvc: appleSvc, githubSvc: githubSvc)
    
    // 캐싱된 뷰모델
    lazy var loginVM: LoginViewModel = {
        LoginViewModel(authSvc: authSvc, networkSvc: networkSvc)
    }()

    lazy var searchVM: SearchViewModel = {
        SearchViewModel(authSvc: authSvc, networkSvc: networkSvc, webPageSvc: webPageSvc)
    }()
    
    lazy var settingVM: SettingViewModel = {
        SettingViewModel(authSvc: authSvc, networkSvc: networkSvc, userSvc: userSvc)
    }()
    
    // kind 라는 변수에 따라 뷰모델이 생성될 필요성에 의해 캐싱을 시도하지 않음
    func todoVM(kind: TodoKind) -> TodoViewModel {
        TodoViewModel(authSvc: authSvc, todoSvc: todoSvc, kind: kind)
    }
    
    private init() {}
}
