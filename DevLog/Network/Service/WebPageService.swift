//
//  WebPageService.swift
//  DevLog
//
//  Created by opfic on 6/3/25.
//

import Foundation
import FirebaseFirestore

class WebPageService {
    private let db = Firestore.firestore()
    
    func requestWebPages(userId: String) async throws -> [WebPageInfo] {
        let WebPageInfoRef = db.document("users/\(userId)/userData/webPageInfos")
        let doc = try await WebPageInfoRef.getDocument()
        
        if doc.exists, let data = doc.data() {
            if let webPageInfos = data["WebPageInfos"] as? [String] {
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
        let WebPageInfosRef = db.document("users/\(userId)/userData/webPageInfos")
        try await WebPageInfosRef.setData(["WebPageInfos": FieldValue.arrayUnion([webPageInfo.url.description])], merge: true)
    }
    
    func deleteWebPage(webPageInfo: WebPageInfo, userId: String) async throws {
        let WebPageInfosRef = db.document("users/\(userId)/userData/webPageInfos")
        try await WebPageInfosRef.updateData(["WebPageInfos": FieldValue.arrayRemove([webPageInfo.url.description])])
    }
}
