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
    
    private let appleService: AppleSignInService
    private let githubService: GithubSignInService
    private let googleService: GoogleSignInService
    private let userService: UserService
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    
    @Published var user: User? = nil
    @Published var userId: String? = nil
    @Published var userEmail: String? = nil
    
    @Published var avatar: Image = Image(systemName: "person.crop.circle.fill")
    @Published var statusMsg: String = ""
    @Published var currentProvider: String = ""
    @Published var providers: [String] = []
    
    init(appleSvc: AppleSignInService, githubSvc: GithubSignInService, googleSvc: GoogleSignInService, userSvc: UserService) {
        self.appleService = appleSvc
        self.githubService = githubSvc
        self.googleService = googleSvc
        self.userService = userSvc
        self.user = Auth.auth().currentUser
        
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            self.user = user
            self.userId = user == nil ? nil : user!.uid
            self.userEmail = user?.email
        }
    }
    
    deinit {
        if let handler = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
    }
    
    func signInWithApple() async throws {
        let user = try await appleService.signInWithApple()
        
        let fcmToken = try await Messaging.messaging().token()
        
        try await userService.upsertUser(user: user, fcmToken: fcmToken, provider: "apple.com")
        
        try await fetchUserInfo(user: user)
    }
    
    func signInWithGithub() async throws {
        let (user, accessToken) = try await githubService.signInWithGithub()
        
        let fcmToken = try await Messaging.messaging().token()
        
        try await userService.upsertUser(user: user, fcmToken: fcmToken, provider: "github.com", accessToken: accessToken)
        
        try await fetchUserInfo(user: user)
    }
    
    func signInWithGoogle() async throws {
        let user = try await googleService.signInWithGoogle()
        
        let fcmToken = try await Messaging.messaging().token()
        
        try await userService.upsertUser(user: user, fcmToken: fcmToken, provider: "google.com")
        
        try await fetchUserInfo(user: user)
    }
    
    func signOut(user: User) async throws {
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
        if provider == "apple.com" {
            try await self.appleSvc.linkWithApple()
        }
        else if provider == "github.com" {
            try await self.githubSvc.linkWithGithub()
        }
        else if provider == "google.com" {
            try await self.googleSvc.linkWithGoogle()
        }
    }
    
    func unlinkFromProvider(provider: String) async throws {
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
    }
}
