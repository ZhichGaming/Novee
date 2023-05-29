//
//  AnimeBase.swift
//  Novee
//
//  Created by Nick on 2023-02-15.
//

import Foundation

class AnimeFetcher {
    init(label: String, sourceId: String, baseUrl: String) {
        self.label = label
        self.sourceId = sourceId
        self.baseUrl = baseUrl
    }
    
    // Source info
    let label: String
    let sourceId: String
    let baseUrl: String
    
    @Published var mediaData: [Anime] = []
}

protocol AnimeSource: MediaSource where AssociatedMediaType == Anime {
    func getStreamingUrl(for episode: Episode, anime: Anime) async -> Episode?
}
