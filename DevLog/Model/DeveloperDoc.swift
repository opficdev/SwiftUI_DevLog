//
//  DeveloperDoc.swift
//  DevLog
//
//  Created by opfic on 5/23/25.
//

import SwiftUI
import LinkPresentation
import UniformTypeIdentifiers

struct DeveloperDoc: Identifiable {
    let id = UUID()
    var image: UIImage?
    var title: String
    var url: URL
    var urlString: String

    init(image: UIImage?, title: String, url: URL, urlString: String) {
        self.image = image
        self.title = title
        self.url = url
        self.urlString = urlString
    }

    static func fetch(from urlString: String) async throws -> DeveloperDoc {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        return await fetch(from: url)
    }

    static func fetch(from url: URL) async -> DeveloperDoc {
        let provider = LPMetadataProvider()
        var image: UIImage? = nil
        var title: String = ""
        var urlString: String = url.absoluteString

        do {
            let metadata = try await provider.startFetchingMetadata(for: url)
            image = try await convertToImage(metadata)
            title = metadata.title ?? ""
            urlString = metadata.url?.host() ?? url.absoluteString
        } catch {
            print("Error fetching metadata: \(error.localizedDescription)")
        }

        return DeveloperDoc(image: image, title: title, url: url, urlString: urlString)
    }

    static func convertToImage(_ metaData: LPLinkMetadata) async throws -> UIImage? {
        let imageType = UTType.image.identifier

        if let imageProvider = metaData.imageProvider,
            imageProvider.hasItemConformingToTypeIdentifier(imageType) {
            let imageItem = try await imageProvider.loadItem(forTypeIdentifier: imageType)

            switch imageItem {
            case let uiImage as UIImage:
                return uiImage
            case let url as URL:
                if let data = try? Data(contentsOf: url) {
                    return UIImage(data: data)
                }
            case let data as Data:
                return UIImage(data: data)
            case let nsData as NSData:
                return UIImage(data: nsData as Data)
            default:
                return nil
            }
        }
        return nil
    }
}
