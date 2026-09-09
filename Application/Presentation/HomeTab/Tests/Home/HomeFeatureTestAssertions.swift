//
//  HomeFeatureTestAssertions.swift
//  HomeTabTests
//
//  Created by opfic on 6/14/26.
//

import Testing
import Foundation
import Domain
import PresentationShared
@testable import HomeTab

@MainActor
func verifyHomeFetchData(
    adapter: HomeStoreTestAdapter,
    fetchTodosUseCaseSpy: FetchTodosUseCaseSpy
) async throws {
    await adapter.fetchData()

    await waitUntil {
        adapter.preferences.count == 2
            && adapter.recentTodos.count == 2
    }

    #expect(adapter.preferences.map(\.id) == ["feature", "custom"])
    #expect(adapter.recentTodos.map(\.id) == ["todo-1", "todo-2"])
    #expect(fetchTodosUseCaseSpy.queries.count == 1)
    #expect(fetchTodosUseCaseSpy.queries.first?.sortTarget == .updatedAt)
    #expect(fetchTodosUseCaseSpy.queries.first?.sortOrder == .latest)
    #expect(fetchTodosUseCaseSpy.queries.first?.pageSize == 100)
}

@MainActor
func verifyHomeTapTodoCategory(
    adapter: HomeStoreTestAdapter
) async throws {
    await adapter.setPresentation(.contentPicker, true)
    await adapter.tapTodoCategory(.system(.feature))

    #expect(!adapter.showContentPicker)
    #expect(adapter.showTodoEditor)
}

@MainActor
func verifyHomeOrderTodoCategory(
    adapter: HomeStoreTestAdapter,
    updatePreferencesUseCaseSpy: UpdateTodoCategoryPreferencesUseCaseSpy
) async throws {
    await adapter.fetchData()

    let updatedCategory = TodoCategoryItem(
        from: .user(
            UserTodoCategory(
                id: "custom",
                name: "Updated",
                colorHex: "#222222"
            )
        )
    )
    let items = [
        updatedCategory,
        TodoCategoryItem(from: .system(.feature))
    ]

    await adapter.tapManageTodoCategory()

    #expect(adapter.showCategoryManage)

    await adapter.orderTodoCategory(items)

    #expect(adapter.preferences == items)
    #expect(adapter.recentTodos.last?.category == updatedCategory.category)
    #expect(updatePreferencesUseCaseSpy.updates == [items.map(\.preference)])
    #expect(!adapter.showCategoryManage)
}

struct HomeFetchDataContext {
    let fetchPreferencesUseCaseSpy: FetchTodoCategoryPreferencesUseCaseSpy
    let fetchTodosUseCaseSpy: FetchTodosUseCaseSpy
}

func makeHomeFetchDataContext() -> HomeFetchDataContext {
    let fetchPreferencesUseCaseSpy = FetchTodoCategoryPreferencesUseCaseSpy()
    fetchPreferencesUseCaseSpy.todoCategoryPreferences = [
        TodoCategoryPreference(category: .system(.feature), isVisible: true),
        TodoCategoryPreference(
            category: .user(
                UserTodoCategory(
                    id: "custom",
                    name: "Custom",
                    colorHex: "#111111"
                )
            ),
            isVisible: true
        )
    ]

    let fetchTodosUseCaseSpy = FetchTodosUseCaseSpy()
    let createdAt = Date(timeIntervalSince1970: 0)
    fetchTodosUseCaseSpy.todoPage = TodoPage(
        items: [
            makeHomeTodo(id: "todo-1", category: .system(.feature), number: 1),
            makeHomeTodo(
                id: "todo-2",
                category: .user(
                    UserTodoCategory(
                        id: "custom",
                        name: "Custom",
                        colorHex: "#111111"
                    )
                ),
                number: 2
            ),
            makeHomeTodo(
                id: "todo-ignored",
                number: 3,
                createdAt: createdAt,
                updatedAt: createdAt
            )
        ],
        nextCursor: nil
    )

    return HomeFetchDataContext(
        fetchPreferencesUseCaseSpy: fetchPreferencesUseCaseSpy,
        fetchTodosUseCaseSpy: fetchTodosUseCaseSpy
    )
}

struct HomeOrderContext {
    let fetchPreferencesUseCaseSpy: FetchTodoCategoryPreferencesUseCaseSpy
    let updatePreferencesUseCaseSpy: UpdateTodoCategoryPreferencesUseCaseSpy
    let fetchTodosUseCaseSpy: FetchTodosUseCaseSpy
}

func makeHomeOrderContext() -> HomeOrderContext {
    let fetchContext = makeHomeFetchDataContext()
    return HomeOrderContext(
        fetchPreferencesUseCaseSpy: fetchContext.fetchPreferencesUseCaseSpy,
        updatePreferencesUseCaseSpy: UpdateTodoCategoryPreferencesUseCaseSpy(),
        fetchTodosUseCaseSpy: fetchContext.fetchTodosUseCaseSpy
    )
}
