//
//  TodayFeature+State.swift
//  TodayTab
//
//  Created by opfic on 6/14/26.
//

import Core
import Foundation

extension TodayFeature {
    static func summaryValue(
        for scope: SectionScope,
        todos: [TodayTodoItem],
        displayOptions: TodayDisplayOptions,
        now: Date
    ) -> Int {
        let displayedTodos = displayedTodos(
            todos: todos,
            displayOptions: displayOptions
        )

        switch scope {
        case .all:
            return displayedTodos.count
        case .focused:
            return displayedTodos.filter(\.isPinned).count
        case .overdue:
            return displayedTodos.filter { isOverdue($0, now: now) }.count
        case .dueSoon:
            return displayedTodos.filter { isDueSoon($0, now: now) }.count
        }
    }

    static func displayedTodos(
        todos: [TodayTodoItem],
        displayOptions: TodayDisplayOptions
    ) -> [TodayTodoItem] {
        let dueDateFilteredTodos: [TodayTodoItem]
        switch displayOptions.dueDateVisibility {
        case .all:
            dueDateFilteredTodos = todos
        case .withDueDateOnly:
            dueDateFilteredTodos = todos.filter { $0.dueDate != nil }
        case .withoutDueDateOnly:
            dueDateFilteredTodos = todos.filter { $0.dueDate == nil }
        }

        switch displayOptions.focusVisibility {
        case .all:
            return dueDateFilteredTodos
        case .focusedOnly:
            return dueDateFilteredTodos.filter(\.isPinned)
        }
    }

    static func groupedSectionItems(
        from items: [TodayTodoItem],
        now: Date
    ) -> TodayFeature.SectionCollection {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        guard let windowEnd = calendar.date(
            byAdding: .day,
            value: TodayFeature.upcomingWindowDays,
            to: startOfToday
        ) else {
            return TodayFeature.SectionCollection(
                focused: items.filter(\.isPinned),
                unscheduled: items.filter { !$0.isPinned && $0.dueDate == nil }
            )
        }

        var collection = TodayFeature.SectionCollection()

        for item in items {
            if item.isPinned {
                collection.focused.append(item)
                continue
            }

            guard let dueDate = item.dueDate else {
                collection.unscheduled.append(item)
                continue
            }

            let dueDay = calendar.startOfDay(for: dueDate)
            if dueDay < startOfToday {
                collection.overdue.append(item)
            } else if dueDay <= windowEnd {
                collection.dueSoon.append(item)
            } else {
                collection.later.append(item)
            }
        }

        return collection
    }

    static func isOverdue(_ item: TodayTodoItem, now: Date) -> Bool {
        guard let dueDate = item.dueDate else { return false }
        let calendar = Calendar.current
        return calendar.startOfDay(for: dueDate) < calendar.startOfDay(for: now)
    }

    static func isDueSoon(_ item: TodayTodoItem, now: Date) -> Bool {
        guard let dueDate = item.dueDate else { return false }
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        guard let windowEnd = calendar.date(
            byAdding: .day,
            value: TodayFeature.upcomingWindowDays,
            to: startOfToday
        ) else {
            return false
        }
        let dueDay = calendar.startOfDay(for: dueDate)
        return startOfToday <= dueDay && dueDay <= windowEnd
    }

    static func makeSection(
        category: SectionCategory,
        title: String,
        items: [TodayTodoItem]
    ) -> [SectionContent] {
        guard !items.isEmpty else { return [] }
        return [SectionContent(category: category, title: title, items: items)]
    }
}
