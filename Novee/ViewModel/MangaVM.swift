//
//  MangaVM.swift
//  Novee
//
//  Created by Nick on 2022-10-17.
//

import Foundation
import SwiftUI

class MangaVM: MediaVM<Manga> {
    static let shared = MangaVM()
    
    init() {
        super.init(selectedSource: "mangakakalot")
        
        sources[mangakakalot.sourceId] = mangakakalot
        sources[manganato.sourceId] = manganato
        sources[chapmanganato.sourceId] = chapmanganato
        sources[asurascans.sourceId] = asurascans
    }

    @Published var sources: [String: any MangaSource] = [:]
    
    @Published var chapterDownloadProgress: ChapterDownloadProgress? = nil

    var sourcesArray: [any MangaSource] {
        Array(sources.values)
    }
    
    private let mangakakalot = MangaKakalot()
    private let manganato = MangaNato()
    private let chapmanganato = ChapMangaNato()
    private let asurascans = AsuraScans()
    
    func changeChapter(chapter: Chapter, manga: Manga, offset: Int = 1) -> Chapter? {
        if let chapterIndex: Int = manga.segments?.firstIndex(where: { $0.id == chapter.id }) {
            guard let chapters = manga.segments else {
                Log.shared.msg("Error: Chapters are empty!")
                return nil
            }
            
            if chapterIndex + offset >= 0 && chapterIndex + offset < chapters.count {
                return chapters[chapterIndex + offset]
            }
        }
        
        return nil
    }
    
    @discardableResult
    func getMangaDetails(for manga: Manga) async -> Manga? {
        let finalUrl = manga.detailsUrl?.getFinalURL()

        let continuation = await withCheckedContinuation { continuation in
            if sources[selectedSource]?.baseUrl.contains(finalUrl?.host ?? "") == true {
                Task {
                    continuation.resume(returning: await sources[selectedSource]!.getMediaDetails(media: manga))
                }
                
                return
            }
            
            for source in sourcesArray {
                if source.baseUrl.contains(finalUrl?.host ?? "") == true {
                    Task {
                        continuation.resume(returning: await sources[source.sourceId]!.getMediaDetails(media: manga))
                    }
                    
                    break
                }
            }
        }
        
        return continuation
    }
    
    @discardableResult
    func getMangaDetails(for manga: Manga, source: String) async -> Manga? {
        let finalUrl = manga.detailsUrl?.getFinalURL()
        
        let continuation = await withCheckedContinuation { continuation in
            if sources[source]?.baseUrl.contains(finalUrl?.host ?? "") == true {
                Task {
                    continuation.resume(returning: await sources[source]!.getMediaDetails(media: manga))
                }
                
                return
            }
            
            for source in sourcesArray {
                if source.baseUrl.contains(finalUrl?.host ?? "") == true {
                    Task {
                        continuation.resume(returning: await sources[source.sourceId]!.getMediaDetails(media: manga))
                    }
                    
                    break
                }
            }
        }
        
        return continuation
    }
    
    func getAllUpdatedMangaDetails(for oldSources: [String: Manga]) async -> [String: Manga] {
        var result = [String: Manga]()

        for oldSource in oldSources {
            if let _ = sources[oldSource.key] {
                if let newManga = await getMangaDetails(for: oldSource.value, source: oldSource.key) {
                    result[oldSource.key] = newManga
                } else {
                    result[oldSource.key] = oldSource.value
                }
            }
        }
        
        return result
    }
    
    func downloadChapter(manga: Manga, chapter: Chapter) async {
        do {
            if !FileManager().fileExists(atPath: URL.mangaStorageUrl.path) {
                try FileManager().createDirectory(at: .mangaStorageUrl, withIntermediateDirectories: false)
            }
            
            Task { @MainActor in
                var images: [Int: NSImage?] = [:] {
                    didSet {
                        Task { @MainActor in
                            chapterDownloadProgress = ChapterDownloadProgress(progress: images.map { $0.value }.filter { $0 != nil }.count, total: images.count)
                        }
                    }
                }
                
                do {
                    let safeMangaTitle = manga.title?.sanitizedFileName ?? "Unknown"
                    let currentMangaFolder = URL.mangaStorageUrl.appendingPathComponent(safeMangaTitle, conformingTo: .folder)
                    let currentChapterFolder = currentMangaFolder.appendingPathComponent(chapter.title.sanitizedFileName)
                    
                    if FileManager().fileExists(atPath: currentChapterFolder.path) {
                        try FileManager().removeItem(at: currentChapterFolder)
                    }
                    
                    if let thumbnailUrl = manga.imageUrl {
                        URLSession.shared.dataTask(with: thumbnailUrl) { data, response, error in
                            if let data = data {
                                if FileManager().fileExists(atPath: currentMangaFolder.appendingPathComponent("thumbnail", conformingTo: .png).path) {
                                    try? FileManager().removeItem(at: currentMangaFolder.appendingPathComponent("thumbnail", conformingTo: .png))
                                }
                                
                                FileManager().createFile(atPath: currentMangaFolder.appendingPathComponent("thumbnail", conformingTo: .png).path, contents: data)
                            }
                        }
                        .resume()
                    }
                        
                    try FileManager().createDirectory(at: currentChapterFolder, withIntermediateDirectories: true)
                
                    await sources[selectedSource]?.getMangaPages(manga: manga, chapter: chapter) { index, image in
                        images[index] = image.image
                        
                        if let image = image.image {
                            let destination = currentChapterFolder.appendingPathComponent("\(index + 1)", conformingTo: .png)
                            
                            FileManager().createFile(atPath: destination.path, contents: image.pngData())
                        }
                    }
                } catch {
                    Log.shared.error(error)
                }
            }
        } catch {
            Log.shared.error(error)
        }
    }
}

struct ChapterDownloadProgress {
    var progress: Int = 0
    var total: Int = 0
}
