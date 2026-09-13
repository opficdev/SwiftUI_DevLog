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
                Group {
                switch store.inspectorContent {
                case .options:
                    TodoPropertiesView(
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
                .inspectorColumnWidth(min: 320, ideal: 420, max: 520)
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
            .adaptiveButtonStyle(shape: .circle, glassEffect: .enabled)
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

struct EditorToolbarActions: View {
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
            .adaptiveButtonStyle(shape: .circle, color: Color.surface, glassEffect: .enabled)
            if store.isLoading {
                ProgressView()
                    .frame(width: iconSize, height: iconSize)
                    .adaptiveButtonStyle(shape: .circle, color: Color.surface, glassEffect: .enabled)
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
                .adaptiveButtonStyle(shape: .circle, color: Color.surface, glassEffect: .enabled)
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

private enum Field: Hashable {
    case title, content
}
