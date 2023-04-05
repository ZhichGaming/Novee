//
//  Anime.swift
//  Novee
//
//  Created by Nick on 2023-02-15.
//

import Foundation
import CoreMedia

struct Anime: Media, Hashable, Identifiable, Codable {
    var id = UUID()
    
    var title: String?
    var altTitles: [String]?
    var description: String?
    var authors: [String]?
    var tags: [AnimeTag]?
    
    var detailsLoadingState: LoadingState = .loading
    
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

struct AnimeTag: Hashable, Identifiable, Codable {
    var id = UUID()
    
    var name: String
    var url: URL?
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

enum GogoanimeSubOrDub: String, Hashable, Codable {
    case sub = "SUB"
    case dub = "DUB"
}

/// Struct for the data fetched by the recent release
/// https://gogoanime.consumet.stream/recent-release
struct GogoanimeRecentReleaseApi: Hashable, Codable {
    var currentPage: String?
    var hasNextPage: Bool?
    var results: [Result]?
    
    struct Result: Hashable, Codable {
        var id, episodeId: String?
        var episodeNumber: Int?
        var title: String?
        var image: String?
        var url: String?

        enum CodingKeys: String, CodingKey {
            case id
            case episodeId = "EpisodeID"
            case episodeNumber, title, image, url
        }
    }
}

/// Struct for the data fetched by the search
/// https://gogoanime.consumet.stream/search?keyw=naruto
struct GogoanimeSearchApi: Hashable, Codable {
    var currentPage: String?
    var hasNextPage: Bool?
    var results: [Result]?
    
    struct Result: Hashable, Codable {
        var id, title: String?
        var url: String?
        var image: String?
        var releaseDate: String?
    }
}

/// Struct for Gogoanime anime details
/// https://gogoanime.consumet.stream/anime-details/naruto
struct GogoanimeDetailsApi: Hashable, Codable {
    var id, title, url: String?
    var genres: [String]?
    var totalEpisodes: Int?
    var image: String?
    var releaseDate, description, subOrDub, type: String?
    var status, otherName: String?
    var episodes: [GogoanimeEpisodesList]?
    
    struct GogoanimeEpisodesList: Hashable, Codable {
        var id: String
        var number: Int
        var url: String
    }
}

struct GogoanimeStreamingUrlApi: Hashable, Codable {
    var headers: Headers?
    var sources: [Source]?
    var download: String?

    struct Headers: Hashable, Codable {
        var referer: String?
    }
    
    struct Source: Hashable, Codable {
        var url: String?
        var isM3U8: Bool?
        var quality: String?
    }
}


