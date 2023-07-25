//
//  NovelVM.swift
//  Novee
//
//  Created by Nick on 2023-03-03.
//

import Foundation

class NovelVM: MediaVM<Novel> {
    static let shared = NovelVM()
    
    init() {
        super.init(selectedSource: "readlightnovels")
        
        sources[readlightnovels.sourceId] = readlightnovels
    }
    
    @Published var sources: [String: any NovelSource] = [:]
        
    var sourcesArray: [any NovelSource] {
        Array(sources.values)
    }
    
    /// `nil` if download is not in progress, `false` if download is in progress and not completed, `true` if download has finished
    @Published var chapterDownloadProgress: Bool? = nil
    
    private let readlightnovels = ReadLightNovels()
    
    func changeChapter(chapter: NovelChapter, novel: Novel, offset: Int = 1) -> NovelChapter? {
        if let chapterIndex: Int = novel.segments?.firstIndex(where: { $0.id == chapter.id }) {
            guard let chapters = novel.segments else {
                Log.shared.msg("Error: Chapters are empty!")
                return nil
            }
            
            if chapterIndex + offset >= 0 && chapterIndex + offset < chapters.count {
                return chapters[chapterIndex + offset]
            }
        }
        
        return nil
    }
    
    func getNovelDetails(for novel: Novel, source: String) async -> Novel? {
        let finalUrl = novel.detailsUrl?.getFinalURL()
        
        return await withCheckedContinuation { continuation in
            if sources[source]?.baseUrl.contains(finalUrl?.host ?? "") == true {
                Task {
                    continuation.resume(returning: await sources[source]!.getMediaDetails(media: novel))
                }
                
                return
            }
            
            for source in sourcesArray {
                if source.baseUrl.contains(finalUrl?.host ?? "") == true {
                    Task {
                        continuation.resume(returning: await sources[source.sourceId]!.getMediaDetails(media: novel))
                    }
                    
                    return
                }
            }
            
            continuation.resume(returning: nil)
        }
    }
    
    func getAllUpdatedNovelDetails(for oldSources: [String: Novel]) async -> [String: Novel] {
        var result = [String: Novel]()

        for oldSource in oldSources {
            if let _ = sources[oldSource.key] {
                if let newNovel = await getNovelDetails(for: oldSource.value, source: oldSource.key) {
                    result[oldSource.key] = newNovel
                } else {
                    result[oldSource.key] = oldSource.value
                }
            }
        }
        
        return result
    }
    
    func downloadChapter(novel: Novel, chapter: NovelChapter) async {
        do {
            if !FileManager().fileExists(atPath: URL.novelStorageUrl.path) {
                try FileManager().createDirectory(at: .novelStorageUrl, withIntermediateDirectories: false)
            }
            
            Task { @MainActor in
                chapterDownloadProgress = false
                let content = await sources[selectedSource]!.getNovelContent(novel: novel, chapter: chapter)
                
                do {
                    let safeNovelTitle = novel.title?.sanitizedFileName ?? "Unknown"
                    let safeChapterTitle = chapter.title.sanitizedFileName
                    let currentNovelFolder = URL.novelStorageUrl.appendingPathComponent(safeNovelTitle, conformingTo: .folder)
                    let destination = currentNovelFolder.appendingPathComponent(safeChapterTitle, conformingTo: .plainText)
                    
                    if !FileManager().fileExists(atPath: currentNovelFolder.path) {
                        try FileManager().createDirectory(at: currentNovelFolder, withIntermediateDirectories: false)
                    }
                    
                    if FileManager().fileExists(atPath: destination.path) {
                        try FileManager().removeItem(at: destination)
                    }
                    
                    if let thumbnailUrl = novel.imageUrl {
                        URLSession.shared.dataTask(with: thumbnailUrl) { data, response, error in
                            if let data = data {
                                if FileManager().fileExists(atPath: currentNovelFolder.appendingPathComponent("thumbnail", conformingTo: .png).path) {
                                    try? FileManager().removeItem(at: currentNovelFolder.appendingPathComponent("thumbnail", conformingTo: .png))
                                }
                                
                                FileManager().createFile(atPath: currentNovelFolder.appendingPathComponent("thumbnail", conformingTo: .png).path, contents: data)
                            }
                        }
                        .resume()
                    }
                    
                    FileManager().createFile(atPath: destination.path, contents: content?.data(using: .utf8))
                } catch {
                    Log.shared.error(error)
                }
                
                chapterDownloadProgress = true
            }
        } catch {
            Log.shared.error(error)
        }
    }
}
