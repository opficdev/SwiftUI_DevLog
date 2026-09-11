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
        @Dependency(\.todayFetchDisplayOptionsUseCase) var fetchDisplayOptionsUseCase
        self._store = State(initialValue: Store(
            initialState: TodayFeature.State(
                displayOptions: fetchDisplayOptionsUseCase.execute()
            )
        ) {
            TodayFeature()
        })
        self.isSelected = isSelected
        self.windowEvent = windowEvent
    }

    public var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24, pinnedViews: [.sectionHeaders]) {
                    Section {
                        scopePicker
                        if displaySections.isEmpty, !store.isLoading {
                            emptyContent
                                .padding(.horizontal)
                        } else {
                            ForEach(displaySections) { section in
                                todoSection(section)
                                    .padding(.horizontal)
                            }
                        }
                    } header: {
                        achievementCard
                    }
                }
                .padding(.bottom, 24)
            }
            .safeAreaInset(edge: .top, spacing: 0) { topBar }
            .background(Color.appBackground.ignoresSafeArea())
            .refreshable { await store.send(.refresh).finish() }
            .navigationDestination(for: TodayRoute.self, destination: destination)
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
                    .foregroundStyle(Color.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.primaryContainer, in: .capsule)

                Spacer(minLength: 8)

                progressCount
                filterMenu
            }

            ProgressView(value: store.todayAchievement?.progress ?? 0)
                .tint(Color.accent)
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.surface)
                .strokeBorder(Color.border, lineWidth: 2)
        }
        .padding(.horizontal)
        .background(Color.appBackground)
    }

    private var progressCount: some View {
        Group {
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
    }

    private var filterMenu: some View {
        Menu {
            Picker(
                String(
                    localized: "today_due_visibility_label",
                    bundle: PresentationResources.bundle
                ),
                selection: $store.displayOptions.dueDateVisibility
            ) {
                ForEach(TodayDisplayOptions.DueDateVisibility.allCases, id: \.self) { option in
                    Text(option.title).tag(option)
                }
            }

            Toggle(
                String(
                    localized: "today_pinned_only",
                    bundle: PresentationResources.bundle
                ),
                isOn: $store.displayOptions.isFocusedOnly
            )
        } label: {
            Image(systemName: "ellipsis")
                .font(.headline)
                .foregroundStyle(Color.textSecondary)
                .padding(8)
        }
    }

    @ViewBuilder
    private var scopePicker: some View {
        let summaryCounts = store.summaryCounts

        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(TodayFeature.SectionScope.allCases, id: \.self) { scope in
                    let isSelected = store.selectedSectionScope == scope
                    Button {
                        withAnimation(.easeInOut) {
                            _ = store.send(.setSectionScope(scope))
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(scope.title)
                            Text("\(summaryCounts[scope, default: 0])")
                                .fontWeight(.bold)
                        }
                        .font(.callout)
                        .foregroundStyle(isSelected ? Color.accent : Color.textSecondary)
                    }
                    .adaptiveButtonStyle(color: isSelected ? Color.primaryContainer : .clear)
                }
            }
        }
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, 16, for: .scrollContent)
    }

    private var displaySections: [TodayDisplaySection] {
        guard store.selectedSectionScope == .all else {
            return store.sections.map(TodayDisplaySection.init)
        }

        let todayItems = visibleTodayTodos
        let todayItemIDs = Set(todayItems.filter { !$0.isCompleted }.map(\.id))
        let remainingSections = store.sections.compactMap { section -> TodayDisplaySection? in
            let items = section.items.filter { !todayItemIDs.contains($0.id) }
            guard !items.isEmpty else { return nil }
            return TodayDisplaySection(section: section, items: items)
        }
        let order: [TodayFeature.SectionCategory] = [.overdue, .dueSoon, .focused, .later, .unscheduled]
        var sections = order.compactMap { category in
            remainingSections.first { $0.category == category }
        }

        guard !todayItems.isEmpty else { return sections }
        let todaySection = TodayDisplaySection(todayItems: todayItems)
        let insertionIndex = sections.firstIndex { $0.category != .overdue } ?? sections.endIndex
        sections.insert(todaySection, at: insertionIndex)
        return sections
    }

    private var visibleTodayTodos: [TodayTodoItem] {
        let items = TodayFeature.displayedTodos(
            todos: store.todayTodos,
            displayOptions: store.displayOptions
        )
        return items.filter(\.isPinned) + items.filter { !$0.isPinned }
    }

    private func todoSection(_ section: TodayDisplaySection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(section.title)
                    .font(.title3.bold())
                    .foregroundStyle(section.accentColor)
                Text("\(section.items.count)")
                    .font(.callout.bold())
                    .foregroundStyle(section.accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(section.accentColor.opacity(0.1), in: .capsule)
                Spacer()
                if section.id == .today {
                    Text(String(localized: "today_pinned_first", bundle: PresentationResources.bundle))
                        .font(.callout)
                        .foregroundStyle(Color.textSecondary)
                }
            }

            LazyVStack(spacing: 12) {
                ForEach(section.items) { item in
                    TodayTodoCard(
                        item: item,
                        onComplete: { store.send(.completeTodo(item)) },
                        onTogglePinned: { store.send(.togglePinned(item)) }
                    )
                }
            }
        }
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
                .strokeBorder(Color.border, lineWidth: 2)
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
        switch store.selectedSectionScope {
        case .all:
            if store.todos.isEmpty {
                return EmptyStateContent(
                    title: String(localized: "today_empty_all_title", bundle: PresentationResources.bundle),
                    message: String(localized: "today_empty_all_message", bundle: PresentationResources.bundle)
                )
            }
            return EmptyStateContent(
                title: String(localized: "today_empty_filtered_title", bundle: PresentationResources.bundle),
                message: String(localized: "today_empty_filtered_message", bundle: PresentationResources.bundle)
            )
        case .focused:
            return EmptyStateContent(
                title: String(localized: "today_empty_focused_title", bundle: PresentationResources.bundle),
                message: String(localized: "today_empty_focused_message", bundle: PresentationResources.bundle)
            )
        case .overdue:
            return EmptyStateContent(
                title: String(localized: "today_empty_overdue_title", bundle: PresentationResources.bundle),
                message: String(localized: "today_empty_overdue_message", bundle: PresentationResources.bundle)
            )
        case .dueSoon:
            return EmptyStateContent(
                title: String(localized: "today_empty_due_soon_title", bundle: PresentationResources.bundle),
                message: String(localized: "today_empty_due_soon_message", bundle: PresentationResources.bundle)
            )
        }
    }

    private struct EmptyStateContent {
        let title: String
        let message: String
    }
}

