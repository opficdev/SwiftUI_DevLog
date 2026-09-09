//
//  SettingsView.swift
//  ProfileTab
//
//  Created by opfic on 5/6/25.
//

import SwiftUI
import Domain
import PresentationShared

struct SettingsView: View {
    @Bindable var store: StoreOf<SettingsFeature>
    let onNavigate: (ProfileRoute) -> Void

    var body: some View {
        let connected = store.isNetworkConnected
        Form {
            Section {
                Button {
                    onNavigate(.theme)
                } label: {
                    HStack {
                        Text(String(localized: "settings_theme", bundle: PresentationResources.bundle))
                            .foregroundStyle(Color.primary)
                        Spacer()
                        Text(store.theme.localizedName(in: PresentationResources.bundle))
                            .foregroundStyle(Color.gray)
                    }
                }

                Button {
                    onNavigate(.pushNotification)
                } label: {
                    Text(String(localized: "settings_notifications", bundle: PresentationResources.bundle))
                        .foregroundStyle(connected ? Color.primary : Color.secondary)
                }
                .disabled(!connected)

                let dirSize = store.dirSize
                Button {
                    store.send(.tapRemoveCacheButton)
                } label: {
                    HStack {
                        Text(String(localized: "settings_clear_temp_data", bundle: PresentationResources.bundle))
                            .foregroundStyle(dirSize == 0 ? Color.secondary : .primary)
                        Spacer()
                        if store.activeLoadingRow == .removeCache {
                            ProgressView()
                                .tint(.secondary)
                        } else {
                            Text(formatFileSize(bytes: dirSize))
                                .foregroundStyle(Color.secondary.opacity(dirSize == 0 ? 0 : 1))
                        }
                    }
                }
                .disabled(dirSize == 0 || store.isLoading)
            }
            
            Section {
                if let appVersion = store.appVersion {
                    HStack {
                        Text(String(localized: "settings_version", bundle: PresentationResources.bundle))
                        Spacer()
                        Text(appVersion)
                    }
                }
                if let policyString = store.policyURL,
                   let url = URL(string: policyString) {
                    Link(destination: url) {
                        Text(String(localized: "settings_privacy_policy", bundle: PresentationResources.bundle))
                            .foregroundColor(Color.blue)
                    }
                }
                if let betaTestURL = store.betaTestURL {
                    Link(destination: betaTestURL) {
                        VStack(alignment: .leading) {
                            Text(String(localized: "settings_join_beta", bundle: PresentationResources.bundle))
                                .foregroundStyle(Color.primary)
                            Text(String(localized: "settings_join_beta_subtitle", bundle: PresentationResources.bundle))
                                .foregroundStyle(Color.gray)
                                .font(.caption)
                        }
                    }
                }
            }
            
            Section {
                Button {
                    onNavigate(.account)
                } label: {
                    Text(String(localized: "settings_account", bundle: PresentationResources.bundle))
                }
                .disabled(!connected)
                Button {
                    store.send(.setAlert(.signOut))
                } label: {
                    HStack {
                        Text(String(localized: "settings_sign_out", bundle: PresentationResources.bundle))
                            .foregroundStyle(.red)
                        Spacer()
                        if store.activeLoadingRow == .signOut {
                            ProgressView()
                        }
                    }
                }
                .disabled(!connected || store.isLoading)
            }
            
            HStack {
                Spacer()
                Button {
                    store.send(.setAlert(.deleteAuth))
                } label: {
                    if store.activeLoadingRow == .deleteAuth {
                        ProgressView()
                            .tint(.red)
                    } else {
                        Text(String(localized: "settings_delete_account", bundle: PresentationResources.bundle))
                            .foregroundStyle(.red)
                            .font(.headline)
                    }
                }
                .disabled(!connected || store.isLoading)
                Spacer()
            }
        }
        .navigationTitle(String(localized: "nav_settings", bundle: PresentationResources.bundle))
        .navigationBarTitleDisplayMode(.inline)
        .prominentAlert(store, state: \.alert, action: \.alert)
        .onAppear {
            store.send(.updateDirSize)
        }
    }

    private func formatFileSize(bytes: Int64) -> String {
        let units = ["B", "KB", "MB", "GB"]
        var value = Double(max(bytes, 0))
        var unitIndex = 0

        while 1024.0 <= value && unitIndex < units.count - 1 {
            value /= 1024.0
            unitIndex += 1
        }

        let truncated = floor(value * 100.0) / 100.0
        let numberString = truncated.formatted(
            .number.precision(.fractionLength(0...2))
        )
        return "\(numberString)\(units[unitIndex])"
    }
}
