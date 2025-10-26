//
//  AppleSignInService.swift
//  DevLog
//
//  Created by opfic on 6/4/25.
//

import AuthenticationServices
import CryptoKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import Foundation

class AppleSignInService {
    private var appleSignInDelegate: AppleSignInDelegate?
    private let store = Firestore.firestore()
    private let functions = Functions.functions(region: "asia-northeast3")
    
    // 아래 변수들은 서비스 내에서만 사용할 뿐 뷰, 뷰모델 혹은 타 서비스에서 접근하는 용도가 아님
    private var user: User? { Auth.auth().currentUser }
    private var userId: String? { user?.uid }
    private var userEmail: String? { user?.email }
    
    func signInWithApple() async throws -> User {
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
            let doc = try await store.document("users/\(result.user.uid)/userData/info").getDocument()
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

        return result.user
    }
    
    // Apple 인증 메서드
    @MainActor
    func authenticateWithAppleAsync() async throws -> AppleAuthResponse {
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
    
    // Apple CustomToken 발급 메서드
    func requestAppleCustomToken(idToken: String, authorizationCode: Data) async throws -> String {
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
    
    // Apple RefreshToken 발급 메서드
    func requestAppleRefreshToken(authorizationCode: Data) async throws -> String {
        guard let userId = self.userId,
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
    func refreshAppleAccessToken() async throws -> String {
        guard let _ = self.user else {
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
    func revokeAppleAccessToken(token: String) async throws {
        guard let _ = self.user else {
            throw URLError(.userAuthenticationRequired)
        }
       
        let revokeFunction = functions.httpsCallable("revokeAppleAccessToken")
        
        let _ = try await revokeFunction.call(["token": token])
    }
    
    
    // FirebaseAuth 사용자와 Apple 연결
    func linkWithApple() async throws {
        guard let user = self.user else {
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
        
        if appleEmail != self.userEmail {
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
}
