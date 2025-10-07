//
//  GoogleSignInService.swift
//  DevLog
//
//  Created by opfic on 6/4/25.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation
import GoogleSignIn

@MainActor
class GoogleSignInService {
    private let db = Firestore.firestore()
    
    private var user: User? { Auth.auth().currentUser }
    private var userId: String? { user?.uid }
    private var userEmail: String? { user?.email }
    
    func signInWithGoogle() async throws -> User {
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
        
        if let photoURL = gidSignIn.user.profile?.imageURL(withDimension: 200) {
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.photoURL = photoURL
            changeRequest.displayName = gidSignIn.user.profile?.name
            
            try await changeRequest.commitChanges()
        }
        
        return result.user
    }
    
    func linkWithGoogle() async throws {
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
        
        if googleEmail != self.userEmail {
            throw EmailFetchError.emailMismatch
        }
        
        guard let idToken = gidSignIn.user.idToken?.tokenString else {
            throw URLError(.badServerResponse)
        }
        
        let accessToken = gidSignIn.user.accessToken.tokenString
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        
        try await user.link(with: credential)
    }
}

extension GoogleSignInService {
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
