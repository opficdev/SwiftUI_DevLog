//
//  TodoDetailView.swift
//  PresentationShared
//
//  Created by opfic on 6/12/25.
//

import SwiftUI
import Combine
import ComposableArchitecture
import Core
import Domain

public struct TodoDetailView: View {
    @Environment(\.isTabContentActive) private var isTabContentActive
    @Environment(\.openWindow) private var openWindow
    @Environment(\.isiOSAppOnMac) private var isiOSAppOnMac
    @State var store: StoreOf<TodoDetailFeature>
    private let windowEvent: TodoEditorWindowEvent?

    public init(
        store: StoreOf<TodoDetailFeature>,
        windowEvent: TodoEditorWindowEvent? = nil
    ) {
        self.store = store
        self.windowEvent = windowEvent
    }

    public var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            if let todo = store.todo {
                TodoDetailContentView(
                    title: todo.title,
                    content: todo.content,
                    referenceItems: store.referenceItems,
                    number: todo.number,
                    onOpenTodoID: { store.send(.setSheet(.todo(TodoIdItem(id: $0)))) }
                )
            } else if store.isLoading {
                LoadingView()
            }
        }
        .onAppear { store.send(.onAppear) }
        .onReceive(windowSubmits) { submit in
            guard case .update(let value, let todo) = submit,
                  value.matchesEdit(todoId: store.todoId) else { return }
            store.send(.setTodo(todo))
        }
        .navigationBarTitleDisplayMode(.inline)
        .prominentAlert(store, state: \.alert, action: \.alert)
        .sheet(
            item: $store.scope(state: \.sheet, action: \.sheet)
                .activePresentation(when: isTabContentActive)
        ) { store in
            sheetContent(store)
        }
        .fullScreenCover(
            item: $store.scope(state: \.fullScreenCover, action: \.fullScreenCover)
                .activePresentation(when: isTabContentActive)
        ) { store in
            fullScreenCoverContent(store)
        }
        .toolbar { toolbarContent }
    }

    private var windowSubmits: AnyPublisher<TodoEditorWindowSubmit, Never> {
        windowEvent?.submits ?? Empty().eraseToAnyPublisher()
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                store.send(.setSheet(.info))
            } label: {
                Image(systemName: "info.circle")
            }
        }
        if store.showEditButton {
            if #available(iOS 26.0, *) {
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    openTodoEditor()
                } label: {
                    Text(String(localized: "todo_edit", bundle: PresentationResources.bundle))
                }
            }
        }
    }

    private func openTodoEditor() {
        if isiOSAppOnMac {
            guard let todo = store.todo else { return }
            openWindow(
                id: TodoEditorWindowValue.sceneId,
                value: TodoEditorWindowValue(todo: todo)
            )
        } else {
            store.send(.setFullScreenCover(.editor))
        }
    }

    @ViewBuilder
    private func fullScreenCoverContent(
        _ coverStore: Store<TodoDetailFeature.FullScreenCoverState, TodoDetailFeature.Action.FullScreenCover>
    ) -> some View {
        switch coverStore.destination {
        case .editor:
            if let todoEditorStore = coverStore.scope(state: \.todoEditor, action: \.todoEditor) {
                TodoEditorView(store: todoEditorStore)
            }
        }
    }

    @ViewBuilder
    private func sheetContent(
        _ sheetStore: Store<TodoDetailFeature.SheetState, TodoDetailFeature.Action.Sheet>
    ) -> some View {
        switch sheetStore.state {
        case .info:
            if let todo = store.todo {
                TodoDetailInfoSheetView(todo: todo) {
                    sheetStore.send(.tapCloseButton)
                }
            }
        case .todo:
            NavigationStack {
                if let todoStore = sheetStore.scope(state: \.todoDetail, action: \.todo) {
                    TodoDetailView(store: todoStore)
                        .toolbar {
                            ToolbarLeadingButton {
                                sheetStore.send(.tapCloseButton)
                            }
                        }
                }
            }
            .background(Color(.systemGroupedBackground))
            .presentationDragIndicator(.visible)
        }
    }
}

private struct TodoDetailInfoSheetView: View {
    let todo: Todo
    let onClose: () -> Void
    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            List {
                Section(String(localized: "todo_options_section", bundle: PresentationResources.bundle)) {
                    HStack {
                        Text(String(localized: "todo_category", bundle: PresentationResources.bundle))
                        Spacer()
                        Text(TodoCategoryItem(from: todo.category).localizedName)
                            .foregroundStyle(.secondary)
                    }

                    statusRow(
                        title: String(localized: "todo_completed", bundle: PresentationResources.bundle),
                        systemImage: todo.isCompleted ? "checkmark.circle.fill" : "circle",
                        color: todo.isCompleted ? .green : .secondary
                    )

                    statusRow(
                        title: String(localized: "todo_pinned", bundle: PresentationResources.bundle),
                        systemImage: todo.isPinned ? "star.fill" : "star",
                        color: todo.isPinned ? .orange : .secondary
                    )

                    HStack {
                        Text(String(localized: "todo_due_date", bundle: PresentationResources.bundle))

                        Spacer()

                        if let dueDate = todo.dueDate {
                            Tag(dueDateText(for: dueDate), isEditing: false)
                                .padding(.vertical, -4)
                        } else {
                            Text(String(localized: "todo_none", bundle: PresentationResources.bundle))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section(String(localized: "todo_tags", bundle: PresentationResources.bundle)) {
                    if todo.tags.isEmpty {
                        Text(String(localized: "todo_no_tags", bundle: PresentationResources.bundle))
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 4)
                    } else {
                        TagList(todo.tags)
                    }
                }
            }
            .navigationTitle(String(localized: "todo_details", bundle: PresentationResources.bundle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarLeadingButton {
                    onClose()
                }
            }
        }
    }

    @ViewBuilder
    private func statusRow(
        title: String,
        systemImage: String,
        color: Color
    ) -> some View {
        HStack {
            Text(title)

            Spacer()

            Image(systemName: systemImage)
                .foregroundStyle(color)
        }
    }

    private func dueDateText(for dueDate: Date) -> String {
        let currentYear = calendar.component(.year, from: Date())
        let dueDateYear = calendar.component(.year, from: dueDate)

        if currentYear == dueDateYear {
            return dueDate.formatted(
                .dateTime.month(.defaultDigits).day(.defaultDigits)
            )
        }

        return dueDate.formatted(
            .dateTime.year(.twoDigits).month(.defaultDigits).day(.defaultDigits)
        )
    }
}
