//
//  AuthService.swift
//  DevLog
//
//  Created by opfic on 6/2/25.
//

import Foundation
import Combine
import FirebaseAuth

class AuthService: ObservableObject {
    @Published var user: User? = nil
    @Published var userId: String? = nil
    
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    
    init() {
        self.user = Auth.auth().currentUser
        
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            self.user = user
            self.userId = user == nil ? nil : user!.uid
        }
    }
    
    deinit {
        if let handler = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
    }
}
