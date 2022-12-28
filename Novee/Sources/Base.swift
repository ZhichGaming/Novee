//
//  Base.swift
//  Novee
//
//  Created by Nick on 2022-12-13.
//

import Foundation

class MangaFetcher {
    @Published var mangaData: [Manga] = []

    func getMangaDetails(manga: Manga, result: Manga) {
        DispatchQueue.main.sync {
            MangaVM.shared.objectWillChange.send()
            
            var passedSourceMangas: [Manga] {
                get { MangaVM.shared.sources[MangaVM.shared.selectedSource]!.mangaData }
                set { MangaVM.shared.sources[MangaVM.shared.selectedSource]?.mangaData = newValue }
            }
            
            let mangaIndex = passedSourceMangas.firstIndex(of: manga) ?? 0
                        
            passedSourceMangas[mangaIndex].title = result.title
            passedSourceMangas[mangaIndex].altTitles = result.altTitles ?? passedSourceMangas[mangaIndex].altTitles
            passedSourceMangas[mangaIndex].description = result.description ?? passedSourceMangas[mangaIndex].description
            passedSourceMangas[mangaIndex].authors = result.authors ?? passedSourceMangas[mangaIndex].authors
            passedSourceMangas[mangaIndex].tags = result.tags ?? passedSourceMangas[mangaIndex].tags
            passedSourceMangas[mangaIndex].chapters = result.chapters ?? passedSourceMangas[mangaIndex].chapters
            
            passedSourceMangas[mangaIndex].detailsLoadingState = .success
        }
    }
}

protocol MangaSource {
    var label: String { get }
    var baseUrl: String { get }
    var sourceId: String { get }
    
    var mangaData: [Manga] { get set }
    
    func fetchMangaDetails(manga: Manga) async -> Manga?

    func getManga() async
    func getMangaDetails(manga: Manga) async
}
