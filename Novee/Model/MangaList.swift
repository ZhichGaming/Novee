//
//  MangaList.swift
//  Novee
//
//  Created by Nick on 2023-01-04.
//

import Foundation

enum MangaStatus: String, Hashable, CaseIterable {
    case dropped = "Dropped"
    case completed = "Completed"
    case reading = "Reading"
    case waiting = "Waiting"
    case toRead = "To read"
}

enum MangaRating: String, Hashable, CaseIterable {
    case horrible = "Horrible"
    case bad = "Bad"
    case good = "Good"
    case best = "Best"
    case none = "None"
}

struct MangaListElement: Hashable, Identifiable {
    let id = UUID()
    
    var manga: [String: Manga] /// Manga from different sources
    var lastChapter: String?
    var status: MangaStatus
    var rating: MangaRating
    var lastReadDate: Date?
    var creationDate: Date
}
