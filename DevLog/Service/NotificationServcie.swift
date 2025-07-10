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
    
    func upsertNotification(notification: PushNotification, userId: String) async throws {
        let collection = db.collection("users/\(userId)/notifications")
        
        let docRef = collection.document(notification.id ?? UUID().uuidString)
        
        try await docRef.setData(notification.toDictionary(), merge: true)
    }
}
