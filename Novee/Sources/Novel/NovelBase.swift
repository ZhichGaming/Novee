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
    
    @Published var novelData: [Novel] = []
    
    func resetNovels() {
        NovelVM.shared.sources[NovelVM.shared.selectedSource]!.novelData = []
    }
    
    func resetChapters(for novel: Novel) {
        guard let index = NovelVM.shared.sources[NovelVM.shared.selectedSource]!.novelData.firstIndex(where: { $0.id == novel.id }) else {
            Log.shared.msg("Failed to reset chapters as the selected novel could not be found.")
            return
        }
        
        NovelVM.shared.sources[NovelVM.shared.selectedSource]!.novelData[index].chapters = []
    }
    
    func resetChapters(index: Int) {
        NovelVM.shared.sources[NovelVM.shared.selectedSource]!.novelData[index].chapters = []
    }
}

protocol NovelSource {
    var label: String { get }
    var baseUrl: String { get }
    var sourceId: String { get }
    
    var novelData: [Novel] { get set }
        
    @discardableResult
    func getNovel(pageNumber: Int) async -> [Novel]
    
    @discardableResult
    func getSearchNovel(pageNumber: Int, searchQuery: String) async -> [Novel]
    
    @discardableResult
    func getNovelDetails(novel: Novel) async -> Novel?
    
    func getNovelContent(novel: Novel, chapter: NovelChapter) async -> String?
}

