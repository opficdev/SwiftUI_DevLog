//
//  MainTabBar.swift
//  Entry
//
//  Created by opfic on 9/9/26.
//

import SwiftUI
import PresentationShared

struct MainTabBar: View {
    @Binding var selectedTab: MainTab
    let unreadPushCount: Int

    var body: some View {
        ExposableTabBar(
            selection: $selectedTab,
            items: MainTab.allCases
        ) { tab, isSelected in
            VStack(spacing: 3) {
                tabIcon(tab)
                Text(tab.title)
                    .font(.caption2)
            }
            .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 2)
        .background {
            Rectangle()
                .fill(Color(asset: .surface))
                .ignoresSafeArea(edges: .bottom)
        }
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private func tabIcon(_ tab: MainTab) -> some View {
        Image(systemName: tab.symbolName)
            .font(.system(size: 20))
            .frame(height: 22)
            .overlay(alignment: .topTrailing) {
                if tab == .notification, 0 < unreadPushCount {
                    Text(unreadPushCount < 100 ? "\(unreadPushCount)" : "99+")
                        .font(.caption2.bold())
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 5)
                        .frame(minWidth: 18, minHeight: 18)
                        .background(Color.red, in: Capsule())
                        .offset(x: 14, y: -7)
                }
            }
    }
}
