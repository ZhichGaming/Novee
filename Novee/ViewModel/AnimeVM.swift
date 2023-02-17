//
//  AnimeVM.swift
//  Novee
//
//  Created by Nick on 2023-02-15.
//

import Foundation

class AnimeVM: ObservableObject {
    static let shared = AnimeVM()
    
    init() {
        sources[gogoanime.sourceId] = gogoanime
    }

    @Published var sources: [String: any AnimeSource] = [:]
    @Published var selectedSource = "gogoanime"
    
    var sourcesArray: [AnimeSource] {
        Array(sources.values)
    }
    
    private let gogoanime = Gogoanime()
    
    func getAnimeDetails(for anime: Anime) async {
        DispatchQueue.main.async { [self] in
            Task {
                await sources[selectedSource]!.getAnimeDetails(anime: anime)
            }
            
            return
        }
    }
    
    func getStreamingUrl(for episode: Episode, anime: Anime, returnEpisode: @escaping (Episode?) -> Void) async {
        await sources[selectedSource]?.getStreamingUrl(for: episode, anime: anime) { newEpisode in
            returnEpisode(newEpisode)
        }
    }
}
