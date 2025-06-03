//
//  SearchViewModel.swift
//  DevLog
//
//  Created by opfic on 6/3/25.
//

import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    private let authService: AuthService
    private let networkService: NetworkActivityService
    private let webPageService: WebPageService
    @Published var searchText: String = ""
    @Published var webPages: [WebPageInfo] = []
    @Published var showError: Bool = false
    @Published var isSearching: Bool = false
    @Published var addNewLink: Bool = false
    @Published var newURL: String = "https://"
    @Published var errorMessage: String = ""
    @Published var selectedWebPage: WebPageInfo? = nil
    
    init(auth: AuthService, network: NetworkActivityService, webPageService: WebPageService = WebPageService()) {
        self.authService = auth
        self.networkService = network
        self.webPageService = webPageService
    }
    
    func requestWebPages() async {
        do {
            guard let userId = authService.userId else { throw URLError(.userAuthenticationRequired) }
            
            networkService.isLoading = true
            defer {
                networkService.isLoading = false
            }
            
            self.webPages = try await webPageService.requestWebPages(userId: userId)
            
        } catch {
            print("Error requesting web pages: \(error.localizedDescription)")
            self.errorMessage = "웹 페이지를 불러오는 중 오류가 발생했습니다."
            self.showError = true
        }
    }
    
    func upsertWebPage(webPage: WebPageInfo) async {
        do {
            guard let userId = authService.userId else { throw URLError(.userAuthenticationRequired) }
            networkService.isLoading = true
            defer {
                networkService.isLoading = false
            }
            
            try await webPageService.upsertWebPage(webPageInfo: webPage, userId: userId)
            
        } catch {
            print("Error upserting web page: \(error.localizedDescription)")
            self.errorMessage = "웹 페이지를 저장하는 중 오류가 발생했습니다."
            self.showError = true
        }
    }
    
    func deleteWebPage(webPage: WebPageInfo) async {
        do {
            guard let userId = authService.userId else { throw URLError(.userAuthenticationRequired) }
            networkService.isLoading = true
            defer {
                networkService.isLoading = false
            }
            
            try await webPageService.deleteWebPage(webPageInfo: webPage, userId: userId)
            
        } catch {
            print("Error deleting web page: \(error.localizedDescription)")
            self.errorMessage = "웹 페이지를 삭제하는 중 오류가 발생했습니다."
            self.showError = true
        }
    }
}
