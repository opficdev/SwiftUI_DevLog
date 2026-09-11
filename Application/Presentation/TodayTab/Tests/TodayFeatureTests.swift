//
//  TodayFeatureTests.swift
//  TodayTabTests
//
//  Created by opfic on 6/14/26.
//

import Testing
import Foundation
import Core
import Domain
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

    @Test("TodayFeature fetchData는 오늘 완료 Todo를 별도 조회해 달성 상태를 만든다")
    func TodayFeature_fetchData는_오늘_완료_Todo를_별도_조회해_달성_상태를_만든다() async throws {
        let now = try #require(makeFixedTodayNow())
        let incompleteToday = makeTodayTodo(id: "incomplete-today", dueDate: now)
        let completedToday = makeTodayTodo(id: "completed-today", isCompleted: true, dueDate: now)
        let fetchSpy = TodayFetchTodosUseCaseSpy(
            pagesByFilter: [
                .withDueDate: TodoPage(items: [incompleteToday], nextCursor: nil),
                .withoutDueDate: TodoPage(items: [], nextCursor: nil)
            ],
            completedTodayPage: TodoPage(items: [completedToday], nextCursor: nil)
        )
        let adapter = TodayStoreTestAdapter(fetchUseCase: fetchSpy, now: now)

        await adapter.fetchData()

        #expect(adapter.completedTodayTodos.map(\.id) == ["completed-today"])
        #expect(adapter.todayTodos.map(\.id) == ["incomplete-today", "completed-today"])
        #expect(adapter.todayAchievement?.completedCount == 1)
        #expect(adapter.todayAchievement?.totalCount == 2)
        #expect(adapter.summaryCounts[.all] == 1)
    }

    @Test("TodayFeature checkCurrentDate는 날짜가 바뀔 때만 오늘 완료 Todo를 다시 조회한다")
    func TodayFeature_checkCurrentDate는_날짜가_바뀔_때만_오늘_완료_Todo를_다시_조회한다() async throws {
        let now = try #require(makeFixedTodayNow())
        let calendar = Calendar.current
        let nextDay = try #require(calendar.date(byAdding: .day, value: 1, to: now))
        let fetchSpy = TodayFetchTodosUseCaseSpy()
        let adapter = TodayStoreTestAdapter(fetchUseCase: fetchSpy, now: now)
        await adapter.fetchData()

        await adapter.checkCurrentDate(now)
        let sameDayQueries = await fetchSpy.calledQueries()
        let sameDayQueryCount = sameDayQueries.count
        #expect(sameDayQueryCount == 3)

        fetchSpy.completedTodayPage = TodoPage(
            items: [makeTodayTodo(id: "next-day", isCompleted: true, dueDate: nextDay)],
            nextCursor: nil
        )
        await adapter.checkCurrentDate(nextDay)

        let queries = await fetchSpy.calledQueries()
        let lastQuery = try #require(queries.last)
        #expect(queries.count == 4)
        #expect(lastQuery.completionFilter == .completed)
        #expect(lastQuery.sortDateFrom == adapter.todayInterval.start)
        #expect(lastQuery.sortDateTo == adapter.todayInterval.end)
        #expect(adapter.completedTodayTodos.map(\.id) == ["next-day"])
        #expect(adapter.todayAchievement?.completedCount == 1)
        #expect(adapter.todayAchievement?.totalCount == 1)
    }

    @Test("TodayFeature는 이전 날짜의 완료 조회 결과를 반영하지 않는다")
    func TodayFeature는_이전_날짜의_완료_조회_결과를_반영하지_않는다() async throws {
        let now = try #require(makeFixedTodayNow())
        let calendar = Calendar.current
        let previousDay = try #require(calendar.date(byAdding: .day, value: -1, to: now))
        let adapter = TodayStoreTestAdapter(now: now)
        let previousInterval = TodayFeature.dayInterval(containing: previousDay)
        let staleItem = try #require(TodayTodoItem(from: makeTodayTodo(
            id: "stale",
            isCompleted: true,
            dueDate: previousDay
        )))

        await adapter.receiveCompletedTodayTodos([staleItem], interval: previousInterval)

        #expect(adapter.completedTodayTodos.isEmpty)
        #expect(!adapter.isTodayDataLoaded)
        #expect(adapter.todayAchievement == nil)
    }

    @Test("TodayFeature는 최초 조회 중 날짜가 바뀌면 새 날짜 전체 데이터를 다시 조회한다")
    func TodayFeature는_최초_조회_중_날짜가_바뀌면_새_날짜_전체_데이터를_다시_조회한다() async throws {
        let now = try #require(makeFixedTodayNow())
        let calendar = Calendar.current
        let nextDay = try #require(calendar.date(byAdding: .day, value: 1, to: now))
        let previousInterval = TodayFeature.dayInterval(containing: now)
        let incompleteTodo = makeTodayTodo(id: "next-incomplete", dueDate: nextDay)
        let completedTodo = makeTodayTodo(
            id: "next-completed",
            isCompleted: true,
            dueDate: nextDay
        )
        let fetchSpy = TodayFetchTodosUseCaseSpy(
            pagesByFilter: [
                .withDueDate: TodoPage(items: [incompleteTodo], nextCursor: nil),
                .withoutDueDate: TodoPage(items: [], nextCursor: nil)
            ],
            completedTodayPage: TodoPage(items: [completedTodo], nextCursor: nil)
        )
        let adapter = TodayStoreTestAdapter(fetchUseCase: fetchSpy, now: now)

        await adapter.checkCurrentDate(nextDay)

        let queries = await fetchSpy.calledQueries()
        let queryCount = queries.count
        #expect(queryCount == 3)
        #expect(adapter.isTodayDataLoaded)
        #expect(adapter.todayTodos.map(\.id) == ["next-incomplete", "next-completed"])
        #expect(adapter.todayAchievement?.completedCount == 1)
        #expect(adapter.todayAchievement?.totalCount == 2)

        let staleItem = try #require(TodayTodoItem(from: makeTodayTodo(
            id: "stale",
            dueDate: nextDay
        )))

        await adapter.receiveTodos(
            incomplete: [staleItem],
            completedToday: [],
            interval: previousInterval
        )

        #expect(adapter.isTodayDataLoaded)
        #expect(adapter.todayTodos.map(\.id) == ["next-incomplete", "next-completed"])
        #expect(adapter.todayAchievement?.completedCount == 1)
        #expect(adapter.todayAchievement?.totalCount == 2)
    }

    @Test("TodayFeature completeTodo는 오늘 Todo를 완료 목록으로 한 번만 이동한다")
    func TodayFeature_completeTodo는_오늘_Todo를_완료_목록으로_한_번만_이동한다() async throws {
        let now = try #require(makeFixedTodayNow())
        let todo = makeTodayTodo(id: "today", dueDate: now)
        let fetchSpy = TodayFetchTodosUseCaseSpy(
            pagesByFilter: [
                .withDueDate: TodoPage(items: [todo], nextCursor: nil),
                .withoutDueDate: TodoPage(items: [], nextCursor: nil)
            ]
        )
        let fetchByIdSpy = TodayFetchTodoByIdUseCaseSpy(todos: [todo])
        let adapter = TodayStoreTestAdapter(
            fetchUseCase: fetchSpy,
            fetchTodoByIdUseCase: fetchByIdSpy,
            now: now
        )
        await adapter.fetchData()
        let item = try #require(adapter.todos.first)

        await adapter.completeTodo(item)

        let completedItem = try #require(adapter.completedTodayTodos.first)
        await adapter.receiveUpdatedTodo(completedItem)
        await adapter.receiveUpdatedTodo(completedItem)

        #expect(adapter.todos.isEmpty)
        #expect(adapter.completedTodayTodos.map(\.id) == ["today"])
        #expect(adapter.todayAchievement?.completedCount == 1)
        #expect(adapter.todayAchievement?.totalCount == 1)
    }

    @Test("TodayFeature completeTodo는 저장된 최신 마감일로 오늘 완료 목록을 갱신한다")
    func TodayFeature_completeTodo는_저장된_최신_마감일로_오늘_완료_목록을_갱신한다() async throws {
        let now = try #require(makeFixedTodayNow())
        let tomorrow = try #require(Calendar.current.date(byAdding: .day, value: 1, to: now))
        let original = makeTodayTodo(id: "today", dueDate: now)
        let latest = makeTodayTodo(id: "today", dueDate: tomorrow)
        let fetchSpy = TodayFetchTodosUseCaseSpy(
            pagesByFilter: [
                .withDueDate: TodoPage(items: [original], nextCursor: nil),
                .withoutDueDate: TodoPage(items: [], nextCursor: nil)
            ]
        )
        let adapter = TodayStoreTestAdapter(
            fetchUseCase: fetchSpy,
            fetchTodoByIdUseCase: TodayFetchTodoByIdUseCaseSpy(todos: [latest]),
            now: now
        )
        await adapter.fetchData()
        let item = try #require(adapter.todos.first)

        await adapter.completeTodo(item)

        #expect(adapter.todos.isEmpty)
        #expect(adapter.completedTodayTodos.isEmpty)
        #expect(adapter.todayAchievement?.completedCount == 0)
        #expect(adapter.todayAchievement?.totalCount == 0)
    }

    @Test("TodayFeature completeTodo 실패는 오늘 달성 상태를 유지한다")
    func TodayFeature_completeTodo_실패는_오늘_달성_상태를_유지한다() async throws {
        let now = try #require(makeFixedTodayNow())
        let todo = makeTodayTodo(id: "today", dueDate: now)
        let fetchSpy = TodayFetchTodosUseCaseSpy(
            pagesByFilter: [
                .withDueDate: TodoPage(items: [todo], nextCursor: nil),
                .withoutDueDate: TodoPage(items: [], nextCursor: nil)
            ]
        )
        let upsertSpy = TodayUpsertTodoUseCaseSpy()
        upsertSpy.error = TodayTestError.failure
        let adapter = TodayStoreTestAdapter(
            fetchUseCase: fetchSpy,
            fetchTodoByIdUseCase: TodayFetchTodoByIdUseCaseSpy(todos: [todo]),
            upsertUseCase: upsertSpy,
            now: now
        )
        await adapter.fetchData()
        let item = try #require(adapter.todos.first)

        await adapter.completeTodo(item)

        #expect(adapter.todos.map(\.id) == ["today"])
        #expect(adapter.completedTodayTodos.isEmpty)
        #expect(adapter.todayAchievement?.completedCount == 0)
        #expect(adapter.todayAchievement?.totalCount == 1)
        #expect(adapter.showAlert)
    }

    @Test("TodayFeature 달성 상태는 isChecked와 표시 옵션의 영향을 받지 않는다")
    func TodayFeature_달성_상태는_isChecked와_표시_옵션의_영향을_받지_않는다() async throws {
        let now = try #require(makeFixedTodayNow())
        let checkedTodo = makeTodayTodo(id: "checked", isChecked: true, dueDate: now)
        let completedTodo = makeTodayTodo(id: "completed", isCompleted: true, dueDate: now)
        let fetchSpy = TodayFetchTodosUseCaseSpy(
            pagesByFilter: [
                .withDueDate: TodoPage(items: [checkedTodo], nextCursor: nil),
                .withoutDueDate: TodoPage(items: [], nextCursor: nil)
            ],
            completedTodayPage: TodoPage(items: [completedTodo], nextCursor: nil)
        )
        let adapter = TodayStoreTestAdapter(fetchUseCase: fetchSpy, now: now)
        await adapter.fetchData()

        await adapter.setDueDateVisibility(.withoutDueDateOnly)
        await adapter.setFocusVisibility(.focusedOnly)

        #expect(adapter.todayAchievement?.completedCount == 1)
        #expect(adapter.todayAchievement?.totalCount == 2)
        #expect(adapter.todayAchievement?.status == .inProgress)
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
