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
    }

    @Published var sources: [String: any MangaSource] = [:]
    @Published var selectedSource = "mangakakalot"
    
    var sourcesArray: [MangaSource] {
        Array(sources.values)
    }
    
    private let mangakakalot = MangaKakalot()
}
