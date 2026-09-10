//
//  RecentTodoItem.swift
//  ProfileTab
//
//  Created by opfic on 9/10/26.
//

import Foundation
import Domain

struct RecentTodoItem: Identifiable, Hashable {
    let id: String
    let number: Int
    let title: String
    let isPinned: Bool
    let updatedAt: Date
    let tags: [String]
    var category: TodoCategory

    init?(from todo: Todo) {
        self.id = todo.id
        self.number = todo.number
        self.title = todo.title
        self.isPinned = todo.isPinned
        self.updatedAt = todo.updatedAt
        self.tags = todo.tags
        self.category = todo.category
    }
}
