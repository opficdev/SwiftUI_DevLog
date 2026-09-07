//
//  AppleAuthenticationServiceImpl.swift
//  Infra
//
//  Created by opfic on 6/4/25.
//

import AuthenticationServices
import FirebaseAuth
import Foundation
import Core
import Data

final class AppleAuthenticationServiceImpl: AppleAuthenticationService {
    private enum CrashlyticsError {
        static let domain = "DevLogInfra.AppleAuthenticationServiceImpl"

        enum Code: Int {
            case signIn = 1
            case deleteAuth
            case link
            case unlink
        }
    }

    private var appleSignInDelegate: AppleSignInDelegate?
    private var appleSignInContinuation: CheckedContinuation<ASAuthorization, Error>?
    private var user: User? { Auth.auth().currentUser }
    private let logger = Logger(category: "AppleAuthService")

    func signIn() async throws -> AuthDataResponse? {
        logger.info("Starting Apple sign in")
        
        do {
            let challenge = try await requestAppleChallenge()
            let response = try await authenticateWithAppleAsync(
                hashedNonce: challenge.hashedNonce
            )

            let displayName = response.fullName?.displayName

            logger.debug("Requesting custom token from Firebase Function")
            let customToken = try await requestAppleCustomToken(
                challengeId: challenge.challengeId,
                authorizationCode: response.authorizationCode,
                displayName: displayName
            )

            logger.debug("Signing in with custom token")
            let result = try await Auth.auth().signIn(withCustomToken: customToken)

            logger.info("Successfully signed in with Apple")
            return result.user.makeResponse(providerID: .apple)
        } catch {
            if error.isSocialLoginCancelled { return nil }

            logger.error("Failed to sign in with Apple", error: error)
            record(error, code: .signIn)
            throw error
        }
    }

    func clearLocalSession() { }

    func deleteAuth(_ uid: String) async throws {
        do {
            logger.info("Deleting Apple grant for user: \(uid)")
            try await FunctionAPIClient.shared.send(.revokeAppleAccessToken)
        } catch {
            logger.error("Failed to delete Apple auth", error: error)
            record(error, code: .deleteAuth)
            throw error
        }
    }

    func link(uid: String) async throws -> Bool {
        do {
            logger.info("Linking Apple account for user: \(uid)")
            let challenge = try await requestAppleChallenge()
            let response = try await authenticateWithAppleAsync(hashedNonce: challenge.hashedNonce)

            try await FunctionAPIClient.shared.send(
                .linkAppleAccount,
                payload: AppleAccountLinkRequest(
                    challengeId: challenge.challengeId,
                    authorizationCode: response.authorizationCode,
                    credentialEmail: response.email
                )
            )
            try await user?.reload()
            return true
        } catch {
            if error.isSocialLoginCancelled { return false }

            let mappedError = mapAppleAPIError(error)
            logger.error("Failed to link Apple account", error: mappedError)
            record(mappedError, code: .link)
            throw mappedError
        }
    }

    func unlink(_ uid: String) async throws {
        do {
            logger.info("Unlinking Apple account for user: \(uid)")
            try await FunctionAPIClient.shared.send(.unlinkAppleAccount)
            try await user?.reload()
        } catch {
            let mappedError = mapAppleAPIError(error)
            logger.error("Failed to unlink Apple account", error: mappedError)
            record(mappedError, code: .unlink)
            throw mappedError
        }
    }

    // Apple 인증 메서드
    @MainActor
    func authenticateWithAppleAsync(hashedNonce: String) async throws -> AppleAuthResponse {
        guard appleSignInDelegate == nil, appleSignInContinuation == nil else {
            throw SocialLoginError.authenticationAlreadyInProgress
        }

        let request = Self.makeAuthorizationRequest(hashedNonce: hashedNonce)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        
        let authorization = try await withCheckedThrowingContinuation { continuation in
            let delegate = AppleSignInDelegate { [weak self] result in
                self?.completeAppleSignIn(with: result)
            }
            self.appleSignInDelegate = delegate
            self.appleSignInContinuation = continuation
            controller.delegate = self.appleSignInDelegate
            controller.presentationContextProvider = self.appleSignInDelegate
            controller.performRequests()
        }

        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let authorizationCode = credential.authorizationCode,
              let authorizationCode = String(data: authorizationCode, encoding: .utf8) else {
            throw URLError(.badServerResponse)
        }
        
        return AppleAuthResponse(
            authorizationCode: authorizationCode,
            fullName: credential.fullName,
            email: credential.email
        )
    }

    @MainActor
    static func makeAuthorizationRequest(hashedNonce: String) -> ASAuthorizationAppleIDRequest {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = hashedNonce
        return request
    }

    @MainActor
    private func completeAppleSignIn(with result: Result<ASAuthorization, Error>) {
        guard let continuation = appleSignInContinuation else { return }

        appleSignInContinuation = nil
        appleSignInDelegate = nil

        switch result {
        case .success(let authorization):
            continuation.resume(returning: authorization)
        case .failure(let error):
            continuation.resume(throwing: error)
        }
    }
    
    private func requestAppleChallenge() async throws -> AppleChallengeResponse {
        try await FunctionAPIClient.shared.send(
            .requestAppleChallenge,
            requiresAuthentication: false
        )
    }

    private func requestAppleCustomToken(
        challengeId: String,
        authorizationCode: String,
        displayName: String?
    ) async throws -> String {
        let response = try await FunctionAPIClient.shared.send(
            .requestAppleCustomToken,
            payload: AppleCustomTokenRequest(
                challengeId: challengeId,
                authorizationCode: authorizationCode,
                displayName: displayName
            ),
            requiresAuthentication: false
        )
        
        return response.customToken
    }
}

extension PersonNameComponents {
    var displayName: String? {
        let formatter = PersonNameComponentsFormatter()
        formatter.style = .long
        let name = formatter.string(from: self)
        return name.isEmpty ? nil : name
    }
}

private extension AppleAuthenticationServiceImpl {
    func mapAppleAPIError(_ error: Error) -> Error {
        if let emailError = error.apiEmailError {
            return emailError
        }

        switch error.apiAuthenticationError {
        case .providerLinkConflict:
            return DataLayerError.linkCredentialAlreadyInUse
        case .lastProvider:
            return DataLayerError.failedToUnlinkLastProvider
        case .none:
            return error
        }
    }

    private static func record(_ error: Error, code: CrashlyticsError.Code) {
        FirebaseCrashlyticsHelper.record(
            error,
            domain: "\(CrashlyticsError.domain).\(code)",
            code: code.rawValue
        )
    }

    private func record(_ error: Error, code: CrashlyticsError.Code) {
        Self.record(error, code: code)
    }
}
