//
//  MangaSourcesVM.swift
//  Novee
//
//  Created by Nick on 2022-12-15.
//

import Foundation

class MangaSourcesVM: ObservableObject {
    static let shared = MangaSourcesVM()
    
    init() {
        sources[mangakakalot.sourceId] = mangakakalot
    }

    @Published var sources: [String: any MangaSource] = [:]
    
    var sourcesArray: [MangaSource] {
        Array(sources.values)
    }
    
    private let mangakakalot = MangaKakalot()
}
