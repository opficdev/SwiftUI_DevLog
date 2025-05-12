//
//  FirebaseViewModel.swift
//  DevLog
//
//  Created by opfic on 5/7/25.
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import FirebaseMessaging
import GoogleSignIn
import AuthenticationServices
import CryptoKit
import Network

@MainActor
final class FirebaseViewModel: NSObject, ObservableObject {
    private var appleSignInDelegate: AppleSignInDelegate?
    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore()
    var email: String { Auth.auth().currentUser?.email ?? "" }
    private let functions = Functions.functions(region: "asia-northeast3")
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var userId: String? { Auth.auth().currentUser?.uid }
    
    @Published var isConnected = true
    @Published var showNetworkAlert = false
    @Published var signIn = false
    @Published var signInWithGithub = false
    
    override init() {
        super.init()
        Task {
            if let _ = Auth.auth().currentUser {
                self.signIn = true
            }
            else {
                self.signIn = false
            }
        }
        
        createAuthStatePublisher()
            .receive(on: RunLoop.main)
            .sink { [weak self] user in
                self?.signIn = user != nil
                // GitHub 로그인 상태 확인
                self?.signInWithGithub = user?.providerData.contains { provider in
                    provider.providerID == "github.com"
                } ?? false
            }
            .store(in: &cancellables)
        
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                
                if !path.usesInterfaceType(.wifi) && !path.usesInterfaceType(.cellular) && path.status != .satisfied {
                    self?.showNetworkAlert = true
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    // Firebase Auth 상태 변경을 Combine Publisher로 래핑
    private func createAuthStatePublisher() -> AnyPublisher<User?, Never> {
        let publisher = PassthroughSubject<User?, Never>()
        
        let handle = Auth.auth().addStateDidChangeListener { _, user in
            publisher.send(user)
        }
        
        // 메모리 관리를 위해 deinit 시 리스너 제거
        _ = AnyCancellable {
            Auth.auth().removeStateDidChangeListener(handle)
        }
        
        return publisher.eraseToAnyPublisher()
    }
    
    func signOut() async throws {
        do {
            guard let user = Auth.auth().currentUser else {
                throw URLError(.userAuthenticationRequired)
            }
            
            self.signIn = false
        
            if user.providerData.contains(where: { $0.providerID == "google.com" }) {
                GIDSignIn.sharedInstance.signOut()
                try await GIDSignIn.sharedInstance.disconnect()
            }
            
            let userRef = db.collection(user.uid).document("info")
            let doc = try await userRef.getDocument()
            
            if doc.exists {
                try await userRef.updateData(["fcmToken": FieldValue.delete()])
            }
            
            try await Messaging.messaging().deleteToken()
            
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
            throw error
        }
    }
}

// MARK: - Google Sign In/Out
extension FirebaseViewModel {
    func signInWithGoogle() async throws {
        do {
            try await signInWithGoogleHelper()
            self.signIn = true
        } catch {
            print("Error signing in with Google: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func signInWithGoogleHelper() async throws {
        guard let topVC = topViewController() else {
            throw URLError(.cannotFindHost)
        }
        
        let gidSignIn = try await GIDSignIn.sharedInstance.signIn(withPresenting: topVC)
        
        guard let idToken = gidSignIn.user.idToken?.tokenString else {
            throw URLError(.badServerResponse)
        }
        
        let accessToken = gidSignIn.user.accessToken.tokenString
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        
        let result = try await Auth.auth().signIn(with: credential)
        
        let fcmToken = try await Messaging.messaging().token()

        try await upsertUser(user: result.user, fcmToken: fcmToken, provider: "google.com")
    }
    
    func topViewController(controller: UIViewController? = nil) -> UIViewController? {
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }

        let controller = controller ?? keyWindow?.rootViewController
        
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        
        if let tabController = controller as? UITabBarController, let selected = tabController.selectedViewController {
            return topViewController(controller: selected)
        }
        
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        
        return controller
    }
}

// MARK: - Apple Sign In/Out
extension FirebaseViewModel {
    func signInWithApple() async throws {
        do {
            try await signInWithAppleHelper()
            self.signIn = true
        } catch {
            print("Error signing in with Apple: \(error.localizedDescription)")
            throw error
        }
    }
    
    
    private func signInWithAppleHelper() async throws {
        let nonce = UUID().uuidString
        let hashedNonce = SHA256.hash(data: Data(nonce.utf8)).map { String(format: "%02x", $0) }.joined()
        
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.email]
        request.nonce = hashedNonce
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        
        let authorization = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ASAuthorization, Error>) in
            self.appleSignInDelegate = AppleSignInDelegate(continuation: continuation)
            controller.delegate = self.appleSignInDelegate
            controller.presentationContextProvider = self.appleSignInDelegate
            controller.performRequests()
        }
        
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let appleIDToken = credential.identityToken,
              let authorizationCode = credential.authorizationCode,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw URLError(.badServerResponse)
        }
        
