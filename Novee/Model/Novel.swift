//
//  Novel.swift
//  Novee
//
//  Created by Nick on 2023-03-03.
//

import Foundation

struct Novel: Hashable, Identifiable, Codable {
    var id = UUID()
    
    var title: String?
    var altTitles: [String]?
    var description: String?
    var authors: [String]?
    var tags: [NovelTag]?
    
    var detailsLoadingState: LoadingState = .loading
    
    var detailsUrl: URL?
    var imageUrl: URL?
    var chapters: [NovelChapter]?
}

struct NovelTag: Hashable, Identifiable, Codable {
    var id = UUID()
    
    var name: String
    var url: URL?
}

struct NovelChapter: Hashable, Identifiable, Codable {
    var id = UUID()
    var title: String

    var chapterUrl: URL
    var content: String?

    var timeUploaded: Date?

    enum CodingKeys: CodingKey {
        case id
        case title
        case chapterUrl
        case timeUploaded
    }
}