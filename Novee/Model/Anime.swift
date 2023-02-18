//
//  Anime.swift
//  Novee
//
//  Created by Nick on 2023-02-15.
//

import Foundation

struct Anime: Hashable, Identifiable, Codable {
    var id = UUID()
    
    var title: String?
    var altTitles: [String]?
    var description: String?
    var authors: [String]?
    var tags: [AnimeTag]?
    
    var detailsLoadingState: LoadingState = .loading
    
    var detailsUrl: URL?
    var imageUrl: URL?
    var episodes: [Episode]?
}

struct AnimeTag: Hashable, Identifiable, Codable {
    var id = UUID()
    
    var name: String
    var url: URL?
}

struct Episode: Hashable, Identifiable, Codable {
    var id = UUID()
    var title: String

    /// The url to the episode of the anime where the human usually watches.
    /// Use `streamingUrl` for the url to the video itself.
    var episodeUrl: URL?
    var streamingUrls: [StreamingUrl]?
    
    /// Referer url to bypass 403 error
    var referer: URL?
    
    /// Url to download the episode.
    var downloadUrl: URL?
    
    /// Used for Gogoanime episode id. 
    var episodeId: String?
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
    var animeId: String
    var episodeId: String
    var animeTitle: String?
    var episodeNum: String?
    var subOrDub: GogoanimeSubOrDub?
    var animeImg: String?
    var episodeUrl: String?

    enum CodingKeys: CodingKey {
        case animeId
        case episodeId
        case animeTitle
        case episodeNum
        case subOrDub
        case animeImg
        case episodeUrl
    }
}

/// Struct for the data fetched by the search
/// https://gogoanime.consumet.stream/search?keyw=naruto
struct GogoanimeSearchApi: Hashable, Codable {
    var animeId: String
    var animeTitle: String?
    var animeURL: String?
    var animeImg: String?
    var status: String?

    enum CodingKeys: String, CodingKey {
        case animeId
        case animeTitle
        case animeURL
        case animeImg
        case status
    }
}

/// Struct for Gogoanime anime details
/// https://gogoanime.consumet.stream/anime-details/naruto
struct GogoanimeDetailsApi: Hashable, Codable {
    var animeTitle: String
    var type: String?
    var releasedDate: String?
    var status: String?
    var genres: [String]?
    var otherNames, synopsis: String?
    var animeImg: String?
    var totalEpisodes: String?
    var episodesList: [GogoanimeEpisodesList]?
}

/// Struct for a list of Gogoanime episodes.
/// Is a substruct for `GogoanimeDetailsApi`
struct GogoanimeEpisodesList: Hashable, Codable {
    var episodeId: String
    var episodeNum: String
    var episodeUrl: String

    enum CodingKeys: String, CodingKey {
        case episodeId
        case episodeNum
        case episodeUrl
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


