//
//  CategoryManageView.swift
//  HomeTab
//
//  Created by opfic on 6/16/25.
//

import SwiftUI
import PresentationShared

struct CategoryManageView: View {
    @Bindable var store: StoreOf<CategoryManageFeature>

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.preferences, id: \.id) { item in
                    HStack(spacing: 0) {
                        CheckBox(isChecked: item.isVisible, font: .title3)
                            .padding(.horizontal)
                            .onTapGesture {
                                store.send(.tapItem(item))
                            }
                        Text(item.localizedName)
                            .lineLimit(1)
                        Spacer()
                        if item.isUserCategory {
                            Button {
                                store.send(.tapEditUserCategory(item))
                            } label: {
                                Image(systemName: "slider.horizontal.3")
                            }
                            .buttonStyle(.borderless)
                            .padding(.trailing, 8)

                            Button(role: .destructive) {
                                store.send(.tapDeleteUserCategory(item))
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                            .padding(.trailing)
                        }
                    }
                }
                .onMove { source, destination in
                    store.send(.moveItem(from: source, target: destination))
                }
                .listRowInsets(EdgeInsets())
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle(String(localized: "nav_todo_manage", bundle: PresentationResources.bundle))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .sheet(item: $store.scope(state: \.categorySheet, action: \.categorySheet)) { sheetStore in
                sheetContent(sheetStore)
            }
            .prominentAlert(store, state: \.alert, action: \.alert)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        store.send(.tapAddUserCategory)
                    } label: {
                        Image(systemName: "plus")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        store.send(.tapDoneButton, animation: .default)
                    } label: {
                        Text(String(localized: "profile_done", bundle: PresentationResources.bundle))
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func sheetContent(
        _ sheetStore: Store<CategoryManageFeature.CategorySheetState, CategoryManageFeature.Action.CategorySheet>
    ) -> some View {
        CategoryManageSheet(store: sheetStore)
    }
}

private struct CategoryManageSheet: View {
    @Bindable var store: Store<CategoryManageFeature.CategorySheetState, CategoryManageFeature.Action.CategorySheet>

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 8) {
                        TextField(
                            "",
                            text: $store.category.name,
                            prompt: Text(store.placeholder).foregroundStyle(.secondary)
                        )
                        .frame(height: UIFont.preferredFont(forTextStyle: .body).lineHeight)

                        Text(store.categoryNameCountText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }

                Section {
                    ColorPicker(selection: $store.category.colorHex.colorValue, supportsOpacity: false) {
                        Text(store.category.colorHex.isEmpty ? "#" : store.category.colorHex)
                            .overlay(alignment: .bottom) {
                                Rectangle()
                                    .frame(height: 1)
                                    .offset(y: 1)
                            }
                            .foregroundStyle(store.category.colorHex.colorValue)
                            .onTapGesture {
                                store.send(.tapRandomColorButton)
                            }
                    }
                    .pickerStyle(.palette)
                }
            }
            .navigationTitle(store.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "common_close", bundle: PresentationResources.bundle)) {
                        store.send(.tapCloseButton)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(store.submitTitle) {
                        store.send(.tapSaveButton)
                    }
                    .disabled(!store.canSubmitUserCategory)
                }
            }
        }
    }
}

private extension String {
    var colorValue: Color {
        get { Color(hexString: self) ?? .randomValue }
        set {
            if let hexValue = newValue.hexValue {
                self = hexValue
            }
        }
    }
}
