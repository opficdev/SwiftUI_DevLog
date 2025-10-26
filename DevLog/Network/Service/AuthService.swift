//
//  AuthService.swift
//  DevLog
//
//  Created by opfic on 6/2/25.
//

import AuthenticationServices
import Combine
import CryptoKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import FirebaseMessaging
import GoogleSignIn
import SwiftUI

final class AuthService {
    private let store = Firestore.firestore()
    private let functions = Functions.functions(region: "asia-northeast3")
    private var appleSignInDelegate: AppleSignInDelegate?
    
    private let appleSvc: AppleSignInService
    private let githubSvc: GithubSignInService
    private let googleSvc: GoogleSignInService
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    
    @Published var user: User?
    @Published var currentProvider: AuthProviderID?
    
    init(
        appleSvc: AppleSignInService,
        githubSvc: GithubSignInService,
        googleSvc: GoogleSignInService
    ) {
        self.appleSvc = appleSvc
        self.githubSvc = githubSvc
        self.googleSvc = googleSvc

        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            Task {
                self.user = user
                if let _ = user {
                    await self.fetchAuth()
                } else {
                    self.currentProvider = nil
                }
            }
        }
    }
    
    deinit {
        if let handler = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
    }
    
    func signInWithApple() async throws -> (User, String) {
        
        let user = try await self.appleSvc.signInWithApple()
        
        self.currentProvider = AuthProviderID.apple
        
        let fcmToken = try await Messaging.messaging().token()
        
        return (user, fcmToken)
    }
    
    func signInWithGithub() async throws -> (User, String, String) {
        let (user, accessToken) = try await self.githubSvc.signInWithGithub()
        
        let fcmToken = try await Messaging.messaging().token()
        
        self.currentProvider = AuthProviderID.gitHub
        
        return (user, fcmToken, accessToken)
    }
    
    func signInWithGoogle() async throws -> (User, String) {
        let user = try await self.googleSvc.signInWithGoogle()
        
        self.currentProvider = AuthProviderID.google
        
        let fcmToken = try await Messaging.messaging().token()
        
        return (user, fcmToken)
    }
    
    func signOut() async throws {
        guard let user = self.user else { throw URLError(.userAuthenticationRequired) }
        
        if user.providerData.contains(where: { $0.providerID == AuthProviderID.google.rawValue }) {
            GIDSignIn.sharedInstance.signOut()
            try await GIDSignIn.sharedInstance.disconnect()
        }
        
        let infoRef = store.document("users/\(user.uid)/userData/tokens")
        let doc = try await infoRef.getDocument()
        
        if doc.exists {
            try await infoRef.updateData(["fcmToken": FieldValue.delete()])
        }
        
        try await Messaging.messaging().deleteToken()
        
        try Auth.auth().signOut()
    }
    
    func deleteAuth() async throws {
        guard let user = self.user else { throw URLError(.userAuthenticationRequired) }
        
        if user.providerData.contains(where: { $0.providerID == AuthProviderID.gitHub.rawValue }) {
            try await self.githubSvc.revokeGitHubAccessToken()
        }
        if user.providerData.contains(where: { $0.providerID == AuthProviderID.apple.rawValue }) {
            let appleToken = try await self.appleSvc.refreshAppleAccessToken()
            try await self.appleSvc.revokeAppleAccessToken(token: appleToken)
        }
        
        let deleteFunction = functions.httpsCallable("deleteAllUserFirestoreData")
        
        let _ = try await deleteFunction.call(["userId": user.uid])
        
        try await signOut()
        try await user.delete()
    }
    
    func linkWithProvider(provider: String) async throws {
        do {
            if provider == AuthProviderID.apple.rawValue {
                try await self.appleSvc.linkWithApple()
            }
            else if provider == AuthProviderID.gitHub.rawValue {
                try await self.githubSvc.linkWithGithub()
            }
            else if provider == AuthProviderID.google.rawValue {
                try await self.googleSvc.linkWithGoogle()
            }
//            self.providers.append(provider)
        }
    }
    
    func unlinkFromProvider(provider: String) async throws {
        do {
            guard let user = self.user else { throw URLError(.userAuthenticationRequired) }
            
//            if let index = self.providers.firstIndex(of: provider) {
//                self.providers.remove(at: index)
//            }
            
            if provider == AuthProviderID.google.rawValue {
                if user.providerData.contains(where: { $0.providerID == provider }) {
                    GIDSignIn.sharedInstance.signOut()
                    try await GIDSignIn.sharedInstance.disconnect()
                }
            }
            else if provider == AuthProviderID.gitHub.rawValue {
                if user.providerData.contains(where: { $0.providerID == provider }) {
                    try await self.githubSvc.revokeGitHubAccessToken()
                }
            }
            else if provider == AuthProviderID.apple.rawValue {
                if user.providerData.contains(where: { $0.providerID == provider }) {
                    let appleToken = try await self.appleSvc.refreshAppleAccessToken()
                    try await self.appleSvc.revokeAppleAccessToken(token: appleToken)
                    let tokensRef = store.document("users/\(user.uid)/userData/tokens")
                    let doc = try await tokensRef.getDocument()
                    if doc.exists {
                        try await tokensRef.updateData(["appleRefreshToken": FieldValue.delete()])
                    }
                }
            }
            _ = try await user.unlink(fromProvider: provider)
        } catch {
//            self.providers.append(provider)
            throw error
        }
    }
    
    func getFCMToken() async throws -> String? {
        if self.user == nil { return nil }
        
        return try await Messaging.messaging().token()
    }
        
    private func fetchAuth() async {
        do {
            guard let userId = self.user?.uid else { throw URLError(.userAuthenticationRequired) }
            let infoRef = store.document("users/\(userId)/userData/info")
            let doc = try await infoRef.getDocument()
            if doc.exists {
                if let provider = doc.get("currentProvider") as? String {
                    if provider == AuthProviderID.apple.rawValue {
                        self.currentProvider = .apple
                    } else if provider == AuthProviderID.google.rawValue {
                        self.currentProvider = .google
                    } else if provider == AuthProviderID.gitHub.rawValue {
                        self.currentProvider = .gitHub
                    }
                }
            }
        } catch {
            print("Error fetching auth: \(error.localizedDescription)")
        }
    }
}