private struct TodayDisplaySection: Identifiable {
    enum Identifier: Hashable {
        case today
        case category(TodayFeature.SectionCategory)
    }

    let id: Identifier
    let category: TodayFeature.SectionCategory?
    let title: String
    let items: [TodayTodoItem]
    let accentColor: Color

    init(_ section: TodayFeature.SectionContent) {
        self.init(section: section, items: section.items)
    }

    init(section: TodayFeature.SectionContent, items: [TodayTodoItem]) {
        self.id = .category(section.category)
        self.category = section.category
        self.title = section.category.displayTitle
        self.items = items
        self.accentColor = section.category == .overdue ? .danger : .primary
    }

    init(todayItems: [TodayTodoItem]) {
        self.id = .today
        self.category = nil
        self.title = String(localized: "today_section_today", bundle: PresentationResources.bundle)
        self.items = todayItems
        self.accentColor = .primary
    }
}

private struct TodayTodoCard: View {
    @Environment(\.colorScheme) private var colorScheme
    @ScaledMetric(relativeTo: .title2) private var completionSize = CGFloat(30)
    let item: TodayTodoItem
    let onComplete: () -> Void
    let onTogglePinned: () -> Void
    private var isDarkMode: Bool { colorScheme == .dark }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            completionStatus

            NavigationLink(value: TodayRoute.todo(TodoIdItem(id: item.id))) {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 8) {
                        todoInformation
                        Text(item.title)
                            .font(.headline)
                            .strikethrough(item.isCompleted)
                            .foregroundStyle(item.isCompleted ? Color.textSecondary : .primary)
                            .multilineTextAlignment(.leading)
                        if !item.content.isEmpty {
                            Text(item.content)
                                .font(.callout)
                                .foregroundStyle(Color.textSecondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.right")
                        .font(.callout.bold())
                        .foregroundStyle(Color.textTertiary)
                }
            }
            .buttonStyle(.plain)
            .todoDetailPreview(todoId: item.id)

            Image(systemName: item.isPinned ? "star.fill" : "star")
                .font(.title3)
                .foregroundStyle(item.isPinned ? Color.warning : .textTertiary)
                .onTapGesture { onTogglePinned() }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.surface)
                .strokeBorder(Color.border, lineWidth: 2)
        }
    }

    @ViewBuilder
    private var completionStatus: some View {
        if item.isCompleted {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.success)
                .frame(width: completionSize, height: completionSize)
        } else {
            Button(action: onComplete) {
                Image(systemName: "circle")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.textTertiary)
                    .frame(width: completionSize, height: completionSize)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var todoInformation: some View {
        let category = TodoCategoryItem(from: item.category)
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: category.symbolName)
                Text(category.localizedName)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(isDarkMode ? .white : category.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                category.color.opacity(isDarkMode ? 1 : 0.2),
                in: .rect(cornerRadius: 8)
            )

            if let dueDate = item.dueDate {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                    Text(dueDateText(dueDate))
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(dueDateColor(dueDate))
            }
        }
    }

    private func dueDateText(_ date: Date) -> String {
        let calendar = Calendar.autoupdatingCurrent
        if calendar.isDateInToday(date) {
            return date.formatted(date: .omitted, time: .shortened)
        }
        if calendar.isDateInYesterday(date) {
            return String(localized: "today_due_yesterday", bundle: PresentationResources.bundle)
        }
        return date.formatted(.dateTime.month(.abbreviated).day().weekday(.abbreviated).hour().minute())
    }

    private func dueDateColor(_ date: Date) -> Color {
        let calendar = Calendar.autoupdatingCurrent
        if calendar.startOfDay(for: date) < calendar.startOfDay(for: Date()) {
            return .danger
        }
        return .accent
    }
}

