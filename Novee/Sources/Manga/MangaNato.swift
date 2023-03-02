//
//  MangaNato.swift
//  Novee
//
//  Created by Nick on 2022-12-12.
//

import Foundation
import SwiftSoup
import SwiftUI

class MangaNato: MangaFetcher, MangaSource {
    override init(label: String = "MangaNato", sourceId: String = "manganato", baseUrl: String = "https://manganato.com") {
        super.init(label: label, sourceId: sourceId, baseUrl: baseUrl)
    }

    func getManga(pageNumber: Int) async -> [Manga] {
        do {
            var htmlPage = ""
            
            DispatchQueue.main.async {
                super.resetMangas()
            }
            
            guard let requestUrl = URL(string: baseUrl + "/genre-all/\(pageNumber)") else {
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
            let mangas: Elements = try document.getElementsByClass("content-genres-item")
            
            /// Announce changes
            DispatchQueue.main.sync {
                MangaVM.shared.objectWillChange.send()
            }
            
            var finalResult: [Manga] = []
            
            for manga in mangas.array() {
                var result = Manga(title: try manga.child(1).child(0).child(0).text())
                result.description = try manga.child(1).child(3).text()
                result.detailsUrl = try URL(string: manga.child(1).child(0).child(0).attr("href"))
                result.imageUrl = try URL(string: manga.child(0).child(0).attr("src"))
                result.chapters = [try Chapter(title: manga.child(1).child(1).text(), chapterUrl: URL(string: manga.child(1).child(1).attr("href"))!)]

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
            let mangas: Elements = try document.getElementsByClass("search-story-item")
            
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
                result.chapters = try manga.child(1).getElementsByClass("item-chapter").map {
                    try Chapter(title: $0.text(), chapterUrl: URL(string: $0.attr("href"))!)
                }

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
            let infoElement: Element = try document.getElementsByClass("story-info-right")[0]
            let tags = try document.getElementsByClass("table-label").first {
                try $0.text().contains("Genres")
            }?.nextElementSibling()?.children().array().filter { $0.hasClass("a-h") }

            result?.title = try infoElement
                .child(0)
                .text()
            result?.altTitles = try infoElement
                .select("table > tbody > tr:nth-child(1) > td.table-value > h2")
                .text()
                .components(separatedBy: ";")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            result?.description = try document
                .select("#panel-story-info-description")
                .text()
                .replacingOccurrences(of: "Description : ", with: "")
            result?.authors = try infoElement
                .select("table > tbody > tr:nth-child(2) > td.table-value")
                .text()
                .components(separatedBy: "-")
            
            if let tags = tags {
                result?.tags = try tags.map { tag in
                    try MangaTag(name: tag.text(), url: URL(string: tag.attr("href")))
                }
            } else {
                print("Could not find tags")
            }
            
            var chapters: [Chapter] = []
            
            for chapterElement in try document.getElementsByClass("row-content-chapter")[0].children() {
                chapters.append(
                    Chapter(
                        title: try chapterElement
                            .child(0)
                            .text(),
                        chapterUrl: URL(string: try chapterElement
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
