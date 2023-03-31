//
//  AnimeList.swift
//  Novee
//
//  Created by Nick on 2023-02-18.
//

import Foundation

struct AnimeListElement: MediaListElement, Hashable, Identifiable, Codable {
    let id = UUID()
    
    var content: [String: Anime] /// Anime from different sources
    var lastSegment: String? {
        didSet {
            if lastSegment != nil {
                lastViewedDate = Date.now
            }
        }
    }
    var status: Status
    var rating: Rating
    var lastViewedDate: Date?
    var creationDate: Date
    
    enum CodingKeys: CodingKey {
        case content
        case lastSegment
        case status
        case rating
        case lastViewedDate
        case creationDate
    }
    
}

struct AnimeWithSource: Hashable, Identifiable, Codable {
    var id = UUID()
    
    var source: String
    var anime: Anime
}
