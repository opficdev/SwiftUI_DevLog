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
    private let apple = AppleSignInService()
    private let github = GithubSignInService()
    private let google = GoogleSignInService()
    
    // 의존 서비스
    lazy var auth = AuthService(apple: apple, github: github, google: google, user: user)
    lazy var network = NetworkActivityService()
    lazy var user = UserService(apple: apple, github: github)
    
    // 캐싱된 뷰모델
    lazy var loginVM: LoginViewModel = {
        LoginViewModel(auth: auth, network: network)
    }()

    lazy var searchVM: SearchViewModel = {
        SearchViewModel(auth: auth, network: network)
    }()
    
    lazy var settingVM: SettingViewModel = {
        SettingViewModel(auth: auth, network: network, user: user)
    }()
    
    private init() {}
}
