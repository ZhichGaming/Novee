//
//  Anime.swift
//  Novee
//
//  Created by Nick on 2023-02-15.
//

import Foundation
import CoreMedia

struct Anime: Media, Hashable, Identifiable, Codable {
    init() { }
    
    typealias MediaListElementType = AnimeListElement
    
    var id = UUID()
    
    var title: String?
    var altTitles: [String]?
    var description: String?
    var authors: [String]?
    var tags: [MediaTag]?
        
    var detailsUrl: URL?
    var imageUrl: URL?
    var segments: [Episode]?
    
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

struct Episode: MediaSegment, Hashable, Identifiable, Codable {
    var id = UUID()
    var title: String

    /// The url to the episode of the anime where the human usually watches.
    /// Use `streamingUrl` for the url to the video itself.
    var segmentUrl: URL
    var streamingUrls: [StreamingUrl]?
    
    /// Referer url to bypass 403 error
    var referer: URL?
    
    /// Url to download the episode.
    var downloadUrl: URL?
    
    /// Used for Gogoanime episode id. 
    var episodeId: String?
    
    /// The time the user left off for this episode, stored in seconds.
    var resumeTime: Double?
}

struct AnimeEpisodePair: Codable, Hashable {
    var anime: Anime
    var episode: Episode
}

struct StreamingUrl: Hashable, Identifiable, Codable {
    var id = UUID()
    
    var url: URL?
    var isM3U8: Bool?
    var quality: String?
}
