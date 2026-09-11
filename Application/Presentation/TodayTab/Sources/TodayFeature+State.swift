//
//  TodayFeature+State.swift
//  TodayTab
//
//  Created by opfic on 6/14/26.
//

import Core
import Foundation
import PresentationShared

extension TodayFeature {
    struct TodayAchievement: Equatable {
        enum Status: Equatable {
            case empty
            case inProgress
            case completed
        }

        let completedCount: Int
        let totalCount: Int

        var progress: Double {
            guard totalCount != 0 else { return 0 }
            return Double(completedCount) / Double(totalCount)
        }

        var status: Status {
            guard totalCount != 0 else { return .empty }
            return completedCount == totalCount ? .completed : .inProgress
        }
    }

    @ObservableState
    struct State: Equatable {
        @Presents var alert: AlertState<Never>?
        var todos: [TodayTodoItem] = []
        var completedTodayTodos: [TodayTodoItem] = []
        var selectedSectionScope: SectionScope = .all
        var displayOptions: TodayDisplayOptions
        var loading = LoadingFeature.State()
        var todayInterval: DateInterval
        var isIncompleteDataLoaded = false
        var isCompletedTodayDataLoaded = false

        init(
            displayOptions: TodayDisplayOptions = .default,
            now: Date = Date()
        ) {
            self.displayOptions = displayOptions
            self.todayInterval = TodayFeature.dayInterval(containing: now)
        }

        var isLoading: Bool {
            loading.isLoading
        }

        var isTodayDataLoaded: Bool {
            isIncompleteDataLoaded && isCompletedTodayDataLoaded
        }

        var todayTodos: [TodayTodoItem] {
            guard isTodayDataLoaded else { return [] }
            return TodayFeature.todayTodos(
                incompleteTodos: todos,
                completedTodos: completedTodayTodos,
                interval: todayInterval
            )
        }

        var todayAchievement: TodayAchievement? {
            guard isTodayDataLoaded else { return nil }
            return TodayFeature.achievement(
                incompleteTodos: todos,
                completedTodos: completedTodayTodos,
                interval: todayInterval
            )
        }

        var sections: [SectionContent] {
            let now = Date()
            let items = TodayFeature.groupedSectionItems(
                from: TodayFeature.displayedTodos(
                    todos: todos,
                    displayOptions: displayOptions
                ),
                now: now
            )

            switch selectedSectionScope {
            case .all:
                return
                    TodayFeature.makeSection(
                        category: .focused,
                        title: String(localized: "today_section_focused", bundle: PresentationResources.bundle),
                        items: items.focused
                    )
                    + TodayFeature.makeSection(
                        category: .overdue,
                        title: String(localized: "today_section_overdue", bundle: PresentationResources.bundle),
                        items: items.overdue
                    )
                    + TodayFeature.makeSection(
                        category: .dueSoon,
                        title: String.localizedStringWithFormat(
                            String(localized: "today_section_due_soon_format", bundle: PresentationResources.bundle),
                            Int64(TodayFeature.upcomingWindowDays)
                        ),
                        items: items.dueSoon
                    )
                    + TodayFeature.makeSection(
                        category: .later,
                        title: String(localized: "today_section_later", bundle: PresentationResources.bundle),
                        items: items.later
                    )
                    + TodayFeature.makeSection(
                        category: .unscheduled,
                        title: String(localized: "today_section_unscheduled", bundle: PresentationResources.bundle),
                        items: items.unscheduled
                    )
            case .focused:
                return TodayFeature.makeSection(
                    category: .focused,
                    title: String(localized: "today_section_focused", bundle: PresentationResources.bundle),
                    items: items.focused
                )
            case .overdue:
                return TodayFeature.makeSection(
                    category: .overdue,
                    title: String(localized: "today_section_overdue", bundle: PresentationResources.bundle),
                    items: items.overdue
                )
            case .dueSoon:
                return TodayFeature.makeSection(
                    category: .dueSoon,
                    title: String.localizedStringWithFormat(
                        String(localized: "today_section_due_soon_format", bundle: PresentationResources.bundle),
                        Int64(TodayFeature.upcomingWindowDays)
                    ),
                    items: items.dueSoon
                )
            }
        }

        var summaryCounts: [SectionScope: Int] {
            let now = Date()
            return Dictionary(
                uniqueKeysWithValues: SectionScope.allCases.map { scope in
                    (
                        scope,
                        TodayFeature.summaryValue(
                            for: scope,
                            todos: todos,
                            displayOptions: displayOptions,
                            now: now
                        )
                    )
                }
            )
        }
    }

    static func dayInterval(
        containing date: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> DateInterval {
        calendar.dateInterval(of: .day, for: date) ?? DateInterval(start: date, duration: 0)
    }

    static func isDue(_ item: TodayTodoItem, in interval: DateInterval) -> Bool {
        guard let dueDate = item.dueDate else { return false }
        return interval.start <= dueDate && dueDate < interval.end
    }

    static func todayTodos(
        incompleteTodos: [TodayTodoItem],
        completedTodos: [TodayTodoItem],
        interval: DateInterval
    ) -> [TodayTodoItem] {
        incompleteTodos.filter { isDue($0, in: interval) }
            + completedTodos.filter { isDue($0, in: interval) }
    }

    static func achievement(
        incompleteTodos: [TodayTodoItem],
        completedTodos: [TodayTodoItem],
        interval: DateInterval
    ) -> TodayAchievement {
        let todos = todayTodos(
            incompleteTodos: incompleteTodos,
            completedTodos: completedTodos,
            interval: interval
        )
        return TodayAchievement(
            completedCount: todos.filter(\.isCompleted).count,
            totalCount: todos.count
        )
    }

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
