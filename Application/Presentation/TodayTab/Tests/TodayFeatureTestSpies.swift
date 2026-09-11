//
//  TodayFeatureTestSpies.swift
//  TodayTabTests
//
//  Created by opfic on 6/14/26.
//

import Foundation
import Core
import Domain
@testable import TodayTab

final class TodayFetchTodosUseCaseSpy: FetchTodosUseCase {
    var pagesByFilter: [TodoQuery.DueDateFilter: TodoPage]
    var error: Error?
    private let recorder = TodayFetchTodosUseCaseCallRecorder()

    init(
        pagesByFilter: [TodoQuery.DueDateFilter: TodoPage] = [
            .withDueDate: TodoPage(items: [], nextCursor: nil),
            .withoutDueDate: TodoPage(items: [], nextCursor: nil)
        ]
    ) {
        self.pagesByFilter = pagesByFilter
    }

    func execute(_ query: TodoQuery, cursor: TodoCursor?) async throws -> TodoPage {
        await recorder.append(query: query, cursor: cursor)

        if let error {
            throw error
        }

        return pagesByFilter[query.dueDateFilter] ?? TodoPage(items: [], nextCursor: nil)
    }

    func calledQueries() async -> [TodoQuery] {
        await recorder.queries()
    }

    func calledCursors() async -> [TodoCursor?] {
        await recorder.cursors()
    }
}

private actor TodayFetchTodosUseCaseCallRecorder {
    var recordedQueries = [TodoQuery]()
    var recordedCursors = [TodoCursor?]()

    func append(query: TodoQuery, cursor: TodoCursor?) {
        recordedQueries.append(query)
        recordedCursors.append(cursor)
    }

    func queries() -> [TodoQuery] {
        recordedQueries
    }

    func cursors() -> [TodoCursor?] {
        recordedCursors
    }
}

final class TodayFetchTodoByIdUseCaseSpy: FetchTodoByIdUseCase {
    var todos: [Todo]
    var error: Error?
    private(set) var todoIds = [String]()

    init(todos: [Todo] = []) {
        self.todos = todos
    }

    func execute(_ todoId: String) async throws -> Todo {
        todoIds.append(todoId)

        if let error {
            throw error
        }

        return todos.first { $0.id == todoId } ?? makeTodayTodo(id: todoId)
    }
}

final class TodayUpsertTodoUseCaseSpy: UpsertTodoUseCase {
    var error: Error?
    private(set) var todos = [Todo]()
    private(set) var todoDrafts = [TodoDraft]()

    func execute(_ todo: Todo) async throws {
        todos.append(todo)

        if let error {
            throw error
        }
    }

    func execute(_ todoDraft: TodoDraft) async throws {
        todoDrafts.append(todoDraft)

        if let error {
            throw error
        }
    }
}

struct TodayFetchDisplayOptionsUseCaseSpy: FetchTodayDisplayOptionsUseCase {
    var options: TodayDisplayOptions = .default

    func execute() -> TodayDisplayOptions {
        options
    }
}

final class TodayUpdateDisplayOptionsUseCaseSpy: UpdateTodayDisplayOptionsUseCase {
    private(set) var options = [TodayDisplayOptions]()

    func execute(_ options: TodayDisplayOptions) {
        self.options.append(options)
    }
}

final class TodayTrackAnalyticsEventUseCaseSpy: TrackAnalyticsEventUseCase {
    private(set) var events = [AnalyticsEvent]()

    var hasTrackedTodoComplete: Bool {
        events.contains {
            guard case .todoComplete = $0 else { return false }
            return true
        }
    }

    func execute(_ event: AnalyticsEvent) {
        events.append(event)
    }
}

func makeTodayTodo(
    id: String = "todo-1",
    isPinned: Bool = false,
    isCompleted: Bool = false,
    number: Int = 1,
    title: String = "Todo",
    dueDate: Date? = nil
) -> Todo {
    let now = Date(timeIntervalSince1970: 0)
    return Todo(
        id: id,
        isPinned: isPinned,
        isCompleted: isCompleted,
        isChecked: false,
        number: number,
        title: title,
        content: "content",
        createdAt: now,
        updatedAt: now,
        completedAt: isCompleted ? now : nil,
        deletedAt: nil,
        dueDate: dueDate,
        tags: [],
        category: .system(.feature)
    )
}

func makeTodaySectionTodos() -> [Todo] {
    let calendar = Calendar.current
    let startOfToday = calendar.startOfDay(for: Date())

    func dueDate(_ dayOffset: Int) -> Date {
        calendar.date(byAdding: .day, value: dayOffset, to: startOfToday) ?? startOfToday
    }

    return [
        makeTodayTodo(id: "focused", isPinned: true, number: 1, dueDate: dueDate(1)),
        makeTodayTodo(id: "overdue", number: 2, dueDate: dueDate(-1)),
        makeTodayTodo(id: "due-soon", number: 3, dueDate: dueDate(2)),
        makeTodayTodo(id: "later", number: 4, dueDate: dueDate(10)),
        makeTodayTodo(id: "unscheduled", number: 5, dueDate: nil)
    ]
}
