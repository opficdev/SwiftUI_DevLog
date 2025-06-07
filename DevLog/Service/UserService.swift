//
//  UserService.swift
//  DevLog
//
//  Created by opfic on 6/4/25.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import SwiftUI

class UserService {
    private let db = Firestore.firestore()
    private let functions = Functions.functions(region: "asia-northeast3")
    private let apppleSvc: AppleSignInService
    private let githubSvc: GithubSignInService
    
    init(appleSvc: AppleSignInService, githubSvc: GithubSignInService) {
        self.apppleSvc = appleSvc
        self.githubSvc = githubSvc
    }
    
    // 유저를 Firestore에 저장 및 업데이트
    func upsertUser(user: User, fcmToken: String, provider: String, accessToken: String? = nil) async throws {
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
    }
    
    func deleteUser(user: User) async throws {
        if user.providerData.contains(where: { $0.providerID == "apple.com" }) {
            let appleToken = try await self.apppleSvc.refreshAppleAccessToken()
            try await self.apppleSvc.revokeAppleAccessToken(token: appleToken)
        }
        if user.providerData.contains(where: { $0.providerID == "github.com" }) {
            try await self.githubSvc.revokeGitHubAccessToken()
        }
  
        let cleanUpFunction = functions.httpsCallable("userCleanup")
        
        let _ = try await cleanUpFunction.call(["userId": user.uid])
    }
    
    func fetchUserInfo(user: User) async throws -> (Image, String, String, [String]) {
        var avatar = Image(systemName: "person.crop.circle.fill")
        var statusMsg = "", currentProvider = "", providers: [String] = []
        
        if let url = user.photoURL {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) {
                avatar = Image(uiImage: uiImage)
            }
        }
                    
        let infoRef = db.document("users/\(user.uid)/userData/info")
        let doc = try await infoRef.getDocument()
        if let data = doc.data() {
            statusMsg = data["statusMsg"] as? String ?? ""
            currentProvider = data["currentProvider"] as? String ?? ""
            providers = user.providerData.compactMap({ $0.providerID })
        }
        
        return (avatar, statusMsg, currentProvider, providers)
    }
}
