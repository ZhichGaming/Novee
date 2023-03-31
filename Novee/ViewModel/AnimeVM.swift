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
    @Published var pageNumber = 1
    @Published var lastSelectedResolution = "720p" {
        didSet {
            UserDefaults.standard.set(lastSelectedResolution, forKey: "lastSelectedAnimeResolution")
        }
    }
    
    @Published var episodeDownloadProgress: EpisodeDownloadProgress? = nil
    
    var sourcesArray: [AnimeSource] {
        Array(sources.values)
    }
    
    private let gogoanime = Gogoanime()
    
    func changeEpisode(episode: Episode, anime: Anime, offset: Int = 1) -> Episode? {
        if let episodeIndex = anime.segments?.firstIndex(where: { $0.id == episode.id }) {
            guard let episodes = anime.segments else {
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
    
    func getAllUpdatedAnimeDetails(for oldSources: [String: Anime]) async -> [String: Anime] {
        var result = [String: Anime]()
        let semaphore = DispatchGroup()

        for oldSource in oldSources {
            if let _ = sources[oldSource.key] {
                semaphore.enter()
                
                await getAnimeDetails(for: oldSource.value, source: oldSource.key) { newAnime in
                    if let newAnime = newAnime {
                        result[oldSource.key] = newAnime
                    } else {
                        result[oldSource.key] = oldSource.value
                    }
                    
                    semaphore.leave()
                }
            }
        }
        
        DispatchQueue.global().sync {
            semaphore.wait()
        }
        
        return result
    }
    
    func getStreamingUrl(for episode: Episode, anime: Anime, returnEpisode: @escaping (Episode?) -> Void) async {
        await sources[selectedSource]?.getStreamingUrl(for: episode, anime: anime) { newEpisode in
            returnEpisode(newEpisode)
        }
    }
    
    func downloadEpisode(for url: StreamingUrl, anime: Anime) async {
        do {
            if !FileManager().fileExists(atPath: URL.animeStorageUrl.path) {
                try FileManager().createDirectory(at: .animeStorageUrl, withIntermediateDirectories: false)
            }
            
            if let url = url.url {
                Task { @MainActor in
                    episodeDownloadProgress = EpisodeDownloadProgress()
                    
                    episodeDownloadProgress?.dataTask = URLSession.shared.downloadTask(with: url) { location, response, error in
                        if let location = location {
                            do {
                                let safeAnimeTitle = anime.title?.sanitizedFileName ?? "Unknown"
                                let currentAnimeFolder = URL.animeStorageUrl.appendingPathComponent(safeAnimeTitle, conformingTo: .folder)
                                let destination = currentAnimeFolder.appendingPathComponent(url.lastPathComponent)
                                
                                if !FileManager().fileExists(atPath: currentAnimeFolder.path) {
                                    try FileManager().createDirectory(at: currentAnimeFolder, withIntermediateDirectories: false)
                                }
                                
                                if FileManager().fileExists(atPath: destination.path) {
                                    try FileManager().removeItem(at: destination)
                                }
                                
                                if let thumbnailUrl = anime.imageUrl {
                                    URLSession.shared.dataTask(with: thumbnailUrl) { data, response, error in
                                        if let data = data {
                                            if FileManager().fileExists(atPath: currentAnimeFolder.appendingPathComponent("thumbnail", conformingTo: .png).path) {
                                                try? FileManager().removeItem(at: currentAnimeFolder.appendingPathComponent("thumbnail", conformingTo: .png))
                                            }
                                            
                                            FileManager().createFile(atPath: currentAnimeFolder.appendingPathComponent("thumbnail", conformingTo: .png).path, contents: data)
                                        }
                                    }
                                    .resume()
                                }
                                
                                try FileManager().moveItem(at: location, to: destination)
                            } catch {
                                Log.shared.error(error)
                            }
                        }
                    }
                    
                    episodeDownloadProgress?.observation = episodeDownloadProgress?.dataTask?.progress.observe(\.fractionCompleted) { observationProgress, _ in
                        DispatchQueue.main.async {
                            self.episodeDownloadProgress?.progress = observationProgress.fractionCompleted
                        }
                    }
                    
                    episodeDownloadProgress?.dataTask?.resume()
                }
            }
        } catch {
            Log.shared.error(error)
        }
    }
    
    func resetEpisodeDownloadProgress() {
        episodeDownloadProgress?.dataTask?.cancel()
        episodeDownloadProgress?.observation?.invalidate()
        
        episodeDownloadProgress = nil
    }
}

struct EpisodeDownloadProgress: Hashable {
    var progress: Double = 0
    let total: Double = 1

    var dataTask: URLSessionDownloadTask?
    var observation: NSKeyValueObservation?
}
