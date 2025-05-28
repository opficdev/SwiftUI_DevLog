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
import LinkPresentation

@MainActor
final class FirebaseViewModel: NSObject, ObservableObject {
    private var appleSignInDelegate: AppleSignInDelegate?
    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore()
    private let functions = Functions.functions(region: "asia-northeast3")
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var userId: String? { Auth.auth().currentUser?.uid }
    private var didSignedInBySession = true    //  기존 세션에 의해 로그인되었는지 여부

    // 뷰에서 직접 변경하지 않는 프로퍼티
    var name: String { Auth.auth().currentUser?.displayName ?? "" }
    var email: String { Auth.auth().currentUser?.email ?? "" }
    var currentProvider = ""
    
    // ui
    @Published var isConnected = true   //  셀룰러 또는 와이파이 연결 상태
    @Published var isLoading = true    // 네트워크 작업 중인지 여부
    @Published var showNetworkAlert = false
    @Published var signIn: Bool? = nil
    
    // SearchView
    @Published var devDocs: [DeveloperDoc] = [] // 개발자 문서 목록
    
    // ProfileView
    @Published var avatar = Image(systemName: "person.crop.circle.fill")
    @Published var statusMsg = ""
    @Published var providers: [String] = []
    
    override init() {
        super.init()
        
        // 앱 최초 시작 시 + 로그인/로그아웃 될 때 변화 감지
        createAuthStatePublisher()
            .receive(on: RunLoop.main)
            .sink { [weak self] user in
                guard let self = self else { return }
                if user != nil {
                    Task {
                        try await self.requestDevDocs()
                        if self.didSignedInBySession {
                            try await self.fetchUserInfo()
                            self.signIn = user != nil
                            self.isLoading = false
                        }
                        // 이 경우에는 새로운 로그인 세션을 생성하므로 upsertUser로 로그인하게 됨
                    }
                }
                else {
                    self.didSignedInBySession = false
                    self.signIn = user != nil
                    self.isLoading = false
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
            self.isLoading = true
            defer {
                self.isLoading = false
            }
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
            self.didSignedInBySession = false
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
            self.isLoading = true
            defer {
                self.isLoading = false
            }
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
        
        let result = try await Auth.auth().signIn(with: credential)
        
        if refreshing, let photoURL = gidSignIn.user.profile?.imageURL(withDimension: 200) {
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.photoURL = photoURL
            changeRequest.displayName = gidSignIn.user.profile?.name
            
            try await changeRequest.commitChanges()
        }
        
        let fcmToken = try await Messaging.messaging().token()

        try await upsertUser(user: result.user, fcmToken: fcmToken, provider: "google.com")
        
        try await fetchUserInfo()
    }
    
    private func linkWithGoogle() async throws {
        guard let user = Auth.auth().currentUser, let topVC = topViewController() else {
            throw URLError(.userAuthenticationRequired)
        }
        
        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            GIDSignIn.sharedInstance.signOut()
        }
        
        let gidSignIn = try await GIDSignIn.sharedInstance.signIn(withPresenting: topVC)
        
        guard let googleEmail = gidSignIn.user.profile?.email else {
            throw EmailFetchError.emailNotFound
        }
        
        if googleEmail != email {
            throw EmailFetchError.emailMismatch
        }
        
        guard let idToken = gidSignIn.user.idToken?.tokenString else {
            throw URLError(.badServerResponse)
        }
        
        let accessToken = gidSignIn.user.accessToken.tokenString
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        
        try await user.link(with: credential)
    }
    
    private func topViewController(controller: UIViewController? = nil) -> UIViewController? {
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
            self.isLoading = true
            defer {
                self.isLoading = false
            }
            try await signInWithAppleHelper()
            self.signIn = true
        } catch {
            print("Error signing in with Apple: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func signInWithAppleHelper() async throws {
        let response = try await authenticateWithAppleAsync()
        
        let nonce = response.nonce
        let credential = response.credential
        let authorizationCode = response.authorizationCode
        let idTokenString = response.idTokenString
                
        // Firebase Function을 통해 customToken 요청
        let customToken = try await requestAppleCustomToken(
            idToken: idTokenString,
            authorizationCode: authorizationCode
        )
        
        // customToken으로 Firebase 로그인
        let result = try await Auth.auth().signIn(withCustomToken: customToken)
        
        let changeRequest = result.user.createProfileChangeRequest()
        var displayName: String? = nil

        // 최초 사용자 가입 시 사용자 이름 설정
        if let fullName = credential.fullName {
            let formatter = PersonNameComponentsFormatter()
            formatter.style = .long
            let formattedName = formatter.string(from: fullName)
            if !formattedName.isEmpty {
                displayName = formattedName
            }
        }

        // 이미 가입된 사용자일 경우 Firestore에서 사용자 이름 가져오기
        if displayName == nil {
            let doc = try await db.document("users/\(result.user.uid)/userData/info").getDocument()
            displayName = doc.data()?["appleName"] as? String
        }

        // FirebaseAuth 사용자 프로필 업데이트
        changeRequest.displayName = displayName ?? ""
        changeRequest.photoURL = nil    //  Apple ID 프로필 사진 URL은 제공되지 않음
        try await changeRequest.commitChanges()
        
        // FirebaseAuth 계정에 Apple ID 연결
        if !result.user.providerData.contains(where: { $0.providerID == "apple.com" }) {
            let appleCredential = OAuthProvider.credential(
                providerID: AuthProviderID.apple,
                idToken: idTokenString,
                rawNonce: nonce
            )
            try await result.user.link(with: appleCredential)
        }
        
        let fcmToken = try await Messaging.messaging().token()
        
        try await upsertUser(user: result.user, fcmToken: fcmToken, provider: "apple.com")
        
        try await fetchUserInfo()
    }
    
    private func linkWithApple() async throws {
        guard let user = Auth.auth().currentUser else {
            throw URLError(.userAuthenticationRequired)
        }
        
        let response = try await authenticateWithAppleAsync()
        
        let nonce = response.nonce
        let credential = response.credential
        let authorizationCode = response.authorizationCode
        let idTokenString = response.idTokenString

        // Firebase Function을 통해 appleRefreshToken 생성
        let refreshToken = try await requestAppleRefreshToken(authorizationCode: authorizationCode)
        
        guard let appleEmail = credential.email else {
            try await revokeAppleAccessToken(token: refreshToken)
            throw EmailFetchError.emailNotFound
        }
        
        if appleEmail != email {
            try await revokeAppleAccessToken(token: refreshToken)
            throw EmailFetchError.emailMismatch
        }
        
        let appleCredential = OAuthProvider.credential(
            providerID: AuthProviderID.apple,
            idToken: idTokenString,
            rawNonce: nonce
        )
        
        try await user.link(with: appleCredential)
    }

    // Apple CustomToken 발급
    private func requestAppleCustomToken(idToken: String, authorizationCode: Data) async throws -> String {
        guard let authorizationCode = String(data: authorizationCode, encoding: .utf8) else {
            throw URLError(.badServerResponse)
        }
        
        let requestTokenFunction = functions.httpsCallable("requestAppleCustomToken")
        let result = try await requestTokenFunction.call([
            "idToken": idToken,
            "authorizationCode": authorizationCode
        ])
        
        if let data = result.data as? [String: Any], let customToken = data["customToken"] as? String {
            return customToken
        }
        throw URLError(.badServerResponse)
    }
    
    private func requestAppleRefreshToken(authorizationCode: Data) async throws -> String {
        guard let userId = userId,
              let authorizationCode = String(data: authorizationCode, encoding: .utf8) else {
            throw URLError(.userAuthenticationRequired)
        }
        
        let requestFuction = functions.httpsCallable("requestAppleRefreshToken")
        
        let params: [String: Any] = [
            "authorizationCode": authorizationCode,
            "userId": userId
        ]
        
        let result = try await requestFuction.call(params)
        
        if let data = result.data as? [String: Any], let accessToken = data["refreshToken"] as? String {
            return accessToken
        }
        throw URLError(.badServerResponse)
    }
    
    // Apple AceessToken 재발급 메서드
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
    
    // Apple AccessToken 취소 메서드
    private func revokeAppleAccessToken(token: String) async throws {
        guard let _ = userId else {
            throw URLError(.userAuthenticationRequired)
        }
       
        let revokeFunction = functions.httpsCallable("revokeAppleAccessToken")
        
        let _ = try await revokeFunction.call(["token": token])
    }
    
    private func authenticateWithAppleAsync() async throws -> AppleAuthResponse {
        // 자체 nonce 생성 및 해시화
        let nonce = UUID().uuidString
        let hashedNonce = SHA256.hash(data: Data(nonce.utf8)).map { String(format: "%02x", $0) }.joined()
        
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]   //  사용자 정보 요청
        request.nonce = hashedNonce //  Apple API는 SHA256 해시값을 요구함
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        
        let authorization = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ASAuthorization, Error>) in
            self.appleSignInDelegate = AppleSignInDelegate(continuation: continuation)
            controller.delegate = self.appleSignInDelegate
            controller.presentationContextProvider = self.appleSignInDelegate
            controller.performRequests()
        }
        
