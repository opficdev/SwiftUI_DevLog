//
//  AccountView.swift
//  ProfileTab
//
//  Created by opfic on 5/14/25.
//

import SwiftUI
import Core
import PresentationShared
import Domain

struct AccountView: View {
    @State var store: StoreOf<AccountFeature>

    var body: some View {
        List {
            Section(String(localized: "account_current_section", bundle: PresentationResources.bundle)) {
                HStack {
                    if let provider = store.currentProvider {
                        providerContent(provider)
                    }
                }
            }
            Section(String(localized: "account_social_section", bundle: PresentationResources.bundle)) {
                let providers = AuthProvider.allCases.filter { $0 != store.currentProvider }
                ForEach(providers, id: \.self) { provider in
                    let isConnected = store.connectedProviders.contains(provider)
                    let showProgressView = store.isLoading && store.activeLoadingProvider == provider
                    HStack {
                        providerContent(provider)
                        Spacer()
                        Button {
                            if isConnected {
                                store.send(.unlinkFromProvider(provider))
                            } else {
                                store.send(.linkWithProvider(provider))
                            }
                        } label: {
                            Text(isConnected
                                 ? String(localized: "account_disconnect", bundle: PresentationResources.bundle)
                                 : String(localized: "account_connect", bundle: PresentationResources.bundle))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isConnected ? Color.red : .blue)
                            .clipShape(.capsule)
                        }
                        .buttonStyle(.plain)
                        .disabled(
                            store.isLoading ||
                            (!isConnected && store.presentationContext == nil)
                        )
                        .opacity(showProgressView ? 0 : 1)
                        .overlay(alignment: .trailing) {
                            if showProgressView {
                                ProgressView()
                            }
                        }
                    }
                }
            }
        }
        .scrollDisabled(true)
        .listStyle(.insetGrouped)
        .navigationTitle(String(localized: "nav_account", bundle: PresentationResources.bundle))
        .onAppear { store.send(.onAppear) }
        .prominentAlert(store, state: \.alert, action: \.alert)
        .background {
            WindowSceneIdentifierReader {
                store.send(.setPresentationContext(
                    $0.map(AuthPresentationContext.init(identifier:))
                ))
            }
        }
    }
    
    private func formattedProviderName(_ provider: AuthProvider) -> String {
        let rawValue = provider.rawValue
        let providerPrefix = rawValue.prefix(1).uppercased()
        let providerSuffix = rawValue.dropFirst().prefix(while: { $0 != "." })
        return providerPrefix + providerSuffix
    }

    @ViewBuilder
    private func providerContent(_ provider: AuthProvider) -> some View {
        Image(formattedProviderName(provider))
            .resizable()
            .scaledToFit()
            .frame(width: UIFont.labelFontSize)
        Text(formattedProviderName(provider))
    }
}
