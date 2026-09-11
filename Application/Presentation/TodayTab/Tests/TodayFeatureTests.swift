//
//  TodayFeatureTests.swift
//  TodayTabTests
//
//  Created by opfic on 6/14/26.
//

import Testing
import Foundation
import Core
@testable import TodayTab

@MainActor
struct TodayFeatureTests {
    @Test("TodayFeature groupedSectionItems는 주입된 now 기준으로 섹션을 분류한다")
    func TodayFeature_groupedSectionItems는_주입된_now_기준으로_섹션을_분류한다() throws {
        let now = try #require(makeFixedTodayNow())
        let items = makeFixedTodayTodoItems(now: now)

        let sections = TodayFeature.groupedSectionItems(from: items, now: now)

        #expect(sections.focused.map(\.id) == ["focused"])
        #expect(sections.overdue.map(\.id) == ["overdue"])
        #expect(sections.dueSoon.map(\.id) == ["due-soon"])
        #expect(sections.later.map(\.id) == ["later"])
        #expect(sections.unscheduled.map(\.id) == ["unscheduled"])
    }

    @Test("TodayFeature summaryValue는 주입된 now 기준으로 요약 값을 계산한다")
    func TodayFeature_summaryValue는_주입된_now_기준으로_요약_값을_계산한다() throws {
        let now = try #require(makeFixedTodayNow())
        let todos = makeFixedTodayTodoItems(now: now)

        #expect(
            TodayFeature.summaryValue(
                for: .all,
                todos: todos,
                displayOptions: .default,
                now: now
            ) == 5
        )
        #expect(
            TodayFeature.summaryValue(
                for: .focused,
                todos: todos,
                displayOptions: .default,
                now: now
            ) == 1
        )
        #expect(
            TodayFeature.summaryValue(
                for: .overdue,
                todos: todos,
                displayOptions: .default,
                now: now
            ) == 1
        )
        #expect(
            TodayFeature.summaryValue(
                for: .dueSoon,
                todos: todos,
                displayOptions: .default,
                now: now
            ) == 2
        )
    }

    @Test("TodayFeature fetchData는 요약과 섹션 상태를 갱신한다")
    func TodayFeature_fetchData는_요약과_섹션_상태를_갱신한다() async throws {
        let todos = makeTodaySectionTodos()
        let fetchSpy = TodayFetchTodosUseCaseSpy(
            pagesByFilter: [
                .withDueDate: .init(items: todos.filter { $0.dueDate != nil }, nextCursor: nil),
                .withoutDueDate: .init(items: todos.filter { $0.dueDate == nil }, nextCursor: nil)
            ]
        )
        let adapter = TodayStoreTestAdapter(fetchUseCase: fetchSpy)

        try await verifyTodayFetchData(adapter: adapter, fetchUseCaseSpy: fetchSpy)
    }

    @Test("TodayFeature setSectionScope는 동일 탭 재선택 시 all로 되돌린다")
    func TodayFeature_setSectionScope는_동일_탭_재선택_시_all로_되돌린다() async throws {
        let todos = makeTodaySectionTodos()
        let fetchSpy = TodayFetchTodosUseCaseSpy(
            pagesByFilter: [
                .withDueDate: .init(items: todos.filter { $0.dueDate != nil }, nextCursor: nil),
                .withoutDueDate: .init(items: todos.filter { $0.dueDate == nil }, nextCursor: nil)
            ]
        )
        let adapter = TodayStoreTestAdapter(fetchUseCase: fetchSpy)

        try await verifyTodaySectionScopeToggle(adapter: adapter, fetchUseCaseSpy: fetchSpy)
    }

    @Test("TodayFeature displayOptions 변경은 필터링 결과와 저장 상태를 갱신한다")
    func TodayFeature_displayOptions_변경은_필터링_결과와_저장_상태를_갱신한다() async throws {
        let todos = makeTodaySectionTodos()
        let fetchSpy = TodayFetchTodosUseCaseSpy(
            pagesByFilter: [
                .withDueDate: .init(items: todos.filter { $0.dueDate != nil }, nextCursor: nil),
                .withoutDueDate: .init(items: todos.filter { $0.dueDate == nil }, nextCursor: nil)
            ]
        )
        let updateSpy = TodayUpdateDisplayOptionsUseCaseSpy()
        let adapter = TodayStoreTestAdapter(
            fetchUseCase: fetchSpy,
            updateDisplayOptionsUseCase: updateSpy
        )

        try await verifyTodayDisplayOptions(
            adapter: adapter,
            fetchUseCaseSpy: fetchSpy,
            updateDisplayOptionsUseCaseSpy: updateSpy
        )
    }

    @Test("TodayFeature togglePinned는 Todo를 갱신하고 섹션을 다시 계산한다")
    func TodayFeature_togglePinned는_Todo를_갱신하고_섹션을_다시_계산한다() async throws {
        let todos = makeTodaySectionTodos()
        let fetchSpy = TodayFetchTodosUseCaseSpy(
            pagesByFilter: [
                .withDueDate: .init(items: todos.filter { $0.dueDate != nil }, nextCursor: nil),
                .withoutDueDate: .init(items: todos.filter { $0.dueDate == nil }, nextCursor: nil)
            ]
        )
        let fetchByIdSpy = TodayFetchTodoByIdUseCaseSpy(todos: todos)
        let upsertSpy = TodayUpsertTodoUseCaseSpy()
        let adapter = TodayStoreTestAdapter(
            fetchUseCase: fetchSpy,
            fetchTodoByIdUseCase: fetchByIdSpy,
            upsertUseCase: upsertSpy
        )

        try await verifyTodayTogglePinned(
            adapter: adapter,
            fetchUseCaseSpy: fetchSpy,
            fetchTodoByIdUseCaseSpy: fetchByIdSpy,
            upsertTodoUseCaseSpy: upsertSpy
        )
    }

    @Test("TodayFeature completeTodo는 Todo를 제거하고 완료 이벤트를 남긴다")
    func TodayFeature_completeTodo는_Todo를_제거하고_완료_이벤트를_남긴다() async throws {
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
    func TodayFeature_fetchData_실패는_에러_표시_상태를_만든다() async {
        let fetchSpy = TodayFetchTodosUseCaseSpy()
        fetchSpy.error = TodayTestError.failure
        let adapter = TodayStoreTestAdapter(fetchUseCase: fetchSpy)

        await verifyTodayFetchFailureShowsAlert(adapter: adapter)
    }
}

private func makeFixedTodayNow() -> Date? {
    Calendar.current.date(
        from: DateComponents(
            year: 2026,
            month: 6,
            day: 14,
            hour: 12
        )
    )
}

private func makeFixedTodayTodoItems(now: Date) -> [TodayTodoItem] {
    let calendar = Calendar.current

    func dueDate(_ dayOffset: Int) -> Date {
        calendar.date(byAdding: .day, value: dayOffset, to: now) ?? now
    }

    return [
        TodayTodoItem(from: makeTodayTodo(id: "focused", isPinned: true, dueDate: dueDate(1)))!,
        TodayTodoItem(from: makeTodayTodo(id: "overdue", dueDate: dueDate(-1)))!,
        TodayTodoItem(from: makeTodayTodo(id: "due-soon", dueDate: dueDate(2)))!,
        TodayTodoItem(from: makeTodayTodo(id: "later", dueDate: dueDate(10)))!,
        TodayTodoItem(from: makeTodayTodo(id: "unscheduled", dueDate: nil))!
    ]
}
