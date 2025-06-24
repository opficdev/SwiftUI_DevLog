//
//  TodoService.swift
//  DevLog
//
//  Created by opfic on 6/2/25.
//

import Foundation
import Combine
import FirebaseFirestore

class TodoService {
    private let db = Firestore.firestore()
    
    func requestPinnedTodoList(userId: String) async throws -> [Todo] {
        let collection = db.collection("users/\(userId)/todoLists/")
        
        let query = collection.whereField(("isPinned"), isEqualTo: true)
            .order(by: "createdAt", descending: true)
        
        let snapshot = try await query.getDocuments()
        
        return snapshot.documents.compactMap { Todo(from: $0) }
    }

    func requestTodoList(kind: TodoKind, userId: String) async throws -> [Todo] {
        let collection = db.collection("users/\(userId)/todoLists/")
        
        let query = collection.whereField("kind", isEqualTo: kind.rawValue)
            .order(by: "createdAt", descending: true)
        
        let snapshot = try await query.getDocuments()
        
        return snapshot.documents.compactMap { Todo(from: $0) }
    }
    
    func upsertTodo(todo: Todo, userId: String) async throws {
        let collection = db.collection("users/\(userId)/todoLists/")
        
        let docRef = collection.document(todo.id.uuidString)
        
        try await docRef.setData(todo.toDictionary(), merge: true)
    }
    
    func deleteTodo(todo: Todo, userId: String) async throws {
        let collection = db.collection("users/\(userId)/todoLists/")
        
        let docRef = collection.document(todo.id.uuidString)
        
        try await docRef.delete()
    }
}
