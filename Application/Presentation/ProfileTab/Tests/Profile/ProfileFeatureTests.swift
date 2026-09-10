//
//  ProfileFeatureTests.swift
//  ProfileTabTests
//
//  Created by opfic on 6/11/26.
//

import Testing
import Combine
import PresentationShared
import Foundation
import Core
import Domain
@testable import ProfileTab

@MainActor
struct ProfileFeatureTests {
    @Test("ProfileFeature는 최근 수정한 Todo를 최대 5개까지 카테고리 설정과 함께 갱신한다")
    func ProfileFeature는_최근_수정한_Todo를_최대_5개까지_카테고리_설정과_함께_갱신한다() async {
        let category = TodoCategory.user(
            UserTodoCategory(id: "custom", name: "Before", colorHex: "#111111")
        )
        let updatedCategory = TodoCategory.user(
            UserTodoCategory(id: "custom", name: "After", colorHex: "#222222")
        )
        let fetchSpy = FetchTodosUseCaseSpy()
        let unchangedDate = Date(timeIntervalSince1970: 0)
        fetchSpy.todoPage = TodoPage(
            items: [
                makeProfileTodo(id: "unchanged", createdAt: unchangedDate, updatedAt: unchangedDate),
                makeProfileTodo(id: "todo-1", category: category),
                makeProfileTodo(id: "todo-2"),
                makeProfileTodo(id: "todo-3"),
                makeProfileTodo(id: "todo-4"),
                makeProfileTodo(id: "todo-5"),
                makeProfileTodo(id: "todo-6")
            ],
            nextCursor: nil
        )
        let preferencesSpy = FetchTodoCategoryPreferencesUseCaseSpy()
        preferencesSpy.preferences = [
            TodoCategoryPreference(category: updatedCategory, isVisible: true)
        ]
        let adapter = ProfileStoreTestAdapter(
            fetchTodosUseCase: fetchSpy,
            fetchPreferencesUseCase: preferencesSpy
        )

        await adapter.refreshRecentTodos()

        #expect(adapter.recentTodos.map(\.id) == ["todo-1", "todo-2", "todo-3", "todo-4", "todo-5"])
        #expect(adapter.recentTodos.first?.category == updatedCategory)
        #expect(fetchSpy.queries.count == 1)
        #expect(fetchSpy.queries.first?.sortTarget == .updatedAt)
        #expect(fetchSpy.queries.first?.sortOrder == .latest)
        #expect(fetchSpy.queries.first?.pageSize == 100)
    }

    @Test("ProfileFeature는 카테고리 설정 조회가 실패해도 최근 Todo를 갱신한다")
    func ProfileFeature는_카테고리_설정_조회가_실패해도_최근_Todo를_갱신한다() async {
        let fetchSpy = FetchTodosUseCaseSpy()
        fetchSpy.todoPage = TodoPage(
            items: [makeProfileTodo(id: "todo")],
            nextCursor: nil
        )
        let preferencesSpy = FetchTodoCategoryPreferencesUseCaseSpy()
        preferencesSpy.error = TestError()
        let adapter = ProfileStoreTestAdapter(
            fetchTodosUseCase: fetchSpy,
            fetchPreferencesUseCase: preferencesSpy
        )

        await adapter.refreshRecentTodos()

        #expect(adapter.recentTodos.map(\.id) == ["todo"])
        #expect(adapter.isAlertPresented)
    }

    @Test("ProfileFeature는 Todo 변경 시 최근 목록만 다시 조회한다")
    func ProfileFeature는_Todo_변경_시_최근_목록만_다시_조회한다() async {
        let fetchSpy = FetchTodosUseCaseSpy()
        let eventBus = TodoMutationEventBusSpy()
        let adapter = ProfileStoreTestAdapter(
            fetchTodosUseCase: fetchSpy,
            todoMutationEventBus: eventBus
        )

        await adapter.startObserving()
        await adapter.publishTodoMutation(.updated("todo"))

        #expect(fetchSpy.queries.count == 1)
        #expect(fetchSpy.queries.first?.sortTarget == .updatedAt)
    }

    @Test("ProfileFeature는 최근 Todo 로딩을 전체 화면 로딩에서 제외한다")
    func ProfileFeature는_최근_Todo_로딩을_전체_화면_로딩에서_제외한다() async {
        let adapter = ProfileStoreTestAdapter()

        await adapter.beginRecentTodosLoading()

        #expect(adapter.isRecentTodosLoading)
        #expect(!adapter.isLoading)
    }

