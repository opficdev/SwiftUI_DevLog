//
//  ExposableTabBar.swift
//  PresentationShared
//
//  Created by opfic on 9/9/26.
//

import SwiftUI

public struct ExposableTabContent<Item: Hashable, Content: View>: View {
    @Binding private var selection: Item
    @State private var visitedItems: Set<Item>
    private let items: [Item]
    private let content: (Item, Bool) -> Content

    public init(
        selection: Binding<Item>,
        items: [Item],
        @ViewBuilder content: @escaping (Item, Bool) -> Content
    ) {
        self._selection = selection
        self._visitedItems = State(initialValue: [selection.wrappedValue])
        self.items = items
        self.content = content
    }

    public var body: some View {
        ZStack {
            ForEach(items, id: \.self) { item in
                if visitedItems.contains(item) || selection == item {
                    let isSelected = selection == item
                    content(item, isSelected)
                        .environment(\.isExposableTabContentActive, isSelected)
                        .opacity(isSelected ? 1 : 0)
                        .allowsHitTesting(isSelected)
                        .zIndex(isSelected ? 1 : 0)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: selection) { _, item in
            visitedItems.insert(item)
        }
    }
}

public struct ExposableTabBar<Item: Hashable, Label: View>: View {
    @Binding private var selection: Item
    private let items: [Item]
    private let label: (Item, Bool) -> Label

    public init(
        selection: Binding<Item>,
        items: [Item],
        @ViewBuilder label: @escaping (Item, Bool) -> Label
    ) {
        self._selection = selection
        self.items = items
        self.label = label
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.self) { item in
                Button {
                    selection = item
                } label: {
                    label(item, selection == item)
                        .frame(maxWidth: .infinity)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

public extension View {
    func exposableTabBar<TabBar: View>(
        isPresented: Bool,
        @ViewBuilder content: @escaping () -> TabBar
    ) -> some View {
        modifier(
            ExposableTabBarModifier(
                isPresented: isPresented,
                tabBar: content
            )
        )
    }

}

public extension EnvironmentValues {
    var isExposableTabContentActive: Bool {
        get { self[ExposableTabContentActiveKey.self] }
        set { self[ExposableTabContentActiveKey.self] = newValue }
    }

    private struct ExposableTabContentActiveKey: EnvironmentKey {
        static let defaultValue = true
    }
}

public extension Binding where Value == Bool {
    func activePresentation(when isActive: Bool) -> Binding {
        Binding(
            get: { isActive && wrappedValue },
            set: { isPresented in
                if isActive || !isPresented {
                    wrappedValue = isPresented
                }
            }
        )
    }
}

public extension Binding {
    func activePresentation<Wrapped>(when isActive: Bool) -> Binding<Wrapped?>
    where Value == Wrapped? {
        Binding<Wrapped?>(
            get: { isActive ? wrappedValue : nil },
            set: { value in
                switch value {
                case .some:
                    if isActive {
                        wrappedValue = value
                    }
                case .none:
                    wrappedValue = nil
                }
            }
        )
    }
}

private struct ExposableTabBarModifier<TabBar: View>: ViewModifier {
    let isPresented: Bool
    @ViewBuilder let tabBar: () -> TabBar

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            if isPresented {
                tabBar()
            }
        }
    }
}

public extension View {
    func exposableSideBar<SideBar: View>(
        isPresented: Binding<Bool>,
        showsToggle: Bool,
        @ViewBuilder content: @escaping () -> SideBar
    ) -> some View {
        modifier(
            ExposableSideBarModifier(
                isPresented: isPresented,
                showsToggle: showsToggle,
                sideBar: content
            )
        )
    }
}

private struct ExposableSideBarModifier<SideBar: View>: ViewModifier {
    @Binding var isPresented: Bool
    let showsToggle: Bool
    @ViewBuilder let sideBar: () -> SideBar

    func body(content: Content) -> some View {
        HStack(spacing: 0) {
            sideBarArea
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .overlay(alignment: .topLeading) {
            if showsToggle {
                Button {
                    isPresented.toggle()
                } label: {
                    Image(systemName: "sidebar.left")
                        .font(.headline)
                        .adaptiveButtonStyle()
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
                .padding(.leading, 8)
            }
        }
        .animation(.snappy, value: isPresented)
    }

    @ViewBuilder
    private var sideBarArea: some View {
        if isPresented {
            HStack(spacing: 0) {
                sideBar()
                Divider()
            }
            .transition(.move(edge: .leading).combined(with: .opacity))
        } else {
            Color.clear
                .frame(width: 0)
                .allowsHitTesting(false)
        }
    }
}
