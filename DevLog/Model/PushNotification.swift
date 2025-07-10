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
    
    init(from: QueryDocumentSnapshot) {
        self.id = from.documentID
        self.title = from["title"] as? String ?? ""
        self.content = from["content"] as? String ?? ""
        self.kind = NotificationKind(rawValue: from["kind"] as? String ?? "") ?? .info
        self.receivedDate = (from["receivedDate"] as? Timestamp)?.dateValue() ?? Date()
        self.isRead = from["isRead"] as? Bool ?? false
    }
    
    init(id: String? = nil, title: String, content: String, kind: NotificationKind, receivedDate: Date, isRead: Bool) {
        self.id = id
        self.title = title
        self.content = content
        self.kind = kind
        self.receivedDate = receivedDate
        self.isRead = isRead
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "title": title,
            "content": content,
            "kind": kind.rawValue,
            "receivedDate": Timestamp(date: receivedDate),
            "isRead": isRead
        ]
    }
}
