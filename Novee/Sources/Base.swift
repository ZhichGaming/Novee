//
//  Base.swift
//  Novee
//
//  Created by Nick on 2022-12-13.
//

import Foundation
import AppKit

class MangaFetcher {
    @Published var mangaData: [Manga] = []

    func assignMangaDetails(manga: Manga, result: Manga) {
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
    
    func getImage(request: URLRequest, manga: Manga, chapter: Chapter, result: @escaping (NSImage?) -> Void) async {
        var selectedMangaIndex: Int? {
            MangaVM.shared.sources[MangaVM.shared.selectedSource]?.mangaData.firstIndex { $0.id == manga.id }
        }
        
        var selectedChapterIndex: Int? { MangaVM.shared.sources[MangaVM.shared.selectedSource]?.mangaData[selectedMangaIndex ?? 0].chapters?.firstIndex { $0.id == chapter.id }
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                Log.shared.error(error)
                return
            }
            
            guard let data = data else {
                Log.shared.msg("An error occured while fetching pages.")
                return
            }
            
            if let image = NSImage(data: data) {
                Task { @MainActor in
                    result(image)
                }
            }
        }
        
        task.resume()
        result(nil)
    }
}

protocol MangaSource {
    var label: String { get }
    var baseUrl: String { get }
    var sourceId: String { get }
    
    var mangaData: [Manga] { get set }
    
    func fetchMangaDetails(manga: Manga) async -> Manga?

    func getManga(pageNumber: Int) async
    func getSearchManga(pageNumber: Int, searchQuery: String) async
    func getMangaDetails(manga: Manga) async
    func getMangaPages(manga: Manga, chapter: Chapter) async -> [NSImage]?
}
