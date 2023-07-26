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
    func fetchLatestSegments<T: MediaListElement>(for media: T) async -> T {
        guard let index = favourites.firstIndex(where: { $0.mediaListElement.id == media.id }) else {
            Log.shared.msg("Cannot find favourited item in list.")
            return media
        }
        
        Task { @MainActor in
            favourites[index].loadingState = .loading
        }
        
        var updatedMediaDetails: [String: T.AssociatedMediaType]? = nil
        
        if let anime = media as? AnimeListElement {
            updatedMediaDetails = await AnimeVM.shared.getAllUpdatedMediaDetails(for: anime.content) as? [String: T.AssociatedMediaType]
        } else if let manga = media as? MangaListElement {
            updatedMediaDetails = await MangaVM.shared.getAllUpdatedMediaDetails(for: manga.content) as? [String: T.AssociatedMediaType]
        } else if let novel = media as? NovelListElement {
            updatedMediaDetails = await NovelVM.shared.getAllUpdatedMediaDetails(for: novel.content) as? [String: T.AssociatedMediaType]
        }
        
        guard let updatedMediaDetails = updatedMediaDetails else {
            Log.shared.msg("Failed to fetch latest segment for favourited item.")
            favourites[index].loadingState = .failed
            return media
        }
        
        Task { @MainActor in
            favourites[index].mediaListElement = T(
                content: updatedMediaDetails,
                lastSegment: favourites[index].mediaListElement.lastSegment,
                status: favourites[index].mediaListElement.status,
                rating: favourites[index].mediaListElement.rating,
                lastViewedDate: favourites[index].mediaListElement.lastViewedDate,
                creationDate: favourites[index].mediaListElement.creationDate)
            
            if updatedMediaDetails.values.isEmpty || !updatedMediaDetails.values.map({ $0.segments == nil }).contains(false) {
                favourites[index].loadingState = .failed
            } else {
                favourites[index].loadingState = .success
            }
        }
        
        return favourites[index].mediaListElement as! T
    }
    
}
