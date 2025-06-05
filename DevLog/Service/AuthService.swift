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
    
    init(apple: AppleSignInService, github: GithubSignInService, google: GoogleSignInService, user: UserService) {
        self.appleService = apple
        self.githubService = github
        self.googleService = google
        self.userService = user
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
    
    func linkWithProviders(provider: String) async throws {
        if provider == "apple.com" {
            try await appleService.linkWithApple()
        }
        else if provider == "github.com" {
            try await githubService.linkWithGithub()
        }
        else if provider == "google.com" {
            try await googleService.linkWithGoogle()
        }
    }
    
    private func fetchUserInfo(user: User) async throws {
        let (avatar, statusMsg, currentProvider, providers) = try await userService.fetchUserInfo(user: user)
        
        self.avatar = avatar
        self.statusMsg = statusMsg
        self.currentProvider = currentProvider
        self.providers = providers
    }
}
