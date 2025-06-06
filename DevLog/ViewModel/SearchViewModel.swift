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
    @Published var showError: Bool = false
    @Published var isSearching: Bool = false
    @Published var addNewLink: Bool = false
    @Published var newURL: String = "https://"
    @Published var errorMsg: String = ""
    @Published var selectedWebPage: WebPageInfo? = nil
    
    init(authSvc: AuthService, networkSvc: NetworkActivityService, webPageSvc: WebPageService) {
        self.authSvc = authSvc
        self.networkSvc = networkSvc
        self.webPageSvc = webPageSvc
    }
    
    func requestWebPages() async {
        do {
            guard let userId = self.authSvc.userId else { throw URLError(.userAuthenticationRequired) }
            
            self.networkSvc.isLoading = true
            defer {
                self.networkSvc.isLoading = false
            }
            
            self.webPages = try await self.webPageSvc.requestWebPages(userId: userId)
            
        } catch {
            print("Error requesting web pages: \(error.localizedDescription)")
            self.errorMsg = "웹 페이지를 불러오는 중 오류가 발생했습니다."
            self.showError = true
        }
    }
    
    func upsertWebPage(webPage: WebPageInfo) async {
        do {
            guard let userId = self.authSvc.userId else { throw URLError(.userAuthenticationRequired) }
            self.networkSvc.isLoading = true
            defer {
                self.networkSvc.isLoading = false
            }
            
            try await self.webPageSvc.upsertWebPage(webPageInfo: webPage, userId: userId)
            
        } catch {
            print("Error upserting web page: \(error.localizedDescription)")
            self.errorMsg = "웹 페이지를 저장하는 중 오류가 발생했습니다."
            self.showError = true
        }
    }
    
    func deleteWebPage(webPage: WebPageInfo) async {
        do {
            guard let userId = self.authSvc.userId else { throw URLError(.userAuthenticationRequired) }
            self.networkSvc.isLoading = true
            defer {
                self.networkSvc.isLoading = false
            }
            
            try await self.webPageSvc.deleteWebPage(webPageInfo: webPage, userId: userId)
            
        } catch {
            print("Error deleting web page: \(error.localizedDescription)")
            self.errorMsg = "웹 페이지를 삭제하는 중 오류가 발생했습니다."
            self.showError = true
        }
    }
}
