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

@MainActor
final class AuthService: ObservableObject {
    private let db = Firestore.firestore()
    private let functions = Functions.functions(region: "asia-northeast3")
    private var appleSignInDelegate: AppleSignInDelegate?
    
    private let appleSvc: AppleSignInService
    private let githubSvc: GithubSignInService
    private let googleSvc: GoogleSignInService
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    
    @Published var user: User? = nil
    @Published var userId: String? = nil
    
    @Published var currentProvider: String = ""
    @Published var email: String = ""
    @Published var providers: [String] = []
    
    init(appleSvc: AppleSignInService, githubSvc: GithubSignInService, googleSvc: GoogleSignInService) {
        self.appleSvc = appleSvc
        self.githubSvc = githubSvc
        self.googleSvc = googleSvc
        self.user = Auth.auth().currentUser
        
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            Task {
                self.user = user
                if let user = user {
                    self.userId = user.uid
                    self.email = user.email ?? ""
                    self.providers = user.providerData.map { $0.providerID }
                    await self.fetchAuth()
                }
                else {
                    self.currentProvider = ""
                    self.email = ""
                    self.providers.removeAll()
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
        
        self.currentProvider = "apple.com"
        
        let fcmToken = try await Messaging.messaging().token()
        
        return (user, fcmToken)
    }
    
    func signInWithGithub() async throws -> (User, String, String) {
        let (user, accessToken) = try await self.githubSvc.signInWithGithub()
        
        let fcmToken = try await Messaging.messaging().token()
        
        self.currentProvider = "github.com"
        
        return (user, fcmToken, accessToken)
    }
    
    func signInWithGoogle() async throws -> (User, String) {
        let user = try await self.googleSvc.signInWithGoogle()
        
        self.currentProvider = "google.com"
        
        let fcmToken = try await Messaging.messaging().token()
        
        return (user, fcmToken)
    }
    
    func signOut() async throws {
        guard let user = self.user else { throw URLError(.userAuthenticationRequired) }
        
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
    }
    
    func deleteAuth() async throws {
        guard let user = self.user else { throw URLError(.userAuthenticationRequired) }
        
        if user.providerData.contains(where: { $0.providerID == "github.com" }) {
            try await self.githubSvc.revokeGitHubAccessToken()
        }
        if user.providerData.contains(where: { $0.providerID == "apple.com" }) {
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
            if provider == "apple.com" {
                try await self.appleSvc.linkWithApple()
            }
            else if provider == "github.com" {
                try await self.githubSvc.linkWithGithub()
            }
            else if provider == "google.com" {
                try await self.googleSvc.linkWithGoogle()
            }
            self.providers.append(provider)
        }
    }
    
    func unlinkFromProvider(provider: String) async throws {
        do {
            guard let user = self.user else { throw URLError(.userAuthenticationRequired) }
            
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
                    try await self.githubSvc.revokeGitHubAccessToken()
                }
            }
            else if provider == "apple.com" {
                if user.providerData.contains(where: { $0.providerID == provider }) {
                    let appleToken = try await self.appleSvc.refreshAppleAccessToken()
                    try await self.appleSvc.revokeAppleAccessToken(token: appleToken)
                    let tokensRef = db.document("users/\(user.uid)/userData/tokens")
                    let doc = try await tokensRef.getDocument()
                    if doc.exists {
                        try await tokensRef.updateData(["appleRefreshToken": FieldValue.delete()])
                    }
                }
            }
            _ = try await user.unlink(fromProvider: provider)
        } catch {
            self.providers.append(provider)
            throw error
        }
    }
    
    private func fetchAuth() async {
        do {
            guard let userId = self.userId else { throw URLError(.userAuthenticationRequired) }
            let infoRef = db.document("users/\(userId)/userData/info")
            let doc = try await infoRef.getDocument()
            if doc.exists {
                self.currentProvider = doc.get("currentProvider") as? String ?? ""
            }
        } catch {
            print("Error fetching auth: \(error.localizedDescription)")
        }
    }
}
