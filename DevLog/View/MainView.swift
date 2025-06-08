//
//  MainView.swift
//  DevLog
//
//  Created by opfic on 5/8/25.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var container: AppContainer
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("홈")
                }
            NotificationView()
                .tabItem {
                    Image(systemName: "bell.fill")
                    Text("알림")
                }
            SearchView(searchVM: container.searchVM)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("검색")
                }
            ProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle.fill")
                    Text("프로필")
                }
        }
    }
}
