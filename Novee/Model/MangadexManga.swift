//
//  Manga.swift
//  Novee
//
//  Created by Nick on 2022-10-16.
//

import Foundation

struct MangadexResponse: Codable {
    var result: String
    var response: String
    var data: [MangadexMangaData]
}

struct MangadexChapterResponse: Codable {
    var result: String
    var response: String
    var data: [MangadexChapter]
}

struct MangadexMangaData: Codable, Identifiable, Equatable {
    var id: UUID
    var type: String
    var attributes: MangadexMangaAttributes
    var relationships: [MangadexRelationship?]
    var chapters: [MangadexChapter]?
}

struct MangadexMangaAttributes: Codable, Equatable {
    var title: [String:String]
    var altTitles: [[String:String]]?
    var description: [String:String]?
    var isLocked: Bool
    var links: [String:String]?
    var originalLanguage: String
    var lastChapter: String?
    var lastVolume: String?
    var status: String
    var year: Int?
    var tags: [MangadexTag]?
    var createdAt: Date
    var updatedAt: Date
}

struct MangadexRelationship: Codable, Identifiable, Equatable {
    var id: UUID
    var type: String
    var related: String?
    var attributes: MangadexRelationshipAttributes?
}

struct MangadexRelationshipAttributes: Codable, Equatable {
    var description: String?
    var volume: String?
    var fileName: String?
    var locale: String?
}

struct MangadexTag: Codable, Identifiable, Equatable {
    var id: UUID
    var type: String
    var attributes: MangadexTagAttributes
    var relationships: [MangadexRelationship?]
}

struct MangadexTagAttributes: Codable, Equatable {
    var name: [String:String]
    var description: [[String:String]]?
    var group: String
}

struct MangadexChapter: Codable, Identifiable, Equatable {
    var id: UUID
    var type: String
    var attributes: MangadexChapterAttributes
    var relationships: [MangadexChapterRelationship]
}

struct MangadexChapterAttributes: Codable, Equatable {
    var volume: String?
    var chapter: String?
    var title: String?
    var translatedLanguage: String
    var externalUrl: String?
    var publishAt: Date
}

struct MangadexChapterRelationship: Codable, Equatable, Identifiable {
    var id: UUID
    var type: String
    var attributes: MangadexGroupAttributes?
}

struct MangadexGroupAttributes: Codable, Equatable, Hashable {
    var name: String
    var website: String?
}
