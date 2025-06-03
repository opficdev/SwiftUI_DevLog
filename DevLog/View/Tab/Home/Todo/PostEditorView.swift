//
//  PostEditorView.swift
//  DevLog
//
//  Created by opfic on 5/31/25.
//

import SwiftUI

struct PostEditorView: View {
    @EnvironmentObject private var todoVM: TodoViewModel
    @Environment(\.dismiss) private var dismiss
    private var navigationTitle: String
    @State private var title: String = ""
    @State private var dueDate: Date? = nil
    @State private var content: String = ""
    @State private var tags: [String] = []
    @State private var isFocused: Bool = false
    
    init(title: String) {
        self.navigationTitle = title
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    TextField("제목", text: $title)
                        .font(.title3)
                        .padding(.horizontal)
                    Divider()
                    DatePicker("마감일", selection: Binding<Date>(
                        get: { dueDate ?? Date() },
                        set: { dueDate = $0 }
                    ), displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .padding(.horizontal)
                    Divider()
                    ScrollView {
                        HStack {
                            HStack {
                                
                            }
                        }
                    }
                    Divider()
                    UIKitTextEditor(text: $content, isFocused: $isFocused, placeholder: "내용을 입력하세요.")
                        .padding(.horizontal)
                }
            }
            .listStyle(.plain)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")}
                    .bold()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        Task {
                            let todo = Todo(
                                title: title,
                                content: content,
                                tags: tags,
                                kind: todoVM.kind
                            )
                            await todoVM.upsertTodoTask(todo)
                            dismiss()
                        }
                    }) {
                        Text("추가")
                    }
                }
            }
        }
    }
}
