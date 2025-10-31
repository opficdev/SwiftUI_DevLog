//
//  SettingViewModel.swift
//  DevLog
//
//  Created by opfic on 5/7/25.
//

import Combine
import SwiftUI

@MainActor
final class SettingViewModel: ObservableObject {
    private let authState: AuthState
    private let updatePushNotificationSettings: UpdatePushNotificationSettings
    private let fetchPushNotificationSettings: FetchPushNotificationSettings
    private let updateAppTheme: UpdateAppTheme
    private let signOut: SignOut
    private let deleteAuth: DeleteAuth
    private let linkProvider: LinkProvider
    private let unlinkProvider: UnlinkProvider
    private let network: NetworkRepository
    private var cancellables = Set<AnyCancellable>()

    @Published var theme: String = ""
    @Published var showAlert: Bool = false
    @Published var alertMsg: String = ""
    
    // AuthInfo
    @Published var currentProvider = ""
    @Published var providers: [String] = []
    
    // NetworkActivityService와 연결되는 Published 프로퍼티
    @Published var isConnected: Bool = true
    @Published var isLoading: Bool = false
    @Published var showNetworkAlert: Bool = false
    
    @Published var pushNotificationEnabled: Bool = true
    @Published var pushNotificationTime = Date()
    
    init(
        authState: AuthState,
        updatePushNotificationSettings: UpdatePushNotificationSettings,
        fetchPushNotificationSettings: FetchPushNotificationSettings,
        updateAppTheme: UpdateAppTheme,
        signOut: SignOut,
        deleteAuth: DeleteAuth,
        linkProvider: LinkProvider,
        unlinkProvider: UnlinkProvider,
        network: NetworkRepository
    ) {
        print(1)
        self.authState = authState
        self.updatePushNotificationSettings = updatePushNotificationSettings
        self.fetchPushNotificationSettings = fetchPushNotificationSettings
        self.updateAppTheme = updateAppTheme
        self.signOut = signOut
        self.deleteAuth = deleteAuth
        self.linkProvider = linkProvider
        self.unlinkProvider = unlinkProvider
        self.network = network
        
        Task { await self.fetchPushNotificationSettings() }
        
        // 현재 로그인된 사용자의 인증 정보를 가져옴
        self.authState.publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.currentProvider = user?.currentProvider ?? ""
                self?.providers = user?.providers ?? []
            }
            .store(in: &cancellables)
        
        self.network.isConnectedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connected in
                self?.isConnected = connected
                self?.showNetworkAlert = !connected
            }
            .store(in: &cancellables)
        
        self.$pushNotificationEnabled.dropFirst()
            .sink { [weak self] _ in
                Task { await self?.updatePushNotificationEnabled() }
            }
            .store(in: &cancellables)
        
        self.$pushNotificationTime.dropFirst()
            .sink { [weak self] _ in
                Task { await self?.updatePushNotificationTime() }
            }
            .store(in: &cancellables)
        
        self.$theme.dropFirst()
            .compactMap(SystemTheme.init(rawValue:))
            .sink { [weak self] _ in
                Task { await self?.updateAppTheme() }
            }
            .store(in: &cancellables)
    }
    
    func signOut() async {
        guard isConnected else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await signOut.signOut()
        } catch {
            show("로그아웃 중 오류가 발생했습니다.")
        }
    }

    func deleteAuth() async {
        guard isConnected else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await deleteAuth.delete()
        } catch {
            show("회원탈퇴 중 오류가 발생했습니다.")
        }
    }
    
    func linkWithProvider(_ provider: AuthProvider) async {
        guard isConnected else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await linkProvider.link(provider)
        } catch {
            var alertMessage = "알 수 없는 오류가 발생했습니다."
            if let emailError = error as? EmailFetchError, emailError == .emailNotFound {
                alertMessage = "연동하려는 계정의 이메일을 확인할 수 없습니다."
            } else if let emailError = error as? EmailFetchError, emailError == .emailMismatch {
                alertMessage = "동일한 이메일을 가진 계정과 연동을 시도해주세요."
            }
            show(alertMessage)
        }
    }
    
    func unlink(_ provider: AuthProvider) async {
        guard isConnected else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await unlinkProvider.unlink(provider)
        } catch {
            show("연동 해제 중 오류가 발생했습니다.")
        }
    }

    func fetchPushNotificationSettings() async {
        guard isConnected else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let settings = try await fetchPushNotificationSettings.fetch()
            self.pushNotificationEnabled = settings.allow
            self.pushNotificationTime = settings.time
        } catch {
            show("푸시 알림 설정을 불러오는 중 오류가 발생했습니다.")
        }
    }
    
    func updatePushNotificationEnabled() async {
        guard isConnected else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await updatePushNotificationSettings.updateEnabled(self.pushNotificationEnabled)
        } catch {
            show("푸시 알림 설정을 업데이트하는 중 오류가 발생했습니다.")
        }
    }
    
    func updatePushNotificationTime() async {
        guard isConnected else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await updatePushNotificationSettings.updateTime(self.pushNotificationTime)
        } catch {
            show("푸시 알림 시간을 업데이트하는 중 오류가 발생했습니다.")
        }
    }
    
    func updateAppTheme() async {
        guard isConnected, let theme = SystemTheme(rawValue: self.theme) else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await updateAppTheme.update(theme)
        } catch {
            show("앱 테마를 업데이트하는 중 오류가 발생했습니다.")
        }
    }
    
    private func show(_ message: String) {
        self.alertMsg = message
        self.showAlert = true
    }
}
