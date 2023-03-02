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
    override init(label: String = "MangaKakalot", sourceId: String = "mangakakalot", baseUrl: String = "https://mangakakalot.com") {
        super.init(label: label, sourceId: sourceId, baseUrl: baseUrl)
    }
 
    func getManga(pageNumber: Int) async -> [Manga] {
        do {
            var htmlPage = ""
            
            DispatchQueue.main.async {
                super.resetMangas()
            }
            
            guard let requestUrl = URL(string: baseUrl + "/manga_list?page=\(pageNumber)") else {
                Log.shared.msg("An error occured while formatting the URL")
                return []
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
            
            var finalResult: [Manga] = []
            
            for manga in mangas.array() {
                var result = Manga(title: try manga.child(0).attr("title"))
                result.description = try manga.children().last()?.text()
                result.detailsUrl = try URL(string: manga.child(0).attr("href"))
                result.imageUrl = try URL(string: manga.child(0).child(0).attr("src"))
                result.chapters = [try Chapter(title: manga.child(2).text(), chapterUrl: URL(string: manga.child(2).attr("href"))!)]
                
                super.mangaData.append(result)
                finalResult.append(result)
            }
            
            return finalResult
        } catch {
            Log.shared.error(error)
            return []
        }
    }
    
    func getSearchManga(pageNumber: Int, searchQuery: String) async -> [Manga] {
        do {
            var htmlPage = ""
            
            let regex = try NSRegularExpression(pattern: "[^a-zA-Z0-9-._~ ]", options: [])
            let safeSearchQuery = regex.stringByReplacingMatches(in: searchQuery, options: [], range: NSRange(location: 0, length: searchQuery.utf16.count), withTemplate: "").replacingOccurrences(of: " ", with: "_")
            
            guard let requestUrl = URL(string: baseUrl + "/search/story/" + safeSearchQuery + "?page=\(pageNumber)") else {
                Log.shared.msg("An error occured while formatting the URL")
                return []
            }

            let (data, _) = try await URLSession.shared.data(from: requestUrl)
            
            if let stringData = String(data: data, encoding: .utf8) {
                if stringData.isEmpty {
                    Log.shared.msg("An error occured while fetching manga.")
                }
                
                htmlPage = stringData
            }
            
            let document: Document = try SwiftSoup.parse(htmlPage)
            let mangas: Elements = try document.getElementsByClass("story_item")
            
            /// Announce changes
            DispatchQueue.main.sync {
                MangaVM.shared.objectWillChange.send()
            }
            
            /// Reset mangas
            mangaData = [Manga]()
            var finalResult: [Manga] = []
            
            for manga in mangas.array() {
                var result = Manga(title: try manga.child(1).child(0).child(0).text())
                result.detailsUrl = try URL(string: manga.child(0).attr("href"))
                result.imageUrl = try URL(string: manga.child(0).child(0).attr("src"))
                result.chapters = try manga.getElementsByClass("story_chapter").map {
                    try Chapter(title: $0.child(0).text(), chapterUrl: URL(string: $0.child(0).attr("href"))!)
                }.reversed()
                
                super.mangaData.append(result)
                finalResult.append(result)
            }
            
            return finalResult
        } catch {
            Log.shared.error(error)
            return []
        }
    }
    
    func fetchMangaDetails(manga: Manga) async -> Manga? {
        var htmlPage = ""
        var result: Manga? = manga
        
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
            let tags: [Element] = try document.select("body > div.container > div.main-wrapper > div.leftCol > div.manga-info-top > ul > li:nth-child(7)").array().filter { $0.hasClass("nofollow") }
            
            result?.title = try infoElement
                .child(0)
                .child(0)
                .text()
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
            result?.tags = try tags.map { tag in
                try MangaTag(name: tag.text(), url: URL(string: tag.attr("href")))
            }
            
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
            result?.detailsLoadingState = .success
        } catch {
            Log.shared.error(error)
        }
        
        return result
    }
    
    func getMangaDetails(manga: Manga) async -> Manga? {
        if let result = await fetchMangaDetails(manga: manga) {
            return result
        } else {
            Log.shared.msg("An error occured while fetching manga details")
            return nil
        }
    }
    
    func getMangaPages(manga: Manga, chapter: Chapter, returnImage: @escaping (Int, MangaImage) -> Void) async {
        var htmlPage = ""

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
            
            images.enumerated().forEach { index, image in
                returnImage(index, MangaImage(image: nil, loadingState: .loading))
            }
            
            for (index, imageElement) in images.enumerated() {
                guard let imageUrl = URL(string: try imageElement.attr("src")) else {
                    Log.shared.msg("An error occured while fetching an image url.")
                    return
                }
                
                var request = URLRequest(url: imageUrl)

                request.setValue(baseUrl, forHTTPHeaderField: "Referer")
                                
                await super.getImage(request: request) { image in
                    if let image = image {
                        returnImage(index, MangaImage(image: image, url: imageUrl, loadingState: .success))
                    } else {
                        returnImage(index, MangaImage(image: image, url: imageUrl, loadingState: .failed))
                    }
                }
            }
        } catch {
            Log.shared.error(error)
        }
    }
}
