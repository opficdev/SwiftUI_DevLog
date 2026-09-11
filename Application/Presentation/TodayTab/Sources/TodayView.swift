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

//    public var body: some View {
//        NavigationStack(path: $path) {
//            List {
//                summarySection
//                if store.sections.isEmpty, !store.isLoading {
//                    emptySection
//                } else {
//                    ForEach(store.sections) { section in
//                        todoSection(section.title, items: section.items)
//                    }
//                }
//            }
//            .listStyle(.insetGrouped)
//            .navigationTitle(String(localized: "nav_today", bundle: PresentationResources.bundle))
//            .navigationDestination(for: TodayRoute.self, destination: destinationView)
//            .toolbar { toolbarContent }
//            .background(NavigationBarConfigurator())
//            .refreshable { await store.send(.refresh).finish() }
//        }
//        .onChange(of: isSelected, initial: true) { _, isSelected in
//            if isSelected {
//                store.send(.fetchData)
//            }
//        }
//        .prominentAlert(store, state: \.alert, action: \.alert)
//        .overlay {
//            if store.isLoading {
//                LoadingView()
//            }
//        }
//    }

    public var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(pinnedViews: [.sectionHeaders]) {
                    Section {

                    } header: {

                    }
                }
            }
        }
    }

    private var topBar: some View {
        VStack {
            HStack {
                Text("오늘 할 일 달성")
                Text("진행 중")
                Spacer()
                HStack(spacing: 8) {
//                    let todayTodos = store.todos.filter { $0.dueDate.}
//                    Text(store.todos.filter { $0.})
                }
            }
        }
    }

    private func destinationView(_ route: TodayRoute) -> some View {
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

    private var summarySection: some View {
        Section {
            ScrollView(.horizontal) {
                let summaryCounts = store.summaryCounts
                let selectedSectionScope = store.selectedSectionScope

                HStack(spacing: 12) {
                    ForEach(TodayFeature.SectionScope.allCases, id: \.self) { scope in
                        Button {
                            withAnimation(SwiftUI.Animation.easeInOut) {
                                _ = store.send(.setSectionScope(scope))
                            }
                        } label: {
                            SummaryCard(
                                title: scope.title,
                                value: summaryCounts[scope, default: 0],
                                accentColor: scope.accentColor,
                                isSelected: selectedSectionScope == scope
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .scrollIndicators(.never)
            .contentMargins(.horizontal, 16)
        }
        .listRowInsets(EdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0))
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Picker(
                    String(localized: "today_due_visibility_label", bundle: PresentationResources.bundle),
                    selection: $store.displayOptions.dueDateVisibility
                ) {
                    ForEach(TodayDisplayOptions.DueDateVisibility.allCases, id: \.self) { option in
                        Text(option.title).tag(option)
                    }
                }

                Toggle(
                    String(localized: "today_pinned_only", bundle: PresentationResources.bundle),
                    isOn: $store.displayOptions.isFocusedOnly
                )
                .tint(.orange)

                if store.displayOptions.focusVisibility == .focusedOnly {
                    Text(String(localized: "today_pinned_only_description", bundle: PresentationResources.bundle))
                        .font(.caption)
                }
            } label: {
                let options = store.displayOptions
                Image(systemName: "line.3.horizontal.decrease.circle\(options == .default ? "" : ".fill")")
            }
        }
    }

    private var emptySection: some View {
        Section {
            VStack(spacing: 8) {
                Text(emptyStateContent.title)
                    .foregroundStyle(.primary)
                Text(emptyStateContent.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
        }
    }

    @ViewBuilder
    private func todoSection(_ title: String, items: [TodayTodoItem]) -> some View {
        if !items.isEmpty {
            Section {
                ForEach(items) { item in
                    todoRow(item)
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            store.send(.togglePinned(item))
                        } label: {
                            Image(systemName: item.isPinned ? "star.slash" : "star.fill")
                        }
                        .tint(.orange)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            store.send(.completeTodo(item))
                        } label: {
                            Label(
                                String(
                                    localized: "today_complete_action",
                                    bundle: PresentationResources.bundle
                                ),
                                systemImage: "checkmark"
                            )
                        }
                        .tint(.green)
                    }
                }
            } header: {
                Text(title)
                    .listRowInsets(EdgeInsets())
            }
        }
    }

    @ViewBuilder
    private func todoRow(_ item: TodayTodoItem) -> some View {
        NavigationLink(value: TodayRoute.todo(TodoIdItem(id: item.id))) {
            TodayTodoRow(item: item)
        }
        .todoDetailPreview(todoId: item.id)
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

    var accentColor: Color {
        switch self {
        case .all:
            return .blue
        case .focused:
            return .orange
        case .overdue:
            return .red
        case .dueSoon:
            return .green
        }
    }
}

private struct SummaryCard: View {
    let title: String
    let value: Int
    let accentColor: Color
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption)
                .foregroundStyle(isSelected ? accentColor : .secondary)
            Text("\(value)")
                .font(.title2.bold())
                .foregroundStyle(Color(.label))
        }
        .frame(width: 96, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? accentColor.opacity(0.2) : accentColor.opacity(0.12))
                .strokeBorder(
                    isSelected ? accentColor.opacity(0.55) : accentColor.opacity(0.18),
                    lineWidth: isSelected ? 1.5 : 1
                )
        )
        .scaleEffect(isSelected ? 1 : 0.98)
    }
}

private struct TodayTodoRow: View {
    private let calendar = Calendar.current
    let item: TodayTodoItem

    var body: some View {
        let todoCategoryItem = TodoCategoryItem(from: item.category)
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: todoCategoryItem.symbolName)
                    .foregroundStyle(todoCategoryItem.color)
                    .frame(width: 18)
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(Color(.label))
                    .lineLimit(1)
                Text("#\(item.number)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.gray)
                    .fixedSize(horizontal: true, vertical: false)
                Spacer()
            }

            HStack(spacing: 8) {
                Text(todoCategoryItem.localizedName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(todoCategoryItem.color)

                if let dueDate {
                    Text(dueDate.text)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(dueDate.textColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(dueDate.backgroundColor)
                        )
                }
            }

            if !item.tags.isEmpty {
                TagList(item.tags, lineLimit: 1)
            }
        }
    }

    private var dueDate: DueDateBadge? {
        guard let date = item.dueDate else { return nil }
        let today = calendar.startOfDay(for: Date())
        let dueDay = calendar.startOfDay(for: date)

        if dueDay < today {
            return DueDateBadge(
                text: String(localized: "today_due_overdue", bundle: PresentationResources.bundle),
                textColor: .red,
                backgroundColor: Color.red.opacity(0.12)
            )
        }

        let formatted = date.formatted(date: .abbreviated, time: .omitted)
        return DueDateBadge(
            text: formatted,
            textColor: .blue,
            backgroundColor: Color.blue.opacity(0.12)
        )
    }

    private struct DueDateBadge {
        let text: String
        let textColor: Color
        let backgroundColor: Color
    }
}
