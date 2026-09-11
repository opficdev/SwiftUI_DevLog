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
    func TodayTodoItem은_예정_화면에_필요한_완료_상태와_내용을_보존한다() throws {
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
    func TodayFeature_achievement는_오늘_마감_Todo만_집계한다() throws {
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
    func TodayFeature_achievement는_대상_없음과_전체_완료_상태를_구분한다() throws {
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
    func TodayFeature_dayInterval은_일광_절약_시간에도_다음_달력_날짜를_경계로_사용한다() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 12)))

        let interval = TodayFeature.dayInterval(containing: date, calendar: calendar)

        #expect(interval.duration == 23 * 60 * 60)
        #expect(calendar.component(.day, from: interval.start) == 8)
        #expect(calendar.component(.day, from: interval.end) == 9)
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
