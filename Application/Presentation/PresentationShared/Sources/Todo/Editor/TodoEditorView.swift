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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.isTabContentActive) private var isTabContentActive
    @Environment(\.isiOSAppOnMac) private var isiOSAppOnMac
    @Environment(\.safeAreaInsets) private var safeAreaInsets
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
            ZStack {
                Color.appBackground.ignoresSafeArea()
                VStack(spacing: 8) {
                    ToolBar(
                        store: store,
                        showsActions: !movesActionsToInspector,
                        onClose: close,
                        onSubmit: submit
                    )
                    GeometryReader { geometry in
                        ScrollView {
                            VStack(spacing: 16) {
                                VStack(alignment: .trailing, spacing: 16) {
                                    TitleField(store: store, field: _field)
                                    ModePicker(store: store, field: _field)
                                        .frame(maxWidth: horizontalSizeClass == .regular ? 280 : .infinity)
                                }
                                .onGeometryChange(for: CGFloat.self) { proxy in
                                    proxy.size.height
                                } action: { height in
                                    store.send(.binding(.set(\.editorHeaderHeight, height)))
                                }
                                ContentView(
                                    store: store,
                                    field: _field,
                                    minimumHeight: max(
                                        0,
                                        geometry.size.height - store.editorHeaderHeight - 16 - safeAreaInsets.bottom
                                    )
                                )
                                .onTapGesture {
                                    field = .content
                                }
                            }
                            .padding(.horizontal)
                        }
                        .contentMargins(.vertical, 16, for: .scrollContent)
                    }
                }
            }
            .onAppear { store.send(.onAppear) }
            .onChange(of: store.saveResult) { _, result in
                handleSaveResult(result)
            }
            .toolbarVisibility(.hidden, for: .navigationBar)
            .prominentAlert(store, state: \.alert, action: \.alert)
            .inspector(isPresented: $store.isInspectorPresented) {
                switch store.inspectorContent {
                case .options:
                    InspectorView(
                        store: store,
                        showsEditorActions: movesActionsToInspector,
                        onSubmit: submit
                    ) {
                        store.send(.binding(.set(\.isInspectorPresented, false)))
                    }
                case .todo(let item):
                    NavigationStack {
                        TodoDetailView(store: Store(
                            initialState: TodoDetailFeature.State(todoId: item.id, showEditButton: false)
                        ) {
                            TodoDetailFeature()
                        })
                        .id(item.id)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button {
                                    store.send(.showInspector(.options))
                                } label: {
                                    Label(
                                        String(
                                            localized: "todo_options_section",
                                            bundle: PresentationResources.bundle
                                        ),
                                        systemImage: "chevron.left"
                                    )
                                }
                            }
                            if movesActionsToInspector {
                                ToolbarItem(placement: .topBarTrailing) {
                                    EditorToolbarActions(store: store, onSubmit: submit)
                                }
                            } else {
                                ToolbarTrailingButton {
                                    store.send(.binding(.set(\.isInspectorPresented, false)))
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var movesActionsToInspector: Bool {
        store.isInspectorPresented && (isiOSAppOnMac || horizontalSizeClass == .regular)
    }

    private func close() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }

    private func submit() {
        store.send(.upsertTodo)
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
}

private struct ToolBar: View {
    let store: StoreOf<TodoEditorFeature>
    let showsActions: Bool
    let onClose: () -> Void
    let onSubmit: () -> Void
    @ScaledMetric(relativeTo: .title) private var iconSize = UIFont.preferredFont(
        forTextStyle: .title1,
        compatibleWith: UITraitCollection(preferredContentSizeCategory: .large)
    ).lineHeight

    var body: some View {
        HStack {
            Button {
                onClose()
            } label: {
                if #available(iOS 26.0, *) {
                    Image(systemName: "xmark")
                        .frame(width: iconSize, height: iconSize)
                } else {
                    Text(String(localized: "common_close", bundle: PresentationResources.bundle))
                }
            }
            .font(.title)
            .adaptiveButtonStyle(shape: .circle)
            Spacer()
            Text(store.navigationTitle)
                .font(.title3.bold())
            Spacer()
            if showsActions {
                EditorToolbarActions(store: store, onSubmit: onSubmit)
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }
}

private struct EditorToolbarActions: View {
    let store: StoreOf<TodoEditorFeature>
    let onSubmit: () -> Void
    @ScaledMetric(relativeTo: .title) private var iconSize = UIFont.preferredFont(
        forTextStyle: .title1,
        compatibleWith: UITraitCollection(preferredContentSizeCategory: .large)
    ).lineHeight

    var body: some View {
        HStack {
            Button {
                store.send(.showInspector(.options))
            } label: {
                Image(systemName: "info.circle")
                    .frame(width: iconSize, height: iconSize)
                    .foregroundStyle(Color.primary)
            }
            .font(.title)
            .adaptiveButtonStyle(shape: .circle, color: Color.surface)
            if store.isLoading {
                ProgressView()
                    .frame(width: iconSize, height: iconSize)
                    .adaptiveButtonStyle(shape: .circle, color: Color.surface)
            } else {
                Button {
                    onSubmit()
                } label: {
                    if #available(iOS 26.0, *) {
                        Image(systemName: "checkmark")
                            .frame(width: iconSize, height: iconSize)
                            .foregroundStyle(Color.primary)
                    } else {
                        Text(String(localized: "todo_manage_save", bundle: PresentationResources.bundle))
                            .foregroundStyle(Color.primary)
                    }
                }
                .font(.title)
                .adaptiveButtonStyle(shape: .circle, color: Color.surface)
                .disabled(!store.isReadyToSubmit)
            }
        }
    }
}

private struct TitleField: View {
    @Bindable var store: StoreOf<TodoEditorFeature>
    @FocusState var field: Field?

    var body: some View {
        TextField(
            "",
            text: $store.title,
            prompt: Text(
                String(
                    localized: "todo_editor_title_required",
                    bundle: PresentationResources.bundle
                )
            )
            .foregroundColor(Color.secondary),
        )
        .font(.title2)
        .focused($field, equals: .title)
        .frame(height: 30)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.surface)
                .strokeBorder(Color.border, lineWidth: 2)
        }
    }
}

private struct ModePicker: View {
    @Bindable var store: StoreOf<TodoEditorFeature>
    @FocusState var field: Field?

    var body: some View {
        HStack(spacing: 0) {
            modeButton(
                String(localized: "todo_write", bundle: PresentationResources.bundle),
                tab: .editor
            )
            modeButton(
                String(localized: "todo_preview", bundle: PresentationResources.bundle),
                tab: .preview
            )
        }
        .padding(2)
        .background(Color.border, in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func modeButton(_ title: String, tab: TodoEditorFeature.EditorTab) -> some View {
        let isSelected = store.tabViewTag == tab

        Button {
            if tab == .editor {
                store.send(.binding(.set(\.tabViewTag, .editor)))
                field = .content
            } else {
                field = nil
                DispatchQueue.main.async {
                    store.send(.binding(.set(\.tabViewTag, .preview)))
                }
            }
        } label: {
            Text(title)
                .font(.body)
                .foregroundStyle(isSelected ? Color.accent : Color.textSecondary)
                .frame(maxWidth: .infinity, minHeight: 36)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.surface)
                            .shadow(color: Color.textSecondary.opacity(0.08), radius: 2, y: 2)
                    }
                }
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

private struct ContentView: View {
    @Bindable var store: StoreOf<TodoEditorFeature>
    @FocusState var field: Field?
    let minimumHeight: CGFloat

    var body: some View {
        Group {
            if store.tabViewTag == .editor {
                VStack(alignment: .leading, spacing: 8) {
                    markdownHint
                    UIKitTextEditor(
                        text: $store.content,
                        placeholder: String(
                            localized: "todo_editor_description_optional",
                            bundle: PresentationResources.bundle
                        )
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
                        onOpenTodoID: { store.send(.showInspector(.todo(TodoIdItem(id: $0)))) }
                    )
                }
            }
        }
        .padding(.vertical, 10)
        .frame(minHeight: minimumHeight, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.surface)
                .strokeBorder(Color.border, lineWidth: 2)
        }
    }

    private var markdownHint: some View {
        Text(String(localized: "todo_editor_markdown_hint", bundle: PresentationResources.bundle))
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var previewPlaceholder: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: "todo_editor_markdown_preview_title", bundle: PresentationResources.bundle))
                .font(.subheadline.weight(.semibold))
            Text(String(localized: "todo_editor_markdown_preview_message", bundle: PresentationResources.bundle))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.vertical, 8)
    }
}