    @Test("ProfileFeature는 같은 아바타 URL을 다시 받아도 프로필 이미지 데이터를 다시 요청한다")
    func ProfileFeature는_같은_아바타_URL을_다시_받아도_프로필_이미지_데이터를_다시_요청한다() async {
        let imageData = Data([1, 2, 3])
        let spy = FetchProfileImageDataUseCaseSpy(data: imageData)
        let adapter = ProfileStoreTestAdapter(fetchProfileImageDataUseCase: spy)
        let avatarURL = URL(string: "https://example.com/avatar.png")!
        let profile = UserProfile(
            name: "opfic",
            email: "opfic@example.com",
            statusMessage: "status",
            avatarURL: avatarURL,
            createdAt: Date(timeIntervalSince1970: 0)
        )

        await adapter.fetchUserData(profile)
        await adapter.fetchUserData(profile)

        #expect(spy.calledURLs == [avatarURL, avatarURL])
        #expect(adapter.avatarImageData?.data == imageData)
    }

    @Test("ProfileFeature는 연결 상태일 때 상태 메시지 저장을 요청한다")
    func ProfileFeature는_연결_상태일_때_상태_메시지_저장을_요청한다() async {
        let spy = UpsertStatusMessageUseCaseSpy()
        let adapter = ProfileStoreTestAdapter(upsertStatusMessageUseCase: spy)

        await adapter.updateStatusMessage("working")
        await adapter.willUpdateStatusMessage()

        #expect(spy.messages == ["working"])
    }

    @Test("ProfileFeature는 마지막 활동 종류를 해제하지 않는다")
    func ProfileFeature는_마지막_활동_종류를_해제하지_않는다() async {
        let spy = UpdateHeatmapActivityTypesUseCaseSpy()
        let fetchSpy = FetchHeatmapActivityTypesUseCaseSpy()
        fetchSpy.activityTypes = ["created"]
        let adapter = ProfileStoreTestAdapter(
            fetchHeatmapActivityTypesUseCase: fetchSpy,
            updateHeatmapActivityTypesUseCase: spy
        )

        await adapter.fetchData()
        await adapter.toggleActivityKind(.created)

        #expect(adapter.selectedActivityKinds == [.created])
        #expect(spy.activityTypes.isEmpty)
    }
}

private final class FetchTodosUseCaseSpy: FetchTodosUseCase {
    var todoPage = TodoPage(items: [], nextCursor: nil)
    private(set) var queries: [TodoQuery] = []

    func execute(_ query: TodoQuery, cursor: TodoCursor?) async throws -> TodoPage {
        queries.append(query)
        return todoPage
    }
}

private final class FetchTodoCategoryPreferencesUseCaseSpy: FetchTodoCategoryPreferencesUseCase {
    var error: Error?
    var preferences = [TodoCategoryPreference]()

    func execute() async throws -> [TodoCategoryPreference] {
        if let error {
            throw error
        }
        return preferences
    }
}

private final class TodoMutationEventBusSpy: TodoMutationEventBus {
    private let subject = PassthroughSubject<TodoMutationEvent, Never>()

    func publish(_ event: TodoMutationEvent) {
        subject.send(event)
    }

    func observe() -> AnyPublisher<TodoMutationEvent, Never> {
        subject.eraseToAnyPublisher()
    }
}

private final class FetchUserDataUseCaseSpy: FetchUserDataUseCase {
    var profile: UserProfile

    init(profile: UserProfile) {
        self.profile = profile
    }

    func execute() async throws -> UserProfile {
        profile
    }
}

private final class FetchProfileImageDataUseCaseSpy: FetchProfileImageDataUseCase {
    var data: Data
    private(set) var calledURLs: [URL] = []

    init(data: Data) {
        self.data = data
    }

    func execute(from url: URL) async throws -> Data {
        calledURLs.append(url)
        return data
    }
}

private final class UpsertStatusMessageUseCaseSpy: UpsertStatusMessageUseCase {
    private(set) var messages: [String] = []

    func execute(_ message: String) async throws {
        messages.append(message)
    }
}

private final class FetchHeatmapActivityTypesUseCaseSpy: FetchHeatmapActivityTypesUseCase {
    var activityTypes: [String] = []

    func execute() -> [String] {
        activityTypes
    }
}

private final class UpdateHeatmapActivityTypesUseCaseSpy: UpdateHeatmapActivityTypesUseCase {
    private(set) var activityTypes: [[String]] = []

    func execute(_ activityTypes: [String]) {
        self.activityTypes.append(activityTypes)
    }
}

@MainActor
private struct ProfileStoreTestAdapter {
    private let store: TestStoreOf<ProfileFeature>
    private let todoMutationEventBus: TodoMutationEventBus

    var avatarImageData: ProfileAvatarImageData? { store.state.avatarImageData }
    var isAlertPresented: Bool { store.state.alert != nil }
    var isLoading: Bool { store.state.isLoading }
    var isRecentTodosLoading: Bool { store.state.isRecentTodosLoading }
    var recentTodos: [RecentTodoItem] { store.state.recentTodos }
    var selectedActivityKinds: Set<ActivityKind> { store.state.selectedActivityKinds }

