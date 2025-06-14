//
//  TodoTask.swift
//  DevLog
//
//  Created by opfic on 5/29/25.
//

import Foundation
import FirebaseFirestore

struct Todo: Identifiable, Codable {
    let id: UUID
    var isPinned: Bool      //  해당 할 일이 상단에 고정되어 있는지 여부
    var isCompleted: Bool   //  해당 할 일의 완료 여부
    var isChecked: Bool     //  해당 할 일의 체크 여부
    var title: String       //  할 일의 제목
    var content: String //  할 일의 설명
    var createdAt: Date     //  할 일 생성 날짜
    var updatedAt: Date     //  할 일 수정 날짜
    var dueDate: Date?      //  할 일의 마감 날짜 (선택 사항)
    var tags: [String]      //  할 일에 연결된 태그들
    var kind: TodoKind      //  할 일의 종류

    init(title: String, isPinned: Bool = false, content: String, tags: [String], dueDate: Date?, kind: TodoKind) {
        self.id = UUID()
        self.isPinned = isPinned
        self.isCompleted = false
        self.isChecked = false
        self.title = title
        self.content = content
        self.createdAt = Date()
        self.updatedAt = Date()
        self.dueDate = dueDate
        self.tags = tags
        self.kind = kind
    }
    
    init(from: QueryDocumentSnapshot) {
        let data = from.data()
        self.id = UUID(uuidString: data["id"] as? String ?? UUID().uuidString) ?? UUID()
        self.isPinned = data["isPinned"] as? Bool ?? false
        self.isCompleted = data["isCompleted"] as? Bool ?? false
        self.isChecked = data["isChecked"] as? Bool ?? false
        self.title = data["title"] as? String ?? ""
        self.content = data["content"] as? String ?? ""
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        self.updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        self.dueDate = (data["dueDate"] as? Timestamp)?.dateValue()
        self.tags = data["tags"] as? [String] ?? []
        self.kind = TodoKind(rawValue: data["kind"] as? String ?? "") ?? .etc
    }
    
    mutating func modify(title: String, isPinned: Bool, content: String, tags: [String], dueDate: Date? = nil, kind: TodoKind) {
        self.title = title
        self.isPinned = isPinned
        self.content = content
        self.tags = tags
        self.dueDate = dueDate
        self.kind = kind
        self.updatedAt = Date()
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "isPinned": isPinned,
            "isCompleted": isCompleted,
            "isChecked": isChecked,
            "title": title,
            "content": content,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt),
            "dueDate": dueDate == nil ? NSNull() : Timestamp(date: dueDate!),   //  NSNull로 nil 처리
            "tags": tags,
            "kind": kind.rawValue
        ]
    }
}
