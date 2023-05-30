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
        
        favourites = result.map { Favourite(mediaListElement: $0, loadingState: .loading) }
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
}
