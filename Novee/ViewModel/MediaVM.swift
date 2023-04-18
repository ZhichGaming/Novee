//
//  MediaVM.swift
//  Novee
//
//  Created by Nick on 2023-03-30.
//

import Foundation

class MediaVM<T: Media>: ObservableObject {
    init(selectedSource: String) {
        self.selectedSource = selectedSource
    }
    
    @Published var selectedSource: String
    @Published var pageNumber = 1
    
    var mediaType: MediaType {
        if T.self == Anime.self {
            return .anime
        } else if T.self == Manga.self {
            return .manga
        } else if T.self == Novel.self {
            return .novel
        }
        
        return .anime
    }
    
    func getMediaDetails(for media: T, source: String) async -> T? {
        if let anime = media as? Anime {
            return await AnimeVM.shared.getAnimeDetails(for: anime, source: source) as! T?
        } else if let manga = media as? Manga {
            return await MangaVM.shared.getMangaDetails(for: manga, source: source) as! T?
        } else if let novel = media as? Novel {
            return await NovelVM.shared.getNovelDetails(for: novel, source: source) as! T?
        } else {
            return nil
        }
    }
    
    func getAllUpdatedMediaDetails(for oldSources: [String: T]) async -> [String: T] {
        var result = [String: T]()
        
        var sources: [String: any MediaSource] {
            switch mediaType {
            case .anime:
                return AnimeVM.shared.sources
            case .manga:
                return MangaVM.shared.sources
            case .novel:
                return NovelVM.shared.sources
            }
        }

        for oldSource in oldSources {
            if let _ = sources[oldSource.key] {
                if let newMedia = await getMediaDetails(for: oldSource.value, source: oldSource.key) {
                    result[oldSource.key] = newMedia
                } else {
                    result[oldSource.key] = oldSource.value
                }
            }
        }
        
        return result
    }
}
