//
//  TodayFeatureSupportTests.swift
//  TodayTabTests
//
//  Created by opfic on 9/12/26.
//

import Testing
import Foundation
import Core
import Domain
@testable import TodayTab

@MainActor
struct TodayFeatureSupportTests {
    @Test("TodayTodoItem은 예정 화면에 필요한 완료 상태와 내용을 보존한다")
    func todayTodoItem은_예정_화면에_필요한_완료_상태와_내용을_보존한다() throws {
        let todo = makeTodayTodo(
            isCompleted: true,
            title: "제목",
            content: "설명"
        )

        let item = try #require(TodayTodoItem(from: todo))

        #expect(item.isCompleted)
        #expect(item.title == "제목")
        #expect(item.content == "설명")
    }

    @Test("TodayFeature achievement는 오늘 마감 Todo만 집계한다")
    func todayFeature_achievement는_오늘_마감_Todo만_집계한다() throws {
        let now = try #require(makeAchievementFixedNow())
        let calendar = Calendar.current
        let interval = TodayFeature.dayInterval(containing: now, calendar: calendar)
        let yesterday = try #require(calendar.date(byAdding: .day, value: -1, to: now))
        let tomorrow = try #require(calendar.date(byAdding: .day, value: 1, to: now))
        let incompleteTodos = [
            TodayTodoItem(from: makeTodayTodo(id: "incomplete-today", dueDate: now)),
            TodayTodoItem(from: makeTodayTodo(id: "without-due-date", dueDate: nil)),
            TodayTodoItem(from: makeTodayTodo(id: "tomorrow", dueDate: tomorrow))
        ].compactMap { $0 }
        let completedTodos = [
            TodayTodoItem(from: makeTodayTodo(id: "completed-today", isCompleted: true, dueDate: now)),
            TodayTodoItem(from: makeTodayTodo(id: "completed-yesterday", isCompleted: true, dueDate: yesterday))
        ].compactMap { $0 }

        let achievement = TodayFeature.achievement(
            incompleteTodos: incompleteTodos,
            completedTodos: completedTodos,
            interval: interval
        )
        let todayTodos = TodayFeature.todayTodos(
            incompleteTodos: incompleteTodos,
            completedTodos: completedTodos,
            interval: interval
        )

        #expect(achievement.completedCount == 1)
        #expect(achievement.totalCount == 2)
        #expect(achievement.progress == 0.5)
        #expect(achievement.status == .inProgress)
        #expect(todayTodos.map(\.id) == ["incomplete-today", "completed-today"])
    }

    @Test("TodayFeature achievement는 대상 없음과 전체 완료 상태를 구분한다")
    func todayFeature_achievement는_대상_없음과_전체_완료_상태를_구분한다() throws {
        let now = try #require(makeAchievementFixedNow())
        let interval = TodayFeature.dayInterval(containing: now)
        let empty = TodayFeature.achievement(
            incompleteTodos: [],
            completedTodos: [],
            interval: interval
        )
        let completed = TodayFeature.achievement(
            incompleteTodos: [],
            completedTodos: [
                try #require(TodayTodoItem(from: makeTodayTodo(isCompleted: true, dueDate: now)))
            ],
            interval: interval
        )

        #expect(empty.completedCount == 0)
        #expect(empty.totalCount == 0)
        #expect(empty.progress == 0)
        #expect(empty.status == .empty)
        #expect(completed.completedCount == 1)
        #expect(completed.totalCount == 1)
        #expect(completed.progress == 1)
        #expect(completed.status == .completed)
    }

