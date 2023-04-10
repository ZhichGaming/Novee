//
//  Manga.swift
//  Novee
//
//  Created by Nick on 2022-12-13.
//

import Foundation
import SwiftUI
import AppKit

struct Manga: Media, Hashable, Identifiable, Codable {
    typealias MediaListElementType = MangaListElement
    
    var id = UUID()
    
    var title: String?
    var altTitles: [String]?
    var description: String?
    var authors: [String]?
    var tags: [MediaTag]?
        
    var detailsUrl: URL?
    var imageUrl: URL?
    var segments: [Chapter]?
    
    enum CodingKeys: CodingKey {
        case id
        case title
        case altTitles
        case description
        case authors
        case tags
        case detailsUrl
        case imageUrl
        case segments
    }
}

struct Chapter: MediaSegment, Hashable, Identifiable, Codable {
    var id = UUID()
    var title: String

    var segmentUrl: URL
    var images: [Int:MangaImage]?

    var timeUploaded: Date?

    enum CodingKeys: CodingKey {
        case id
        case title
        case segmentUrl
        case timeUploaded
    }
}

struct MangaChapterPair: Codable, Hashable {
    var manga: Manga
    var chapter: Chapter
}

struct MangaImage: Hashable {
    var image: NSImage?
    
    var url: URL?
    var loadingState: LoadingState = .loading
}