    init(
        fetchProfileImageDataUseCase: FetchProfileImageDataUseCase = FetchProfileImageDataUseCaseSpy(data: Data()),
        fetchTodosUseCase: FetchTodosUseCase = FetchTodosUseCaseSpy(),
        fetchPreferencesUseCase: FetchTodoCategoryPreferencesUseCase = FetchTodoCategoryPreferencesUseCaseSpy(),
        todoMutationEventBus: TodoMutationEventBus = TodoMutationEventBusSpy(),
        upsertStatusMessageUseCase: UpsertStatusMessageUseCase = UpsertStatusMessageUseCaseSpy(),
        fetchHeatmapActivityTypesUseCase: FetchHeatmapActivityTypesUseCase = FetchHeatmapActivityTypesUseCaseSpy(),
        updateHeatmapActivityTypesUseCase: UpdateHeatmapActivityTypesUseCase = UpdateHeatmapActivityTypesUseCaseSpy()
    ) {
        self.todoMutationEventBus = todoMutationEventBus
        store = TestStore(initialState: ProfileFeature.State()) {
            ProfileFeature()
        } withDependencies: {
            $0.profileFetchUserDataUseCase = FetchUserDataUseCaseSpy(
                profile: UserProfile(
                    name: "opfic",
                    email: "opfic@example.com",
                    statusMessage: "",
                    avatarURL: nil,
                    createdAt: Date(timeIntervalSince1970: 0)
                )
            )
            $0.profileFetchImageDataUseCase = fetchProfileImageDataUseCase
            $0.profileFetchTodosUseCase = fetchTodosUseCase
            $0.fetchTodoCategoryPreferencesUseCase = fetchPreferencesUseCase
            $0.profileTodoMutationEventBus = todoMutationEventBus
            $0.profileUpsertStatusMessageUseCase = upsertStatusMessageUseCase
            $0.profileNetworkConnectivityUseCase = ObserveNetworkConnectivityUseCaseSpy()
            $0.profileFetchHeatmapActivityTypesUseCase = fetchHeatmapActivityTypesUseCase
            $0.profileUpdateHeatmapActivityTypesUseCase = updateHeatmapActivityTypesUseCase
            $0.continuousClock = ImmediateClock()
        }
        store.exhaustivity = .off(showSkippedAssertions: false)
    }

    func fetchData() async {
        await store.send(.fetchData)
        await drainReceivedActions()
    }

    func startObserving() async {
        await store.send(.startObserving)
        await Task.yield()
    }

    func refreshRecentTodos() async {
        await store.send(.refreshRecentTodos)
        await drainReceivedActions()
    }

    func publishTodoMutation(_ event: TodoMutationEvent) async {
        todoMutationEventBus.publish(event)
        await drainReceivedActions()
    }

    func beginRecentTodosLoading() async {
        await store.send(
            .loading(
                .begin(
                    target: ProfileFeature.LoadingTarget.recentTodos.target,
                    mode: .immediate
                )
            )
        )
        await drainReceivedActions()
    }

    func fetchUserData(_ profile: UserProfile) async {
        await store.send(.store(.fetchUserData(profile)))
        await drainReceivedActions()
    }

    func updateStatusMessage(_ message: String) async {
        await store.send(.binding(.set(\.statusMessage, message))) {
            $0.statusMessage = message
        }
    }

    func willUpdateStatusMessage() async {
        await store.send(.willUpdateStatusMessage)
        await drainReceivedActions()
    }

    func toggleActivityKind(_ activityKind: ActivityKind) async {
        switch activityKind {
        case .created:
            await store.send(.binding(.set(\.isCreatedActivitySelected, !store.state.isCreatedActivitySelected))) {
                $0.isCreatedActivitySelected.toggle()
            }
        case .completed:
            await store.send(.binding(.set(\.isCompletedActivitySelected, !store.state.isCompletedActivitySelected))) {
                $0.isCompletedActivitySelected.toggle()
            }
        case .deleted:
            await store.send(.binding(.set(\.isDeletedActivitySelected, !store.state.isDeletedActivitySelected))) {
                $0.isDeletedActivitySelected.toggle()
            }
        }
        await drainReceivedActions()
    }

    private func drainReceivedActions() async {
        for _ in 0..<10 {
            await store.skipReceivedActions(strict: false)
        }
    }
}

private func makeProfileTodo(
    id: String,
    category: TodoCategory = .system(.feature),
    createdAt: Date = Date(timeIntervalSince1970: 0),
    updatedAt: Date = Date(timeIntervalSince1970: 10)
) -> Todo {
    Todo(
        id: id,
        isPinned: false,
        isCompleted: false,
        isChecked: false,
        number: 1,
        title: "Todo",
        content: "content",
        createdAt: createdAt,
        updatedAt: updatedAt,
        completedAt: nil,
        deletedAt: nil,
        dueDate: nil,
        tags: [],
        category: category
    )
}

private struct TestError: Error { }