        let firebaseCredential = OAuthProvider.credential(
            providerID: AuthProviderID.apple,
            idToken: idTokenString,
            rawNonce: nonce
        )
        
        let result = try await Auth.auth().signIn(with: firebaseCredential)
        
        let fcmToken = try await Messaging.messaging().token()
        
        try await upsertUser(user: result.user, fcmToken: fcmToken, provider: "apple.com", credential: credential)
        
        try await requestAppleRefreshToken(authorizationCode: authorizationCode)
    }
    
    private func requestAppleRefreshToken(authorizationCode: Data) async throws {
        guard let userId = userId,
              let authorizationCode = String(data: authorizationCode, encoding: .utf8) else {
            throw URLError(.userAuthenticationRequired)
        }
        
        let requestFuction = functions.httpsCallable("requestAppleRefreshToken")
        
        let params: [String: Any] = [
            "authorizationCode": authorizationCode,
            "userId": userId
        ]
        
        let _ = try await requestFuction.call(params)
    }
    
    // 애플 액세스 토큰 재발급 메서드
    private func refreshAppleAccessToken() async throws -> String {
        guard let _ = userId else {
            throw URLError(.userAuthenticationRequired)
        }
    
        let refreshFunction = functions.httpsCallable("refreshAppleAccessToken")
        let result = try await refreshFunction.call()
        
        guard let data = result.data as? [String: Any],
              let accessToken = data["token"] as? String else {
            throw URLError(.cannotParseResponse)
        }
        
        return accessToken
    }
    
    // 애플 액세스 토큰 취소 메서드
    private func revokeAppleAccessToken(token: String) async throws {
        guard let _ = userId else {
            throw URLError(.userAuthenticationRequired)
        }
       
        let revokeFunction = functions.httpsCallable("revokeAppleAccessToken")
        
        let _ = try await revokeFunction.call(["token": token])
    }
}

// MARK: - GitHub Sign In/Out
extension FirebaseViewModel {
    func signInWithGithub() async throws {
        do {
            try await signInWithGithubHelper()
            self.signIn = true
        }
        catch {
            print("Error signing in with GitHub: \(error.localizedDescription)")
            throw error
        }
    }

    private func signInWithGithubHelper() async throws {
        // 1. GitHub OAuth 로그인 (Safari 등으로 사용자 인증 후, authorizationCode 수신)
        let authorizationCode = try await requestGithubAuthorizationCode()
        
        // 2. Firebase Functions를 통해 customToken 발급 요청
        let (accessToken, customToken) = try await requestGithubCustomTokens(authorizationCode: authorizationCode)
        
        // 3. Firebase 로그인
        let result = try await Auth.auth().signIn(withCustomToken: customToken)
        
        // 4. 서버로부터 받은 정보로 인증 및 제공자 연결
        
        if !result.user.providerData.contains(where: { $0.providerID == "github.com" }) {
            let credential = OAuthProvider.credential(providerID: AuthProviderID.gitHub, accessToken: accessToken)
            try await result.user.link(with: credential)
        }
        // 5. Firebase Messaging을 통해 FCM 토큰 발급
        let fcmToken = try await Messaging.messaging().token()
        
        try await upsertUser(user: result.user, fcmToken: fcmToken, provider: "github.com", githubAccessToken: accessToken)
    }

