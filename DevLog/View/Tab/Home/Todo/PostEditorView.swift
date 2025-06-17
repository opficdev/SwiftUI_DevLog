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
    @State private var dueDate: Date = Date()
    @State private var content: String = ""
    @State private var tags: [String] = []
    @State private var focusOnEditor: Bool = false
    @FocusState private var focusOnTagField: Bool
    @State private var tagText: String = ""
    @State private var hasDueDate: Bool = true
    
    init(title: String, todo: Todo? = nil) {
        self.navigationTitle = title
        if let todo = todo {
            self._title = State(initialValue: todo.title)
            self._dueDate = State(initialValue: todo.dueDate ?? Date())
            self._content = State(initialValue: todo.content)
            self._tags = State(initialValue: todo.tags)
            self._hasDueDate = State(initialValue: todo.dueDate != nil)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    TextField("", text: $title,
                        prompt: Text("제목").foregroundColor(Color.gray)
                    )
                    .font(.title3)
                    .padding(.horizontal)
                    Divider()
                    HStack {
                        DatePicker("마감일", selection: $dueDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .disabled(!hasDueDate)
                        .foregroundStyle(hasDueDate ? Color.primary : Color.gray)
                        Divider()
                        Button(action: {
                            hasDueDate.toggle()
                            dueDate = Date()
                        }) {
                            CheckBox(isChecked: $hasDueDate)
                        }
                    }
                    .padding(.horizontal)
                    Divider()
                    HStack {
                        Text("태그")
                            .foregroundStyle(tags.isEmpty ? Color.gray : Color.primary)
                        Divider()
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(tags, id: \.self) { tag in
                                    HStack {
                                        Text(tag)
                                        Button(action: {
                                            if let index = tags.firstIndex(of: tag) {
                                                tags.remove(at: index)
                                            }
                                        }) {
                                            Image(systemName: "xmark")
                                                .font(.caption)
                                                .foregroundStyle(Color.gray)
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                    .background(
                                        Capsule()
                                            .fill(Color(UIColor.systemFill))
                                    )
                                }
                                TextField("", text: $tagText)
                                    .focused($focusOnTagField)
                                    .onSubmit {
                                        if !tagText.isEmpty {
                                            tags.append(tagText)
                                            tagText = ""
                                            focusOnTagField = false
                                        }
                                    }
                                    .onChange(of: focusOnTagField) { newValue in
                                        if !newValue && !tagText.isEmpty {
                                            tags.append(tagText)
                                            tagText = ""
                                        }
                                    }
                            }
                        }
                        Divider()
                        Button(action: {
                            focusOnTagField.toggle()
                        }) {
                            Image(systemName: "\(focusOnTagField ? "xmark" : "plus").circle.fill")
                                .foregroundStyle(Color.gray)
                                .font(.title2)
                        }
                    }
                    .padding(.horizontal)
                    Divider()
                    UIKitTextEditor(text: $content, isFocused: $focusOnEditor, placeholder: "내용을 입력하세요.")
                        .padding(.horizontal)
                }
            }
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
                                dueDate: hasDueDate ? dueDate : nil,
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

#Preview {
    PostEditorView(title: "새 Todo")
        .environmentObject(AppContainer.shared.todoVM(kind: .etc))
}
