//
//  AnimeListVM.swift
//  Novee
//
//  Created by Nick on 2023-02-18.
//

import Foundation

class AnimeListVM: MediaListVM<AnimeListElement> {
    static let shared = AnimeListVM()
    
    init() {
        super.init(savePath: URL.animeListStorageUrl.path)
    }
    
    func addToList(source: String, anime: Anime, lastSegment: String? = nil, status: Status, rating: Rating = .none, creationDate: Date = Date.now, lastViewedDate: Date? = nil) {
        list.append(AnimeListElement(content: [source: anime], lastSegment: lastSegment, status: status, rating: rating, lastViewedDate: lastViewedDate, creationDate: creationDate))
    }
    
    func addToList(animes: [String: Anime], lastSegment: String? = nil, status: Status, rating: Rating = .none, creationDate: Date = Date.now, lastViewedDate: Date? = nil) {
        list.append(AnimeListElement(content: animes, lastSegment: lastSegment, status: status, rating: rating, lastViewedDate: lastViewedDate, creationDate: creationDate))
    }
    
    func findEpisodeInList(anime: Anime, episode: Episode) -> Episode? {
        let animeListElement = findInList(media: anime)
        
        return animeListElement?.content[AnimeVM.shared.selectedSource]?.segments?.first { sourceEpisode in
            if sourceEpisode.episodeId != nil && episode.episodeId != nil {
                return sourceEpisode.episodeId == episode.episodeId
            } else {
                return sourceEpisode.segmentUrl == episode.segmentUrl
            }
        }
    }
    
    func updateResumeTime(anime: Anime, episode: Episode, newTime: Double) {
        guard let animeIndex = list.firstIndex(where: { $0.id == findInList(media: anime)?.id }) else { return }
        guard let episodeIndex = list[animeIndex].content[AnimeVM.shared.selectedSource]?.segments?.firstIndex(where: {
            if $0.episodeId != nil && episode.episodeId != nil {
                return $0.episodeId == episode.episodeId
            } else {
                return $0.title == episode.title
            }
        }) else { return }
        
        list[animeIndex].content[AnimeVM.shared.selectedSource]?.segments?[episodeIndex].resumeTime = newTime
    }
    
    func getResumeTime(anime: Anime, episode: Episode) -> Double? {
        guard let animeIndex = list.firstIndex(where: { $0.id == findInList(media: anime)?.id }) else { return nil }
        guard let episodeIndex = list[animeIndex].content[AnimeVM.shared.selectedSource]?.segments?.firstIndex(where: { $0.id == findEpisodeInList(anime: anime, episode: episode)?.id }) else { return nil }
        
        return list[animeIndex].content[AnimeVM.shared.selectedSource]?.segments?[episodeIndex].resumeTime
    }
}
