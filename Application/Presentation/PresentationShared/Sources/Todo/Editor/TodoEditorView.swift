//
//  TodoEditorView.swift
//  PresentationShared
//
//  Created by opfic on 5/31/25.
//

import SwiftUI
import ComposableArchitecture
import Core
import Domain

public struct TodoEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isiOSAppOnMac) private var isiOSAppOnMac
    @State var store: StoreOf<TodoEditorFeature>
    @FocusState private var field: Field?
    private let calendar = Calendar.current
    var onCreateSuccess: (() -> Void)?
    var onUpdateSuccess: ((Todo) -> Void)?
    var onClose: (() -> Void)?

    public init(
        store: StoreOf<TodoEditorFeature>,
        onCreateSuccess: (() -> Void)? = nil,
        onUpdateSuccess: ((Todo) -> Void)? = nil,
        onClose: (() -> Void)? = nil
    ) {
        self.store = store
        self.onCreateSuccess = onCreateSuccess
        self.onUpdateSuccess = onUpdateSuccess
        self.onClose = onClose
    }

    public var body: some View {
        NavigationStack {
            Group {
                if store.tabViewTag == .editor {
                    editorContent
                } else {
                    previewContent
                }
            }
            .onTapGesture {
                field = .content
            }
            .onAppear { store.send(.onAppear) }
            .onChange(of: store.saveResult) { _, result in
                handleSaveResult(result)
            }
            .navigationTitle(store.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.background, for: .navigationBar)
            .sheet(item: $store.scope(state: \.sheet, action: \.sheet)) { store in
                sheetContent(store)
            }
            .toolbar {
                if !isiOSAppOnMac {
                    ToolbarLeadingButton { close() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.send(.setSheet(.info))
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
                if store.isLoading {
                    if #available(iOS 26.0, *) {
                        ToolbarSpacer(.fixed, placement: .topBarTrailing)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        ProgressView()
                    }
                } else {
                    ToolbarTrailingButton {
                        submit()
                    }
                    .disabled(!store.isReadyToSubmit)
                }
            }
            .prominentAlert(store, state: \.alert, action: \.alert)
        }
    }

    private var editorContent: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                titleSection
                LazyVStack(
                    alignment: .leading,
                    spacing: 0,
                    pinnedViews: [.sectionHeaders]
                ) {
                    Section {
                        tabView
                    } header: {
                        if !isiOSAppOnMac {
                            tabPicker
                                .padding(.horizontal)
                        }
                    }
                }
            }
        }
    }

    private var previewContent: some View {
        VStack(spacing: 10) {
            titleSection
            if !isiOSAppOnMac {
                tabPicker
                    .padding(.horizontal)
            }
            tabView
        }
    }

    @ViewBuilder
    private var titleSection: some View {
        Group {
            if isiOSAppOnMac {
                HStack(spacing: 12) {
                    titleField
                    tabPicker
                        .frame(width: 180)
                }
            } else {
                titleField
            }
        }
        .padding(.horizontal)
    }

    private var titleField: some View {
        TextField(
            "",
            text: $store.title,
            prompt: Text(String(localized: "todo_editor_title_required")).foregroundColor(Color.secondary),
        )
        .font(.title2)
        .frame(height: 30)
        .focused($field, equals: .title)
    }

    private var tabPicker: some View {
        Picker(
            "",
            selection: Binding(
                get: { store.tabViewTag },
                set: { tag in
                    if tag == .editor {
                        store.send(.binding(.set(\.tabViewTag, .editor)))
                        field = .content
                    } else {
                        transitionToPreview()
                    }
                }
            )
        ) {
            Text(String(localized: "todo_write"))
                .tag(TodoEditorFeature.EditorTab.editor)
            Text(String(localized: "todo_preview"))
                .tag(TodoEditorFeature.EditorTab.preview)
        }
        .pickerStyle(.segmented)
    }

    private var tabView: some View {
        Group {
            if store.tabViewTag == .editor {
                VStack(alignment: .leading, spacing: 8) {
                    markdownHint
                    UIKitTextEditor(
                        text: $store.content,
                        placeholder: String(localized: "todo_editor_description_optional")
                    )
                    .focused($field, equals: .content)
                }
                .padding(.horizontal)
            } else {
                if store.content.isEmpty {
                    previewPlaceholder
                        .padding(.horizontal)
                } else {
                    TodoMarkdownContentView(
                        content: store.content,
                        referenceItems: store.referenceItems,
                        onOpenTodoID: { store.send(.setSheet(.todo(TodoIdItem(id: $0)))) }
                    )
                }
            }
        }
        .padding(.top, 10)
    }

    private var markdownHint: some View {
        Text(String(localized: "todo_editor_markdown_hint"))
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var previewPlaceholder: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: "todo_editor_markdown_preview_title"))
                .font(.subheadline.weight(.semibold))
            Text(String(localized: "todo_editor_markdown_preview_message"))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.vertical, 8)
    }

    private func submit() {
        store.send(.upsertTodo)
    }

    private func close() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }

    private func transitionToPreview() {
        field = nil

        DispatchQueue.main.async {
            store.send(.binding(.set(\.tabViewTag, .preview)))
        }
    }

    private func handleSaveResult(_ result: TodoEditorFeature.SaveResult?) {
        switch result {
        case .created:
            onCreateSuccess?()
        case .updated(let todo):
            onUpdateSuccess?(todo)
        case .none:
            break
        }
    }

    @ViewBuilder
    private func sheetContent(
        _ sheetStore: Store<TodoEditorFeature.SheetState, TodoEditorFeature.Action.Sheet>
    ) -> some View {
        switch sheetStore.state {
        case .info:
            TodoEditorInfoSheetView(store: store) {
                sheetStore.send(.tapCloseButton)
            }
        case .todo(let item):
            NavigationStack {
                TodoDetailView(store: Store(
                    initialState: TodoDetailFeature.State(todoId: item.id, showEditButton: false)
                ) {
                    TodoDetailFeature()
                })
                .toolbar {
                    ToolbarLeadingButton {
                        sheetStore.send(.tapCloseButton)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .presentationDragIndicator(.visible)
        }
    }

    private enum Field: Hashable {
        case title, content
    }
}

private struct TodoEditorInfoSheetView: View {
    @Bindable var store: StoreOf<TodoEditorFeature>
    let onClose: () -> Void
    @FocusState private var isTagFieldFocused: Bool
    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            List {
                Section(String(localized: "todo_options_section")) {
                    Picker(
                        String(localized: "todo_category"),
                        selection: Binding(
                            get: { store.category.id },
                            set: { categoryId in
                                guard let item = store.categories.first(where: {
                                    $0.id == categoryId
                                }) else {
                                    return
                                }

                                store.send(.binding(.set(\.category, item)))
                            }
                        )
                    ) {
                        ForEach(store.categories, id: \.id) { item in
                            Text(item.localizedName)
                                .tag(item.id)
                        }
                    }

                    Toggle(
                        String(localized: "todo_completed"),
                        isOn: Binding(
                            get: { store.isCompleted },
                            set: { store.send(.setCompleted($0)) }
                        )
                    )
                    .tint(.blue)

                    Toggle(
                        String(localized: "todo_pinned"),
                        isOn: Binding(
                            get: { store.isPinned },
                            set: { store.send(.binding(.set(\.isPinned, $0))) }
                        )
                    )
                    .tint(.blue)

                    dueDateControl
                }

                Section(String(localized: "todo_tags")) {
                    HStack(spacing: 12) {
                        TextField(
                            String(localized: "todo_add"),
                            text: $store.tagText
                        )
                        .frame(height: UIFont.preferredFont(forTextStyle: .title2).lineHeight)
                        .textInputAutocapitalization(.never)
                        .focused($isTagFieldFocused)
                        .onSubmit {
                            submitTag()
                        }

                        if isTagFieldFocused {
                            Button {
                                submitTag()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(canSubmitTag ? .blue : .secondary)
                            }
                            .disabled(!canSubmitTag)
                        }
                    }

                    if store.tags.isEmpty {
                        Text(String(localized: "todo_no_tags"))
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 4)
                    } else {
                        TagList(
                            store.tags,
                            isEditing: isTagFieldFocused,
                            action: { store.send(.removeTag($0)) }
                        )
                    }
                }
            }
            .navigationTitle(String(localized: "todo_details"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarLeadingButton {
                    onClose()
                }
            }
        }
    }

    private var dueDateControl: some View {
        DueDatePicker(selection: Binding(
            get: { store.dueDate ?? Date() },
            set: { store.send(.binding(.set(\.dueDate, $0))) }
        )) {
            HStack {
                Text(String(localized: "todo_due_date"))
                    .foregroundStyle(.primary)
                Spacer()
                if let dueDate = store.dueDate {
                    Tag(dueDateText(for: dueDate), isEditing: true) {
                        store.send(.binding(.set(\.dueDate, nil)))
                    }
                    .padding(.vertical, -4)
                } else {
                    Text(String(localized: "todo_none"))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func submitTag() {
        guard canSubmitTag else { return }

        let tagText = normalizedTagText
        store.send(.addTag(tagText))
        store.send(.binding(.set(\.tagText, "")))
    }

    private var normalizedTagText: String {
        store.tagText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSubmitTag: Bool {
        !normalizedTagText.isEmpty && !store.tags.contains(normalizedTagText)
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

private struct DueDatePicker<Content: View>: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @State private var isPresented: Bool = false
    @State private var height: CGFloat = .pi
    @Binding var dueDate: Date
    @ViewBuilder private var content: () -> Content

    init(
        selection dueDate: Binding<Date>,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._dueDate = dueDate
        self.content = content
    }

    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            content()
        }
        .sheet(isPresented: $isPresented) {
            DatePicker(
                "",
                selection: $dueDate,
                displayedComponents: .date
            )
            .labelsHidden()
            .datePickerStyle(.graphical)
            .presentationDragIndicator(.visible)
            .presentationDetents([.height(height)])
            .background {
                GeometryReader { geometry in
                    Color.clear.onAppear {
                        height = geometry.size.height + safeAreaInsets.bottom + safeAreaInsets.top
                    }
                }
            }
        }
    }
}
