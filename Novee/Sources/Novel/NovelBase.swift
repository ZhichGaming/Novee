//
//  NovelBase.swift
//  Novee
//
//  Created by Nick on 2023-03-03.
//

import Foundation

class NovelFetcher {
    init(label: String, sourceId: String, baseUrl: String) {
        self.label = label
        self.sourceId = sourceId
        self.baseUrl = baseUrl
    }
    
    // Source info
    let label: String
    let sourceId: String
    let baseUrl: String
    
    @Published var mediaData: [Novel] = []
    
    func resetNovels() {
        NovelVM.shared.sources[NovelVM.shared.selectedSource]!.mediaData = []
    }
    
    func resetChapters(for novel: Novel) {
        guard let index = NovelVM.shared.sources[NovelVM.shared.selectedSource]!.mediaData.firstIndex(where: { $0.id == novel.id }) else {
            Log.shared.msg("Failed to reset chapters as the selected novel could not be found.")
            return
        }
        
        NovelVM.shared.sources[NovelVM.shared.selectedSource]!.mediaData[index].segments = []
    }
    
    func resetChapters(index: Int) {
        NovelVM.shared.sources[NovelVM.shared.selectedSource]!.mediaData[index].segments = []
    }
}

protocol NovelSource: MediaSource where AssociatedMediaType == Novel {
    func getNovelContent(novel: Novel, chapter: NovelChapter) async -> String?
}

