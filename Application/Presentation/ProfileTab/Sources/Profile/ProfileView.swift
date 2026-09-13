//
//  ProfileView.swift
//  ProfileTab
//
//  Created by opfic on 5/7/25.
//

// swiftlint:disable file_length
import SwiftUI
import Core
import Domain
import PresentationShared

public struct ProfileView: View {
    @State private var settingsStore: StoreOf<SettingsFeature>
    @State private var store: StoreOf<ProfileFeature>
    @State private var path = [ProfileRoute]()
    private let isSelected: Bool
    private let windowEvent: TodoEditorWindowEvent

    public init(
        isSelected: Bool,
        windowEvent: TodoEditorWindowEvent
    ) {
        let store = Store(initialState: ProfileFeature.State()) {
            ProfileFeature()
        }
        let settingsStore = Store(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
        self._store = State(initialValue: store)
        self._settingsStore = State(initialValue: settingsStore)
        self.isSelected = isSelected
        self.windowEvent = windowEvent
    }

    public var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16, pinnedViews: [.sectionHeaders]) {
                    Section {
                        ProfileCard(store: store, isSelected: isSelected)
                        RecentActivityCard(store: store) { todoId in
                            path.append(.recentTodo(todoId))
                        }
                    } header: { titleBar }
                }
                .padding(.horizontal, 16)
            }
            .refreshable { await store.send(.refresh).finish() }
            .toolbarVisibility(.hidden, for: .navigationBar)
            .background(Color.appBackground)
            .navigationDestination(for: ProfileRoute.self, destination: destinationView)
        }
        .onChange(of: isSelected, initial: true) { _, isSelected in
            if isSelected {
                store.send(.fetchData)
            }
        }
        .onAppear {
            store.send(.startObserving)
            settingsStore.send(.startObserving)
        }
        .prominentAlert(store, state: \.alert, action: \.alert)
        .sheet(
            isPresented: $store.showQuarterPicker.activePresentation(when: isSelected)
        ) { quarterPickerSheet }
        .overlay {
            if store.isLoading {
                LoadingView()
            }
        }
    }

    private var titleBar: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("프로필")
                    .font(.largeTitle.bold())
                Spacer()
                Button {
                    path.append(.settings)
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(Color.textTertiary)
                }
                .adaptiveButtonStyle()
            }
            Text("꾸준히 쌓아온 개발 기록을 확인하세요")
                .foregroundStyle(Color.textSecondary)
                .font(.caption)
        }
    }

    @ViewBuilder
    private func destinationView(_ route: ProfileRoute) -> some View {
        switch route {
        case .settings:
            SettingsView(store: settingsStore) { path.append($0) }
        case .activity(let todoId):
            TodoDetailView(store: Store(
                initialState: TodoDetailFeature.State(todoId: todoId, showEditButton: false)
            ) {
                TodoDetailFeature()
            })
        case .recentTodo(let todoId):
            TodoDetailView(store: Store(
                initialState: TodoDetailFeature.State(todoId: todoId, showEditButton: true)
            ) {
                TodoDetailFeature()
            }, windowEvent: windowEvent)
        case .theme:
            ThemeView(theme: $settingsStore.theme)
        case .pushNotification:
            PushNotificationSettingsView(store: Store(
                initialState: PushNotificationSettingsFeature.State()
            ) {
                PushNotificationSettingsFeature()
            })
        case .account:
            AccountView(store: Store(initialState: AccountFeature.State()) {
                AccountFeature()
            })
        }
    }

    private var activityHeatmapSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(String(localized: "profile_quarterly_activity", bundle: PresentationResources.bundle))
                    .font(.headline)
                Spacer()
                if !store.isViewingCurrentQuarter {
                    Button {
                        store.send(.moveToCurrentQuarter)
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .bold()
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                }
                Menu {
                    ForEach(ActivityKindItem.selectableItems) { activityKindItem in
                        if let activityKind = ActivityKind(rawValue: activityKindItem.rawValue) {
                            switch activityKind {
                            case .created:
                                Toggle(activityKindItem.title, isOn: $store.isCreatedActivitySelected)
                                    .disabled(store.isCreatedActivityToggleDisabled)
                            case .completed:
                                Toggle(activityKindItem.title, isOn: $store.isCompletedActivitySelected)
                                    .disabled(store.isCompletedActivityToggleDisabled)
                            case .deleted:
                                Toggle(activityKindItem.title, isOn: $store.isDeletedActivitySelected)
                                    .disabled(store.isDeletedActivityToggleDisabled)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                        .bold()
                        .foregroundStyle(.blue)
                }
            }

            HStack {
                Button {
                    store.send(.moveQuarter(-1))
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(!store.canMoveToPreviousQuarter)
                Spacer()
                Button {
                    store.send(.openQuarterPicker)
                } label: {
                    HStack(spacing: 4) {
                        Text(store.quarterTitle)
                            .font(.subheadline)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                Spacer()
                Button {
                    store.send(.moveQuarter(1))
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(!store.canMoveToNextQuarter)
            }

            if let quarter = store.activityQuarter {
                HeatmapView(
                    quarter: quarter,
                    selectedActivityKinds: store.selectedActivityKinds,
                    selectedDay: store.selectedDay,
                    onSelectDay: { store.send(.selectDay($0)) }
                )
                if let selectedDay = store.selectedDay {
                    selectedDayDetailSection(for: selectedDay)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private var quarterPickerSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text(String(localized: "profile_year", bundle: PresentationResources.bundle))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Picker(
                        "",
                        selection: $store.selectedQuarterPickerYear
                    ) {
                        ForEach(store.availableQuarterYears, id: \.self) { year in
                            Text(verbatim: String(year))
                                .tag(year)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                    ForEach(1...4, id: \.self) { quarter in
                        quarterSelectionButton(for: quarter)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(20)
            .navigationTitle(String(localized: "profile_select_quarter", bundle: PresentationResources.bundle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarTrailingButton {
                    store.send(.setQuarterPickerPresented(false))
                }
            }
        }
        .presentationDetents([.fraction(0.3)])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func quarterSelectionButton(for quarter: Int) -> some View {
        let quarterStart = store.state.quarterStartForPicker(quarter: quarter)
        let isEnabled = store.state.isQuarterSelectableForPicker(quarter)
        let isSelected = store.state.isQuarterSelectedForPicker(quarter)

        Button {
            guard let quarterStart else { return }
            store.send(.selectQuarter(quarterStart))
        } label: {
            Text(
                String.localizedStringWithFormat(
                    String(localized: "profile_quarter_format", bundle: PresentationResources.bundle),
                    Int64(quarter)
                )
            )
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(.systemGray5))
            )
            .foregroundStyle(isSelected ? .white : isEnabled ? .primary : .secondary)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    @ViewBuilder
    private func selectedDayDetailSection(for day: HeatmapDay) -> some View {
        let activities = store.selectedDayActivities

        VStack(alignment: .leading, spacing: 12) {
            Text(day.date.formatted(.dateTime.year().month(.wide).day()))
                .font(.subheadline)
                .bold()

            if activities.isEmpty {
                Text(String(localized: "profile_activity_none", bundle: PresentationResources.bundle))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(activities) { activity in
                    Button {
                        selectActivity(activity)
                    } label: {
                        let item = TodoCategoryItem(from: activity.category)
                        let rowColor = activity.isDeleted ? Color.secondary : .primary
                        HStack(spacing: 8) {
                            Image(systemName: item.symbolName)
                                .foregroundStyle(item.color)
                                .frame(width: 20)
                            Text(activity.title)
                                .font(.caption)
                                .lineLimit(1)
                                .foregroundStyle(rowColor)
                            Text("#\(activity.number)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            ForEach(activity.activityKindItems) { item in
                                Text(item.title)
                                    .font(.caption2)
                                    .foregroundStyle(item.badgeColor)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(item.badgeColor.opacity(0.14))
                                    )
                            }
                            Spacer()
                            if !activity.isDeleted {
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .disabled(activity.isDeleted)
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(.top, 4)
    }

    private func selectActivity(_ activity: HeatmapActivityItem) {
        guard !activity.isDeleted else { return }
        path.append(.activity(activity.todoId))
    }
}

private struct ProfileCard: View {
    @Bindable var store: StoreOf<ProfileFeature>
    @FocusState private var focused: Bool
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Group {
                    if let data = store.avatarImageData?.data,
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.onPrimaryContainer, Color.primaryContainer)
                    }
                }
                .frame(width: 60, height: 60)
                .cornerRadius(30)
                .transaction { $0.animation = nil }

                VStack(alignment: .leading) {
                    Text(store.name)
                        .font(.title2)
                        .bold()
                    Text(store.email)
                        .font(.caption2)
                        .foregroundStyle(Color.gray)
                }
            }

            HStack {
                HStack {
                    Image(systemName: "face.smiling")
                    TextField(
                        text: $store.statusMessage
                    ) {
                        Text(String(localized: "profile_status_placeholder", bundle: PresentationResources.bundle))
                    }
                    .frame(height: UIFont.preferredFont(forTextStyle: .body).lineHeight)
                    .focused($focused)
                    .disabled(!store.isNetworkConnected)

                    if !store.statusMessage.isEmpty,
                       store.showDoneButton {
                        Button {
                            store.send(.tapResetStatusMessageButton)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                        }
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                .foregroundStyle(Color.onPrimaryContainer)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.primaryContainer)
                )
                if store.showDoneButton {
                    Button {
                        focused = false
                        store.send(.willUpdateStatusMessage)
                    } label: {
                        Text(String(localized: "profile_done", bundle: PresentationResources.bundle))
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .opacity(store.isNetworkConnected ? 1 : 0.7)
        }
        .onChange(of: isSelected, initial: true) { _, isSelected in
            if !isSelected {
                focused = false
            }
        }
        .onChange(of: focused) { _, focused in
            store.send(.updateStatusTextFieldFocus(focused), animation: .default)
        }
    }
}

// 개발 활동 카드
private struct DevActivityCard: View {
    @Bindable var store: StoreOf<ProfileFeature>

    var body: some View {

    }
}

// 개발 목표 카드
private struct DevAchieveMentCard: View {
    @Bindable var store: StoreOf<ProfileFeature>

    var body: some View {

    }
}

// 최근 활동 카드
private struct RecentActivityCard: View {
    @Bindable var store: StoreOf<ProfileFeature>
    @ScaledMetric(relativeTo: .largeTitle) private var labelWidth = CGFloat(34)
    let onSelectTodo: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "profile_recent_title", bundle: PresentationResources.bundle))
                .font(.title2.bold())

            Group {
                if store.isRecentTodosLoading && store.recentTodos.isEmpty {
                    LoadingView()
                        .frame(maxWidth: .infinity, minHeight: 80)
                } else if store.recentTodos.isEmpty {
                    Text(String(localized: "profile_recent_empty", bundle: PresentationResources.bundle))
                        .font(.callout)
                        .foregroundStyle(Color.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 80)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(store.recentTodos.enumerated()), id: \.element.id) { index, todo in
                            Button {
                                onSelectTodo(todo.id)
                            } label: {
                                HStack(spacing: 12) {
                                    RecentTodoRow(todo: todo)
                                    Spacer(minLength: 0)
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Color.textTertiary)
                                }
                                .contentShape(.rect)
                            }
                            .buttonStyle(.plain)
                            .todoDetailPreview(todoId: todo.id)
                            .padding(.vertical, 12)

                            if index < store.recentTodos.count - 1 {
                                Divider()
                                    .padding(.leading, labelWidth + 12)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }
}

private struct RecentTodoRow: View {
    @ScaledMetric(relativeTo: .largeTitle) private var labelWidth = CGFloat(34)
    let todo: RecentTodoItem

    var body: some View {
        let category = TodoCategoryItem(from: todo.category)
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(category.color)
                .frame(width: labelWidth, height: labelWidth)
                .overlay {
                    Image(systemName: category.symbolName)
                        .foregroundStyle(Color.white)
                        .font(.title3)
                }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    if todo.isPinned {
                        Image(systemName: "star.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                    Text(todo.title)
                        .foregroundStyle(Color.primary)
                        .font(.headline)
                        .lineLimit(1)
                    Text("#\(todo.number)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.gray)
                        .fixedSize(horizontal: true, vertical: false)
                }

                HStack(spacing: 6) {
                    Text(category.localizedName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(category.color)

                    RelativeTimeText(date: todo.updatedAt)
                }

                if !todo.tags.isEmpty {
                    TagList(todo.tags, lineLimit: 1)
                }
            }
        }
    }
}

enum ProfileRoute: Hashable {
    case settings
    case activity(String)
    case recentTodo(String)
    case theme
    case pushNotification
    case account
}
