//
//  AuthRepositoryImpl.swift
//  DevLog
//
//  Created by 최윤진 on 10/10/25.
//

import Foundation
import Combine
import FirebaseAuth

final class AuthRepositoryImpl: AuthRepository {
    // MARK: - Services
    private let authService: AuthService
    private let appleSignInService: AppleSignInService
    private let googleSignInService: GoogleSignInService
    private let githubSignInService: GithubSignInService
    
    // MARK: - State
    private let currentAuthUserSubject: CurrentValueSubject<AuthUser?, Never>
    var authStatePublisher: AnyPublisher<AuthUser?, Never> {
        currentAuthUserSubject.eraseToAnyPublisher()
    }
    var currentUser: AuthUser? {
        get { currentAuthUserSubject.value }
        set { currentAuthUserSubject.value = newValue }
    }
    private var cancellables: Set<AnyCancellable> = []
    
    // MARK: - Init
    init(
        authService: AuthService,
        appleSignInService: AppleSignInService,
        googleSignInService: GoogleSignInService,
        githubSignInService: GithubSignInService,
        initialAuthUser: AuthUser? = nil
    ) {
        self.authService = authService
        self.appleSignInService = appleSignInService
        self.googleSignInService = googleSignInService
        self.githubSignInService = githubSignInService
        self.currentAuthUserSubject = CurrentValueSubject<AuthUser?, Never>(initialAuthUser)
        
        // AuthService의 사용자 상태를 도메인 모델로 매핑하여 퍼블리시
        authService.$user
            .map { [weak self] (firebaseUser: User?) -> AuthUser? in
                guard let self = self, let firebaseUser = firebaseUser else { return nil }
                return self.firebaseUserToAuthUser(from: firebaseUser)
            }
            .sink { [weak self] authUser in
                self?.currentAuthUserSubject.value = authUser
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Errors
    private enum AuthRepositoryError: Error {
        case unknownProvider
    }
    
    // MARK: - Use Cases
    func signInWithApple() async throws -> (AuthUser, String) {
        let (firebaseUser, fcmToken) = try await authService.signInWithApple()
        let authUser = firebaseUserToAuthUser(from: firebaseUser, currentProvider: .apple)
        currentAuthUserSubject.value = authUser
        return (authUser, fcmToken)
    }
    
    func signInWithGoogle() async throws -> (AuthUser, String) {
        let (firebaseUser, fcmToken) = try await authService.signInWithGoogle()
        let authUser = firebaseUserToAuthUser(from: firebaseUser, currentProvider: .google)
        currentAuthUserSubject.value = authUser
        return (authUser, fcmToken)
    }
    
    func signInWithGithub() async throws -> (AuthUser, String, String) {
        // 반환 순서: (User, fcmToken, accessToken)
        let (firebaseUser, fcmToken, accessToken) = try await authService.signInWithGithub()
        let authUser = firebaseUserToAuthUser(from: firebaseUser, currentProvider: .gitHub)
        currentAuthUserSubject.value = authUser
        return (authUser, fcmToken, accessToken)
    }
    
    func signOut() async throws {
        try await authService.signOut()
        currentAuthUserSubject.value = nil
    }
    
    func deleteAuth() async throws {
        try await authService.deleteAuth()
        currentAuthUserSubject.value = nil
    }
    
    func link(provider: AuthProviderID) async throws {
        try await authService.linkWithProvider(provider: provider.rawValue)
    }
    
    func unlink(provider: AuthProviderID) async throws {
        try await authService.unlinkFromProvider(provider: provider.rawValue)
    }
    
    // MARK: - Helpers
    private func firebaseUserToAuthUser(from user: User, currentProvider: AuthProviderID? = nil) -> AuthUser {
        return AuthUser(
            id: user.uid,
            email: user.email,
            providers: user.providerData.map { $0.providerID },
            currentProvider: currentProvider?.rawValue
        )
    }
}
