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
    
    // Documentation: https://github.com/riimuru/gogoanime-api#routes
    let api = "https://gogoanime.consumet.stream"
    
    func getAnime(pageNumber: Int) async -> [Anime] {
        do {
            guard let requestUrl = URL(string: api + "/recent-release" + "?page=" + String(pageNumber)) else {
                Log.shared.msg("An error occured while formatting the URL")
                return []
            }

            let (data, _) = try await URLSession.shared.data(from: requestUrl)
            
            let animes = try JSONDecoder().decode([GogoanimeRecentReleaseApi].self, from: data)
            
            var result: [Anime] = []
                        
            for anime in animes {
                let converted = Anime(
                    title: anime.animeTitle,
                    detailsUrl: URL(string: api + "/anime-details/" + anime.animeId),
                    imageUrl: URL(string: anime.animeImg ?? ""))
                
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
            
            guard let requestUrl = URL(string: api + "/search?keyw=\(safeSearchQuery)&page=\(pageNumber)") else {
                Log.shared.msg("An error occured while formatting the URL")
                return []
            }

            let (data, _) = try await URLSession.shared.data(from: requestUrl)
            
            let animes = try JSONDecoder().decode([GogoanimeSearchApi].self, from: data)
            
            var result: [Anime] = []
                        
            for anime in animes {
                let converted = Anime(
                    title: anime.animeTitle,
                    detailsUrl: URL(string: api + "/anime-details/" + anime.animeId),
                    imageUrl: URL(string: anime.animeImg ?? ""))
                
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
            
            let result: Anime? = Anime(
                title: newAnime.animeTitle,
                altTitles: newAnime.otherNames?.components(separatedBy: ", "),
                description: newAnime.synopsis,
                tags: newAnime.genres?.map { AnimeTag(name: $0) },
                detailsUrl: anime.detailsUrl,
                imageUrl: URL(string: newAnime.animeImg ?? ""),
                episodes: newAnime.episodesList?.map { Episode(
                    title: "Episode " + $0.episodeNum,
                    episodeUrl: URL(string: $0.episodeUrl)!,
                    episodeId: $0.episodeId)
                }.reversed())
            
            if let result = result {
                super.assignAnimeDetails(anime: anime, result: result)
            } else {
                Log.shared.msg("New anime details is nil.")
                return nil
            }
            
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
