//
//  SwiftUI_DevLogApp.swift
//  SwiftUI_DevLog
//
//  Created by opfic on 5/2/25.
//

import SwiftUI

@main
struct SwiftUI_DevLogApp: App {
    let persistenceController = PersistenceController.shared
    @AppStorage("theme") var theme: SystemTheme = .automatic

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(theme.colorScheme)
        }
    }
}
