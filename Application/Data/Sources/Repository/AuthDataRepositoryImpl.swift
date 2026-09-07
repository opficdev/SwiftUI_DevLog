//
//  AuthDataRepositoryImpl.swift
//  Data
//
//  Created by 최윤진 on 2/12/26.
//

import Domain

final class AuthDataRepositoryImpl: AuthDataRepository {
    private let authService: AuthService
    private let appleAuthService: AppleAuthenticationService
    private let githubAuthService: GithubAuthenticationService
    private let googleAuthService: GoogleAuthenticationService
    
    init(
        authService: AuthService,
        appleAuthService: AppleAuthenticationService,
        githubAuthService: GithubAuthenticationService,
        googleAuthService: GoogleAuthenticationService
    ) {
        self.authService = authService
        self.appleAuthService = appleAuthService
        self.githubAuthService = githubAuthService
        self.googleAuthService = googleAuthService
    }
    
    func fetchCurrentProvider() async throws -> AuthProvider? {
        guard let providerString = try await authService.getProviderID() else {
            return nil
        }
        return AuthProvider(rawValue: providerString)
    }
    
    func fetchAllProviders() async throws -> [AuthProvider] {
        let providerStrings = authService.providerIDs
        return providerStrings.compactMap { AuthProvider(rawValue: $0) }
    }
    
    func linkProvider(_ provider: AuthProvider) async throws -> Bool {
        guard let uid = authService.uid else {
            throw AuthError.notAuthenticated
        }
        
        let service: AuthenticationService
        switch provider {
        case .apple:
            service = appleAuthService
        case .google:
            service = googleAuthService
        case .github:
            service = githubAuthService
        }

        do {
            return try await service.link(uid: uid)
        } catch {
            throw mapLinkError(error)
        }
    }
    
    func unlinkProvider(_ provider: AuthProvider) async throws {
        guard let uid = authService.uid else {
            throw AuthError.notAuthenticated
        }

        if authService.providerCount <= 1 {
            throw AuthError.failedToUnlinkLastProvider
        }
        
        let service: AuthenticationService
        switch provider {
        case .apple:
            service = appleAuthService
        case .google:
            service = googleAuthService
        case .github:
            service = githubAuthService
        }
        
        do {
            try await service.unlink(uid)
        } catch {
            throw error.toDomain()
        }
    }
}

private extension AuthDataRepositoryImpl {
    func mapLinkError(_ error: Error) -> Error {
        if let emailError = error as? EmailError {
            switch emailError {
            case .notFound:
                return AuthError.linkEmailNotFound
            case .mismatch:
                return AuthError.linkEmailMismatch
            case .githubEmailConflict:
                return AuthError.githubEmailConflict
            }
        }

        return error.toDomain()
    }
}
