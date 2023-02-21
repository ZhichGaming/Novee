//
//  AnimeListVM.swift
//  Novee
//
//  Created by Nick on 2023-02-18.
//

import Foundation

class AnimeListVM: ObservableObject {
    static let shared = AnimeListVM()
    
    init() {
        list = []
        decode()
    }
    
    @Published var list: [AnimeListElement] {
        didSet {
            encode()
        }
    }
    
    func encode() {
        do {
            let encoded = try JSONEncoder().encode(list)
            
            FileManager().createFile(atPath: URL.animeListStorageUrl.path, contents: encoded)
        } catch {
            Log.shared.error(error)
        }
    }
    
    func decode() {
        do {
            if !FileManager().fileExists(atPath: URL.animeListStorageUrl.path) {
                FileManager().createFile(atPath: URL.animeListStorageUrl.path, contents: Data([]))
                return
            }
            
            if let data = FileManager().contents(atPath: URL.animeListStorageUrl.path) {
                let decoded = try JSONDecoder().decode([AnimeListElement].self, from: data)
                list = decoded
            } else {
                Log.shared.msg("An error occured while loading anime list data.")
            }
        } catch {
            Log.shared.error(error)
        }
    }
    
    func addToList(source: String, anime: Anime, lastEpisode: String? = nil, status: AnimeStatus, rating: AnimeRating = .none, creationDate: Date = Date.now, lastWatchDate: Date? = nil) {
        list.append(AnimeListElement(anime: [source: anime], lastEpisode: lastEpisode, status: status, rating: rating, lastWatchDate: lastWatchDate, creationDate: creationDate))
    }
    
    func addToList(animes: [String: Anime], lastEpisode: String? = nil, status: AnimeStatus, rating: AnimeRating = .none, creationDate: Date = Date.now, lastWatchDate: Date? = nil) {
        list.append(AnimeListElement(anime: animes, lastEpisode: lastEpisode, status: status, rating: rating, lastWatchDate: lastWatchDate, creationDate: creationDate))
    }
    
    func updateAnimeInListElement(id: UUID, source: String, anime: Anime) {
        if let index = list.firstIndex(where: { $0.id == id }) {
            list[index].anime[source] = anime
        } else {
            Log.shared.msg("A list entry with this UUID could not be found.")
        }
    }
    
    func updateListEntry(id: UUID, newValue: AnimeListElement) {
        if let index = list.firstIndex(where: { $0.id == id }) {
            list[index] = newValue
        } else {
            Log.shared.msg("A list entry with this UUID could not be found.")
        }
    }
    
    func updateStatus(id: UUID, to status: AnimeStatus) {
        if let index = list.firstIndex(where: { $0.id == id }) {
            list[index].status = status
        } else {
            Log.shared.msg("A list entry with this UUID could not be found.")
        }
    }
    
    func updateRating(id: UUID, to rating: AnimeRating) {
        if let index = list.firstIndex(where: { $0.id == id }) {
            list[index].rating = rating
        } else {
            Log.shared.msg("A list entry with this UUID could not be found.")
        }
    }
    
    func updateLastEpisode(id: UUID, to episode: String) {
        if let index = list.firstIndex(where: { $0.id == id }) {
            list[index].lastEpisode = episode
        } else {
            Log.shared.msg("A list entry with this UUID could not be found.")
        }
    }
    
    func updateLastReadDate(id: UUID, to date: Date?) {
        if let index = list.firstIndex(where: { $0.id == id }) {
            list[index].lastWatchDate = date
        } else {
            Log.shared.msg("A list entry with this UUID could not be found.")
        }
    }
    
    func findInList(anime: Anime) -> AnimeListElement? {
        let inputTitles = [anime.title] + (anime.altTitles ?? [])
        
        for anime in list {
            for source in anime.anime {
                for listTitle in [source.value.title] + (source.value.altTitles ?? []) {
                    for inputTitle in inputTitles {
                        if listTitle == inputTitle {
                            return anime
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    func findChapterInList(anime: Anime, episode: Episode) -> Episode? {
        let animeListElement = findInList(anime: anime)
        
        return animeListElement?.anime[AnimeVM.shared.selectedSource]?.episodes?.first(where: {
            if $0.episodeId != nil && episode.episodeId != nil {
                return $0.episodeId == episode.episodeId
            } else if $0.episodeUrl != nil && episode.episodeUrl != nil {
                return $0.episodeUrl == episode.episodeUrl
            } else {
                return $0.title == episode.title
            }
        })
    }
    
    func changeStaleReadingStatus(id: UUID) {
        if let index = list.firstIndex(where: { $0.id == id }) {
            let fiveDaysAgo = Calendar.current.date(byAdding: .day, value: -5, to: Date())!

            if list[index].lastWatchDate ?? Date.now < fiveDaysAgo {
                let containsLastEpisode = Array(list[index].anime.values).map { anime in
                    let episodeTitles = (anime.episodes ?? []).map { $0.title }
                    
                    if let lastTitle = episodeTitles.last, lastTitle == list[index].lastEpisode ?? "" {
                        return true
                    }
                    
                    return false
                }.contains(true)
                
                if containsLastEpisode {
                    list[index].status = .waiting
                } else {
                    list[index].status = .dropped
                }
            }
        } else {
            print("Error at changeStaleReadingStatus: Cannot find an element in the list with the id \(id)")
        }
    }
    
    func updateResumeTime(anime: Anime, episode: Episode, newTime: Double) {
        guard let animeIndex = list.firstIndex(where: { $0.id == findInList(anime: anime)?.id }) else { return }
        guard let episodeIndex = list[animeIndex].anime[AnimeVM.shared.selectedSource]?.episodes?.firstIndex(where: {
            if $0.episodeId != nil && episode.episodeId != nil {
                return $0.episodeId == episode.episodeId
            } else if $0.episodeUrl != nil && episode.episodeUrl != nil {
                return $0.episodeUrl == episode.episodeUrl
            } else {
                return $0.title == episode.title
            }
        }) else { return }
        
        list[animeIndex].anime[AnimeVM.shared.selectedSource]?.episodes?[episodeIndex].resumeTime = newTime
    }
    
    func getResumeTime(anime: Anime, episode: Episode) -> Double? {
        guard let animeIndex = list.firstIndex(where: { $0.id == findInList(anime: anime)?.id }) else { return nil }
        guard let episodeIndex = list[animeIndex].anime[AnimeVM.shared.selectedSource]?.episodes?.firstIndex(where: { $0.id == findChapterInList(anime: anime, episode: episode)?.id }) else { return nil }
        
        return list[animeIndex].anime[AnimeVM.shared.selectedSource]?.episodes?[episodeIndex].resumeTime
    }
    
}
