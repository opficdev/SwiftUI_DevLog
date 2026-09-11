//
//  FunctionAPIEndpoint.swift
//  Infra
//
//  Created by opfic on 6/26/26.
//

import Foundation

extension FunctionAPIEndpoint where Response == EmptyAPIResponse {
    static func requestTodoDeletion(_ id: String) -> Self {
        Self(method: .post, path: "/todos/\(functionAPIPathSegment(id))/deletion-request")
    }

    static func undoTodoDeletion(_ id: String) -> Self {
        Self(method: .delete, path: "/todos/\(functionAPIPathSegment(id))/deletion-request")
    }

    static func requestPushNotificationDeletion(_ id: String) -> Self {
        Self(method: .post, path: "/push-notifications/\(functionAPIPathSegment(id))/deletion-request")
    }

    static func undoPushNotificationDeletion(_ id: String) -> Self {
        Self(method: .delete, path: "/push-notifications/\(functionAPIPathSegment(id))/deletion-request")
    }

    static let revokeGithubAccessToken = Self(method: .delete, path: "/auth/github/access-token")
    static let linkGithubAccount = Self(method: .put, path: "/auth/github/account-link")
    static let unlinkGithubAccount = Self(method: .delete, path: "/auth/github/account-link")
    static let revokeGoogleAccessToken = Self(method: .delete, path: "/auth/google/access-token")
    static let linkGoogleAccount = Self(
        method: .put,
        path: "/auth/google/authorization-code/account-link"
    )
    static let unlinkGoogleAccount = Self(method: .delete, path: "/auth/google/account-link")
    static let linkAppleAccount = Self(method: .put, path: "/auth/apple/account-link")
    static let unlinkAppleAccount = Self(method: .delete, path: "/auth/apple/account-link")
    static let revokeAppleAccessToken = Self(method: .delete, path: "/auth/apple/access-token")
}

extension FunctionAPIEndpoint where Response == AppleChallengeResponse {
    static let requestAppleChallenge = Self(method: .post, path: "/auth/apple/challenges")
}

extension FunctionAPIEndpoint where Response == FirebaseCustomTokenResponse {
    static let requestAppleCustomToken = Self(method: .post, path: "/auth/apple/custom-token")
    static let requestGithubCustomToken = Self(method: .post, path: "/auth/github/custom-token")
    static let requestGoogleAuthorizationCustomToken = Self(
        method: .post,
        path: "/auth/google/authorization-code/custom-token"
    )
}

extension FunctionAPIEndpoint where Response == OAuthAuthenticationSessionResponse {
    static let requestGithubSignInSession = Self(
        method: .post,
        path: "/auth/github/sign-in-sessions"
    )
    static let requestGithubAccountLinkSession = Self(
        method: .post,
        path: "/auth/github/account-link-sessions"
    )
}

private func functionAPIPathSegment(_ value: String) -> String {
    var allowed = CharacterSet.alphanumerics
    allowed.insert(charactersIn: "-._~")
    return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
}
