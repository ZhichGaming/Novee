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
    init(pageType: MangaNato.PageType = .mangaList, type: String = "latest", pageNumber: Int = 1) {
        self.pageType = pageType
        self.type = type
        self.pageNumber = pageNumber
        super.init()
    }
    
    @Published var mangaData: [Manga] = []
        
    // Source info
    let label: String = "MangaNato"
    let sourceId: String = "manganato"
    let baseUrl: String = "https://manganato.com"

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
    
    func getMangaDetails(manga: Manga) async {
        do {
            let mangaIndex = mangaData.firstIndex(of: manga)!
            var htmlPage = ""
            
            do {
                let (data, _) = try await URLSession.shared.data(from: mangaData[mangaIndex].detailsUrl!)
                
                if let stringData = String(data: data, encoding: .utf8) {
                    if stringData.isEmpty {
                        Log.shared.msg("An error occured while fetching manga details.")
                    }
                    
                    htmlPage = stringData
                }
            } catch {
                Log.shared.error(error)
            }
            
            let document: Document = try SwiftSoup.parse(htmlPage)
            let infoElement: Element = try document.getElementsByClass("story-info-right")[0]

            let title: String? = try infoElement
                .child(0)
                .text()
            let altTitles: [String]? = try infoElement
                .select("table > tbody > tr:nth-child(1) > td.table-value > h2")
                .text()
                .components(separatedBy: ";")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            let description: String? = try document
                .select("#panel-story-info-description")
                .text()
                .replacingOccurrences(of: "Description : ", with: "")
            let authors: [String]? = try infoElement
                .select("table > tbody > tr:nth-child(2) > td.table-value")
                .text()
                .components(separatedBy: "-")
            let tags: [String]? = try Array(document
                .select("table > tbody > tr:nth-child(4) > td.table-value")
                .text()
                .replacingOccurrences(of: " ", with: "")
                .components(separatedBy: "-")
                .filter { !$0.isEmpty })

            DispatchQueue.main.sync {
                MangaVM.shared.objectWillChange.send()
                
                mangaData[mangaIndex].title = title ?? mangaData[mangaIndex].title
                mangaData[mangaIndex].altTitles = altTitles ?? mangaData[mangaIndex].altTitles
                mangaData[mangaIndex].description = description ?? mangaData[mangaIndex].description
                mangaData[mangaIndex].authors = authors ?? mangaData[mangaIndex].authors
                mangaData[mangaIndex].tags = tags ?? mangaData[mangaIndex].tags
                
                mangaData[mangaIndex].detailsLoadingState = .success
            }
        } catch {
            Log.shared.error(error)
        }
    }
}
