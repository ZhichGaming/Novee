//
//  MangaBase.swift
//  Novee
//
//  Created by Nick on 2022-12-13.
//

import Foundation
import AppKit

class MangaFetcher {
    init(label: String, sourceId: String, baseUrl: String) {
        self.label = label
        self.sourceId = sourceId
        self.baseUrl = baseUrl
    }
    
    // Source info
    let label: String
    let sourceId: String
    let baseUrl: String
    
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
    
    func refetchMangaPage(chapter: Chapter, pageIndex: Int, returnImage: @escaping (MangaImage) -> Void) async {
        guard let imageUrl = chapter.images?[pageIndex]?.url else {
            Log.shared.msg("An error occured while refetching image.")
            return
        }
        
        returnImage(MangaImage(image: nil, url: imageUrl, loadingState: .loading))
        
        var request = URLRequest(url: imageUrl)

        request.setValue(baseUrl, forHTTPHeaderField: "Referer")
        
        await getImage(request: request) { image in
            if let image = image {
                returnImage(MangaImage(image: image, url: imageUrl, loadingState: .success))
            } else {
                returnImage(MangaImage(image: nil, url: imageUrl, loadingState: .failed))
            }
        }
    }
    
    func getImage(request: URLRequest, result: @escaping (NSImage?) -> Void) async {
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                Log.shared.error(error)
                result(nil)
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
    }
    
    func resetMangas() {
        MangaVM.shared.sources[MangaVM.shared.selectedSource]!.mangaData = []
    }
    
    func resetChapters(for manga: Manga) {
        guard let index = MangaVM.shared.sources[MangaVM.shared.selectedSource]!.mangaData.firstIndex(where: { $0.id == manga.id }) else {
            Log.shared.msg("Failed to reset chapters as the selected manga could not be found.")
            return
        }
        
        MangaVM.shared.sources[MangaVM.shared.selectedSource]!.mangaData[index].chapters = []
    }
    
    func resetChapters(index: Int) {
        MangaVM.shared.sources[MangaVM.shared.selectedSource]!.mangaData[index].chapters = []
    }
    
    /// These functions are here if they are ever going to be used. They are useless at the time of being written since the pages are currently not stored within MangaVM. 
    func resetPages(manga: Manga, chapter: Chapter) {
        guard let mangaIndex = MangaVM.shared.sources[MangaVM.shared.selectedSource]!.mangaData.firstIndex(where: { $0.id == manga.id }) else {
            Log.shared.msg("Failed to reset chapter pages as the selected manga could not be found.")
            return
        }
        
        guard let chapterIndex = MangaVM.shared.sources[MangaVM.shared.selectedSource]!.mangaData.firstIndex(where: { $0.id == manga.id }) else {
            Log.shared.msg("Failed to reset chapter pages as the selected chapter could not be found.")
            return
        }
        
        MangaVM.shared.sources[MangaVM.shared.selectedSource]!.mangaData[mangaIndex].chapters?[chapterIndex].images = [:]
    }
    
    func resetPages(mangaIndex: Int, chapterIndex: Int) {
        MangaVM.shared.sources[MangaVM.shared.selectedSource]!.mangaData[mangaIndex].chapters?[chapterIndex].images = [:]
    }
}

protocol MangaSource {
    var label: String { get }
    var baseUrl: String { get }
    var sourceId: String { get }
    
    var mangaData: [Manga] { get set }
    
    func fetchMangaDetails(manga: Manga) async -> Manga?
    
    @discardableResult
    func getManga(pageNumber: Int) async -> [Manga]
    
    @discardableResult
    func getSearchManga(pageNumber: Int, searchQuery: String) async -> [Manga]
    
    @discardableResult
    func getMangaDetails(manga: Manga) async -> Manga?
    
    func refetchMangaPage(chapter: Chapter, pageIndex: Int, returnImage: @escaping (MangaImage) -> Void) async
    func getMangaPages(manga: Manga, chapter: Chapter, returnImage: @escaping (Int, MangaImage) -> Void) async
}
