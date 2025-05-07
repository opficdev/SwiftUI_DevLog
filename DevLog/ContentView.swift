//
//  ContentView.swift
//  SwiftUI_DevLog
//
//  Created by opfic on 5/2/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack {
                    
                }
                .navigationTitle("Dev Log")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 0) {
                        NavigationLink(destination: SettingView()) {
                            Image(systemName: "gearshape")
                        }
                        Button(action: {
                            
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
    }
}


#Preview {
    ContentView()
}
