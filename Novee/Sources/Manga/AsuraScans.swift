//
//  AsuraScans.swift
//  Novee
//
//  Created by Nick on 2023-02-28.
//

import Foundation
import SwiftSoup

class AsuraScans: MangaFetcher, MangaSource {
    override init(label: String = "AsuraScans", sourceId: String = "asurascans", baseUrl: String = "https://www.asurascans.com") {
        super.init(label: label, sourceId: sourceId, baseUrl: baseUrl)
    }
    
    func getManga(pageNumber: Int) async -> [Manga] {
        do {
            var htmlPage = ""
            
            DispatchQueue.main.async {
                super.resetMangas()
            }
            
            guard let requestUrl = URL(string: baseUrl + "/page/\(pageNumber)/") else {
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
            let mangas: [Element] = try document.getElementsByClass("listupd")[1].children().array().filter { $0.hasClass("utao styletwo") }
            
            /// Announce changes
            DispatchQueue.main.sync {
                MangaVM.shared.objectWillChange.send()
            }

            var finalResult: [Manga] = []
            
            for manga in mangas {
                var result = Manga(title: try manga.child(0).child(1).child(0).attr("title"))
                result.detailsUrl = try URL(string: manga.child(0).child(0).child(0).attr("href"))
                result.imageUrl = try URL(string: manga.child(0).child(0).child(0).child(0).attr("src"))
                result.chapters = try manga.child(0).child(1).child(1).children().array().map {
                    let chapterElement = $0.children().array().first { $0.nodeName() == "a" }!
                    
                    return Chapter(title: try chapterElement.text(), chapterUrl: URL(string: try chapterElement.attr("href"))!)
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
    
    func getSearchManga(pageNumber: Int, searchQuery: String) async -> [Manga] {
        do {
            var htmlPage = ""
            
            let safeSearchQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            
            guard let requestUrl = URL(string: baseUrl + "/page/\(pageNumber)/?s=\(safeSearchQuery)") else {
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
            let mangas: Elements = try document.getElementsByClass("listupd")[0].children()
            
            /// Announce changes
            DispatchQueue.main.sync {
                MangaVM.shared.objectWillChange.send()
            }
            
            /// Reset mangas
            mangaData = [Manga]()
            var finalResult: [Manga] = []
            
            for manga in mangas.array() {
                var result = Manga(title: try manga.child(0).child(0).child(1).child(0).text())
                result.detailsUrl = try URL(string: manga.child(0).child(0).attr("href"))
                result.imageUrl = try URL(string: manga.child(0).child(0).child(0).child(2).attr("src"))
                
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
            let infoElement: Element = try document.getElementsByClass("bigcontent")[0]
            
            result?.title = try infoElement
                .child(1)
                .child(0)
                .text()
            
            if let altTitlesElement = try infoElement.child(1).children().array().first(where: { try $0.text().hasPrefix("Alternative Titles") }) {
                result?.altTitles = try altTitlesElement.child(1).text().components(separatedBy: ", ")
            }
            
            if let descriptionElement = try infoElement.child(1).children().array().first(where: { try $0.text().hasPrefix("Synopsis") }) {
                result?.description = try descriptionElement.text()
            }
            
            if let tagsElement = try infoElement.child(1).children().array().first(where: { try $0.text().hasPrefix("Genres") }) {
                result?.tags = try tagsElement.child(1).children().array().map {
                        try MangaTag(name: $0.text(), url: URL(string: $0.attr("href")))
                    }
            }
            
            if let authorsElement = try infoElement.child(1).children().array().first(where: {
                if $0.children().size() < 2 { return false }
                
                return try $0.child(1).text().hasPrefix("Author")
            }) {
                result?.authors = [try authorsElement.child(1).child(1).text().trimmingCharacters(in: .whitespacesAndNewlines)]
            }
            
            if let newUrl = URL(string: try infoElement.child(0).child(0).child(0).attr("href")) {
                result?.imageUrl = newUrl
            }
            
            var chapters: [Chapter] = []
            
            for chapterElement in try document.getElementsByClass("clstyle")[0].children() {
                chapters.append(
                    Chapter(
                        title: try chapterElement
                            .child(0)
                            .child(0)
                            .child(0)
                            .child(0)
                            .text(),
                        chapterUrl: URL(string: try chapterElement
                            .child(0)
                            .child(0)
                            .child(0)
                            .attr("href"))!
                    )
                )
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
            
            guard let readerArea = try document.getElementById("readerarea") else {
                Log.shared.msg("An error occured while fetching the images area.")
                return
            }
            
            let images = readerArea.children().array().filter { $0.nodeName() == "p" && !$0.children().isEmpty() && $0.child(0).nodeName() == "img" }.map { $0.child(0) }
            
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
