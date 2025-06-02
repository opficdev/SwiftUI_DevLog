//
//  LoginViewModel.swift
//  DevLog
//
//  Created by opfic on 6/2/25.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import GoogleSignIn

@MainActor
final class LoginViewModel: ObservableObject {
    private var didSignedInBySession = true
    private var cancellables = Set<AnyCancellable>()
    private let auth: AuthService
    private let db = Firestore.firestore()
    @Published var signIn: Bool = false
    @Published var isLoading: Bool = true
    
    init(auth: AuthService) {
        self.auth = auth
        
        createAuthStatePublisher()
            .receive(on: RunLoop.main)
            .sink { [weak self] user in
                guard let self = self else { return }
                if user != nil {
                    Task {
//                        try await self.requestWebPageInfos()
                        if self.didSignedInBySession {
//                            try await self.fetchUserInfo()
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
