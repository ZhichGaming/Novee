//
//  MangaSourcesVM.swift
//  Novee
//
//  Created by Nick on 2022-12-13.
//

import Foundation

class MangaSourcesVM: ObservableObject {
    static let shared = MangaSourcesVM()
    
    init() {
        sources[mangakakalot.sourceId] = mangakakalot
    }

    @Published var sources: [String: any MangaSource] = [:]
    
//    var sourcesArray: Published<[MangaSource]> {
    var sourcesArray: [MangaSource] {
//        Published(wrappedValue: Array(sources.values))
        Array(sources.values)
    }
    
    private let mangakakalot = MangaKakalot()
}
