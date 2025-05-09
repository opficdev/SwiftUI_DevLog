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
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var userId: String? { Auth.auth().currentUser?.uid }
    private var appleSignInDelegate: AppleSignInDelegate?
    private let db = Firestore.firestore()
    private let functions = Functions.functions(region: "asia-northeast3")
    private var cancellables = Set<AnyCancellable>()
    var email: String { Auth.auth().currentUser?.email ?? "" }
    
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
        guard let user = Auth.auth().currentUser else {
            throw URLError(.userAuthenticationRequired)
        }
        
        self.signIn = false
        
        do {
            if Auth.auth().currentUser?.providerData.contains(where: { $0.providerID == "google.com" }) ?? false {
                GIDSignIn.sharedInstance.signOut()
                try await GIDSignIn.sharedInstance.disconnect()
            }
            
            let userRef = db.collection(user.uid).document("info")
            
            try await userRef.updateData(["fcmToken": FieldValue.delete()])
            
            try Auth.auth().signOut()
            try await Messaging.messaging().deleteToken()
        } catch {
            print("SignOut Error: \(error)")
            throw error
        }
    }
}

// MARK: - Google Sign In/Out
extension FirebaseViewModel {
    func signInGoogle() async {
        do {
            try await signInGoogleHelper()
            self.signIn = true
        } catch {
            print("Google SignIn Error: \(error)")
        }
    }
    
    func signOutGoogle() async throws {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            try await GIDSignIn.sharedInstance.disconnect()
            self.signIn = false
        } catch {
            print("Google SignOut Error: \(error)")
            throw error
        }
    }
    
    private func signInGoogleHelper() async throws {
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

        upsertUser(user: result.user, fcmToken: fcmToken)
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
    func signInApple() async {
        do {
            try await signInAppleHelper()
            self.signIn = true
        } catch {
            print("Apple SignIn Error: \(error)")
        }
    }
    
    func signOutApple() async {
        do {
            try Auth.auth().signOut()
            self.signIn = false
        } catch {
            print("Apple SignOut Error: \(error)")
        }
    }
    
    private func signInAppleHelper() async throws {
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
        
        upsertUser(user: result.user, fcmToken: fcmToken)
        
        try await getAppleRefreshToken(authorizationCode: authorizationCode)
    }
    
    private func getAppleRefreshToken(authorizationCode: Data) async throws {
        guard let userId = userId,
              let authorizationCode = String(data: authorizationCode, encoding: .utf8) else {
            throw URLError(.userAuthenticationRequired)
        }
        
        let getFuction = functions.httpsCallable("getAppleRefreshToken")
        
        let params: [String: Any] = [
            "authorizationCode": authorizationCode,
            "userId": userId
        ]
            
        do {
            let _ = try await getFuction.call(params)
        } catch {
            print("Error get Apple Refresh Token: \(error)")
            throw error
        }
    }
    
    // 애플 액세스 토큰 재발급 메서드
    func refreshAppleAccessToken() async throws -> String {
        guard let _ = userId else {
            throw URLError(.userAuthenticationRequired)
        }
        
        let refreshFunction = functions.httpsCallable("refreshAppleAccessToken")
        
        do {
            let result = try await refreshFunction.call()
            
            if let data = result.data as? [String: Any], let accessToken = data["token"] as? String {
                return accessToken
            }
            return ""
        } catch {
            print("Error refresh Apple Token: \(error.localizedDescription)")
            throw error
        }
    }
    
    // 애플 액세스 토큰 취소 메서드
    func revokeAppleAccessToken(token: String) async throws -> Bool {
        guard let _ = userId else {
            throw URLError(.userAuthenticationRequired)
        }
       
        let revokeFunction = functions.httpsCallable("revokeAppleAccessToken")
        
        do {
            let _ = try await revokeFunction.call(["token": token])
            return true
        } catch {
            print("Error revoke Apple Token: \(error.localizedDescription)")
            throw error
        }
    }
}

// MARK: - GitHub Sign In/Out
extension FirebaseViewModel {
    func signInGithub() async {
        do {
            await signInGithubHelper()
            self.signIn = true
        }
    }

    private func signInGithubHelper() async {
        // 1. GitHub OAuth 로그인 (Safari 등으로 사용자 인증 후, authorizationCode 수신)
        do {
            let authorizationCode = try await requestGithubAuthorizationCode()
            
            // 2. Firebase Functions를 통해 customToken 발급 요청
            let (accessToken, customToken) = try await getGithubCustomTokens(authorizationCode: authorizationCode)
            
            // 3. Firebase 로그인
            let result = try await Auth.auth().signIn(withCustomToken: customToken)
            
            // 서버로부터 받은 정보로 인증 및 제공자 연결
            let credential = OAuthProvider.credential(providerID: AuthProviderID.gitHub, accessToken: accessToken)
            try await Auth.auth().currentUser?.link(with: credential)
            
            let fcmToken = try await Messaging.messaging().token()
            
            upsertUser(user: result.user, fcmToken: fcmToken)
        } catch {
            
        }
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
        let scope = "read:user"
        
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
            session.prefersEphemeralWebBrowserSession = true
            
            if !session.start() {
                continuation.resume(throwing: URLError(.userCancelledAuthentication))
            }
        }
    }

    // MARK: - Firebase Function 호출: Custom Token 발급
    private func getGithubCustomTokens(authorizationCode: String) async throws -> (String, String) {
        let getTokenFunction = functions.httpsCallable("getGithubCustomTokens")

        do {
            let result = try await getTokenFunction.call(["code": authorizationCode])
            if let data = result.data as? [String: Any],
               let accessToken = data["accessToken"] as? String,
               let customToken = data["customToken"] as? String {
                return (accessToken, customToken)
            } else {
                throw URLError(.badServerResponse)
            }
        } catch {
            print("Error getting GitHub Custom Token: \(error.localizedDescription)")
            throw error
        }
    }
}

extension FirebaseViewModel {
    func upsertUser(user: User, fcmToken: String) {
        let userRef = db.collection(user.uid).document("info")
        let data: [String: Any] = [
            "email": user.email ?? "",
            "name": user.displayName ?? "",
            "avatarURL": user.photoURL?.absoluteString ?? "",
            "theme": "automatic",
            "fcmToken": fcmToken,
            "allowPushAlarm": true,
            "lastLogin": FieldValue.serverTimestamp()
        ]
        
        userRef.setData(data, merge: true) { error in
            if let error = error {
                print("Error saving user data: \(error)")
            }
            else {
                print("User data saved successfully.")
            }
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
