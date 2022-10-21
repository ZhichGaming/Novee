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

struct MangadexMangaData: Codable, Identifiable {
    var id: UUID
    var type: String
    var attributes: MangadexMangaAttributes
    var relationships: [MangadexRelationship?]
}

struct MangadexMangaAttributes: Codable {
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

struct MangadexTag: Codable, Identifiable {
    var id: UUID
    var type: String
    var attributes: MangadexTagAttributes
    var relationships: [MangadexRelationship?]
}

struct MangadexTagAttributes: Codable {
    var name: [String:String]
    var description: [[String:String]]?
    // Check what this is
    var group: String
}

struct MangadexRelationship: Codable, Identifiable {
    var id: UUID
    var type: String
    var related: String?
    var attributes: MangadexRelationshipAttributes?
}

struct MangadexRelationshipAttributes: Codable {
    var description: String?
    var volume: String?
    var fileName: String?
    var locale: String?
}

struct MangadexChapter: Codable {
    var hash: String
    var data: [String]
}
