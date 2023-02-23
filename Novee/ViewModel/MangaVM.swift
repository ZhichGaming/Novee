//
//  MangaVM.swift
//  Novee
//
//  Created by Nick on 2022-10-17.
//

import Foundation
import SwiftUI

class MangaVM: ObservableObject {
    static let shared = MangaVM()
    
    init() {
        sources[mangakakalot.sourceId] = mangakakalot
        sources[manganato.sourceId] = manganato
        sources[chapmanganato.sourceId] = chapmanganato
    }

    @Published var sources: [String: any MangaSource] = [:]
    @Published var selectedSource = "mangakakalot"
    @Published var pageNumber = 1
    
    var sourcesArray: [MangaSource] {
        Array(sources.values)
    }
    
    private let mangakakalot = MangaKakalot()
    private let manganato = MangaNato()
    private let chapmanganato = ChapMangaNato()
    
    func changeChapter(chapter: Chapter, manga: Manga, offset: Int = 1) -> Chapter? {
        if let chapterIndex: Int = manga.chapters?.firstIndex(where: { $0.id == chapter.id }) {
            guard let chapters = manga.chapters else {
                Log.shared.msg("Error: Chapters are empty!")
                return nil
            }
            
            if chapterIndex + offset >= 0 && chapterIndex + offset < chapters.count {
                return chapters[chapterIndex + offset]
            }
        }
        
        return nil
    }
    
    func getMangaDetails(for manga: Manga) async {
        let mangaIndex = (sources[selectedSource]?.mangaData.firstIndex(of: manga))!
        let finalUrl = sources[selectedSource]?.mangaData[mangaIndex].detailsUrl?.getFinalURL()

        DispatchQueue.main.async { [self] in
            if sources[selectedSource]?.baseUrl.contains(finalUrl?.host ?? "") == true {
                Task {
                    await sources[selectedSource]!.getMangaDetails(manga: manga)
                }
                return
            }
            
            for source in sourcesArray {
                if source.baseUrl.contains(finalUrl?.host ?? "") == true {
                    Task {
                        await sources[source.sourceId]!.getMangaDetails(manga: manga)
                    }
                    break
                } else if source.sourceId == sourcesArray.last?.sourceId {
                    sources[selectedSource]?.mangaData[mangaIndex].detailsLoadingState = .notFound
                }
            }
        }
    }
    
    func getMangaDetails(for manga: Manga, source: String, result: @escaping (Manga?) -> Void) async {
        let finalUrl = manga.detailsUrl?.getFinalURL()
        
        DispatchQueue.main.async { [self] in
            if sources[source]?.baseUrl.contains(finalUrl?.host ?? "") == true {
                Task {
                    result(await sources[source]!.getMangaDetails(manga: manga))
                }
                
                return
            }
            
            for source in sourcesArray {
                if source.baseUrl.contains(finalUrl?.host ?? "") == true {
                    Task {
                        result(await sources[source.sourceId]!.getMangaDetails(manga: manga))
                    }
                    
                    break
                }
            }
        }
    }
}
