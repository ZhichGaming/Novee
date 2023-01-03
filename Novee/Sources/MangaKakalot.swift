//
//  MangaKakalot.swift
//  Novee
//
//  Created by Nick on 2022-12-12.
//

import Foundation
import SwiftSoup
import SwiftUI

class MangaKakalot: MangaFetcher, MangaSource {
    init(label: String = "MangaKakalot", sourceId: String = "mangakakalot", baseUrl: String = "https://mangakakalot.com") {
        self.label = label
        self.sourceId = sourceId
        self.baseUrl = baseUrl
        
        super.init()
    }
            
    // Source info
    let label: String
    let sourceId: String
    let baseUrl: String
 
    func getManga(pageNumber: Int) async {
        do {
            var htmlPage = ""
            
            DispatchQueue.main.async {
                super.resetMangas()
            }
            
            guard let requestUrl = URL(string: baseUrl + "/manga_list?page=\(pageNumber)") else {
                Log.shared.msg("An error occured while formatting the URL")
                return
            }

            let (data, _) = try await URLSession.shared.data(from: requestUrl)
            
            if let stringData = String(data: data, encoding: .utf8) {
                if stringData.isEmpty {
                    Log.shared.msg("An error occured while fetching manga.")
                }
                
                htmlPage = stringData
            }
            
            let document: Document = try SwiftSoup.parse(htmlPage)
            let mangas: Elements = try document.getElementsByClass("list-truyen-item-wrap")
            
            /// Announce changes
            DispatchQueue.main.sync {
                MangaVM.shared.objectWillChange.send()
            }
            
            for manga in mangas.array() {
                var result = Manga(title: try manga.child(0).attr("title"))
                result.description = try manga.children().last()?.text()
                result.detailsUrl = try URL(string: manga.child(0).attr("href"))
                result.imageUrl = try URL(string: manga.child(0).child(0).attr("src"))
                
                super.mangaData.append(result)
            }
        } catch {
            Log.shared.error(error)
        }
    }
    
    func getSearchManga(pageNumber: Int, searchQuery: String) async {
        do {
            var htmlPage = ""
            
            do {
                let regex = try NSRegularExpression(pattern: "[^a-zA-Z0-9-._~ ]", options: [])
                let safeSearchQuery = regex.stringByReplacingMatches(in: searchQuery, options: [], range: NSRange(location: 0, length: searchQuery.utf16.count), withTemplate: "").replacingOccurrences(of: " ", with: "_")
                
                guard let requestUrl = URL(string: baseUrl + "/search/story/" + safeSearchQuery + "?page=\(pageNumber)") else {
                    Log.shared.msg("An error occured while formatting the URL")
                    return
                }

                let (data, _) = try await URLSession.shared.data(from: requestUrl)
                
                if let stringData = String(data: data, encoding: .utf8) {
                    if stringData.isEmpty {
                        Log.shared.msg("An error occured while fetching manga.")
                    }
                    
                    htmlPage = stringData
                }
            } catch {
                Log.shared.error(error)
            }
            
            let document: Document = try SwiftSoup.parse(htmlPage)
            let mangas: Elements = try document.getElementsByClass("story_item")
            
            /// Announce changes
            DispatchQueue.main.sync {
                MangaVM.shared.objectWillChange.send()
            }
            
            /// Reset mangas
            mangaData = [Manga]()

            for manga in mangas.array() {
                var result = Manga(title: try manga.child(1).child(0).child(0).text())
                result.detailsUrl = try URL(string: manga.child(0).attr("href"))
                result.imageUrl = try URL(string: manga.child(0).child(0).attr("src"))
                
                super.mangaData.append(result)
            }
        } catch {
            Log.shared.error(error)
        }
    }
    
