//
//  NovelVM.swift
//  Novee
//
//  Created by Nick on 2023-03-03.
//

import Foundation

class NovelVM: ObservableObject {
    static let shared = NovelVM()
    
    init() {
        sources[readlightnovels.sourceId] = readlightnovels
    }
    
    @Published var sources: [String: any NovelSource] = [:]
    @Published var selectedSource = "readlightnovels"
    @Published var pageNumber = 1
        
    var sourcesArray: [NovelSource] {
        Array(sources.values)
    }
    
    /// `nil` if download is not in progress, `false` if download is in progress and not completed, `true` if download has finished
    @Published var chapterDownloadProgress: Bool? = nil
    
    private let readlightnovels = ReadLightNovels()
    
    func changeChapter(chapter: NovelChapter, novel: Novel, offset: Int = 1) -> NovelChapter? {
        if let chapterIndex: Int = novel.chapters?.firstIndex(where: { $0.id == chapter.id }) {
            guard let chapters = novel.chapters else {
                Log.shared.msg("Error: Chapters are empty!")
                return nil
            }
            
            if chapterIndex + offset >= 0 && chapterIndex + offset < chapters.count {
                return chapters[chapterIndex + offset]
            }
        }
        
        return nil
    }
    
    func getNovelDetails(for novel: Novel, source: String, result: @escaping (Novel?) -> Void) async {
        let finalUrl = novel.detailsUrl?.getFinalURL()
        
        DispatchQueue.main.async { [self] in
            if sources[source]?.baseUrl.contains(finalUrl?.host ?? "") == true {
                Task {
                    result(await sources[source]!.getNovelDetails(novel: novel))
                }
                
                return
            }
            
            for source in sourcesArray {
                if source.baseUrl.contains(finalUrl?.host ?? "") == true {
                    Task {
                        result(await sources[source.sourceId]!.getNovelDetails(novel: novel))
                    }
                    
                    break
                }
            }
        }
    }
    
    func getAllUpdatedNovelDetails(for oldSources: [String: Novel]) async -> [String: Novel] {
        var result = [String: Novel]()
        let semaphore = DispatchGroup()

        for oldSource in oldSources {
            if let _ = sources[oldSource.key] {
                semaphore.enter()
                
                await getNovelDetails(for: oldSource.value, source: oldSource.key) { newNovel in
                    if let newNovel = newNovel {
                        result[oldSource.key] = newNovel
                    } else {
                        result[oldSource.key] = oldSource.value
                    }
                    
                    semaphore.leave()
                }
            }
        }
        
        DispatchQueue.global().sync {
            semaphore.wait()
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
