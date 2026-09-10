//
//  HeatmapActivityItem.swift
//  ProfileTab
//
//  Created by opfic on 3/2/26.
//

import Foundation
import Core
import Domain

public struct HeatmapActivityItem: Identifiable, Hashable, Comparable {
    public var id: String { todoId }
    public let todoId: String
    public let title: String
    public let number: Int
    public let category: TodoCategory
    public let activityKinds: [ActivityKind]
    public let isDeleted: Bool

    public var activityKindItems: [ActivityKindItem] {
        let orderedKinds: [ActivityKind] = [.created, .completed, .deleted]
        return orderedKinds.compactMap { activityKind in
            if activityKinds.contains(activityKind) {
                return ActivityKindItem(from: activityKind)
            }
            return nil
        }
    }

    init?(todo: Todo, activityKinds: [ActivityKind]) {
        self.todoId = todo.id
        self.title = todo.title
        self.number = todo.number
        self.category = todo.category
        self.activityKinds = activityKinds
        self.isDeleted = todo.deletedAt != nil
    }

    public static func < (lhs: HeatmapActivityItem, rhs: HeatmapActivityItem) -> Bool {
        lhs.number < rhs.number
    }
}
