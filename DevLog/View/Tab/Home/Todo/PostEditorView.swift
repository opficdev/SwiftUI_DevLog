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
    
    init(title: String) {
        self.navigationTitle = title
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    TextField("제목", text: $title)
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
                            ZStack {
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.gray, lineWidth: 1)
                                    .frame(width: 15, height: 15)
                                if hasDueDate {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    Divider()
                    HStack {
                        Text("태그")
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
                                            .stroke(Color.gray, lineWidth: 1)
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
                            focusOnTagField = true
                        }) {
                            Image(systemName: "pencil")
                                .foregroundStyle(Color.gray)
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
