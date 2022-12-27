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
    init(label: String = "MangaKakalot", sourceId: String = "mangakakalot", baseUrl: String = "https://mangakakalot.com", pageType: MangaKakalot.PageType = .mangaList, type: String = "latest", pageNumber: Int = 1) {
        self.label = label
        self.sourceId = sourceId
        self.baseUrl = baseUrl
        
        self.pageType = pageType
        self.type = type
        self.pageNumber = pageNumber
        super.init()
    }
    
    @Published var mangaData: [Manga] = []
        
    // Source info
    let label: String
    let sourceId: String
    let baseUrl: String

    // Request parameters
    enum PageType {
        case mangaList
        case search
    }
    
    var pageType: PageType
    
    var type: String
    var pageNumber: Int
    var searchQuery: String = ""
    
    var requestUrl: URL {
        var result: URL?
        
        switch pageType {
        case .mangaList:
            result = URL(string: baseUrl + "/"
                         + "manga_list" + "?"
                         + "type=\(type)" + "&" + "page=\(pageNumber)")!
        case .search:
            result = URL(string: baseUrl + "/"
                         + "search/story/"
                         + searchQuery.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)!
        }
        return result!
    }
        
    func getManga() async {
        do {
            var htmlPage = ""

            do {
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
                
                self.mangaData.append(result)
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
            result?.altTitles = try infoElement
                .getElementsByClass("story-alternative")[0]
                .text()
                .replacingOccurrences(of: "Alternative :", with: "")
                .components(separatedBy: ";")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
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

            result?.chapters = chapters
        } catch {
            Log.shared.error(error)
        }
        
        return result
    }
    
    func getMangaDetails(manga: Manga) async {
        let mangaIndex = mangaData.firstIndex(of: manga)!
        if let result = await fetchMangaDetails(manga: manga) {
            DispatchQueue.main.sync {
                MangaVM.shared.objectWillChange.send()
                
                mangaData[mangaIndex].title = result.title
                mangaData[mangaIndex].altTitles = result.altTitles ?? mangaData[mangaIndex].altTitles
                mangaData[mangaIndex].description = result.description ?? mangaData[mangaIndex].description
                mangaData[mangaIndex].authors = result.authors ?? mangaData[mangaIndex].authors
                mangaData[mangaIndex].tags = result.tags ?? mangaData[mangaIndex].tags
                mangaData[mangaIndex].chapters = result.chapters ?? mangaData[mangaIndex].chapters
                
                mangaData[mangaIndex].detailsLoadingState = .success
            }
        } else {
            Log.shared.msg("An error occured while fetching manga details")
        }
    }
    
    func getMangaDetailsOnSelectedSource(manga: Manga) async {
        if let result = await fetchMangaDetails(manga: manga) {
            DispatchQueue.main.sync {
                MangaVM.shared.objectWillChange.send()
                
                var passedSourceMangas: [Manga] {
                    get { MangaVM.shared.sources[MangaVM.shared.selectedSource]!.mangaData }
                    set { MangaVM.shared.sources[MangaVM.shared.selectedSource]?.mangaData = newValue }
                }
                let mangaIndex = passedSourceMangas.firstIndex(of: manga)!
                
                passedSourceMangas[mangaIndex].title = result.title
                passedSourceMangas[mangaIndex].altTitles = result.altTitles ?? passedSourceMangas[mangaIndex].altTitles
                passedSourceMangas[mangaIndex].description = result.description ?? passedSourceMangas[mangaIndex].description
                passedSourceMangas[mangaIndex].authors = result.authors ?? passedSourceMangas[mangaIndex].authors
                passedSourceMangas[mangaIndex].tags = result.tags ?? passedSourceMangas[mangaIndex].tags
                passedSourceMangas[mangaIndex].chapters = result.chapters ?? passedSourceMangas[mangaIndex].chapters
                
                passedSourceMangas[mangaIndex].detailsLoadingState = .success
            }
        } else {
            Log.shared.msg("An error occured while fetching manga details")
        }
    }
}
