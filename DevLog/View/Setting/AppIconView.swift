//
//  AppIconView.swift
//  DevLog
//
//  Created by opfic on 5/14/25.
//

import SwiftUI

struct AppIconView: View {
    @AppStorage("appIcon") var appIcon: AppIcon = .primary
    @EnvironmentObject var settingVM: SettingViewModel
    @State private var showAlert = false
    let icons: [String] = {
        guard let iconsDict = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any] else { return [] }
        var iconNames: [String] = []

        // Primary icon
        if let primary = iconsDict["CFBundlePrimaryIcon"] as? [String: Any],
           let primaryFiles = primary["CFBundleIconFiles"] as? [String],
           let primaryName = primaryFiles.first {
            iconNames.append(primaryName)
        }

        // Alternate icons
        if let alternates = iconsDict["CFBundleAlternateIcons"] as? [String: Any] {
            for (key, value) in alternates {
                if let altDict = value as? [String: Any],
                   let altFiles = altDict["CFBundleIconFiles"] as? [String],
                   let altName = altFiles.first {
                    iconNames.append(altName)
                }
            }
        }

        guard iconNames.count > 1 else { return iconNames }
        let primary = iconNames.first!
        let sortedRest = iconNames.dropFirst().sorted {
            let name1 = AppIcon(iconName: $0)?.localizedName ?? $0
            let name2 = AppIcon(iconName: $1)?.localizedName ?? $1
            return name1.localizedStandardCompare(name2) == .orderedAscending
        }
        return [primary] + sortedRest
    }()
    
    
    var body: some View {
        List(icons, id: \.self) { icon in
            Button(action: {
                appIcon = AppIcon(iconName: icon) ?? .primary
                Task {
                    do {
                        let icon = icon == "Primary" ? nil : icon
                        try await settingVM.setAppIcon(iconName: icon)
                    } catch {
                        showAlert = true
                    }
                }
            }) {
                HStack {
                    Image(icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                    Text(AppIcon(iconName: icon)?.localizedName ?? "")
                        .foregroundStyle(Color.primary)
                    Spacer()
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                        .opacity(icon.lowercased() == appIcon.rawValue ? 1 : 0)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("앱 아이콘")
        .alert("로고 변경", isPresented: $showAlert) {
            Button("확인", role: .cancel) {
                showAlert = false
            }
        } message: {
            Text("로고 변경에 실패했습니다.")
        }
    }
}

#Preview {
    AppIconView()
        .environmentObject(SettingViewModel())
}
