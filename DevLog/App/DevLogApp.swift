//
//  DevLogApp.swift
//  DevLog
//
//  Created by opfic on 5/2/25.
//

import SwiftUI

@main
struct DevLogApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @AppStorage("theme") var theme: SystemTheme = .automatic
    @StateObject private var container = AppContainer.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(container)
                .environmentObject(container.loginVM)
                .preferredColorScheme(theme.colorScheme)
        }
    }
}