private struct InspectorView: View {
    @Bindable var store: StoreOf<TodoEditorFeature>
    @FocusState private var isTagFieldFocused: Bool
    @ScaledMetric(relativeTo: .title) private var iconSize = UIFont.preferredFont(
        forTextStyle: .title1,
        compatibleWith: UITraitCollection(preferredContentSizeCategory: .large)
    ).lineHeight
    var showsEditorActions = false
    var onSubmit: () -> Void = {}
    let onClose: () -> Void
    private let calendar = Calendar.current

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 8) {
                toolBar
                content
            }
        }
    }

    private var toolBar: some View {
        HStack {
            Spacer()
            if showsEditorActions {
                EditorToolbarActions(store: store, onSubmit: onSubmit)
            } else {
                Button {
                    onClose()
                } label: {
                    Image(systemName: "checkmark")
                        .frame(width: iconSize, height: iconSize)
                        .foregroundStyle(Color.primary)
                }
                .font(.title)
                .adaptiveButtonStyle(shape: .circle, color: Color.surface)
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .overlay {
            if !showsEditorActions {
                Text(String(localized: "todo_details", bundle: PresentationResources.bundle))
                    .font(.title3.bold())
            }
        }
    }

    private var content: some View {
            ScrollView {
                LazyVStack(spacing: 24) {
                    VStack(spacing: 0) {
                        HStack(spacing: 12) {
                            optionIcon("tag.fill", color: Color.accent)
                            Spacer()
                            Picker(
                                String(localized: "todo_category", bundle: PresentationResources.bundle),
                                selection: $store.category
                            ) {
                                ForEach(store.categories, id: \.id) { item in
                                    Text(item.localizedName)
                                        .tag(item)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Color.accent)
                        }
                        .padding(.vertical, 12)

                        Divider().overlay(Color.border)

                        Toggle(isOn: $store.isCompleted) {
                            HStack(spacing: 12) {
                                optionIcon("circle", color: Color.textSecondary)
                                Text(String(localized: "todo_completed", bundle: PresentationResources.bundle))
                            }
                        }
                        .tint(Color.accent)
                        .padding(.vertical, 12)

                        Divider().overlay(Color.border)

                        Toggle(isOn: $store.isPinned) {
                            HStack(spacing: 12) {
                                optionIcon("star.fill", color: Color.warning)
                                Text(String(localized: "todo_pinned", bundle: PresentationResources.bundle))
                            }
                        }
                        .tint(Color.accent)
                        .padding(.vertical, 12)

                        Divider().overlay(Color.border)

                        dueDateControl
                            .padding(.vertical, 12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.surface)
                            .strokeBorder(Color.border, lineWidth: 2)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "todo_tags", bundle: PresentationResources.bundle))
                            .font(.headline)
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 12) {
                                TextField(
                                    String(localized: "todo_add", bundle: PresentationResources.bundle),
                                    text: $store.tagText
                                )
                                .frame(height: UIFont.preferredFont(forTextStyle: .title2).lineHeight)
                                .textInputAutocapitalization(.never)
                                .focused($isTagFieldFocused)
                                .onSubmit { submitTag() }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.surfaceSecondary)
                                        .strokeBorder(Color.border, lineWidth: 2)
                                }
                                .tint(Color.accent)

                                Button {
                                    submitTag()
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.title2.weight(.semibold))
                                        .foregroundStyle(canSubmitTag ? Color.surface : Color.textSecondary)
                                        .padding(12)
                                        .background(
                                            canSubmitTag ? Color.accent : Color.surfaceSecondary,
                                            in: Circle()
                                        )
                                }
                                .buttonStyle(.plain)
                                .disabled(!canSubmitTag)
                            }

                            if store.tags.isEmpty {
                                Text(String(localized: "todo_no_tags", bundle: PresentationResources.bundle))
                                    .foregroundStyle(.secondary)
                                    .padding(.vertical, 4)
                            } else {
                                TagList(
                                    store.tags,
                                    isEditing: true,
                                    action: { store.send(.removeTag($0)) }
                                )
                            }
                            Text(String(
                                localized: "todo_tag_duplicate_hint",
                                bundle: PresentationResources.bundle
                            ))
                        }
                        .padding(20)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.surface)
                                .strokeBorder(Color.border, lineWidth: 2)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .contentMargins(.top, 16, for: .scrollContent)
    }

    private func optionIcon(_ name: String, color: Color) -> some View {
        Image(systemName: name)
            .font(.title3)
            .foregroundStyle(color)
            .frame(width: 44, height: 44)
            .background(color.opacity(0.08), in: Circle())
    }

    private var dueDateControl: some View {
        DueDatePicker(selection: $store.selectedDueDate) {
            HStack(spacing: 12) {
                optionIcon("calendar", color: Color.textSecondary)
                Text(String(localized: "todo_due_date", bundle: PresentationResources.bundle))
                    .foregroundStyle(.primary)
                Spacer()
                if let dueDate = store.dueDate {
                    Tag(dueDateText(for: dueDate), isEditing: true) {
                        store.send(.binding(.set(\.dueDate, nil)))
                    }
                    .padding(.vertical, -4)
                } else {
                    Text(String(localized: "todo_none", bundle: PresentationResources.bundle))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func close() {
        isTagFieldFocused = false
        onClose()
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
    @Environment(\.isTabContentActive) private var isTabContentActive
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
        .sheet(isPresented: $isPresented.activePresentation(when: isTabContentActive)) {
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

private enum Field: Hashable {
    case title, content
}
