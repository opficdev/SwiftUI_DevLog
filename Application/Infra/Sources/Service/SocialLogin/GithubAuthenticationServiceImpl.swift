//
//  GithubAuthenticationServiceImpl.swift
//  Infra
//
//  Created by opfic on 6/4/25.
//

import FirebaseAuth
import Core
import Data

final class GithubAuthenticationServiceImpl: GithubAuthenticationService {
    private enum CrashlyticsError {
        static let domain = "DevLogInfra.GithubAuthenticationServiceImpl"

        enum Code: Int {
            case signIn = 1
            case deleteAuth
            case link
            case unlink
        }
    }

    private var user: User? { Auth.auth().currentUser }
    private let logger = Logger(category: "GithubAuthService")

    func signIn() async throws -> AuthDataResponse? {
        logger.info("Starting GitHub sign in")

        do {
            let request = try await OAuthAuthenticationTicketRequester.request(
                endpoint: .requestGithubSignInSession,
                requiresAuthentication: false
            )
            let response = try await FunctionAPIClient.shared.send(
                .requestGithubCustomToken,
                payload: request,
                requiresAuthentication: false
            )

            logger.debug("Signing in with custom token")
            let result = try await Auth.auth().signIn(withCustomToken: response.customToken)

            logger.info("Successfully signed in with GitHub")
            return result.user.makeResponse(providerID: .gitHub)
        } catch {
            if error.isSocialLoginCancelled { return nil }

            let mappedError = mapGithubAPIError(error)
            logger.error("Failed to sign in with GitHub", error: mappedError)
            record(mappedError, code: .signIn)
            throw mappedError
        }
    }

    func clearLocalSession() { }

    func deleteAuth(_ uid: String) async throws {
        do {
            try await FunctionAPIClient.shared.send(.revokeGithubAccessToken)
        } catch {
            logger.error("Failed to delete GitHub auth", error: error)
            record(error, code: .deleteAuth)
            throw error
        }
    }

    func link(uid: String) async throws -> Bool {
        logger.info("Linking GitHub account for user: \(uid)")

        do {
            let request = try await OAuthAuthenticationTicketRequester.request(
                endpoint: .requestGithubAccountLinkSession,
                requiresAuthentication: true
            )
            try await FunctionAPIClient.shared.send(
                .linkGithubAccount,
                payload: request
            )
            try await user?.reload()

            logger.info("Successfully linked GitHub account")
            return true
        } catch {
            if error.isSocialLoginCancelled { return false }

            let mappedError = mapGithubAPIError(error)
            logger.error("Failed to link GitHub account", error: mappedError)
            record(mappedError, code: .link)
            throw mappedError
        }
    }

    func unlink(_ uid: String) async throws {
        do {
            logger.info("Unlinking GitHub account for user: \(uid)")
            try await FunctionAPIClient.shared.send(.unlinkGithubAccount)
            try await user?.reload()
        } catch {
            let mappedError = mapGithubAPIError(error)
            logger.error("Failed to unlink GitHub account", error: mappedError)
            record(mappedError, code: .unlink)
            throw mappedError
        }
    }
}

private extension GithubAuthenticationServiceImpl {
    func mapGithubAPIError(_ error: Error) -> Error {
        if let emailError = error.apiEmailError {
            return emailError
        }

        if error.apiAuthenticationError == .lastProvider {
            return DataLayerError.failedToUnlinkLastProvider
        }

        return error
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
