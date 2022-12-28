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
    
    var sourcesArray: [MangaSource] {
        Array(sources.values)
    }
    
    private let mangakakalot = MangaKakalot()
    private let manganato = MangaNato()
    private let chapmanganato = ChapMangaNato()
    
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
}
