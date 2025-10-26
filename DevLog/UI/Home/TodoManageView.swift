//
//  TodoManageView.swift
//  DevLog
//
//  Created by opfic on 6/16/25.
//

import SwiftUI

struct TodoManageView: View {
    @EnvironmentObject var homeVM: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(homeVM.todoKinds, id: \.self.id) { kind in
                    HStack(spacing: 0) {
                        CheckBox(isChecked: .constant(homeVM.selectedTodoKinds.contains(kind)), font: .title3)
                            .padding(.horizontal)
                            .onTapGesture {
                                if homeVM.selectedTodoKinds.contains(kind) {
                                    if homeVM.selectedTodoKinds.count > 1 {
                                        homeVM.selectedTodoKindStrings.removeAll { $0 == kind.rawValue }
                                    }
                                } else {
                                    let currIdx = homeVM.todoKindStrings.firstIndex(of: kind.rawValue)!
                                    var prevIdx = 0
                                    for idx in stride(from: currIdx - 1, through: 0, by: -1)
                                    where homeVM.selectedTodoKindStrings
                                        .contains(homeVM.todoKindStrings[idx]) {
                                        prevIdx = idx
                                        break
                                    }
                                    homeVM.selectedTodoKindStrings.insert(kind.rawValue, at: prevIdx)
                                }
                            }
                        Text(kind.localizedName)
                    }
                }
                .onMove { (source: IndexSet, destination: Int) in
                    homeVM.todoKindStrings.move(fromOffsets: source, toOffset: destination)
                    let selectedSet = Set(homeVM.selectedTodoKindStrings)
                    let newSelectedOrder = homeVM.todoKindStrings.filter { selectedSet.contains($0) }
                    homeVM.selectedTodoKindStrings = newSelectedOrder
                }
                .listRowInsets(EdgeInsets())
            }
            .environment(\.editMode, .constant(EditMode.active))
            .navigationTitle("TODO 편집")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("완료")
                    }
                }
            }
        }
        .environment(\.editMode, .constant(EditMode.active))    //  편집 모드 활성화 (row 우측에 line.3.horizontal 추가됨)
    }
}

#Preview {
    TodoManageView()
        .environmentObject(AppContainer.shared.homeVM)
}