        // Apple ID 인증 결과 처리
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let appleIdToken = credential.identityToken,
              let authorizationCode = credential.authorizationCode,
              let idTokenString = String(data: appleIdToken, encoding: .utf8) else {
            throw URLError(.badServerResponse)
        }
        
        return AppleAuthResponse(
                nonce: nonce,
                credential: credential,
                authorizationCode: authorizationCode,
                idTokenString: idTokenString
        )
    }
}

// MARK: - GitHub Sign In/Out
extension FirebaseViewModel {
    func signInWithGithub() async throws {
        do {
            self.isLoading = true
            defer {
                self.isLoading = false
            }
            try await signInWithGithubHelper()
            self.signIn = true
        }
        catch {
            print("Error signing in with GitHub: \(error.localizedDescription)")
            throw error
        }
    }

    private func signInWithGithubHelper() async throws {
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
        
        // 6. Firebase Messaging을 통해 FCM 토큰 발급
        let fcmToken = try await Messaging.messaging().token()
        
        try await upsertUser(user: result.user, fcmToken: fcmToken, provider: "github.com", accessToken: accessToken)
        
        try await fetchUserInfo()
    }

    private func requestGithubAuthorizationCode() async throws -> String {
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
    private func requestGithubTokens(authorizationCode: String) async throws -> (String, String) {
        let requestTokenFunction = functions.httpsCallable("requestGithubTokens")
        let result = try await requestTokenFunction.call(["code": authorizationCode])
        
        if let data = result.data as? [String: Any],
           let accessToken = data["accessToken"] as? String,
           let customToken = data["customToken"] as? String {
            return (accessToken, customToken)
        }
        throw URLError(.badServerResponse)
    }
    
    private func revokeGitHubAccessToken(accessToken: String? = nil) async throws {
        guard let _ = userId else {
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
    
    private func linkWithGithub() async throws {
        guard let user = Auth.auth().currentUser else {
            throw URLError(.userAuthenticationRequired)
        }
        let tokensRef = db.document("users/\(user.uid)/userData/tokens")
        let authorizationCode = try await requestGithubAuthorizationCode()
        let (accessToken, _) = try await requestGithubTokens(authorizationCode: authorizationCode)
        
        let githubUser = try await requestGitHubUserProfile(accessToken: accessToken)
        
        guard let githubEmail = githubUser.email else {
            try await revokeGitHubAccessToken(accessToken: accessToken)
            throw EmailFetchError.emailNotFound
        }
        
        if githubEmail != email {
            try await revokeGitHubAccessToken(accessToken: accessToken)
            throw EmailFetchError.emailMismatch
        }
        
        try await tokensRef.setData(["githubAccessToken": accessToken], merge: true)
        
        let credential = OAuthProvider.credential(providerID: AuthProviderID.gitHub, accessToken: accessToken)
        try await user.link(with: credential)
    }
}

// MARK: etc
extension FirebaseViewModel {
    // 유저를 Firestore에 저장 및 업데이트
    private func upsertUser(user: User, fcmToken: String, provider: String, accessToken: String? = nil) async throws {
        let infoRef = db.document("users/\(user.uid)/userData/info")
        let tokensRef = db.document("users/\(user.uid)/userData/tokens")
        let settingsRef = db.document("users/\(user.uid)/userData/settings")
        
        // 사용자 기본 정보
        var field: [String: Any] = [
            "statusMsg": "",
            "lastLogin": FieldValue.serverTimestamp(),
            "currentProvider": provider,
        ]
        
        // 공급자 이슈로 인한 nil 방지
        if let email = user.email {
            field["email"] = email
        }
        
        if let displayName = user.displayName {
            field["name"] = displayName
        }
        
        self.currentProvider = provider
        
        if provider == "apple.com" && user.displayName != nil && user.displayName != "" {
            field["appleName"] = user.displayName
        }
        
        try await infoRef.setData(field, merge: true); field.removeAll()
        
        field["fcmToken"] = fcmToken
        
        // 깃헙, 애플 로그인 시 추가 정보 저장
        if provider == "github.com", let accessToken = accessToken {
            field["githubAccessToken"] = accessToken
        }
        
        try await tokensRef.setData(field, merge: true); field.removeAll()
        
        try await settingsRef.setData(["allowPushAlarm": true, "theme": "automatic", "appIcon": "automatic"], merge: true)
        
        self.signIn = true
    }
    
    func deleteUser() async throws {
        guard let user = Auth.auth().currentUser, let userId = userId else {
            throw URLError(.userAuthenticationRequired)
        }
        
        do {
            self.isLoading = true
            defer {
                self.isLoading = false
            }
            
            if user.providerData.contains(where: { $0.providerID == "github.com" }) {
                try await revokeGitHubAccessToken()
            }
            if user.providerData.contains(where: { $0.providerID == "apple.com" }) {
                let appleToken = try await refreshAppleAccessToken()
                try await revokeAppleAccessToken(token: appleToken)
            }
        
            let cleanUpFunction = functions.httpsCallable("userCleanup")
            
            _ = try await cleanUpFunction.call(["userId": userId])
            try await signOut()
            try await user.delete()
            self.signIn = false
        } catch {
            print("Error delete User: \(error.localizedDescription)")
            throw error
        }
    }
    
    func upsertStatusMsg() async throws {
        do {
            self.isLoading = true
            defer {
                self.isLoading = false
            }
            guard let userId = userId else {
                throw URLError(.userAuthenticationRequired)
            }
            
            let infoRef = db.document("users/\(userId)/userData/info")
            
            let field = ["statusMsg": statusMsg]
            try await infoRef.setData(field, merge: true)
        } catch {
            print("Error upsert status message: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func fetchUserInfo() async throws {
        do {
            self.isLoading = true
            defer {
                self.isLoading = false
            }
            guard let user = Auth.auth().currentUser, let userId = userId else {
                throw URLError(.userAuthenticationRequired)
            }
            
            if let url = user.photoURL {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let uiImage = UIImage(data: data) {
                    self.avatar = Image(uiImage: uiImage)
                }
            }
            else {
                self.avatar = Image(systemName: "person.crop.circle.fill")
            }
                        
            let infoRef = db.document("users/\(userId)/userData/info")
            let doc = try await infoRef.getDocument()
            if let data = doc.data() {
                if let statusMsg = data["statusMsg"] as? String {
                    self.statusMsg = statusMsg
                }
                if let currentProvider = data["currentProvider"] as? String {
                    self.currentProvider = currentProvider
                }
                self.providers = user.providerData.compactMap({ $0.providerID })
            }
        } catch {
            print("Error fetching user info: \(error.localizedDescription)")
            throw error
        }
    }
    
    func linkWithProviders(provider: String) async throws {
        do {
            self.isLoading = true
            defer {
                self.isLoading = false
            }
        
            if provider == "google.com" {
                try await linkWithGoogle()
            }
            else if provider == "github.com" {
                try await linkWithGithub()
            }
            else if provider == "apple.com" {
                try await linkWithApple()
            }
            self.providers.append(provider)
        } catch {
            print("Error linkinging with \(provider): \(error.localizedDescription)")
            throw error
        }
    }
    
    func unlinkWithProviders(provider: String) async throws {
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
                    let tokensRef = db.document("users/\(user.uid)/userData/tokens")
                    let doc = try await tokensRef.getDocument()
                    if doc.exists {
                        try await tokensRef.updateData(["appleRefreshToken": FieldValue.delete()])
                    }
                }
            }
            _ = try await user.unlink(fromProvider: provider)
        } catch {
            print("Error unlinking \(provider): \(error.localizedDescription)")
            self.providers.append(provider)
            throw error
        }
    }
    
    func requestDevDocs() async throws {
        guard let userId = userId else {
            throw URLError(.userAuthenticationRequired)
        }
        
        do {
            self.isLoading = true
            defer {
                self.isLoading = false
            }
            
            let devDocsRef = db.document("users/\(userId)/userData/devDocs")
            let doc = try await devDocsRef.getDocument()
            
            if doc.exists, let data = doc.data() {
                if let devDocs = data["devDocs"] as? [String] {
                    var result = [DeveloperDoc]()
                    for url in devDocs {
                        let doc = try await DeveloperDoc.fetch(from: url)
                        result.append(doc)
                    }
                    self.devDocs = result
                }
                else {
                    throw URLError(.badServerResponse)
                }
            }
        } catch {
            print("Error requesting dev docs: \(error.localizedDescription)")
            throw error
        }
    }
        
    func upsertDevDoc(_ doc: DeveloperDoc, urlString: String) async throws {
        guard let userId = userId else {
            throw URLError(.userAuthenticationRequired)
        }
        
        do {
            self.isLoading = true
            defer {
                self.isLoading = false
            }
            
            let devDocsRef = db.document("users/\(userId)/userData/devDocs")
            try await devDocsRef.setData(["devDocs": FieldValue.arrayUnion([urlString])], merge: true)
            
        } catch {
            print("Error upserting dev docs: \(error.localizedDescription)")
            throw error
        }
    }
    
    func deleteDevDoc(_ doc: DeveloperDoc) async throws {
        guard let userId = userId else {
            throw URLError(.userAuthenticationRequired)
        }
        
        do {
            self.isLoading = true
            defer {
                self.isLoading = false
            }
            
            let devDocsRef = db.document("users/\(userId)/userData/devDocs")
            let urlString = doc.url.absoluteString
            try await devDocsRef.updateData(["devDocs": FieldValue.arrayRemove([urlString])])
        } catch {
            print("Error deleting dev docs: \(error.localizedDescription)")
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
