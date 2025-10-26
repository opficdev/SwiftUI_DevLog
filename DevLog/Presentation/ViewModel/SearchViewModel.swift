//
//  SearchViewModel.swift
//  DevLog
//
//  Created by opfic on 6/3/25.
//

import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    private let authSvc: AuthService
    private let networkSvc: NetworkActivityService
    private let webPageSvc: WebPageService
    @Published var searchText: String = ""
    @Published var webPages: [WebPageInfo] = []
    @Published var showAlert: Bool = false
    @Published var isSearching: Bool = false
    @Published var addNewLink: Bool = false
    @Published var newURL: String = "https://"
    @Published var alertMsg: String = ""
    @Published var selectedWebPage: WebPageInfo?
    @Published var isLoading: Bool = false
    @Published var isConnected: Bool = true
    
    init(authSvc: AuthService, networkSvc: NetworkActivityService, webPageSvc: WebPageService) {
        self.authSvc = authSvc
        self.networkSvc = networkSvc
        self.webPageSvc = webPageSvc
        
        // NetworkActivityService.isConnected를 self.isConnected와 단방향 연결
        self.networkSvc.$isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: &self.$isConnected)
    }
    
    func requestWebPages() async {
        if !self.isConnected { return }
        do {
            guard let userId = self.authSvc.user?.uid else { throw URLError(.userAuthenticationRequired) }

            self.isLoading = true
            defer {
                self.isLoading = false
            }
            
            self.webPages = try await self.webPageSvc.requestWebPages(userId: userId)
            
        } catch {
            print("Error requesting web pages: \(error.localizedDescription)")
            self.alertMsg = "웹 페이지를 불러오는 중 오류가 발생했습니다."
            self.showAlert = true
        }
    }
    
    func upsertWebPage(webPage: WebPageInfo) async {
        if !self.isConnected { return }
        do {
            guard let userId = self.authSvc.user?.uid else { throw URLError(.userAuthenticationRequired) }
            self.isLoading = true
            defer {
                self.isLoading = false
            }
            
            try await self.webPageSvc.upsertWebPage(webPageInfo: webPage, userId: userId)
            
        } catch {
            print("Error upserting web page: \(error.localizedDescription)")
            self.alertMsg = "웹 페이지를 저장하는 중 오류가 발생했습니다."
            self.showAlert = true
        }
    }
    
    func deleteWebPage(webPage: WebPageInfo) async {
        if !self.isConnected { return }
        do {
            guard let userId = self.authSvc.user?.uid else { throw URLError(.userAuthenticationRequired) }
            self.isLoading = true
            defer {
                self.isLoading = false
            }
            
            try await self.webPageSvc.deleteWebPage(webPageInfo: webPage, userId: userId)
            
        } catch {
            print("Error deleting web page: \(error.localizedDescription)")
            self.alertMsg = "웹 페이지를 삭제하는 중 오류가 발생했습니다."
            self.showAlert = true
        }
    }
}
