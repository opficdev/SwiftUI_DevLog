//
//  TodoEditorFeatureTests.swift
//  PresentationSharedTests
//
//  Created by opfic on 6/12/26.
//

import Testing
import Foundation
import Domain
@testable import PresentationShared

@MainActor
struct TodoEditorFeatureTests {
    @Test("새 Todo 작성 상태는 선택한 카테고리로 초기화된다")
    func 새_Todo_작성_상태는_선택한_카테고리로_초기화된다() async {
        let adapter = TodoEditorStoreTestAdapter(category: .system(.doc))

        #expect(adapter.category == TodoCategoryItem(from: .system(.doc)))
        #expect(adapter.categories == [TodoCategoryItem(from: .system(.doc))])
        #expect(adapter.title.isEmpty)
        #expect(adapter.content.isEmpty)
        #expect(adapter.tags.isEmpty)
        #expect(adapter.isReadyToSubmit == false)
    }

    @Test("기존 Todo 편집 상태는 Todo 값으로 초기화되고 변경 여부를 계산한다")
    func 기존_Todo_편집_상태는_Todo_값으로_초기화되고_변경_여부를_계산한다() async {
        let todo = makeTodoEditorTodo(
            id: "todo-1",
            isPinned: true,
            isCompleted: true,
            title: "Original",
            content: "Body",
            completedAt: Date(timeIntervalSince1970: 10),
            dueDate: Date(timeIntervalSince1970: 20),
            tags: ["swift", "tca"],
            category: .system(.issue)
        )
        let adapter = TodoEditorStoreTestAdapter(todo: todo)

        #expect(adapter.isPinned)
        #expect(adapter.isCompleted)
        #expect(adapter.title == "Original")
        #expect(adapter.content == "Body")
        #expect(adapter.completedAt == Date(timeIntervalSince1970: 10))
        #expect(adapter.dueDate == Date(timeIntervalSince1970: 20))
        #expect(adapter.tags == ["swift", "tca"])
        #expect(adapter.category == TodoCategoryItem(from: .system(.issue)))
        #expect(adapter.hasChanges == false)
        #expect(adapter.isReadyToSubmit == false)

        await adapter.setTitle("Changed")

        #expect(adapter.hasChanges)
        #expect(adapter.isReadyToSubmit)
    }

    @Test("마감일을 원본과 같은 날짜로 되돌리면 변경되지 않은 상태가 된다")
    func 마감일을_원본과_같은_날짜로_되돌리면_변경되지_않은_상태가_된다() async throws {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: Date(timeIntervalSince1970: 4_102_444_800))
        let originalDueDate = day.addingTimeInterval(43_200)
        let restoredDueDate = day.addingTimeInterval(3_600)
        let changedDueDate = try #require(calendar.date(byAdding: .day, value: 1, to: originalDueDate))
        let todo = makeTodoEditorTodo(title: "Original", dueDate: originalDueDate)
        let adapter = TodoEditorStoreTestAdapter(todo: todo)

        await adapter.setDueDate(changedDueDate)

        #expect(adapter.hasChanges)
        #expect(adapter.isReadyToSubmit)

        await adapter.setDueDate(restoredDueDate)

