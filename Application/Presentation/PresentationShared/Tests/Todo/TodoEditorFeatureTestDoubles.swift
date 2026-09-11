//
//  TodoEditorFeatureTestDoubles.swift
//  PresentationSharedTests
//
//  Created by opfic on 6/12/26.
//

import Testing
import Foundation
import Domain
@testable import PresentationShared

let todoEditorNow = Date(timeIntervalSince1970: 1_000)

@MainActor
final class TodoEditorStoreTestAdapter {
    private let store: TestStoreOf<TodoEditorFeature>
    private let now: Date

    var isCompleted: Bool { store.state.isCompleted }
    var completedAt: Date? { store.state.completedAt }
    var isPinned: Bool { store.state.isPinned }
    var title: String { store.state.title }
    var content: String { store.state.content }
    var referenceItems: [Int: TodoReferenceItem] { store.state.referenceItems }
    var dueDate: Date? { store.state.dueDate }
    var inspectorContent: TodoEditorFeature.InspectorContent { store.state.inspectorContent }
    var isInspectorPresented: Bool { store.state.isInspectorPresented }
    var isLoading: Bool { store.state.isLoading }
    var tags: [String] { Array(store.state.tags) }
    var categories: [TodoCategoryItem] { store.state.categories }
    var category: TodoCategoryItem { store.state.category }
    var hasChanges: Bool { store.state.hasChanges }
    var isReadyToSubmit: Bool { store.state.isReadyToSubmit }
    var saveResult: TodoEditorFeature.SaveResult? { store.state.saveResult }
    var hasErrorAlert: Bool { store.state.alert == expectedTodoEditorErrorAlert() }

    init(
        category: TodoCategory,
        now: Date = todoEditorNow,
        fetchPreferencesUseCase: FetchTodoCategoryPreferencesUseCase = TodoEditorFetchPreferencesUseCaseSpy(),
        fetchReferenceItemsUseCase: FetchReferenceItemsUseCase = TodoEditorFetchReferenceItemsUseCaseSpy(),
        upsertTodoUseCase: UpsertTodoUseCase = TodoEditorUpsertTodoUseCaseSpy()
    ) {
        self.now = now
        store = TestStore(
            initialState: TodoEditorFeature.State(category: category, id: "todo-draft-id")
        ) {
            TodoEditorFeature()
        } withDependencies: {
            $0.date.now = now
            $0.fetchTodoCategoryPreferencesUseCase = fetchPreferencesUseCase
            $0.fetchReferenceItemsUseCase = fetchReferenceItemsUseCase
            $0.upsertTodoUseCase = upsertTodoUseCase
        }
        store.exhaustivity = .off(showSkippedAssertions: false)
    }

    init(
        todo: Todo,
        now: Date = todoEditorNow,
        fetchPreferencesUseCase: FetchTodoCategoryPreferencesUseCase = TodoEditorFetchPreferencesUseCaseSpy(),
        fetchReferenceItemsUseCase: FetchReferenceItemsUseCase = TodoEditorFetchReferenceItemsUseCaseSpy(),
        upsertTodoUseCase: UpsertTodoUseCase = TodoEditorUpsertTodoUseCaseSpy()
    ) {
        self.now = now
        store = TestStore(initialState: TodoEditorFeature.State(todo: todo)) {
            TodoEditorFeature()
        } withDependencies: {
            $0.date.now = now
            $0.fetchTodoCategoryPreferencesUseCase = fetchPreferencesUseCase
            $0.fetchReferenceItemsUseCase = fetchReferenceItemsUseCase
            $0.upsertTodoUseCase = upsertTodoUseCase
        }
        store.exhaustivity = .off(showSkippedAssertions: false)
    }

    func onAppear() async {
        await store.send(.onAppear)
        await drainReceivedActions()
    }

    func addTag(_ tag: String) async {
        await store.send(.addTag(tag)) {
            if !tag.isEmpty {
                $0.tags.append(tag)
            }
        }
    }

    func removeTag(_ tag: String) async {
        await store.send(.removeTag(tag)) {
            $0.tags.removeAll { $0 == tag }
        }
    }

    func setContent(_ content: String) async {
        await store.send(.binding(.set(\.content, content))) {
            $0.content = content
        }
        await drainReceivedActions()
    }

    func setCompleted(_ isCompleted: Bool) async {
        let shouldUpdateDate = store.state.isCompleted != isCompleted
        await store.send(.setCompleted(isCompleted)) {
            if shouldUpdateDate {
                $0.completedAt = isCompleted ? self.now : nil
            }
            $0.isCompleted = isCompleted
        }
    }

    func showInspector(_ content: TodoEditorFeature.InspectorContent) async {
        await store.send(.showInspector(content)) {
            $0.inspectorContent = content
            $0.isInspectorPresented = true
        }
    }

    func setInspectorPresented(_ isPresented: Bool) async {
        await store.send(.binding(.set(\.isInspectorPresented, isPresented))) {
            $0.isInspectorPresented = isPresented
        }
    }

    func setDueDate(_ dueDate: Date?) async {
        let expectedDueDate = expectedDueDate(for: dueDate)
        await store.send(.binding(.set(\.dueDate, dueDate))) {
            $0.dueDate = expectedDueDate
        }
    }

    func setPinned(_ isPinned: Bool) async {
        await store.send(.binding(.set(\.isPinned, isPinned))) {
            $0.isPinned = isPinned
        }
    }

