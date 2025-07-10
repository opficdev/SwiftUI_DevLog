//
//  PushNotification.swift
//  DevLog
//
//  Created by opfic on 6/28/25.
//

import Foundation
import FirebaseFirestore

struct PushNotification: Codable, Identifiable {
    @DocumentID var id: String?
    var title: String
    var content: String
    var kind: NotificationKind
    var receivedDate: Date
    var isRead: Bool
}
