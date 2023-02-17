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

    func assignAnimeDetails(anime: Anime, result: Anime) {
        DispatchQueue.main.sync {
            AnimeVM.shared.objectWillChange.send()
            
            var passedSourceAnimes: [Anime] {
                get { AnimeVM.shared.sources[AnimeVM.shared.selectedSource]!.animeData }
                set { AnimeVM.shared.sources[AnimeVM.shared.selectedSource]?.animeData = newValue }
            }
            
            let animeIndex = passedSourceAnimes.firstIndex(of: anime) ?? 0
                        
            passedSourceAnimes[animeIndex].title = result.title
            passedSourceAnimes[animeIndex].altTitles = result.altTitles ?? passedSourceAnimes[animeIndex].altTitles
            passedSourceAnimes[animeIndex].description = result.description ?? passedSourceAnimes[animeIndex].description
            passedSourceAnimes[animeIndex].authors = result.authors ?? passedSourceAnimes[animeIndex].authors
            passedSourceAnimes[animeIndex].tags = result.tags ?? passedSourceAnimes[animeIndex].tags
            passedSourceAnimes[animeIndex].episodes = result.episodes ?? passedSourceAnimes[animeIndex].episodes
            
            passedSourceAnimes[animeIndex].detailsLoadingState = .success
        }
    }
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
