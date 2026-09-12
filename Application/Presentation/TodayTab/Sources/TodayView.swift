//
//  TodayView.swift
//  TodayTab
//
//  Created by opfic on 3/6/26.
//

import SwiftUI
import Core
import Domain
import PresentationShared

public struct TodayView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var path = [TodayRoute]()
    @State private var store: StoreOf<TodayFeature>
    private let isSelected: Bool
    private let windowEvent: TodoEditorWindowEvent

    public init(
        isSelected: Bool,
        windowEvent: TodoEditorWindowEvent
    ) {
        self._store = State(initialValue: Store(
            initialState: TodayFeature.State()
        ) {
            TodayFeature()
        })
        self.isSelected = isSelected
        self.windowEvent = windowEvent
    }

    public var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8, pinnedViews: [.sectionHeaders]) {
                    Section {
                        if store.sections.isEmpty, !store.isLoading {
                            emptyContent
                        } else {
                            ForEach(store.sections) { section in
                                TodoSection(
                                    section: section,
                                    isNavigationEnabled: !store.isTodoInspectorPresented,
                                    onSelect: { path.append(.todo(TodoIdItem(id: $0.id))) },
                                    onInspect: { store.send(.showTodoInspector($0)) }
                                )
                            }
                            .padding(.bottom, 12)
                        }
                    } header: {
                        VStack {
                            achievementCard
                            filterBar
                        }
                        .background(Color.appBackground)
                    }
                }
                .padding(.horizontal)
            }
            .safeAreaInset(edge: .top, spacing: 0) { topBar }
            .background(Color.appBackground.ignoresSafeArea())
            .refreshable { await store.send(.refresh).finish() }
            .navigationDestination(for: TodayRoute.self, destination: destination)
            .sheet(isPresented: $store.isCategoryFilterPresented) {
                CategoryFilterSheet(store: store)
            }
        }
        .inspector(isPresented: $store.isTodoInspectorPresented) {
            todoInspector
        }
        .onChange(of: isSelected, initial: true) { _, isSelected in
            if isSelected {
                store.send(.fetchData)
            }
        }
        .onChange(of: scenePhase) { _, scenePhase in
            if scenePhase == .active, isSelected {
                store.send(.checkCurrentDate(Date()))
            }
        }
        .task(id: isSelected) {
            guard isSelected else { return }
            await monitorDateChanges()
        }
        .prominentAlert(store, state: \.alert, action: \.alert)
        .overlay {
            if store.isLoading {
                LoadingView()
            }
        }
    }

    private var topBar: some View {
        Text(String(localized: "nav_today", bundle: PresentationResources.bundle))
            .font(.largeTitle.bold())
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(Color.appBackground, ignoresSafeAreaEdges: .top)
    }

    private var achievementCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 10) {
                Text(String(
                    localized: "today_achievement_title",
                    bundle: PresentationResources.bundle)
                )
                .font(.title3.bold())

                Text(achievementStatusTitle)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Color.onPrimaryContainer)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.primaryContainer, in: .capsule)

                Spacer(minLength: 8)

                progressCount
            }

            ProgressView(value: store.todayAchievement?.progress ?? 0)
                .tint(Color.accent)
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.surface)
        }
    }

    @ViewBuilder
    private var progressCount: some View {
        if let achievement = store.todayAchievement {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("\(achievement.completedCount)")
                    .font(.title2.bold())
                    .foregroundStyle(Color.accent)
                Text("/")
                Text("\(achievement.totalCount)")
            }
            .font(.callout.weight(.semibold))
            .foregroundStyle(Color.textSecondary)
        } else {
            Text("-- / --")
                .font(.callout.weight(.semibold))
                .foregroundStyle(Color.textSecondary)
        }
    }

    @ViewBuilder
    private var filterBar: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 8) {
                ForEach(TodayFeature.TodoScope.allCases, id: \.self) { scope in
                    let isSelected = store.selectedTodoScope == scope
                    Button {
                        withAnimation(.easeInOut) {
                            _ = store.send(.setTodoScope(scope))
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(scope.title)
                            Text("\(store.summaryCounts[scope, default: 0])")
                                .fontWeight(.bold)
                        }
                        .font(.callout)
                        .foregroundStyle(isSelected ? Color.onPrimaryContainer : .onControlBackground)
                    }
                    .adaptiveButtonStyle(color: isSelected ? Color.primaryContainer : .controlBackground)
                }

                let category = store.selectedCategory
                let isSelected = category != nil
                Button {
                    store.send(.binding(.set(\.isCategoryFilterPresented, true)))
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: category?.symbolName ?? "tray.2")
                            .foregroundStyle(category?.color ?? Color.onControlBackground)
                        Text(
                            category?.localizedName
                                ?? String(
                                    localized: "todo_category",
                                    bundle: PresentationResources.bundle
                                )
                        )
                    }
                    .font(.callout)
                    .foregroundStyle(isSelected ? Color.onPrimaryContainer : .onControlBackground)
                }
                .adaptiveButtonStyle(color: isSelected ? Color.primaryContainer : .controlBackground)
            }
        }
        .scrollIndicators(.hidden)
        .padding(.horizontal, -16)
        .contentMargins(.horizontal, 16, for: .scrollContent)
    }

    private var emptyContent: some View {
        VStack(spacing: 8) {
            Text(emptyStateContent.title)
                .font(.headline)
            Text(emptyStateContent.message)
                .font(.callout)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.surface)
        }
    }

    @ViewBuilder
    private var todoInspector: some View {
        if let editorStore = store.scope(state: \.todoEditor, action: \.todoEditor) {
            TodoEditorView(
                store: editorStore,
                onClose: { store.send(.dismissTodoInspector) }
            )
            .inspectorColumnWidth(min: 320, ideal: 420, max: 520)
        }
    }

    private func destination(_ route: TodayRoute) -> some View {
        switch route {
        case .todo(let item):
            TodoDetailView(
                store: Store(
                    initialState: TodoDetailFeature.State(todoId: item.id, showEditButton: true)
                ) {
                    TodoDetailFeature()
                },
                windowEvent: windowEvent
            )
            .id(item.id)
        }
    }

    private func monitorDateChanges() async {
        while !Task.isCancelled {
            let date = Date()
            store.send(.checkCurrentDate(date))
            let interval = TodayFeature.dayInterval(containing: date)
            let seconds = min(max(interval.end.timeIntervalSince(date), 1), 60)
            do {
                try await Task.sleep(for: .seconds(seconds))
            } catch {
                return
            }
        }
    }

    private var achievementStatusTitle: String {
        store.todayAchievement?.status.title
            ?? String(localized: "today_achievement_status_loading", bundle: PresentationResources.bundle)
    }

    private var emptyStateContent: EmptyStateContent {
        if store.todos.isEmpty, store.completedTodayTodos.isEmpty {
            return EmptyStateContent(
                title: String(localized: "today_empty_all_title", bundle: PresentationResources.bundle),
                message: String(localized: "today_empty_all_message", bundle: PresentationResources.bundle)
            )
        }
        if store.hasActiveFilters {
            return EmptyStateContent(
                title: String(localized: "today_empty_filtered_title", bundle: PresentationResources.bundle),
                message: String(localized: "today_empty_filtered_message", bundle: PresentationResources.bundle)
            )
        }
        return EmptyStateContent(
            title: String(localized: "today_empty_all_title", bundle: PresentationResources.bundle),
            message: String(localized: "today_empty_all_message", bundle: PresentationResources.bundle)
        )
    }

    private struct EmptyStateContent {
        let title: String
        let message: String
    }
}

