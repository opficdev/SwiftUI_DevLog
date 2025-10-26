//
//  GithubSignInService.swift
//  DevLog
//
//  Created by opfic on 6/4/25.
//

import AuthenticationServices
import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import Foundation

@MainActor
class GithubSignInService: NSObject {
    private let store = Firestore.firestore()
    private let functions = Functions.functions(region: "asia-northeast3")
    
    private var user: User? { Auth.auth().currentUser }
    private var userId: String? { user?.uid }
    private var userEmail: String? { user?.email }
    
    func signInWithGithub() async throws -> (User, String) {
        // 1. GitHub OAuth 로그인 요청
        let authorizationCode = try await requestGithubAuthorizationCode()
        
        // 2. Firebase Functions를 통해 customToken 발급 요청
        let (accessToken, customToken) = try await requestGithubTokens(authorizationCode: authorizationCode)
        
        // 3. Firebase 로그인
        let result = try await Auth.auth().signIn(withCustomToken: customToken)
        
        // 4. Firebase Auth 사용자 프로필 업데이트
        let githubUser = try await requestGitHubUserProfile(accessToken: accessToken)
        
        if let photoURL = githubUser.avatarUrl, let url = URL(string: photoURL) {
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.photoURL = url
            changeRequest.displayName = githubUser.name ?? githubUser.login
            try await changeRequest.commitChanges()
        }
        
        // 5. GitHub 계정과 Firebase Auth 계정 연결
        if !result.user.providerData.contains(where: { $0.providerID == "github.com" }) {
            let credential = OAuthProvider.credential(providerID: AuthProviderID.gitHub, accessToken: accessToken)
            try await result.user.link(with: credential)
        }
        
        return (result.user, accessToken)
    }
    
    func requestGithubAuthorizationCode() async throws -> String {
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GITHUB_CLIENT_ID") as? String,
              let redirectURL = Bundle.main.object(forInfoDictionaryKey: "APP_REDIRECT_URL") as? String,
              let urlComponents = URLComponents(string: redirectURL),
              let callbackURLScheme = urlComponents.scheme else {
            throw URLError(.badURL)
        }

        // state: CSRF(사이트 간 요청 위조) 공격 방지용 랜덤 문자열
        let state = UUID().uuidString
        let scope = "read:user user:email"  //  공개된 정보와 이메일 요청
        
        // Use URLComponents for proper encoding
        var components = URLComponents(string: "https://github.com/login/oauth/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "redirect_url", value: redirectURL),
            URLQueryItem(name: "state", value: state)
        ]
        
        guard let authURL = components.url else {
            throw URLError(.badURL)
        }

        return try await withCheckedThrowingContinuation { continuation in
                let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: callbackURLScheme) { callbackURL, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let callbackURL = callbackURL,
                    let queryItems = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?.queryItems,
                    let code = queryItems.first(where: { $0.name == "code" })?.value else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }

                // 반환된 state 값 확인 / 받아온 값이 다르면 CSRF 공격 가능성 있음
                guard let returnedState = queryItems.first(where: { $0.name == "state" })?.value,
                    returnedState == state else {
                    continuation.resume(throwing: URLError(.userCancelledAuthentication))
                    return
                }

               continuation.resume(returning: code)
            }

            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false   //  웹에서 깃헙 로그인 후 세션 유지
            
            if !session.start() {
                continuation.resume(throwing: URLError(.userCancelledAuthentication))
            }
        }
    }
    
    // Firebase Function 호출: Custom Token 발급
    func requestGithubTokens(authorizationCode: String) async throws -> (String, String) {
        let requestTokenFunction = functions.httpsCallable("requestGithubTokens")
        let result = try await requestTokenFunction.call(["code": authorizationCode])
        
        if let data = result.data as? [String: Any],
           let accessToken = data["accessToken"] as? String,
           let customToken = data["customToken"] as? String {
            return (accessToken, customToken)
        }
        throw URLError(.badServerResponse)
    }
    
    func revokeGitHubAccessToken(accessToken: String? = nil) async throws {
        guard let _ = self.user else {
            throw URLError(.userAuthenticationRequired)
        }
        
        var param: [String: Any] = [:]
        
        if let accessToken = accessToken {
            param["accessToken"] = accessToken
        }
        
        let revokeFunction = functions.httpsCallable("revokeGithubAccessToken")
        
        let _ = try await revokeFunction.call(param)
    }

    // GitHub API로 사용자 프로필 정보 가져오기
    func requestGitHubUserProfile(accessToken: String) async throws -> GitHubUser {
        var request = URLRequest(url: URL(string: "https://api.github.com/user")!)
        request.httpMethod = "GET"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(GitHubUser.self, from: data)
    }
    
    func linkWithGithub() async throws {
        guard let user = self.user, let userId = self.userId else {
            throw URLError(.userAuthenticationRequired)
        }
        let tokensRef = store.document("users/\(userId)/userData/tokens")
        let authorizationCode = try await requestGithubAuthorizationCode()
        let (accessToken, _) = try await requestGithubTokens(authorizationCode: authorizationCode)
        
        let githubUser = try await requestGitHubUserProfile(accessToken: accessToken)
        
        guard let githubEmail = githubUser.email else {
            try await revokeGitHubAccessToken(accessToken: accessToken)
            throw EmailFetchError.emailNotFound
        }
        
        if githubEmail != self.userEmail {
            try await revokeGitHubAccessToken(accessToken: accessToken)
            throw EmailFetchError.emailMismatch
        }
        
        try await tokensRef.setData(["githubAccessToken": accessToken], merge: true)
        
        let credential = OAuthProvider.credential(providerID: AuthProviderID.gitHub, accessToken: accessToken)
        try await user.link(with: credential)
    }
}

extension GithubSignInService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let window = UIApplication.shared.connectedScenes
            .flatMap({ ($0 as? UIWindowScene)?.windows ?? [] })
            .first(where: { $0.isKeyWindow }) else {
                return ASPresentationAnchor()
        }
        return window
    }
}
