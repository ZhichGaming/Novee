//
//  AnimeBase.swift
//  Novee
//
//  Created by Nick on 2023-02-15.
//

import Foundation

class AnimeFetcher {
    init(label: String, sourceId: String, baseUrl: String) {
        self.label = label
        self.sourceId = sourceId
        self.baseUrl = baseUrl
    }
    
    // Source info
    let label: String
    let sourceId: String
    let baseUrl: String
    
    @Published var animeData: [Anime] = []
}

protocol AnimeSource {
    var label: String { get }
    var baseUrl: String { get }
    var sourceId: String { get }
    
    var animeData: [Anime] { get set }
        
    @discardableResult
    func getAnime(pageNumber: Int) async -> [Anime]
    
    @discardableResult
    func getSearchAnime(pageNumber: Int, searchQuery: String) async -> [Anime]
    
    @discardableResult
    func getAnimeDetails(anime: Anime) async -> Anime?
    
    func getStreamingUrl(for episode: Episode, anime: Anime, returnEpisode: @escaping (Episode?) -> Void) async
}