private struct CategoryFilterSheet: View {
    let store: StoreOf<TodayFeature>

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    CategoryFilterRow(
                        category: nil,
                        title: String(
                            localized: "today_filter_all_categories",
                            bundle: PresentationResources.bundle
                        ),
                        isSelected: store.selectedCategoryID == nil,
                        action: { store.send(.setCategory(nil)) }
                    )
                    if !store.visibleCategories.isEmpty {
                        Divider()
                    }
                    ForEach(
                        Array(zip(store.visibleCategories.indices, store.visibleCategories)),
                        id: \.1.id
                    ) { index, category in
                        CategoryFilterRow(
                            category: category,
                            title: category.localizedName,
                            isSelected: store.selectedCategoryID == category.id,
                            action: { store.send(.setCategory(category.id)) }
                        )
                        if index < store.visibleCategories.count - 1 {
                            Divider()
                        }
                    }
                }
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.surface)
                }
                .padding()
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle(String(localized: "todo_category", bundle: PresentationResources.bundle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.send(.binding(.set(\.isCategoryFilterPresented, false)))
                    } label: {
                        Text(String(localized: "profile_done", bundle: PresentationResources.bundle))
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
    }
}

private struct CategoryFilterRow: View {
    let category: TodoCategoryItem?
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: category?.symbolName ?? "tray.2")
                    .foregroundStyle(category?.color ?? Color.textSecondary)
                Text(title)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                }
            }
            .font(.callout)
            .foregroundStyle(isSelected ? Color.accent : .textSecondary)
            .frame(maxWidth: .infinity)
            .padding()
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

