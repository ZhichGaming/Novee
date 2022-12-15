//
//  MangaKakalot.swift
//  Novee
//
//  Created by Nick on 2022-12-12.
//

import Foundation
import SwiftSoup

class MangaKakalot: MangaFetcher, MangaSource {
    init(pageType: MangaKakalot.PageType = .mangaList, type: String = "latest", pageNumber: Int = 1) {
        self.pageType = pageType
        self.type = type
        self.pageNumber = pageNumber
        super.init()
        
        Task {
            self.htmlPage = await super.getPage(requestUrl: requestUrl)
            parseManga()
        }
    }
    
    @Published var mangaData: [Manga] = []
        
    // Source info
    let label: String = "MangaKakalot"
    let sourceId: String = "mangakakalot"
    let baseUrl: String = "https://mangakakalot.com"

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
    
    // HTML result of the received page
    var htmlPage: String?
    
    func parseManga() {
        do {
            let document: Document = try SwiftSoup.parse(htmlPage!)
            let mangas: Elements = try document.getElementsByClass("list-truyen-item-wrap")
                        
            for manga in mangas.array() {
                var result = Manga(name: try manga.child(0).attr("title"))
                result.description = try manga.children().last()?.text()
                result.link = try URL(string: manga.child(0).attr("href"))
                result.imageLink = try URL(string: manga.child(0).child(0).attr("src"))
                
                mangaData.append(result)
            }
        } catch {
            Log.shared.error(error)
        }
    }
}
