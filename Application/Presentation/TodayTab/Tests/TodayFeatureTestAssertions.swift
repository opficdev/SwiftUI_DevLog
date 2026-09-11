//
//  TodayFeatureTestAssertions.swift
//  TodayTabTests
//
//  Created by opfic on 6/14/26.
//

import Testing
import Core
import Domain
@testable import TodayTab

@MainActor
private func waitUntilTodayMainActor(
    timeout: Duration = .seconds(1),
    pollInterval: Duration = .milliseconds(20),
    _ condition: @escaping @MainActor () -> Bool
) async {
    let continuousClock = ContinuousClock()
    let deadline = continuousClock.now + timeout

    while !condition() && continuousClock.now < deadline {
        try? await Task.sleep(for: pollInterval)
    }
}

@MainActor
func verifyTodayFetchData<Adapter: TodayStateDriving>(
    adapter: Adapter,
    fetchUseCaseSpy: TodayFetchTodosUseCaseSpy
) async throws {
    await adapter.fetchData()

    await waitUntilTodayMainActor {
        adapter.todos.count == 5
    }

    let queries = await fetchUseCaseSpy.calledQueries()
    let queriesByDueDateFilter = Dictionary(
        uniqueKeysWithValues: queries.map { ($0.dueDateFilter, $0) }
    )
    let cursors = await fetchUseCaseSpy.calledCursors()

    #expect(queries.count == 2)
    #expect(Set(queries.map(\.dueDateFilter)) == Set([.withDueDate, .withoutDueDate]))
    #expect(queries.allSatisfy { $0.completionFilter == .incomplete })
    #expect(queriesByDueDateFilter[.withDueDate]?.sortTarget == .dueDate)
    #expect(queriesByDueDateFilter[.withDueDate]?.sortOrder == .oldest)
    #expect(queriesByDueDateFilter[.withoutDueDate]?.sortTarget == .updatedAt)
    #expect(queriesByDueDateFilter[.withoutDueDate]?.sortOrder == .latest)
    #expect(queries.map(\.pageSize).allSatisfy { $0 == 20 })
    #expect(queries.map(\.fetchAllPages).allSatisfy { $0 })
    #expect(cursors.count == 2)
    #expect(cursors.allSatisfy { $0 == nil })
    #expect(adapter.todos.map(\.id) == ["focused", "overdue", "due-soon", "later", "unscheduled"])
    #expect(adapter.summaryCounts == [
        .all: 5,
        .focused: 1,
        .overdue: 1,
        .dueSoon: 2
    ])
    #expect(adapter.displayedSections == [
        TodayDisplayedSection(category: .focused, itemIds: ["focused"]),
        TodayDisplayedSection(category: .overdue, itemIds: ["overdue"]),
        TodayDisplayedSection(category: .dueSoon, itemIds: ["due-soon"]),
        TodayDisplayedSection(category: .later, itemIds: ["later"]),
        TodayDisplayedSection(category: .unscheduled, itemIds: ["unscheduled"])
    ])
}

@MainActor
func verifyTodaySectionScopeToggle<Adapter: TodayStateDriving>(
    adapter: Adapter,
    fetchUseCaseSpy: TodayFetchTodosUseCaseSpy
) async throws {
    try await verifyTodayFetchData(adapter: adapter, fetchUseCaseSpy: fetchUseCaseSpy)

    await adapter.setSectionScope(.focused)

    #expect(adapter.selectedSectionScope == .focused)
    #expect(adapter.displayedSections == [
        TodayDisplayedSection(category: .focused, itemIds: ["focused"])
    ])

    await adapter.setSectionScope(.focused)

    #expect(adapter.selectedSectionScope == .all)
    #expect(adapter.displayedSections.count == 5)

    await adapter.setSectionScope(.overdue)

    #expect(adapter.selectedSectionScope == .overdue)
    #expect(adapter.displayedSections == [
        TodayDisplayedSection(category: .overdue, itemIds: ["overdue"])
    ])
}

