//
//  FavouritesVM.swift
//  Novee
//
//  Created by Nick on 2023-04-20.
//

import Foundation

class FavouritesVM: ObservableObject {
    static var shared = FavouritesVM()
    
    // rewrite this to Favourites array
    @Published var favourites: [Favourite] = []
    
    @discardableResult
    func getFavourites() -> [any MediaListElement] {
        let animeListVM = AnimeListVM.shared
        let mangaListVM = MangaListVM.shared
        let novelListVM = NovelListVM.shared
        
        let animeFavourites = animeListVM.list.filter { $0.rating == .best }
        let mangaFavourites = mangaListVM.list.filter { $0.rating == .best }
        let novelFavourites = novelListVM.list.filter { $0.rating == .best }
        
        let result = [animeFavourites as [any MediaListElement], mangaFavourites as [any MediaListElement], novelFavourites as [any MediaListElement]].reduce([], +).sorted { $0.lastViewedDate ?? .distantPast > $1.lastViewedDate ?? .distantPast }
        
        favourites = result.map { Favourite(mediaListElement: $0, loadingState: nil) }
        return result
    }
    
    func unfavourite<T: MediaListElement>(_ media: T) {
        switch media.type {
        case .anime:
            guard let index = AnimeListVM.shared.list.firstIndex(where: { $0.id == media.id }) else {
                Log.shared.msg("Cannot find favourited item in list.")
                return
            }
            
            AnimeListVM.shared.list[index].rating = .good
        case .manga:
            guard let index = MangaListVM.shared.list.firstIndex(where: { $0.id == media.id }) else {
                Log.shared.msg("Cannot find favourited item in list.")
                return
            }
            
            MangaListVM.shared.list[index].rating = .good
        case .novel:
            guard let index = NovelListVM.shared.list.firstIndex(where: { $0.id == media.id }) else {
                Log.shared.msg("Cannot find favourited item in list.")
                return
            }
            
            NovelListVM.shared.list[index].rating = .good
        }
        
        getFavourites()
    }

    @discardableResult
    func fetchLatestSegments<T: MediaListElement>(for media: T) async -> T? {
        guard let index = favourites.firstIndex(where: { $0.mediaListElement.id == media.id }) else {
            Log.shared.msg("Cannot find favourited item in list.")
            return media
        }
        
        Task { @MainActor in
            favourites[index].loadingState = .loading
        }
        
        var updatedMediaDetails: [String: T.AssociatedMediaType]? = nil
        
        if let anime = media as? AnimeListElement {
            updatedMediaDetails = await AnimeVM.shared.getAllUpdatedMediaDetails(for: anime.content, returnUnupdatedValue: false) as? [String: T.AssociatedMediaType]
        } else if let manga = media as? MangaListElement {
            updatedMediaDetails = await MangaVM.shared.getAllUpdatedMediaDetails(for: manga.content, returnUnupdatedValue: false) as? [String: T.AssociatedMediaType]
        } else if let novel = media as? NovelListElement {
            updatedMediaDetails = await NovelVM.shared.getAllUpdatedMediaDetails(for: novel.content, returnUnupdatedValue: false) as? [String: T.AssociatedMediaType]
        }
        
        guard let updatedMediaDetails = updatedMediaDetails else {
            Log.shared.msg("Failed to fetch latest segment for favourited item.")
            
            Task { @MainActor in
                favourites[index].loadingState = .failed
            }
            
            return nil
        }
        
        if updatedMediaDetails.values.isEmpty || !updatedMediaDetails.values.map({ $0.segments == nil }).contains(false) {
            Task { @MainActor in
                favourites[index].loadingState = .failed
            }
                        
//            print("Values is empty: " + updatedMediaDetails.values.isEmpty.description)
//            print("Does not contain a segment that isn't nil: " + (!updatedMediaDetails.values.map({ $0.segments == nil }).contains(false)).description)
            
            return nil
        } else {
            Task { @MainActor in
                favourites[index].loadingState = .success
            }
            
            return favourites[index].mediaListElement as? T
        }
    }
    
    /// Gets the latest segment for some `mediaListElement` from sources saved in the user's media lists.
    func getLastFetchedSegment(for mediaListElement: any MediaListElement) async -> String? {
        guard let allLatestSegments = await fetchLatestSegments(for: mediaListElement)?.content else {
            return nil
        }
        
        var currentLatestSegment = ""
        
        for source in allLatestSegments.values {
            /// This if statement checks if the current looped over source has chapters later than previous sources. Checks if:
            /// - The current latest segment exists in this source.
            /// - The last segment exists in this source (whether the source is empty).
            /// - The current latest segment is not the source last segment.
            if let currentLast = source.segments?.first(where: { $0.title == currentLatestSegment }),
               let sourceLast = source.segments?.last?.title,
               currentLast.title != sourceLast {
                currentLatestSegment = sourceLast
            } else if let sourceLast = source.segments?.last?.title, currentLatestSegment.isEmpty {
                currentLatestSegment = sourceLast
            }
        }
        
        return currentLatestSegment
    }
}