private struct TodoSection: View {
    let section: TodayFeature.SectionContent
    let isNavigationEnabled: Bool
    let onSelect: (TodayTodoItem) -> Void
    let onInspect: (TodayTodoItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(section.title)
                    .font(.title3.bold())
                    .foregroundStyle(section.category.accentColor)
                Text("\(section.items.count)")
                    .font(.callout.bold())
                    .foregroundStyle(section.category.accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(section.category.accentColor.opacity(0.1), in: .capsule)
                Spacer()
                if section.category == .today {
                    Text(String(localized: "today_pinned_first", bundle: PresentationResources.bundle))
                        .font(.callout)
                        .foregroundStyle(Color.textSecondary)
                }
            }

            LazyVStack(spacing: 0) {
                ForEach(Array(zip(section.items.indices, section.items)), id: \.1.id) { index, item in
                    TodoRow(
                        item: item,
                        isNavigationEnabled: isNavigationEnabled,
                        onSelect: { onSelect(item) },
                        onInspect: { onInspect(item) }
                    )
                    if index < section.items.count - 1 {
                        Divider()
                    }
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.surface)
            }
        }
    }
}

private struct TodoRow: View {
    let item: TodayTodoItem
    let isNavigationEnabled: Bool
    let onSelect: () -> Void
    let onInspect: () -> Void

    var body: some View {
        Button {
            guard isNavigationEnabled else { return }
            onSelect()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.headline)
                        .strikethrough(item.isCompleted)
                        .foregroundStyle(item.isCompleted ? Color.textSecondary : .primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    if !item.content.isEmpty {
                        Text(item.content)
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                            .lineLimit(1)
                            .multilineTextAlignment(.leading)
                    }
                    todoMetadata
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.callout.bold())
                    .foregroundStyle(Color.textTertiary)
                    .opacity(isNavigationEnabled ? 1 : 0)
            }
            .overlay {
                TodoInspectorInteractionView(action: onInspect)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private var todoMetadata: some View {
        let category = TodoCategoryItem(from: item.category)
        HStack(spacing: 10) {
            Text("#\(item.number)")
                .foregroundStyle(Color.accent)

            Image(systemName: category.symbolName)
                .foregroundStyle(category.color)

            if let dueDate = item.dueDate {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                    Text(dueDateText(dueDate))
                }
                .foregroundStyle(dueDateColor(dueDate))
            }
        }
        .font(.caption.weight(.semibold))
        .lineLimit(1)
    }

    private func dueDateText(_ date: Date) -> String {
        let calendar = Calendar.autoupdatingCurrent
        if calendar.isDateInToday(date) {
            return String(localized: "today_section_today", bundle: PresentationResources.bundle)
        }
        if calendar.isDateInYesterday(date) {
            return String(localized: "today_due_yesterday", bundle: PresentationResources.bundle)
        }
        return date.formatted(.dateTime.month(.abbreviated).day().weekday(.abbreviated))
    }

    private func dueDateColor(_ date: Date) -> Color {
        let calendar = Calendar.autoupdatingCurrent
        if calendar.startOfDay(for: date) < calendar.startOfDay(for: Date()) {
            return .danger
        }
        return .textSecondary
    }
}

private struct TodoInspectorInteractionView: UIViewRepresentable {
    let action: () -> Void

    func makeCoordinator() -> TodoInspectorInteractionCoordinator {
        TodoInspectorInteractionCoordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        context.coordinator.update(action: action)
        context.coordinator.install(on: view)
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        context.coordinator.update(action: action)
    }
}

private final class TodoInspectorInteractionCoordinator: NSObject {
    private weak var view: UIView?
    private var contextMenuInteraction: UIContextMenuInteraction?
    private var action: (() -> Void)?

    func update(action: @escaping () -> Void) {
        self.action = action
    }

    func install(on view: UIView) {
        guard self.view !== view else { return }

        if let contextMenuInteraction {
            self.view?.removeInteraction(contextMenuInteraction)
        }

        let contextMenuInteraction = UIContextMenuInteraction(delegate: self)
        view.addInteraction(contextMenuInteraction)
        self.view = view
        self.contextMenuInteraction = contextMenuInteraction
    }
}

extension TodoInspectorInteractionCoordinator: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        action?()
        return nil
    }
}

private extension TodayFeature.TodoScope {
    var title: String {
        switch self {
        case .remaining:
            return String(localized: "today_filter_remaining", bundle: PresentationResources.bundle)
        case .important:
            return String(localized: "today_filter_important", bundle: PresentationResources.bundle)
        }
    }
}

private extension TodayFeature.SectionCategory {
    var accentColor: Color {
        self == .overdue ? .danger : .primary
    }
}

private extension TodayFeature.TodayAchievement.Status {
    var title: String {
        let key = switch self {
        case .empty: "today_achievement_status_empty"
        case .inProgress: "today_achievement_status_in_progress"
        case .completed: "today_achievement_status_completed"
        }
        return String(localized: String.LocalizationValue(key), bundle: PresentationResources.bundle)
    }
}
