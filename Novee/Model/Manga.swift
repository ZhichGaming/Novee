//
//  Manga.swift
//  Novee
//
//  Created by Nick on 2022-12-13.
//

import Foundation
import SwiftUI
import AppKit

enum LoadingState: Codable {
    case loading, success, failed, notFound
}

struct Manga: Hashable, Identifiable, Codable {
    var id = UUID()
    
    var title: String
    var altTitles: [String]?
    var description: String?
    var authors: [String]?
    var tags: [String]?
    
    var detailsLoadingState: LoadingState = .loading
    
    var detailsUrl: URL?
    var imageUrl: URL?
    var chapters: [Chapter]?
}

struct Chapter: Hashable, Identifiable, Codable {
    var id = UUID()
    var title: String

    var chapterUrl: URL
    var images: [NSImage]?

    var timeUploaded: Date?

    enum CodingKeys: CodingKey {
        case id
        case title
        case chapterUrl
        case timeUploaded
    }
}
