//
//  SearchFeatureTests.swift
//  HomeTabTests
//
//  Created by opfic on 6/12/26.
//

import Testing
import Foundation
import Core
import Domain
import PresentationShared
@testable import HomeTab

@MainActor
struct SearchFeatureTests {
    @Test("초기화 시 최근 검색어를 상태에 반영한다")
    func 초기화_시_최근_검색어를_상태에_반영한다() {
        let adapter = SearchStoreTestAdapter(recentQueries: ["swift", "tca"])

        #expect(adapter.recentQueries == ["swift", "tca"])
    }

    @Test("onAppear는 검색 상태를 활성화한다")
    func onAppear는_검색_상태를_활성화한다() async {
        let adapter = SearchStoreTestAdapter()

        await adapter.onAppear()

        #expect(adapter.isSearching)
    }

    @Test("addRecentQuery는 공백을 제거하고 중복 제거 후 앞에 추가한다")
    func addRecentQuery는_공백을_제거하고_중복_제거_후_앞에_추가한다() async {
        let updateSpy = SearchUpdateRecentQueriesUseCaseSpy()
        let adapter = SearchStoreTestAdapter(
            recentQueries: ["swift", "tca"],
            updateRecentQueriesUseCase: updateSpy
        )

        await adapter.addRecentQuery(" tca ")

        await waitUntil {
            updateSpy.queries == [["tca", "swift"]]
        }

        #expect(adapter.recentQueries == ["tca", "swift"])
        #expect(updateSpy.queries == [["tca", "swift"]])
    }

    @Test("addRecentQuery는 최대 20개까지만 유지한다")
    func addRecentQuery는_최대_20개까지만_유지한다() async {
        let queries = (0..<20).map { "query-\($0)" }
        let adapter = SearchStoreTestAdapter(recentQueries: queries)

        await adapter.addRecentQuery("latest")

        #expect(adapter.recentQueries.count == 20)
        #expect(adapter.recentQueries.first == "latest")
        #expect(!adapter.recentQueries.contains("query-19"))
    }

    @Test("removeRecentQuery와 clearRecentQueries는 최근 검색어 저장소를 갱신한다")
    func removeRecentQuery와_clearRecentQueries는_최근_검색어_저장소를_갱신한다() async {
        let updateSpy = SearchUpdateRecentQueriesUseCaseSpy()
        let adapter = SearchStoreTestAdapter(
            recentQueries: ["swift", "tca"],
            updateRecentQueriesUseCase: updateSpy
        )

        await adapter.removeRecentQuery("swift")
        await adapter.clearRecentQueries()

        await waitUntil {
            updateSpy.queries == [["tca"], []]
        }

        #expect(adapter.recentQueries.isEmpty)
        #expect(updateSpy.queries == [["tca"], []])
    }

    @Test("setSearchQuery는 표시 범위를 초기화하고 디바운스 후 검색 결과를 반영한다")
    func setSearchQuery는_표시_범위를_초기화하고_디바운스_후_검색_결과를_반영한다() async {
        let todo = makeSearchTodo(id: "todo-1", title: "Swift")
        let todoSpy = SearchFetchTodosUseCaseSpy(page: TodoPage(items: [todo], nextCursor: nil))
        let clock = TestClock()
        let adapter = SearchStoreTestAdapter(
            fetchTodosUseCase: todoSpy,
            configureDependencies: {
                $0.continuousClock = clock
            }
        )

        await adapter.setShowAllTodos(true)
        await adapter.setSearchQuery(" swift ")
        await clock.advance(by: .milliseconds(400))
        await adapter.receiveAppliedSearchQuery("swift")
        await adapter.receiveSearchResults(todos: [TodoListItem(from: todo)!])

        #expect(adapter.searchQuery == " swift ")
        #expect(!adapter.showAllTodos)
        #expect(todoSpy.queries.map(\.keyword) == ["swift"])
        #expect(adapter.todos == [TodoListItem(from: todo)])
        #expect(!adapter.isLoading)
    }

    @Test("빈 검색어는 검색 결과를 비우고 로딩을 종료한다")
    func 빈_검색어는_검색_결과를_비우고_로딩을_종료한다() async {
        let todo = TodoListItem(from: makeSearchTodo(id: "todo-1"))!
        let adapter = SearchStoreTestAdapter(
            initialTodos: [todo],
            isLoading: true
        )

        await adapter.setSearchQuery(" ")

        #expect(adapter.todos.isEmpty)
        #expect(!adapter.isLoading)
    }

    @Test("# 단독 검색어는 안내 상태로 전환하고 조회를 시작하지 않는다")
    func 해시_단독_검색어는_안내_상태로_전환하고_조회를_시작하지_않는다() async {
        let todo = TodoListItem(from: makeSearchTodo(id: "todo-1"))!
        let todoSpy = SearchFetchTodosUseCaseSpy()
        let adapter = SearchStoreTestAdapter(
            initialTodos: [todo],
            isLoading: true,
            fetchTodosUseCase: todoSpy
        )

        await adapter.setSearchQuery("#")

        #expect(adapter.isHashOnlyQuery)
        #expect(adapter.todos.isEmpty)
        #expect(!adapter.isLoading)
        #expect(todoSpy.queries.isEmpty)
    }

    @Test("# 검색어는 Todo 검색 결과를 반영한다")
    func 해시태그_검색어는_Todo_검색_결과를_반영한다() async {
        let todo = makeSearchTodo(id: "todo-1", title: "Issue")
        let todoSpy = SearchFetchTodosUseCaseSpy(page: TodoPage(items: [todo], nextCursor: nil))
        let adapter = SearchStoreTestAdapter(fetchTodosUseCase: todoSpy)

        await adapter.applySearchQuery(" #123 ")
        await adapter.receiveSearchResults(todos: [TodoListItem(from: todo)!])

        #expect(todoSpy.queries.map(\.keyword) == ["#123"])
        #expect(adapter.todos == [TodoListItem(from: todo)])
    }

    @Test("검색 실패 시 공통 에러 알림을 표시하고 로딩을 종료한다")
    func 검색_실패_시_공통_에러_알림을_표시하고_로딩을_종료한다() async {
        let todoSpy = SearchFetchTodosUseCaseSpy()
        todoSpy.error = SearchFeatureTestError.failure
        let adapter = SearchStoreTestAdapter(isLoading: true, fetchTodosUseCase: todoSpy)

        await adapter.applySearchQuery("swift")
        await adapter.receiveSearchFailure()

        #expect(adapter.alert == expectedSearchErrorAlert())
        #expect(!adapter.isLoading)
    }

    @Test("setSearching false는 검색을 취소하고 로딩을 종료한다")
    func setSearching_false는_검색을_취소하고_로딩을_종료한다() async {
        let adapter = SearchStoreTestAdapter(isSearching: true, isLoading: true)

        await adapter.setSearching(false)

        #expect(!adapter.isSearching)
        #expect(!adapter.isLoading)
    }
}
