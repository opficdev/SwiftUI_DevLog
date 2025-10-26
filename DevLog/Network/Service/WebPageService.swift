//
//  WebPageService.swift
//  DevLog
//
//  Created by opfic on 6/3/25.
//

import Foundation
import FirebaseFirestore

class WebPageService {
    private let store = Firestore.firestore()
    
    func requestWebPages(userId: String) async throws -> [WebPageInfo] {
        let webPageInfoRef = store.document("users/\(userId)/userData/webPageInfos")
        let doc = try await webPageInfoRef.getDocument()

        if doc.exists, let data = doc.data() {
            if let webPageInfos = data["webPageInfos"] as? [String] {
                return try await withThrowingTaskGroup(of: WebPageInfo.self, returning: [WebPageInfo].self) { group in
                    for urlString in webPageInfos {
                        group.addTask {
                            let doc = try await WebPageInfo.fetch(from: urlString)
                            return doc
                        }
                    }
         
                    var result = [WebPageInfo]()
                    for try await pageInfo in group {
                        result.append(pageInfo)
                    }

                    return result
                }
            }
        }
        throw URLError(.badServerResponse)
    }
    
    func upsertWebPage(webPageInfo: WebPageInfo, userId: String) async throws {
        let webPageInfosRef = store.document("users/\(userId)/userData/webPageInfos")
        try await webPageInfosRef.setData(["WebPageInfos": FieldValue.arrayUnion([webPageInfo.url.description])], merge: true)
    }
    
    func deleteWebPage(webPageInfo: WebPageInfo, userId: String) async throws {
        let webPageInfosRef = store.document("users/\(userId)/userData/webPageInfos")
        try await webPageInfosRef.updateData(["WebPageInfos": FieldValue.arrayRemove([webPageInfo.url.description])])
    }
}