    func setTab(_ tab: TodoEditorFeature.EditorTab) async {
        await store.send(.binding(.set(\.tabViewTag, tab))) {
            $0.tabViewTag = tab
        }
        await drainReceivedActions()
    }

    func setTitle(_ title: String) async {
        await store.send(.binding(.set(\.title, title))) {
            $0.title = title
        }
        await drainReceivedActions()
    }

    func upsertTodo() async {
        await store.send(.upsertTodo) {
            $0.saveResult = nil
        }
        await receiveBeginLoading()
    }

    func receiveCreateSucceeded() async {
        await store.receive(.createSucceeded) {
            $0.saveResult = .created
        }
    }

    func receiveCreatedDelegate() async {
        await store.receive(.delegate(.created))
    }

    func receiveUpdateSucceeded(_ todo: Todo) async {
        await store.receive(.updateSucceeded(todo)) {
            $0.saveResult = .updated(todo)
        }
    }

    func receiveUpdatedDelegate(_ todo: Todo) async {
        await store.receive(.delegate(.updated(todo)))
    }

    func drainReceivedActions() async {
        await store.skipReceivedActions(strict: false)
        await store.skipReceivedActions(strict: false)
        await store.skipReceivedActions(strict: false)
    }

    private func expectedDueDate(for dueDate: Date?) -> Date? {
        guard let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: now),
              let dueDate else {
            return nil
        }

        return max(dueDate, tomorrowDate)
    }

    private func receiveBeginLoading() async {
        await store.receive(.loading(.begin(target: .default, mode: .immediate))) {
            $0.loading.setImmediateLoading()
        }
    }
}

private extension LoadingFeature.State {
    mutating func setImmediateLoading() {
        let target = LoadingFeature.Target.default
        immediateCountByTarget[target] = 1
        visibleTargets.insert(target)
        isLoading = !visibleTargets.isEmpty
    }
}

final class TodoEditorFetchPreferencesUseCaseSpy: FetchTodoCategoryPreferencesUseCase {
    var preferences: [TodoCategoryPreference]
    private(set) var executeCallCount = 0

    init(preferences: [TodoCategoryPreference] = []) {
        self.preferences = preferences
    }

    func execute() async throws -> [TodoCategoryPreference] {
        executeCallCount += 1
        return preferences
    }
}

final class TodoEditorFetchReferenceItemsUseCaseSpy: FetchReferenceItemsUseCase {
    var references: [Int: TodoReference]
    var error: Error?
    private(set) var numbers: [[Int]] = []

    init(references: [Int: TodoReference] = [:]) {
        self.references = references
    }

    func execute(_ numbers: [Int]) async throws -> [Int: TodoReference] {
        self.numbers.append(numbers)

        if let error {
            throw error
        }

        return references
    }
}

final class TodoEditorUpsertTodoUseCaseSpy: UpsertTodoUseCase {
    var error: Error?
    var shouldSuspend = false
    private(set) var todos: [Todo] = []
    private(set) var todoDrafts: [TodoDraft] = []
    private var continuation: CheckedContinuation<Void, Never>?
    private var shouldResume = false

    func execute(_ todo: Todo) async throws {
        todos.append(todo)
        await suspendIfNeeded()

        if let error {
            throw error
        }
    }

    func execute(_ draft: TodoDraft) async throws {
        todoDrafts.append(draft)
        await suspendIfNeeded()

        if let error {
            throw error
        }
    }

    func resume() {
        guard let continuation else {
            shouldResume = true
            return
        }

        self.continuation = nil
        continuation.resume()
    }

    private func suspendIfNeeded() async {
        guard shouldSuspend else { return }

        await withCheckedContinuation { continuation in
            if shouldResume {
                shouldResume = false
                continuation.resume()
            } else {
                self.continuation = continuation
            }
        }
    }
}

enum TodoEditorTestError: Error {
    case failure
}

func expectedTodoEditorErrorAlert() -> AlertState<Never> {
    AlertState {
        TextState(String(localized: "common_error_title", bundle: PresentationResources.bundle))
    } actions: {
        ButtonState(role: .cancel) {
            TextState(String(localized: "common_close", bundle: PresentationResources.bundle))
        }
    } message: {
        TextState(String(localized: "common_error_message", bundle: PresentationResources.bundle))
    }
}

func makeTodoEditorTodo(
    id: String = "todo-1",
    isPinned: Bool = false,
    isCompleted: Bool = false,
    isChecked: Bool = false,
    number: Int = 1,
    title: String = "Todo",
    content: String = "content",
    createdAt: Date = Date(timeIntervalSince1970: 0),
    updatedAt: Date = Date(timeIntervalSince1970: 0),
    completedAt: Date? = nil,
    deletedAt: Date? = nil,
    dueDate: Date? = nil,
    tags: [String] = [],
    category: TodoCategory = .system(.doc)
) -> Todo {
    Todo(
        id: id,
        isPinned: isPinned,
        isCompleted: isCompleted,
        isChecked: isChecked,
        number: number,
        title: title,
        content: content,
        createdAt: createdAt,
        updatedAt: updatedAt,
        completedAt: completedAt,
        deletedAt: deletedAt,
        dueDate: dueDate,
        tags: tags,
        category: category
    )
}

func makeTodoEditorReference(
    id: String,
    title: String = "Reference"
) -> TodoReference {
    TodoReference(
        id: id,
        title: title,
        category: .system(.issue)
    )
}
