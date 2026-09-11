//
//  TodayTodoItem.swift
//  TodayTab
//
//  Created by opfic on 3/6/26.
//

import Foundation
import Domain

public struct TodayTodoItem: Identifiable, Hashable {
    public let id: String
    public let number: Int
    public let title: String
    public let tags: [String]
    public let isPinned: Bool
    public let updatedAt: Date
    public let dueDate: Date?
    public let category: TodoCategory

    init?(from todo: Todo) {
        self.id = todo.id
        self.number = todo.number
        self.title = todo.title
        self.tags = todo.tags
        self.isPinned = todo.isPinned
        self.updatedAt = todo.updatedAt
        self.dueDate = todo.dueDate
        self.category = todo.category
    }
}