    @Test("TodayFeature dayInterval은 일광 절약 시간에도 다음 달력 날짜를 경계로 사용한다")
    func todayFeature_dayInterval은_일광_절약_시간에도_다음_달력_날짜를_경계로_사용한다() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 12)))

        let interval = TodayFeature.dayInterval(containing: date, calendar: calendar)

        #expect(interval.duration == 23 * 60 * 60)
        #expect(calendar.component(.day, from: interval.start) == 8)
        #expect(calendar.component(.day, from: interval.end) == 9)
    }

    @Test("TodayFeature setTodoScope는 남은 일과 중요 보기를 전환한다")
    func todayFeature_setTodoScope는_남은_일과_중요_보기를_전환한다() async throws {
        let todos = makeTodaySectionTodos()
        let fetchSpy = TodayFetchTodosUseCaseSpy(
            pagesByFilter: [
                .withDueDate: .init(items: todos.filter { $0.dueDate != nil }, nextCursor: nil),
                .withoutDueDate: .init(items: todos.filter { $0.dueDate == nil }, nextCursor: nil)
            ]
        )
        let adapter = TodayStoreTestAdapter(fetchUseCase: fetchSpy)

        try await verifyTodayTodoScope(adapter: adapter, fetchUseCaseSpy: fetchSpy)
    }

    @Test("TodayFeature 카테고리는 저장 순서와 단일 선택을 유지한다")
    func todayFeature_카테고리는_저장_순서와_단일_선택을_유지한다() async throws {
        let now = Date()
        let categories = [
            TodoCategoryPreference(category: .system(.doc), isVisible: true),
            TodoCategoryPreference(category: .system(.feature), isVisible: true),
            TodoCategoryPreference(category: .system(.issue), isVisible: false)
        ]
        let todos = [
            makeTodayTodo(id: "swift", isPinned: true, dueDate: now, category: .system(.feature)),
            makeTodayTodo(id: "ios", dueDate: now, category: .system(.feature)),
            makeTodayTodo(id: "doc", dueDate: now, category: .system(.doc))
        ]
        let fetchSpy = TodayFetchTodosUseCaseSpy(
            pagesByFilter: [
                .withDueDate: .init(items: todos.filter { $0.dueDate != nil }, nextCursor: nil),
                .withoutDueDate: .init(items: todos.filter { $0.dueDate == nil }, nextCursor: nil)
            ]
        )
        let adapter = TodayStoreTestAdapter(
            fetchUseCase: fetchSpy,
            fetchCategoryPreferencesUseCase: TodayFetchCategoryPreferencesUseCaseSpy(
                preferences: categories
            ),
            now: now
        )

        await adapter.fetchData()
        await adapter.setCategory(SystemTodoCategory.feature.rawValue)

        #expect(adapter.visibleCategoryIDs == ["doc", "feature"])
        #expect(adapter.displayedSections == [
            TodayDisplayedSection(category: .today, itemIds: ["swift", "ios"])
        ])

        await adapter.setTodoScope(.important)
        #expect(adapter.displayedSections == [
            TodayDisplayedSection(category: .today, itemIds: ["swift"])
        ])

        await adapter.setCategoryFilterPresented(true)
        #expect(adapter.isCategoryFilterPresented)

        await adapter.setTodoScope(.remaining)
        await adapter.setCategory(nil)
        #expect(adapter.displayedSections == [
            TodayDisplayedSection(category: .today, itemIds: ["swift", "ios", "doc"])
        ])
    }

    @Test("TodayFeature completeTodo는 Todo를 제거하고 완료 이벤트를 남긴다")
    func todayFeature_completeTodo는_Todo를_제거하고_완료_이벤트를_남긴다() async throws {
        let todos = makeTodaySectionTodos()
        let fetchSpy = TodayFetchTodosUseCaseSpy(
            pagesByFilter: [
                .withDueDate: .init(items: todos.filter { $0.dueDate != nil }, nextCursor: nil),
                .withoutDueDate: .init(items: todos.filter { $0.dueDate == nil }, nextCursor: nil)
            ]
        )
        let fetchByIdSpy = TodayFetchTodoByIdUseCaseSpy(todos: todos)
        let upsertSpy = TodayUpsertTodoUseCaseSpy()
        let trackSpy = TodayTrackAnalyticsEventUseCaseSpy()
        let adapter = TodayStoreTestAdapter(
            fetchUseCase: fetchSpy,
            fetchTodoByIdUseCase: fetchByIdSpy,
            upsertUseCase: upsertSpy,
            trackAnalyticsEventUseCase: trackSpy
        )

        try await verifyTodayCompleteTodo(
            adapter: adapter,
            fetchUseCaseSpy: fetchSpy,
            fetchTodoByIdUseCaseSpy: fetchByIdSpy,
            upsertTodoUseCaseSpy: upsertSpy,
            trackAnalyticsEventUseCaseSpy: trackSpy
        )
    }

    @Test("TodayFeature fetchData 실패는 에러 표시 상태를 만든다")
    func todayFeature_fetchData_실패는_에러_표시_상태를_만든다() async {
        let fetchSpy = TodayFetchTodosUseCaseSpy()
        fetchSpy.error = TodayTestError.failure
        let adapter = TodayStoreTestAdapter(fetchUseCase: fetchSpy)

        await verifyTodayFetchFailureShowsAlert(adapter: adapter)
    }

    @Test("TodayFeature 카테고리 조회 실패는 Todo 조회 결과를 유지한다")
    func todayFeature_카테고리_조회_실패는_Todo_조회_결과를_유지한다() async {
        let todo = makeTodayTodo(dueDate: Date())
        let fetchSpy = TodayFetchTodosUseCaseSpy(
            pagesByFilter: [
                .withDueDate: .init(items: [todo], nextCursor: nil),
                .withoutDueDate: .init(items: [], nextCursor: nil)
            ]
        )
        let categorySpy = TodayFetchCategoryPreferencesUseCaseSpy()
        categorySpy.error = TodayTestError.failure
        let adapter = TodayStoreTestAdapter(
            fetchUseCase: fetchSpy,
            fetchCategoryPreferencesUseCase: categorySpy
        )

        await adapter.fetchData()

        #expect(adapter.todos.map(\.id) == [todo.id])
        #expect(adapter.showAlert)
    }
}

private func makeAchievementFixedNow() -> Date? {
    Calendar.current.date(
        from: DateComponents(
            year: 2026,
            month: 6,
            day: 14,
            hour: 12
        )
    )
}
