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
        
        if let resolution = UserDefaults.standard.string(forKey: "lastSelectedAnimeResolution") {
            lastSelectedResolution = resolution
        }
    }

    @Published var sources: [String: any AnimeSource] = [:]
    @Published var selectedSource = "gogoanime"
    @Published var lastSelectedResolution = "720p" {
        didSet {
            UserDefaults.standard.set(lastSelectedResolution, forKey: "lastSelectedAnimeResolution")
        }
    }
    
    var sourcesArray: [AnimeSource] {
        Array(sources.values)
    }
    
    private let gogoanime = Gogoanime()
    
    func changeEpisode(episode: Episode, anime: Anime, offset: Int = 1) -> Episode? {
        if let episodeIndex = anime.episodes?.firstIndex(where: { $0.id == episode.id }) {
            guard let episodes = anime.episodes else {
                Log.shared.msg("Error: Episodes are empty!")
                return nil
            }
            
            if episodeIndex + offset >= 0 && episodeIndex + offset < episodes.count {
                return episodes[episodeIndex + offset]
            }
        }
        
        return nil
    }
    
    func getAnimeDetails(for anime: Anime) async {
        DispatchQueue.main.async { [self] in
            Task {
                await sources[selectedSource]!.getAnimeDetails(anime: anime)
            }
            
            return
        }
    }
    
    func getAnimeDetails(for anime: Anime, source: String, result: @escaping (Anime?) -> Void) async {        
        DispatchQueue.main.async { [self] in
            Task {
                result(await sources[source]!.getAnimeDetails(anime: anime))
            }
        }
    }
    
    func getStreamingUrl(for episode: Episode, anime: Anime, returnEpisode: @escaping (Episode?) -> Void) async {
        await sources[selectedSource]?.getStreamingUrl(for: episode, anime: anime) { newEpisode in
            returnEpisode(newEpisode)
        }
    }
}