    // MARK: - GitHub OAuth Code 요청
    private func requestGithubAuthorizationCode() async throws -> String {
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GITHUB_CLIENT_ID") as? String,
              let redirectURL = Bundle.main.object(forInfoDictionaryKey: "APP_REDIRECT_URL") as? String else {
            throw URLError(.badURL)
        }

        // Extract URL scheme from the redirect URI
        let urlComponents = URLComponents(string: redirectURL)
        let callbackURLScheme = urlComponents?.scheme ?? "DevLog"

        // Generate a random state for CSRF protection
        let state = UUID().uuidString
        let scope = "read:user user:email"
        
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

                // Validate the returned state parameter
                guard let returnedState = queryItems.first(where: { $0.name == "state" })?.value,
                    returnedState == state else {
                    continuation.resume(throwing: URLError(.userCancelledAuthentication))
                    return
                }

               continuation.resume(returning: code)
            }

            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            
            if !session.start() {
                continuation.resume(throwing: URLError(.userCancelledAuthentication))
            }
        }
    }

    // MARK: - Firebase Function 호출: Custom Token 발급
    private func requestGithubCustomTokens(authorizationCode: String) async throws -> (String, String) {
        let requestTokenFunction = functions.httpsCallable("requestGithubCustomTokens")
        let result = try await requestTokenFunction.call(["code": authorizationCode])
        
        if let data = result.data as? [String: Any],
           let accessToken = data["accessToken"] as? String,
           let customToken = data["customToken"] as? String {
            return (accessToken, customToken)
        }
        throw URLError(.badServerResponse)
    }
    
    private func revokeGitHubAccessToken() async throws {
        guard let _ = userId else {
            throw URLError(.userAuthenticationRequired)
        }
        
        let revokeFunction = functions.httpsCallable("revokeGithubAccessToken")
        
        let _ = try await revokeFunction.call()
    }

}

extension FirebaseViewModel {
    private func upsertUser(user: User, fcmToken: String, provider: String, githubAccessToken token : String? = nil) async throws {
        let userRef = db.collection(user.uid).document("info")
        let doc = try await userRef.getDocument()
        var field: [String: Any] = [
            "email": user.email ?? "",
            "name": user.displayName ?? "",
            "theme": "automatic",
            "fcmToken": fcmToken,
            "allowPushAlarm": true,
            "lastLogin": FieldValue.serverTimestamp(),
            "lastProvider": provider
        ]
        
        if token != nil || provider == "github.com" {
            // GitHub Access Token 저장
            field["githubAccessToken"] = token!
            field["githubAvatarURL"] = user.photoURL?.absoluteString ?? ""
        }
        else if provider == "apple.com" {
            field["appleAvatarURL"] = user.photoURL?.absoluteString ?? ""
        }
        else {
            field["googleAvatarURL"] = user.photoURL?.absoluteString ?? ""
        }
        
        try await userRef.setData(field, merge: true)
    }
    
    func deleteUser() async throws {
        guard let user = Auth.auth().currentUser, let userId = userId else {
            throw URLError(.userAuthenticationRequired)
        }
        
        self.signIn = false
        
        // 유저가 작성한 데이터들을 삭제하는 cloud functions 구현 예정
        do {
            if user.providerData.contains(where: { $0.providerID == "apple.com" }) {
                let appleToken = try await refreshAppleAccessToken()
                try await revokeAppleAccessToken(token: appleToken)
            }
            if user.providerData.contains(where: { $0.providerID == "github.com" }) {
                try await revokeGitHubAccessToken()
            }
        
            try await db.collection(userId).document("info").delete()
            try await signOut()
            try await user.delete()
        } catch {
            print("Error delete User: \(error.localizedDescription)")
            throw error
        }
    }
}


extension FirebaseViewModel: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let window = UIApplication.shared.connectedScenes
            .flatMap({ ($0 as? UIWindowScene)?.windows ?? [] })
            .first(where: { $0.isKeyWindow }) else {
                return ASPresentationAnchor()
        }
        return window
    }
}
