//
//  CategoryFilterSheet.swift
//  TodayTab
//
//  Created by opfic on 9/13/26.
//

import SwiftUI
import Core
import PresentationShared

struct CategoryFilterSheet: View {
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

extension TodayFeature.TodoScope {
    var title: String {
        switch self {
        case .remaining:
            return String(localized: "today_filter_remaining", bundle: PresentationResources.bundle)
        case .important:
            return String(localized: "today_filter_important", bundle: PresentationResources.bundle)
        }
    }
}
