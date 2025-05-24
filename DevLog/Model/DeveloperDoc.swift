//
//  DeveloperDoc.swift
//  DevLog
//
//  Created by opfic on 5/23/25.
//

import SwiftUI

struct DeveloperDoc: Identifiable {
    let id = UUID()
    var image: UIImage?
    var title: String
    var urlString: String
    
    init(_ title: String, urlString: String, uiImage: UIImage? = nil) {
        self.title = title
        self.urlString = urlString
        self.image = uiImage
    }
}
