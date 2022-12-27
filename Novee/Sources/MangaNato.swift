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
    init(label: String = "MangaNato", sourceId: String = "manganato", baseUrl: String = "https://manganato.com", pageType: MangaNato.PageType = .mangaList, type: String = "latest", pageNumber: Int = 1) {
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
                         + "genre-all" + "/"
                         + "\(pageNumber)")!
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
            let mangas: Elements = try document.getElementsByClass("content-genres-item")
            
            /// Announce changes
            DispatchQueue.main.sync {
                MangaVM.shared.objectWillChange.send()
            }
            
            for manga in mangas.array() {
                var result = Manga(title: try manga.child(1).child(0).child(0).text())
                result.description = try manga.child(1).child(3).text()
                result.detailsUrl = try URL(string: manga.child(1).child(0).child(0).attr("href"))
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
            let infoElement: Element = try document.getElementsByClass("story-info-right")[0]
            
            result = Manga(title: try infoElement
                .child(0)
                .text())
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
            result?.tags = try Array(document
                .select("table > tbody > tr:nth-child(4) > td.table-value")
                .text()
                .replacingOccurrences(of: " ", with: "")
                .components(separatedBy: "-")
                .filter { !$0.isEmpty })
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
                
                mangaData[mangaIndex].detailsLoadingState = .success
            }
        } else {
            Log.shared.msg("An error occured while fetching manga details")
        }
    }
    
    func getMangaDetails(manga: Manga, mangaIndex: Int) async {
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
                
                passedSourceMangas[mangaIndex].detailsLoadingState = .success
            }
        } else {
           Log.shared.msg("An error occured while fetching manga details")
        }
    }
}
