//
//  SearchRowItem.swift
//  HomeTab
//
//  Created by 최윤진 on 9/11/26.
//

import Domain
import Foundation

struct SearchTodoItem: Identifiable, Hashable {
    public let id: String
    public let number: Int
    public let title: String
    public let category: TodoCategory
    public let createdAt: Date
    public let isPinned: Bool

    public init(todo: Todo) {
        self.id = todo.id
        self.number = todo.number
        self.title = todo.title
        self.category = todo.category
        self.createdAt = todo.createdAt
        self.isPinned = todo.isPinned
    }
}
