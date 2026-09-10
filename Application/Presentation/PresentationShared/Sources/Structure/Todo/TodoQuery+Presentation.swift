//
//  TodoQuery+Presentation.swift
//  PresentationShared
//
//  Created by opfic on 6/12/26.
//

import Core
import Foundation

public extension TodoQuery.SortTarget {
    var title: String {
        switch self {
        case .createdAt:
            return String(localized: "todo_sort_created", bundle: PresentationResources.bundle)
        case .completedAt:
            return String(localized: "profile_activity_completed", bundle: PresentationResources.bundle)
        case .deletedAt:
            return String(localized: "profile_activity_deleted", bundle: PresentationResources.bundle)
        case .updatedAt:
            return String(localized: "todo_sort_updated", bundle: PresentationResources.bundle)
        case .dueDate:
            return String(localized: "todo_sort_due_date", bundle: PresentationResources.bundle)
        }
    }
}

public extension TodoQuery.SortOrder {
    var title: String {
        switch self {
        case .latest:
            return String(localized: "todo_sort_latest", bundle: PresentationResources.bundle)
        case .oldest:
            return String(localized: "todo_sort_oldest", bundle: PresentationResources.bundle)
        }
    }
}

public extension TodoQuery.CompletionFilter {
    var title: String {
        switch self {
        case .all:
            return String(localized: "todo_completion_all", bundle: PresentationResources.bundle)
        case .incomplete:
            return String(localized: "todo_completion_incomplete", bundle: PresentationResources.bundle)
        case .completed:
            return String(localized: "todo_completion_completed", bundle: PresentationResources.bundle)
        }
    }
}
