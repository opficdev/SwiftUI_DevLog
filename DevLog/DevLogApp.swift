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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(theme.colorScheme)
        }
    }
}