        #expect(adapter.hasChanges == false)
        #expect(adapter.isReadyToSubmit == false)
    }

    @Test("onAppear는 Todo 카테고리 설정을 가져와 상태에 반영한다")
    func onAppear는_Todo_카테고리_설정을_가져와_상태에_반영한다() async {
        let fetchSpy = TodoEditorFetchPreferencesUseCaseSpy(preferences: [
            TodoCategoryPreference(category: .system(.doc), isVisible: true),
            TodoCategoryPreference(category: .system(.issue), isVisible: false)
        ])
        let adapter = TodoEditorStoreTestAdapter(
            category: .system(.etc),
            fetchPreferencesUseCase: fetchSpy
        )

        await adapter.onAppear()

        #expect(fetchSpy.executeCallCount == 1)
        #expect(adapter.categories == [
            TodoCategoryItem(from: TodoCategoryPreference(category: .system(.doc), isVisible: true)),
            TodoCategoryItem(from: TodoCategoryPreference(category: .system(.issue), isVisible: false))
        ])
    }

    @Test("숨김 카테고리 Todo도 ID로 선택 상태를 유지한다")
    func 숨김_카테고리_Todo도_ID로_선택_상태를_유지한다() async {
        let visiblePreference = TodoCategoryPreference(category: .system(.doc), isVisible: true)
        let hiddenPreference = TodoCategoryPreference(category: .system(.issue), isVisible: false)
        let adapter = TodoEditorStoreTestAdapter(
            todo: makeTodoEditorTodo(category: .system(.issue)),
            fetchPreferencesUseCase: TodoEditorFetchPreferencesUseCaseSpy(
                preferences: [visiblePreference, hiddenPreference]
            )
        )

        await adapter.onAppear()

        #expect(adapter.selectedCategoryID == TodoCategoryItem(from: hiddenPreference).id)
        #expect(adapter.categories.contains { $0.id == adapter.selectedCategoryID })

        await adapter.setSelectedCategoryID(TodoCategoryItem(from: visiblePreference).id)
        #expect(adapter.category == TodoCategoryItem(from: visiblePreference))

        await adapter.setSelectedCategoryID(TodoCategoryItem(from: hiddenPreference).id)
        #expect(adapter.category == TodoCategoryItem(from: hiddenPreference))

        await adapter.setSelectedCategoryID("missing-category")
        #expect(adapter.category == TodoCategoryItem(from: hiddenPreference))
    }

    @Test("태그 추가와 삭제는 OrderedSet 상태를 변경한다")
    func 태그_추가와_삭제는_OrderedSet_상태를_변경한다() async {
        let adapter = TodoEditorStoreTestAdapter(category: .system(.doc))

        await adapter.addTag("swift")
        await adapter.addTag("tca")
        await adapter.addTag("swift")
        await adapter.removeTag("swift")

        #expect(adapter.tags == ["tca"])
    }

    @Test("완료 상태가 바뀔 때 completedAt을 함께 갱신한다")
    func 완료_상태가_바뀔_때_completedAt을_함께_갱신한다() async {
        let adapter = TodoEditorStoreTestAdapter(category: .system(.doc))

        await adapter.setCompleted(true)

        #expect(adapter.isCompleted)
        #expect(adapter.completedAt == todoEditorNow)

        await adapter.setCompleted(false)

        #expect(adapter.isCompleted == false)
        #expect(adapter.completedAt == nil)
    }

    @Test("미래 마감일은 그대로 반영하고 nil 입력은 마감일을 제거한다")
    func 미래_마감일은_그대로_반영하고_nil_입력은_마감일을_제거한다() async {
        let adapter = TodoEditorStoreTestAdapter(category: .system(.doc))
        let dueDate = Date(timeIntervalSince1970: 4_102_444_800)

        await adapter.setDueDate(dueDate)

        #expect(adapter.dueDate == dueDate)

        await adapter.setDueDate(nil)

        #expect(adapter.dueDate == nil)
    }

    @Test("미리보기 전환은 본문의 참조 Todo를 해석해 상태에 반영한다")
    func 미리보기_전환은_본문의_참조_Todo를_해석해_상태에_반영한다() async {
        let reference3 = makeTodoEditorReference(id: "todo-3", title: "Reference 3")
        let reference5 = makeTodoEditorReference(id: "todo-5", title: "Reference 5")
        let referenceSpy = TodoEditorFetchReferenceItemsUseCaseSpy(references: [
            3: reference3,
            5: reference5
        ])
        let adapter = TodoEditorStoreTestAdapter(
            category: .system(.doc),
            fetchReferenceItemsUseCase: referenceSpy
        )

        await adapter.setContent("""
        body
        - refs #3
        - refs #5
        - refs #3
        """)
        await adapter.setTab(.preview)

        #expect(referenceSpy.numbers == [[3, 5]])
        #expect(adapter.referenceItems[3] == TodoReferenceItem(from: reference3))
        #expect(adapter.referenceItems[5] == TodoReferenceItem(from: reference5))
    }

    @Test("하나의 inspector에서 옵션과 참조 Todo를 전환한다")
    func 하나의_inspector에서_옵션과_참조_Todo를_전환한다() async {
        let adapter = TodoEditorStoreTestAdapter(category: .system(.doc))
        let item = TodoIdItem(id: "todo-2")

        await adapter.showInspector(.options)

        #expect(adapter.isInspectorPresented)
        #expect(adapter.inspectorContent == .options)

        await adapter.showInspector(.todo(item))

        #expect(adapter.inspectorContent == .todo(item))
        #expect(adapter.isInspectorPresented)

        await adapter.showInspector(.options)

        #expect(adapter.inspectorContent == .options)
        #expect(adapter.isInspectorPresented)

        await adapter.setInspectorPresented(false)

        #expect(!adapter.isInspectorPresented)
        await adapter.showInspector(.todo(item))

        #expect(adapter.inspectorContent == .todo(item))
        #expect(adapter.isInspectorPresented)
    }

    @Test("새 Todo 저장 성공은 draft를 저장하고 생성 delegate를 전송한다")
    func 새_Todo_저장_성공은_draft를_저장하고_생성_delegate를_전송한다() async {
        let upsertSpy = TodoEditorUpsertTodoUseCaseSpy()
        upsertSpy.shouldSuspend = true
        let adapter = TodoEditorStoreTestAdapter(
            category: .system(.doc),
            upsertTodoUseCase: upsertSpy
        )
        let dueDate = Date(timeIntervalSince1970: 4_102_444_800)

        await adapter.setTitle("Title")
        await adapter.setContent("Content")
        await adapter.setPinned(true)
        await adapter.setDueDate(dueDate)
        await adapter.addTag("swift")
        await adapter.upsertTodo()

        #expect(adapter.isLoading)
        #expect(upsertSpy.todoDrafts.first?.title == "Title")
        #expect(upsertSpy.todoDrafts.first?.content == "Content")
        #expect(upsertSpy.todoDrafts.first?.isPinned == true)
        #expect(upsertSpy.todoDrafts.first?.dueDate == dueDate)
        #expect(upsertSpy.todoDrafts.first?.tags == ["swift"])
        #expect(upsertSpy.todoDrafts.first?.category == .system(.doc))

        upsertSpy.resume()
        await adapter.receiveCreateSucceeded()
        await adapter.receiveCreatedDelegate()
        await adapter.drainReceivedActions()

        #expect(adapter.saveResult == .created)
        #expect(adapter.isLoading == false)
    }

    @Test("기존 Todo 저장 성공은 수정 Todo를 저장하고 수정 delegate를 전송한다")
    func 기존_Todo_저장_성공은_수정_Todo를_저장하고_수정_delegate를_전송한다() async throws {
        let upsertSpy = TodoEditorUpsertTodoUseCaseSpy()
        upsertSpy.shouldSuspend = true
        let todo = makeTodoEditorTodo(
            id: "todo-1",
            number: 7,
            title: "Original",
            content: "Body",
            createdAt: Date(timeIntervalSince1970: 10),
            category: .system(.issue)
        )
        let adapter = TodoEditorStoreTestAdapter(todo: todo, upsertTodoUseCase: upsertSpy)

        await adapter.setTitle("Changed")
        await adapter.setContent("Changed body")
        await adapter.upsertTodo()

        let updated = try #require(upsertSpy.todos.first)

        upsertSpy.resume()
        await adapter.receiveUpdateSucceeded(updated)
        await adapter.receiveUpdatedDelegate(updated)
        await adapter.drainReceivedActions()

        #expect(updated.id == "todo-1")
        #expect(updated.number == 7)
        #expect(updated.title == "Changed")
        #expect(updated.content == "Changed body")
        #expect(updated.createdAt == Date(timeIntervalSince1970: 10))
        #expect(updated.updatedAt == todoEditorNow)
        #expect(updated.category == .system(.issue))
        #expect(adapter.saveResult == .updated(updated))
    }

    @Test("저장 실패는 공통 에러 알림을 표시하고 로딩을 해제한다")
    func 저장_실패는_공통_에러_알림을_표시하고_로딩을_해제한다() async {
        let upsertSpy = TodoEditorUpsertTodoUseCaseSpy()
        upsertSpy.error = TodoEditorTestError.failure
        let adapter = TodoEditorStoreTestAdapter(
            category: .system(.doc),
            upsertTodoUseCase: upsertSpy
        )

        await adapter.setTitle("Title")
        await adapter.upsertTodo()
        await adapter.drainReceivedActions()

        #expect(adapter.hasErrorAlert)
        #expect(adapter.isLoading == false)
        #expect(adapter.saveResult == nil)
    }
}
