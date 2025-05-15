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
    private let functions = Functions.functions(region: "asia-northeast3")
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var userId: String? { Auth.auth().currentUser?.uid }

    // 뷰에서 직접 변경하지 않는 프로퍼티
    var name: String { Auth.auth().currentUser?.displayName ?? "" }
    var email: String { Auth.auth().currentUser?.email ?? "" }
    var avatar: some View {
        AsyncImage(url: Auth.auth().currentUser?.photoURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
            default:
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
            }
        }
    }
    var currentProvider = ""
    
    @Published var isConnected = true
    @Published var showNetworkAlert = false
    @Published var signIn: Bool? = nil
    @Published var statusMsg = ""
    @Published var providers: [String] = []
    @Published var isLoading = false    // 네트워크 작업 중인지 여부
    
    override init() {
        super.init()
        
        //  Auth.auth().currentUser가 변경될 때만 감지한다. -> 즉 앱이 시작될 때 or 로그인/로그아웃 될 때
        createAuthStatePublisher()
            .receive(on: RunLoop.main)
            .sink { [weak self] user in
                self?.signIn = user != nil
                Task {
                    if self?.signIn == true {
                        let userRef = self?.db.collection(user!.uid).document("info")
                        let doc = try await userRef?.getDocument()
                        if let data = doc?.data() {
                            if let provider = data["currentProvider"] as? String {
                                self?.currentProvider = provider
                            }
                            if let statusMsg = data["statusMsg"] as? String {
                                self?.statusMsg = statusMsg
                            }
                            self?.providers = user!.providerData.compactMap({ $0.providerID })
                        }
                    }
                }
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
        
        return publisher
            .handleEvents(receiveCancel: {
                Auth.auth().removeStateDidChangeListener(handle)
            })
            .eraseToAnyPublisher()
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
            
            let infoRef = db.document("users/\(user.uid)/userData/info")
            let doc = try await infoRef.getDocument()
            
            if doc.exists {
                try await infoRef.updateData(["fcmToken": FieldValue.delete()])
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
    
    private func signInWithGoogleHelper(refreshing: Bool = true) async throws {
        guard let topVC = topViewController() else {
            throw URLError(.cannotFindHost)
        }
        
        let gidSignIn = try await GIDSignIn.sharedInstance.signIn(withPresenting: topVC)
        
        guard let idToken = gidSignIn.user.idToken?.tokenString else {
            throw URLError(.badServerResponse)
        }
        
        let accessToken = gidSignIn.user.accessToken.tokenString
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        
        let fcmToken = try await Messaging.messaging().token()
        
        let result = try await Auth.auth().signIn(with: credential)
        
        if refreshing, let photoURL = gidSignIn.user.profile?.imageURL(withDimension: 200) {
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.photoURL = photoURL
            changeRequest.displayName = gidSignIn.user.profile?.name
            
            try await changeRequest.commitChanges()
        }

        try await upsertUser(user: result.user, fcmToken: fcmToken, provider: "google.com", refreshing: refreshing)
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
    
    
    private func signInWithAppleHelper(refreshing: Bool = true) async throws {
        let nonce = UUID().uuidString
        let hashedNonce = SHA256.hash(data: Data(nonce.utf8)).map { String(format: "%02x", $0) }.joined()
        
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
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
        
        let changeRequest = result.user.createProfileChangeRequest()
        var displayName: String? = nil

        if let fullName = credential.fullName {
            let formatter = PersonNameComponentsFormatter()
            formatter.style = .long
            let formattedName = formatter.string(from: fullName)
            if !formattedName.isEmpty {
                displayName = formattedName
            }
        }

        if displayName == nil {
            let doc = try await db.document("users/\(result.user.uid)/userData/info").getDocument()
            displayName = doc.data()?["appleName"] as? String
        }

        // nil이 될 확률은 희박하지만, nil일 경우를 대비하여 처리
        if refreshing, let displayName = displayName {
            changeRequest.displayName = displayName
            changeRequest.photoURL = URL(string: "")
            try await changeRequest.commitChanges()
        }
        
        let fcmToken = try await Messaging.messaging().token()
        
        try await upsertUser(user: result.user, fcmToken: fcmToken, provider: "apple.com", refreshing: refreshing)
        
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

    private func signInWithGithubHelper(refreshing: Bool = true) async throws {
        // 1. GitHub OAuth 로그인 (Safari 등으로 사용자 인증 후, authorizationCode 수신)
        let authorizationCode = try await requestGithubAuthorizationCode()
        
        // 2. Firebase Functions를 통해 customToken 발급 요청
        let (accessToken, customToken) = try await requestGithubCustomTokens(authorizationCode: authorizationCode)
        
        // 3. Firebase 로그인
        let result = try await Auth.auth().signIn(withCustomToken: customToken)
        
        let githubUser = try await requestGitHubUserProfile(accessToken: accessToken)
        
        // 5. Firebase Auth 사용자 프로필 업데이트
        if refreshing, let photoURL = githubUser.avatarUrl, let url = URL(string: photoURL) {
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.photoURL = url
            changeRequest.displayName = githubUser.name ?? githubUser.login
            try await changeRequest.commitChanges()
        }
        
        if !result.user.providerData.contains(where: { $0.providerID == "github.com" }) {
            let credential = OAuthProvider.credential(providerID: AuthProviderID.gitHub, accessToken: accessToken)
            try await result.user.link(with: credential)
        }
        
        // 5. Firebase Messaging을 통해 FCM 토큰 발급
        let fcmToken = try await Messaging.messaging().token()
        
        try await upsertUser(user: result.user, fcmToken: fcmToken, provider: "github.com", githubAccessToken: accessToken, refreshing: refreshing)
    }

    private func requestGithubAuthorizationCode() async throws -> String {
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GITHUB_CLIENT_ID") as? String,
              let redirectURL = Bundle.main.object(forInfoDictionaryKey: "APP_REDIRECT_URL") as? String,
              let urlComponents = URLComponents(string: redirectURL),
              let callbackURLScheme = urlComponents.scheme else {
            throw URLError(.badURL)
        }

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

    // Firebase Function 호출: Custom Token 발급
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

    
    // GitHub API로 사용자 프로필 정보 가져오기
    private func requestGitHubUserProfile(accessToken: String) async throws -> GitHubUser {
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
}

// MARK: etc
extension FirebaseViewModel {
    private func upsertUser(user: User, fcmToken: String, provider: String, githubAccessToken token : String? = nil) async throws {
        let infoRef = db.document("users/\(user.uid)/userData/info")
        let tokenRef = db.document("users/\(user.uid)/userData/token")
        let settingsRef = db.document("users/\(user.uid)/userData/settings")
        
        // 사용자 기본 정보
        var field: [String: Any] = [
            "statusMsg": "",
            "lastLogin": FieldValue.serverTimestamp(),
            "provider": provider,
        ]
        
        // 공급자 이슈로 인한 nil 방지
        if let email = user.email {
            field["email"] = email
        }
        
        if let displayName = user.displayName {
            field["name"] = displayName
        }
        
        self.currentProvider = provider
        
        try await infoRef.setData(field, merge: true); field.removeAll()
        
        field["fcmToken"] = fcmToken
        
        if let token = token, provider == "github.com" {
            field["githubAccessToken"] = token
        }
        
        try await tokenRef.setData(field, merge: true); field.removeAll()
        
        try await settingsRef.setData(["allowPushAlarm": true, "theme": "automatic","appIcon": "automatic"], merge: true)
    }
    
    func deleteUser() async throws {
        guard let user = Auth.auth().currentUser, let userId = userId else {
            throw URLError(.userAuthenticationRequired)
        }
        
        self.signIn = false
        
        // 유저가 작성한 데이터들을 삭제하는 cloud functions 구현 예정
        do {
            if user.providerData.contains(where: { $0.providerID == "google.com" }) {
                GIDSignIn.sharedInstance.signOut()
                try await GIDSignIn.sharedInstance.disconnect()
            }
            if user.providerData.contains(where: { $0.providerID == "github.com" }) {
                try await revokeGitHubAccessToken()
            }
            if user.providerData.contains(where: { $0.providerID == "apple.com" }) {
                let appleToken = try await refreshAppleAccessToken()
                try await revokeAppleAccessToken(token: appleToken)
            }
        
            try await db.collection(userId).document("info").delete()
            try await signOut()
            try await user.delete()
        } catch {
            print("Error delete User: \(error.localizedDescription)")
            throw error
        }
    }
    
    func upsertStatusMsg() async throws {
        do {
            guard let userId = userId else {
                throw URLError(.userAuthenticationRequired)
            }
            
            let userRef = db.collection(userId).document("info")
            
            let field = ["statusMsg": statusMsg]
            try await userRef.setData(field, merge: true)
        } catch {
            print("Error upsert status message: \(error.localizedDescription)")
            throw error
        }
    }
    
    func fetchStatusMsg() async throws {
        do {
            guard let userId = userId else {
                throw URLError(.userAuthenticationRequired)
            }
            
            let userRef = db.collection(userId).document("info")
            let doc = try await userRef.getDocument()
            
            if let statusMsg = doc.data()?["statusMsg"] as? String {
                self.statusMsg = statusMsg
            }
        } catch {
            print("Error fetching status message: \(error.localizedDescription)")
            throw error
        }
    }
    
    func connectWithProvider(provider: String) async throws {
        guard let _ = Auth.auth().currentUser else {
            throw URLError(.userAuthenticationRequired)
        }
        
        do {
            self.isLoading = true
            defer {
                self.isLoading = false
            }
            if provider == "google.com" {
                try await signInWithGoogleHelper(refreshing: false)
            }
            else if provider == "github.com" {
                try await signInWithGithubHelper(refreshing: false)
            }
            else if provider == "apple.com" {
                try await signInWithAppleHelper(refreshing: false)
            }
            self.providers.append(provider)
        } catch {
            print("Error connecting with \(provider): \(error.localizedDescription)")
            throw error
        }
    }
    
    func disconnectWithProvider(provider: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw URLError(.userAuthenticationRequired)
        }
        
        do {
            self.isLoading = true
            defer {
                self.isLoading = false
            }
            if let index = self.providers.firstIndex(of: provider) {
                self.providers.remove(at: index)
            }
            
            if provider == "google.com" {
                if user.providerData.contains(where: { $0.providerID == provider }) {
                    GIDSignIn.sharedInstance.signOut()
                    try await GIDSignIn.sharedInstance.disconnect()
                }
            }
            else if provider == "github.com" {
                if user.providerData.contains(where: { $0.providerID == provider }) {
                    try await revokeGitHubAccessToken()
                }
            }
            else if provider == "apple.com" {
                if user.providerData.contains(where: { $0.providerID == provider }) {
                    let appleToken = try await refreshAppleAccessToken()
                    try await revokeAppleAccessToken(token: appleToken)
                }
            }
            _ = try await user.unlink(fromProvider: provider)
        } catch {
            print("Error disconnecting \(provider): \(error.localizedDescription)")
            self.providers.append(provider)
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
