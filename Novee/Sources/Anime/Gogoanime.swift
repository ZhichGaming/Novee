//
//  Gogoanime.swift
//  Novee
//
//  Created by Nick on 2023-02-15.
//

import Foundation
import SwiftSoup

class Gogoanime: AnimeFetcher, AnimeSource {
    override init(label: String = "Gogoanime", sourceId: String = "gogoanime", baseUrl: String = "https://ww4.gogoanimes.org") {
        super.init(label: label, sourceId: sourceId, baseUrl: baseUrl)
    }
    
    // Documentation: https://docs.consumet.org/rest-api/Anime/gogoanime/get-recent-episodes
    let api = "https://api.consumet.org/anime/gogoanime"
    
    func getAnime(pageNumber: Int) async -> [Anime] {
        do {
            guard let requestUrl = URL(string: api + "/recent-episodes" + "?page=" + String(pageNumber)) else {
                Log.shared.msg("An error occured while formatting the URL")
                return []
            }

            let (data, _) = try await URLSession.shared.data(from: requestUrl)
            
            let animes = try JSONDecoder().decode(GogoanimeRecentReleaseApi.self, from: data)
            
            var result: [Anime] = []
                        
            for anime in animes.results ?? [] {
                let converted = Anime(
                    title: anime.title,
                    detailsUrl: URL(string: api + "/info/" + (anime.id ?? "")),
                    imageUrl: URL(string: anime.image ?? ""))
                
                result.append(converted)
            }
            
            DispatchQueue.main.sync {
                AnimeVM.shared.objectWillChange.send()
            }
            
            super.animeData = result
            return result
        } catch {
            Log.shared.error(error)
            return []
        }
    }
    
    func getSearchAnime(pageNumber: Int, searchQuery: String) async -> [Anime] {
        do {
            let safeSearchQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            
            guard let requestUrl = URL(string: api + "/\(safeSearchQuery)?page=\(pageNumber)") else {
                Log.shared.msg("An error occured while formatting the URL")
                return []
            }

            let (data, _) = try await URLSession.shared.data(from: requestUrl)
            
            let animes = try JSONDecoder().decode(GogoanimeSearchApi.self, from: data)
            
            var result: [Anime] = []
                        
            for anime in animes.results ?? [] {
                let converted = Anime(
                    title: anime.title,
                    detailsUrl: URL(string: api + "/info/" + (anime.id ?? "")),
                    imageUrl: URL(string: anime.image ?? ""))
                
                result.append(converted)
            }
            
            DispatchQueue.main.sync {
                AnimeVM.shared.objectWillChange.send()
            }
            
            super.animeData = result
            return result
        } catch {
            Log.shared.error(error)
            return []
        }
    }
    
    func getAnimeDetails(anime: Anime) async -> Anime? {
        do {
            guard let requestUrl = anime.detailsUrl else {
                Log.shared.msg("No valid details url.")
                return nil
            }

            let (data, _) = try await URLSession.shared.data(from: requestUrl)
            
            let newAnime = try JSONDecoder().decode(GogoanimeDetailsApi.self, from: data)
            
            var result: Anime? = Anime(
                title: newAnime.title,
                altTitles: newAnime.otherName != nil ? [newAnime.otherName!] : nil,
                description: newAnime.description,
                tags: newAnime.genres?.map { AnimeTag(name: $0) },
                detailsUrl: anime.detailsUrl,
                imageUrl: URL(string: newAnime.image ?? ""),
                episodes: newAnime.episodes?.map { Episode(
                    title: "Episode \($0.number)",
                    episodeUrl: URL(string: $0.url)!,
                    episodeId: $0.id)
                })
            result?.detailsLoadingState = .success
            
            return result
        } catch {
            Log.shared.error(error)
            return nil
        }
    }
    
    func getStreamingUrl(for episode: Episode, anime: Anime, returnEpisode: @escaping (Episode?) -> Void) async {
        guard let episodeId = episode.episodeId else {
            Log.shared.msg("An error occured while getting episodeId.")
            return
        }
        
        if let requestUrl = URL(string: "https://api.consumet.org/anime/gogoanime/watch/" + episodeId) {
            let request = URLRequest(url: requestUrl)
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                do {
                    let decoded = try JSONDecoder().decode(GogoanimeStreamingUrlApi.self, from: data ?? Data())
                    
                    var result: Episode = episode
                    
                    result.referer = URL(string: decoded.headers?.referer ?? "")
                    result.downloadUrl = URL(string: decoded.download ?? "")
                    result.streamingUrls = decoded.sources?.map {
                        StreamingUrl(
                            url: URL(string: $0.url ?? ""),
                            isM3U8: $0.isM3U8,
                            quality: $0.quality
                        )
                    }
                    
                    returnEpisode(result)
                } catch {
                    Log.shared.error(error)
                }
            }
            
            task.resume()
        } else {
            returnEpisode(nil)
        }
    }
}
