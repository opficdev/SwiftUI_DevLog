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
    
    @Published var name: String = ""
    @Published var avatar: Image = Image(systemName: "person.crop.circle.fill")
    @Published var statusMsg: String = ""
    
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
    
    func fetchUserInfo(user: User) async throws {
        var avatar = Image(systemName: "person.crop.circle.fill")
        
        if let url = user.photoURL {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) {
                avatar = Image(uiImage: uiImage)
            }
        }
                
        self.avatar = avatar
        self.name = user.displayName ?? String(user.email?.split(separator: "@").first ?? "")
        self.statusMsg = statusMsg
    }
    
    func upsertStatusMsg(userId: String, statusMsg: String) async throws {
        let infoRef = db.document("users/\(userId)/userData/info")
        
        try await infoRef.setData(["statusMsg": statusMsg], merge: true)
    }
}
