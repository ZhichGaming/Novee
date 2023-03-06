//
//  MangaList.swift
//  Novee
//
//  Created by Nick on 2023-01-04.
//

import Foundation

enum BookStatus: String, Hashable, CaseIterable, Codable {
    case dropped = "Dropped"
    case completed = "Completed"
    case reading = "Reading"
    case waiting = "Waiting"
    case toRead = "To read"
}

enum BookRating: String, Hashable, CaseIterable, Codable {
    case horrible = "Horrible"
    case bad = "Bad"
    case good = "Good"
    case best = "Best"
    case none = "None"
}

struct MangaListElement: Hashable, Identifiable, Codable {
    let id = UUID()
    
    var manga: [String: Manga] /// Manga from different sources
    var lastChapter: String? {
        didSet {
            if lastChapter != nil {
                lastReadDate = Date.now
            }
        }
    }
    var status: BookStatus
    var rating: BookRating
    var lastReadDate: Date?
    var creationDate: Date
    
    enum CodingKeys: CodingKey {
        case manga
        case lastChapter
        case status
        case rating
        case lastReadDate
        case creationDate
    }
}

struct MangaWithSource: Hashable, Identifiable, Codable {
    var id = UUID()
    
    var source: String
    var manga: Manga
}