private extension TodayDisplayOptions.DueDateVisibility {
    var title: String {
        switch self {
        case .all:
            return String(localized: "today_due_visibility_all", bundle: PresentationResources.bundle)
        case .withDueDateOnly:
            return String(localized: "today_due_visibility_with_due", bundle: PresentationResources.bundle)
        case .withoutDueDateOnly:
            return String(localized: "today_due_visibility_without_due", bundle: PresentationResources.bundle)
        }
    }
}

private extension TodayFeature.SectionScope {
    var title: String {
        switch self {
        case .all:
            return String(localized: "today_summary_all", bundle: PresentationResources.bundle)
        case .focused:
            return String(localized: "today_summary_focused", bundle: PresentationResources.bundle)
        case .overdue:
            return String(localized: "today_summary_overdue", bundle: PresentationResources.bundle)
        case .dueSoon:
            return String(localized: "today_summary_due_soon", bundle: PresentationResources.bundle)
        }
    }
}

private extension TodayFeature.SectionCategory {
    var displayTitle: String {
        switch self {
        case .overdue:
            return String(localized: "today_section_overdue", bundle: PresentationResources.bundle)
        case .dueSoon:
            return String(localized: "today_section_upcoming", bundle: PresentationResources.bundle)
        case .focused:
            return String(localized: "today_section_focused", bundle: PresentationResources.bundle)
        case .later:
            return String(localized: "today_section_later", bundle: PresentationResources.bundle)
        case .unscheduled:
            return String(localized: "today_section_unscheduled", bundle: PresentationResources.bundle)
        }
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