    func fetchMangaDetails(manga: Manga) async -> Manga? {
        var htmlPage = ""
        var result: Manga?
        
        do {
            let (data, _) = try await URLSession.shared.data(from: manga.detailsUrl!)
            
            if let stringData = String(data: data, encoding: .utf8) {
                if stringData.isEmpty {
                    Log.shared.msg("An error occured while fetching manga details.")
                }
                
                htmlPage = stringData
            }
        
            let document: Document = try SwiftSoup.parse(htmlPage)
            let infoElement: Element = try document.getElementsByClass("manga-info-text")[0]
            
            result = Manga(title: try infoElement
                .child(0)
                .child(0)
                .text())
            if try !infoElement.getElementsByClass("story-alternative").isEmpty() {
                result?.altTitles = try infoElement
                    .getElementsByClass("story-alternative")[0]
                    .text()
                    .replacingOccurrences(of: "Alternative :", with: "")
                    .components(separatedBy: ";")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            }
            result?.description = try document
                .select("#noidungm")
                .text()
            result?.authors = try infoElement
                .child(1)
                .text()
                .replacingOccurrences(of: "Author(s) : ", with: "")
                .components(separatedBy: ", ")
            result?.tags = try Array(document
                .select("body > div.container > div.main-wrapper > div.leftCol > div.manga-info-top > ul > li:nth-child(7)")
                .eachText()[0]
                .replacingOccurrences(of: "Genres :", with: "")
                .replacingOccurrences(of: " ", with: "")
                .components(separatedBy: ",")
                .filter { !$0.isEmpty })
            
            var chapters: [Chapter] = []
            
            for chapterElement in try document.getElementsByClass("chapter-list")[0].children() {
                chapters.append(
                    Chapter(
                        title: try chapterElement
                            .child(0)
                            .child(0)
                            .text(),
                        chapterUrl: URL(string: try chapterElement
                            .child(0)
                            .child(0)
                            .attr("href"))!
                    ))
            }

            result?.chapters = chapters.reversed()
        } catch {
            Log.shared.error(error)
        }
        
        return result
    }
    
    func getMangaDetails(manga: Manga) async {
        if let result = await fetchMangaDetails(manga: manga) {
            super.assignMangaDetails(manga: manga, result: result)
        } else {
            Log.shared.msg("An error occured while fetching manga details")
        }
    }
    
    func getMangaPages(manga: Manga, chapter: Chapter) async -> [NSImage] {
        var htmlPage = ""
        var result = [NSImage]()

        var selectedMangaIndex: Int? {
            MangaVM.shared.sources[MangaVM.shared.selectedSource]?.mangaData.firstIndex { $0.id == manga.id }
        }
        
        var selectedChapterIndex: Int? { MangaVM.shared.sources[MangaVM.shared.selectedSource]?.mangaData[selectedMangaIndex ?? 0].chapters?.firstIndex { $0.id == chapter.id }
        }
        
        Task { @MainActor in
            MangaVM.shared.sources[MangaVM.shared.selectedSource]?.mangaData[selectedMangaIndex ?? 0].chapters?[selectedChapterIndex ?? 0].images = [NSImage]()
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: chapter.chapterUrl)

            if let stringData = String(data: data, encoding: .utf8) {
                if stringData.isEmpty {
                    Log.shared.msg("An error occured while fetching manga pages.")
                }
                
                htmlPage = stringData
            }
            
            let document: Document = try SwiftSoup.parse(htmlPage)

            let images = try document.getElementsByClass("container-chapter-reader")[0].children().filter { $0.nodeName() == "img" }

            for (index, imageElement) in images.enumerated() {
                guard let imageUrl = URL(string: try imageElement.attr("src")) else {
                    Log.shared.msg("An error occured while fetching an image url.")
                    return []
                }
                
                var request = URLRequest(url: imageUrl)

                request.setValue(baseUrl, forHTTPHeaderField: "Referer")
                
                if selectedMangaIndex == nil || selectedChapterIndex == nil {
                    Log.shared.msg("An error occured while getting an index.")
                    return []
                }

                var repeatCount = 0
                /// Wait for previous page to finish saving before going to the next one. This may stop all the pages from loading if a single page is corrupted.
                while index > result.count && repeatCount < 3000 {
                    usleep(10000)
                    repeatCount += 1
                }
                
                let semaphore = DispatchSemaphore(value: 0)
                
                await super.getImage(request: request, manga: manga, chapter: chapter) { image in
                    if let image = image {
                        result.append(image)
                        semaphore.signal()
                    }
                }
                
                DispatchQueue.global().sync {
                    semaphore.wait()
                }
            }
        } catch {
            Log.shared.error(error)
        }
        
        return result
    }
}
