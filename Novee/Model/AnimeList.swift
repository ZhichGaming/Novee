//
//  AnimeList.swift
//  Novee
//
//  Created by Nick on 2023-02-18.
//

import Foundation

enum AnimeStatus: String, Hashable, CaseIterable, Codable {
    case dropped = "Dropped"
    case completed = "Completed"
    case watching = "Watching"
    case waiting = "Waiting"
    case toWatch = "To watch"
}

enum AnimeRating: String, Hashable, CaseIterable, Codable {
    case horrible = "Horrible"
    case bad = "Bad"
    case good = "Good"
    case best = "Best"
    case none = "None"
}

struct AnimeListElement: Hashable, Identifiable, Codable {
    let id = UUID()
    
    var anime: [String: Anime] /// Anime from different sources
    var lastEpisode: String? {
        didSet {
            if lastEpisode != nil {
                lastWatchDate = Date.now
            }
        }
    }
    var status: AnimeStatus
    var rating: AnimeRating
    var lastWatchDate: Date?
    var creationDate: Date
    
    enum CodingKeys: CodingKey {
        case anime
        case lastEpisode
        case status
        case rating
        case lastWatchDate
        case creationDate
    }
    
}

struct AnimeWithSource: Hashable, Identifiable, Codable {
    var id = UUID()
    
    var source: String
    var anime: Anime
}
