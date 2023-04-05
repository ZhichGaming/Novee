//
//  HomeVM.swift
//  Novee
//
//  Created by Nick on 2023-03-29.
//

import Foundation

class HomeVM: ObservableObject {
    static var shared = HomeVM()
    
    init() {
        
    }
    
    @Published var newAnime: [Anime] = []
    @Published var newManga: [Manga] = []
    @Published var newNovels: [Novel] = []
    
    func getLatestActivities(_ length: Int = 10) -> [any MediaListElement] {
        let anime = AnimeListVM.shared.getLatestMedia(length)
        let manga = MangaListVM.shared.getLatestMedia(length)
        let novel = NovelListVM.shared.getLatestMedia(length)
        
        // Create an array with the media objects
        let doubleMediaList: [[any MediaListElement]] = [anime, manga, novel]
        var mediaList = doubleMediaList.flatMap { $0 }

        // Sort the media objects by their lastViewedDate, if available
        mediaList.sort {
            guard let lhsDate = $0.lastViewedDate, let rhsDate = $1.lastViewedDate else {
                // If one of the dates is nil, put it at the end of the list
                return true
            }
            
            return lhsDate < rhsDate
        }

        // Return the last item in the array, which has the latest date, if there is one
        return mediaList.suffix(length)
    }
    
    func fetchLatestMedia() async {
        await getLatestAnime()
        await getLatestManga()
        await getLatestNovels()
    }
    
    @discardableResult
    func getLatestAnime(page: Int = 1) async -> [Anime] {
        let mediaVM = AnimeVM.shared
        
        let result = await mediaVM.sources[mediaVM.selectedSource]!.getAnime(pageNumber: page)
        
        Task { @MainActor in
            newAnime.append(contentsOf: result)
        }
        
        return result
    }
    
    @discardableResult
    func getLatestManga(page: Int = 1) async -> [Manga] {
        let mediaVM = MangaVM.shared
        
        let result = await mediaVM.sources[mediaVM.selectedSource]!.getManga(pageNumber: page)
        
        Task { @MainActor in
            newManga.append(contentsOf: result)
        }
        
        return result
    }
    
    @discardableResult
    func getLatestNovels(page: Int = 1) async -> [Novel] {
        let mediaVM = NovelVM.shared
        
        let result = await mediaVM.sources[mediaVM.selectedSource]!.getNovel(pageNumber: page)
        
        Task { @MainActor in
            newNovels.append(contentsOf: result)
        }
        
        return result
    }
    
}
