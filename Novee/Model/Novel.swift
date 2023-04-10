//
//  Novel.swift
//  Novee
//
//  Created by Nick on 2023-03-03.
//

import Foundation

struct Novel: Media, Hashable, Identifiable, Codable {
    typealias MediaListElementType = NovelListElement
    
    var id = UUID()
    
    var title: String?
    var altTitles: [String]?
    var description: String?
    var authors: [String]?
    var tags: [MediaTag]?
        
    var detailsUrl: URL?
    var imageUrl: URL?
    var segments: [NovelChapter]?
    
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

struct NovelChapter: MediaSegment, Hashable, Identifiable, Codable {
    var id = UUID()
    var title: String

    var segmentUrl: URL
    var content: String?

    var timeUploaded: Date?

    enum CodingKeys: CodingKey {
        case id
        case title
        case segmentUrl
        case timeUploaded
    }
}

struct NovelChapterPair: Codable, Hashable {
    var novel: Novel
    var chapter: NovelChapter
}