@MainActor
func verifyTodayDisplayOptions<Adapter: TodayStateDriving>(
    adapter: Adapter,
    fetchUseCaseSpy: TodayFetchTodosUseCaseSpy,
    updateDisplayOptionsUseCaseSpy: TodayUpdateDisplayOptionsUseCaseSpy
) async throws {
    try await verifyTodayFetchData(adapter: adapter, fetchUseCaseSpy: fetchUseCaseSpy)

    await adapter.setDueDateVisibility(.withoutDueDateOnly)

    #expect(adapter.displayOptions.dueDateVisibility == .withoutDueDateOnly)
    #expect(adapter.summaryCounts == [
        .all: 1,
        .focused: 0,
        .overdue: 0,
        .dueSoon: 0
    ])
    #expect(adapter.displayedSections == [
        TodayDisplayedSection(category: .unscheduled, itemIds: ["unscheduled"])
    ])

    await adapter.setDueDateVisibility(.all)
    await adapter.setFocusVisibility(.focusedOnly)

    #expect(adapter.displayOptions.focusVisibility == .focusedOnly)
    #expect(adapter.summaryCounts == [
        .all: 1,
        .focused: 1,
        .overdue: 0,
        .dueSoon: 1
    ])
    #expect(adapter.displayedSections == [
        TodayDisplayedSection(category: .focused, itemIds: ["focused"])
    ])

    await adapter.resetDisplayOptions()

    #expect(adapter.displayOptions == .default)
    #expect(updateDisplayOptionsUseCaseSpy.options == [
        TodayDisplayOptions(dueDateVisibility: .withoutDueDateOnly, focusVisibility: .all),
        TodayDisplayOptions(dueDateVisibility: .all, focusVisibility: .all),
        TodayDisplayOptions(dueDateVisibility: .all, focusVisibility: .focusedOnly),
        .default
    ])
}

@MainActor
func verifyTodayTogglePinned<Adapter: TodayStateDriving>(
    adapter: Adapter,
    fetchUseCaseSpy: TodayFetchTodosUseCaseSpy,
    fetchTodoByIdUseCaseSpy: TodayFetchTodoByIdUseCaseSpy,
    upsertTodoUseCaseSpy: TodayUpsertTodoUseCaseSpy
) async throws {
    try await verifyTodayFetchData(adapter: adapter, fetchUseCaseSpy: fetchUseCaseSpy)

    let item = try #require(adapter.todos.first { $0.id == "later" })
    await adapter.togglePinned(item)

    await waitUntilTodayMainActor {
        adapter.todos.first { $0.id == "later" }?.isPinned == true
    }

    #expect(fetchTodoByIdUseCaseSpy.todoIds == ["later"])
    #expect(upsertTodoUseCaseSpy.todos.last?.id == "later")
    #expect(upsertTodoUseCaseSpy.todos.last?.isPinned == true)
    #expect(adapter.summaryCounts == [
        .all: 5,
        .focused: 2,
        .overdue: 1,
        .dueSoon: 2
    ])
    #expect(adapter.displayedSections == [
        TodayDisplayedSection(category: .focused, itemIds: ["focused", "later"]),
        TodayDisplayedSection(category: .overdue, itemIds: ["overdue"]),
        TodayDisplayedSection(category: .dueSoon, itemIds: ["due-soon"]),
        TodayDisplayedSection(category: .unscheduled, itemIds: ["unscheduled"])
    ])
}

@MainActor
func verifyTodayCompleteTodo<Adapter: TodayStateDriving>(
    adapter: Adapter,
    fetchUseCaseSpy: TodayFetchTodosUseCaseSpy,
    fetchTodoByIdUseCaseSpy: TodayFetchTodoByIdUseCaseSpy,
    upsertTodoUseCaseSpy: TodayUpsertTodoUseCaseSpy,
    trackAnalyticsEventUseCaseSpy: TodayTrackAnalyticsEventUseCaseSpy
) async throws {
    try await verifyTodayFetchData(adapter: adapter, fetchUseCaseSpy: fetchUseCaseSpy)

    let item = try #require(adapter.todos.first { $0.id == "due-soon" })
    await adapter.completeTodo(item)

    await waitUntilTodayMainActor {
        !adapter.todos.map(\.id).contains("due-soon")
    }

    #expect(fetchTodoByIdUseCaseSpy.todoIds == ["due-soon"])
    #expect(upsertTodoUseCaseSpy.todos.last?.id == "due-soon")
    #expect(upsertTodoUseCaseSpy.todos.last?.isCompleted == true)
    #expect(trackAnalyticsEventUseCaseSpy.hasTrackedTodoComplete)
    #expect(adapter.summaryCounts == [
        .all: 4,
        .focused: 1,
        .overdue: 1,
        .dueSoon: 1
    ])
    #expect(adapter.displayedSections == [
        TodayDisplayedSection(category: .focused, itemIds: ["focused"]),
        TodayDisplayedSection(category: .overdue, itemIds: ["overdue"]),
        TodayDisplayedSection(category: .later, itemIds: ["later"]),
        TodayDisplayedSection(category: .unscheduled, itemIds: ["unscheduled"])
    ])
}

@MainActor
func verifyTodayFetchFailureShowsAlert<Adapter: TodayStateDriving>(
    adapter: Adapter
) async {
    await adapter.fetchData()

    await waitUntilTodayMainActor {
        adapter.showAlert
    }

    #expect(adapter.showAlert)
}
