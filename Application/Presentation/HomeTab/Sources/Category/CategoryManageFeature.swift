//
//  CategoryManageFeature.swift
//  HomeTab
//
//  Created by opfic on 6/11/26.
//

import Domain
import PresentationShared
import SwiftUI

@Reducer
struct CategoryManageFeature {
    @ObservableState
    struct State: Equatable {
        var preferences: [TodoCategoryItem]
        @Presents var categorySheet: CategorySheetState?
        @Presents var alert: AlertState<Action.Alert>?
    }

    @ObservableState
    struct CategorySheetState: Equatable {
        var category: UserTodoCategory
        var preferences: [TodoCategoryItem]

        var isEditing: Bool {
            preferences.contains { $0.id == category.id }
        }
        var navigationTitle: String {
            isEditing
                ? String(localized: "todo_manage_edit_category_title", bundle: PresentationResources.bundle)
                : String(localized: "todo_manage_add_category_title", bundle: PresentationResources.bundle)
        }
        var submitTitle: String {
            isEditing
                ? String(localized: "todo_manage_save", bundle: PresentationResources.bundle)
                : String(localized: "todo_add", bundle: PresentationResources.bundle)
        }
        var placeholder: String {
            category.name
        }
        var categoryNameCountText: String {
            "\(category.name.count)/20"
        }
        var canSubmitUserCategory: Bool {
            let name = category.name.trimmingCharacters(in: .whitespacesAndNewlines)
            if name.isEmpty {
                return false
            }

            if SystemTodoCategory.allCases.contains(where: {
                $0.rawValue.caseInsensitiveCompare(name) == .orderedSame
            }) {
                return false
            }

            if preferences.contains(where: { item in
                guard case .user(let userCategory) = item.category, userCategory.id != category.id else {
                    return false
                }

                return userCategory.name.caseInsensitiveCompare(name) == .orderedSame
            }) {
                return false
            }

            if let item = preferences.first(where: { $0.id == category.id }) {
                if case .user(let originalCategory) = item.category {
                    let originalName = originalCategory.name.trimmingCharacters(in: .whitespacesAndNewlines)
                    if originalName == name && originalCategory.colorHex == category.colorHex {
                        return false
                    }
                }
            }

            return true
        }
        var todoCategoryItem: TodoCategoryItem {
            TodoCategoryItem(
                from: .user(
                    UserTodoCategory(
                        id: category.id,
                        name: category.name.trimmingCharacters(in: .whitespacesAndNewlines),
                        colorHex: category.colorHex
                    )
                )
            )
        }
    }

    enum Action: Equatable {
        case alert(PresentationAction<Alert>)
        case categorySheet(PresentationAction<CategorySheet>)
        case delegate(Delegate)
        case tapAddUserCategory
        case moveItem(from: IndexSet, target: Int)
        case tapItem(TodoCategoryItem)
        case tapEditUserCategory(TodoCategoryItem)
        case tapDeleteUserCategory(TodoCategoryItem)
        case tapDoneButton
        case setCategorySheet(CategorySheetState?)

        enum Alert: Equatable {
            case confirmDeleteUserCategory(TodoCategoryItem)
        }

        enum Delegate: Equatable {
            case done([TodoCategoryItem])
        }

        enum CategorySheet: BindableAction, Equatable {
            case binding(BindingAction<CategorySheetState>)
            case tapCloseButton
            case tapRandomColorButton
            case tapSaveButton
        }
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .alert(.presented(.confirmDeleteUserCategory(let item))):
                if let index = state.preferences.firstIndex(where: { $0.id == item.id }) {
                    state.preferences.remove(at: index)
                }
            case .alert:
                break
            case .delegate:
                break
            case .categorySheet(.dismiss):
                state.categorySheet = nil
            case .categorySheet(.presented(.tapCloseButton)):
                state.categorySheet = nil
            case .categorySheet(.presented(.tapSaveButton)):
                if var item = state.categorySheet?.todoCategoryItem {
                    if let index = state.preferences.firstIndex(where: { $0.id == item.id }) {
                        item.isVisible = state.preferences[index].isVisible
                        state.preferences[index] = item
                    } else {
                        state.preferences.append(item)
                    }

                    state.categorySheet = nil
                }
            case .categorySheet:
                break
            case .tapAddUserCategory:
                if let randomHexValue = Color.randomValue.hexValue {
                    state.categorySheet = CategorySheetState(
                        category: UserTodoCategory(
                            id: UUID().uuidString.lowercased(),
                            name: "",
                            colorHex: randomHexValue
                        ),
                        preferences: state.preferences
                    )
                }
            case .moveItem(let from, let target):
                state.preferences.move(fromOffsets: from, toOffset: target)
            case .tapItem(let item):
                if let index = state.preferences.firstIndex(where: { $0.id == item.id }) {
                    state.preferences[index].isVisible.toggle()
                }
            case .tapEditUserCategory(let item):
                if item.isUserCategory, case .user(let category) = item.category {
                    state.categorySheet = CategorySheetState(
                        category: category,
                        preferences: state.preferences
                    )
                }
            case .tapDeleteUserCategory(let item):
                if item.isUserCategory {
                    state.alert = Self.deleteAlertState(for: item)
                }
            case .tapDoneButton:
                return .send(.delegate(.done(state.preferences)))
            case .setCategorySheet(let sheet):
                state.categorySheet = sheet
            }
            return .none
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$categorySheet, action: \.categorySheet) {
            CategoryManageSheetFeature()
        }
    }
}

private struct CategoryManageSheetFeature: Reducer {
    typealias State = CategoryManageFeature.CategorySheetState
    typealias Action = CategoryManageFeature.Action.CategorySheet

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(\.category.name):
                state.category.name = String(state.category.name.prefix(20))
            case .binding:
                break
            case .tapRandomColorButton:
                if let randomHexValue = Color.randomValue.hexValue {
                    state.category.colorHex = randomHexValue
                }
            case .tapCloseButton, .tapSaveButton:
                break
            }
            return .none
        }
    }
}

private extension CategoryManageFeature {
    static func deleteAlertState(for item: TodoCategoryItem) -> AlertState<Action.Alert> {
        AlertState {
            TextState(String(localized: "todo_manage_delete_category_title", bundle: PresentationResources.bundle))
        } actions: {
            ButtonState(role: .cancel) {
                TextState(String(localized: "common_cancel", bundle: PresentationResources.bundle))
            }
            ButtonState(role: .destructive, action: .confirmDeleteUserCategory(item)) {
                TextState(String(localized: "common_delete", bundle: PresentationResources.bundle))
            }
        } message: {
            TextState(String(localized: "todo_manage_delete_category_message", bundle: PresentationResources.bundle))
        }
    }
}
