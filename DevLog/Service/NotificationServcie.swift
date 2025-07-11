//
//  NotificationServcie.swift
//  DevLog
//
//  Created by opfic on 7/10/25.
//

import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class NotificationService: ObservableObject {
    private let db = Firestore.firestore()
    
    func requestNotification(userId: String) async throws -> [PushNotification] {
        let collection = db.collection("users/\(userId)/notifications")
        
        let snapshot = try await collection.getDocuments()
        
        return snapshot.documents.compactMap { PushNotification(from: $0) }
    }
}
