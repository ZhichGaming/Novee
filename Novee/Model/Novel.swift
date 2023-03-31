//
//  Novel.swift
//  Novee
//
//  Created by Nick on 2023-03-03.
//

import Foundation

struct Novel: Media, Hashable, Identifiable, Codable {
    var id = UUID()
    
    var title: String?
    var altTitles: [String]?
    var description: String?
    var authors: [String]?
    var tags: [NovelTag]?
    
    var detailsLoadingState: LoadingState = .loading
    
    var detailsUrl: URL?
    var imageUrl: URL?
    var segments: [NovelChapter]?
}

struct NovelTag: Hashable, Identifiable, Codable {
    var id = UUID()
    
    var name: String
    var url: URL?
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

