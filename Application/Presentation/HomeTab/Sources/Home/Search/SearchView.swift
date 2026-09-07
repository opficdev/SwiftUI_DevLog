//
//  SearchView.swift
//  HomeTab
//
//  Created by 최윤진 on 2/12/26.
//

import SwiftUI
import Domain
import PresentationShared

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var router = NavigationRouter<Path>()
    @State var store: StoreOf<SearchFeature>

    init(store: StoreOf<SearchFeature>) {
        self.store = store
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            searchableContent
                .navigationDestination(for: Path.self) { path in
                    switch path {
                    case .todo(let todoId):
                        TodoDetailView(store: Store(
                            initialState: TodoDetailFeature.State(todoId: todoId, showEditButton: true)
                        ) {
                            TodoDetailFeature()
                        })
                    case .web(let page):
                        WebView(url: page.url)
                            .ignoresSafeArea()
                            .toolbar {
                                ToolbarItem(placement: .principal) {
                                    Text(page.title)
                                        .bold()
                                }
                            }
                    }
                }
                .onAppear { store.send(.onAppear) }
                .onChange(of: store.isSearching) { _, isSearching in
                    if !isSearching {
                        dismiss()
                    }
                }
                .prominentAlert(store, state: \.alert, action: \.alert)
        }
    }

    @ViewBuilder
    private var searchableContent: some View {
        Group {
            if store.searchQuery.isEmpty {
                if store.recentQueries.isEmpty {
                    searchInstruction
                } else {
                    ScrollView {
                        recentQueries
                    }
                }
            } else if store.isHashOnlyQuery {
                hashGuide
            } else if store.isLoading {
                LoadingView()
            } else if store.webPages.isEmpty && store.todos.isEmpty {
                emptySearchResult
            } else {
                ScrollView {
                    searchResults
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .searchable(
            text: $store.searchQuery,
            isPresented: $store.isSearching,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: Text(String(localized: "search_prompt"))
        )
        .onSubmit(of: .search) {
            store.send(.addRecentQuery(store.searchQuery))
        }
    }

    private var searchInstruction: some View {
        VStack {
            Spacer()
            Text(String(localized: "search_instruction"))
                .foregroundStyle(Color.gray)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var emptySearchResult: some View {
        VStack {
            Spacer()
            Text(String(localized: "search_empty"))
                .foregroundStyle(Color.gray)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var hashGuide: some View {
        VStack(spacing: 8) {
            Spacer()
            Text(String(localized: "search_hash_guide_title"))
                .font(.headline)
                .foregroundStyle(Color(.label))
            Text(String(localized: "search_hash_guide_message"))
                .font(.subheadline)
                .foregroundStyle(Color.gray)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
    }

    private var searchResults: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !store.todos.isEmpty {
                todoResults
            }
            if !store.webPages.isEmpty {
                webPages
            }
        }
        .padding(.vertical, 8)
    }

    private var todoResults: some View {
        let todos = store.visibleTodos

        return VStack(alignment: .leading, spacing: 12) {
            Text("Todos")
                .font(.headline)
                .foregroundStyle(Color(.label))
            Divider()
            LazyVStack(spacing: 0) {
                ForEach(todos, id: \.id) { todo in
                    todoResultRow(todo)
                }
            }
            .padding(.top, -12)
            if store.shouldShowMoreTodos {
                Button(String(localized: "search_show_more")) {
                    store.send(.setShowAllTodos(true))
                }
                .font(.subheadline)
                .foregroundStyle(Color.gray)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 16)
    }

    private var webPages: some View {
        let pages = store.visibleWebPages

        return VStack(alignment: .leading, spacing: 12) {
            Text("Web Pages")
                .font(.headline)
                .foregroundStyle(Color(.label))
            Divider()
            LazyVStack(spacing: 0) {
                ForEach(pages, id: \.id) { page in
                    webResultRow(page)
                }
            }
            .padding(.top, -12)
            if store.shouldShowMoreWebPages {
                Button(String(localized: "search_show_more")) {
                    store.send(.setShowAllWebPages(true))
                }
                .font(.subheadline)
                .foregroundStyle(Color.gray)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 16)
    }

    private func todoResultRow(_ item: TodoListItem) -> some View {
        Button {
            router.push(Path.todo(item.id))
        } label: {
            VStack(spacing: 0) {
                TodoItemRow(item)
                Divider()
            }
        }
        .todoDetailPreview(todoId: item.id)
    }

    private func webResultRow(_ item: WebPageItem) -> some View {
        NavigationLink(value: Path.web(item)) {
            VStack(spacing: 0) {
                WebItemRow(item: item, showsChevron: true)
                Divider()
            }
        }
    }

    private var recentQueries: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "search_recent"))
                    .font(.headline)
                    .foregroundStyle(Color(.label))
                Spacer()
                Button(String(localized: "search_clear_all")) {
                    store.send(.clearRecentQueries)
                }
                .font(.subheadline)
                .foregroundStyle(Color.gray)
            }

            ForEach(store.recentQueries, id: \.self) { query in
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(Color.gray)
                    Text(query)
                        .foregroundStyle(Color.primary)
                    Spacer()
                    Button {
                        store.send(.removeRecentQuery(query))
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.gray)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    store.send(.binding(.set(\.searchQuery, query)))
                    store.send(.binding(.set(\.isSearching, true)))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private enum Path: Hashable {
        case todo(String)
        case web(WebPageItem)
    }
}
