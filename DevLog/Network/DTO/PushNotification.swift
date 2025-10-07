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
    let title: String   //  알림 제목
    let body: String    //  알림 내용
    let receivedDate: Date  //  알림 수신 날짜
    var isRead: Bool    //  알림 읽음 여부
    let todoId: String //  Todo ID
    
    init(from: QueryDocumentSnapshot) {
        self.id = from.documentID
        self.title = from["title"] as? String ?? ""
        self.body = from["body"] as? String ?? ""
        self.receivedDate = (from["receivedDate"] as? Timestamp)?.dateValue() ?? Date()
        self.isRead = from["isRead"] as? Bool ?? false
        self.todoId = from["todoId"] as? String ?? ""
    }
    
    init(id: String? = nil, title: String, body: String, receivedDate: Date, isRead: Bool, todoId: String) {
        self.id = id
        self.title = title
        self.body = body
        self.receivedDate = receivedDate
        self.isRead = isRead
        self.todoId = todoId
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "title": title,
            "body": body,
            "receivedDate": Timestamp(date: receivedDate),
            "isRead": isRead,
            "todoId": todoId
        ]
    }
}
