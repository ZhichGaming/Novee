//
//  ReadLightNovels.swift
//  Novee
//
//  Created by Nick on 2023-03-04.
//

import Foundation
import SwiftSoup

class ReadLightNovels: NovelFetcher, NovelSource {
    override init(label: String = "Read Light Novels", sourceId: String = "readlightnovels", baseUrl: String = "https://readlightnovels.net") {
        super.init(label: label, sourceId: sourceId, baseUrl: baseUrl)
    }
    
    func getNovel(pageNumber: Int) async -> [Novel] {
        do {
            var htmlPage = ""
            
            DispatchQueue.main.async {
                super.resetNovels()
            }
            
            guard let requestUrl = URL(string: baseUrl + "/latest/page/\(pageNumber)") else {
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
            let novels: Elements = try document.getElementsByClass("col-md-3 col-sm-6 col-xs-6 home-truyendecu")
            
            /// Announce changes
            DispatchQueue.main.sync {
                NovelVM.shared.objectWillChange.send()
            }
            
            var finalResult: [Novel] = []
            
            for novel in novels.array() {
                var result = Novel(title: try novel.child(0).child(0).child(1).child(0).text())
                result.detailsUrl = try URL(string: novel.child(0).attr("href"))
                result.imageUrl = try URL(string: novel.child(0).child(0).child(0).attr("src"))
                
                super.novelData.append(result)
                finalResult.append(result)
            }
            
            return finalResult
        } catch {
            Log.shared.error(error)
            return []
        }
    }
    
    func getSearchNovel(pageNumber: Int, searchQuery: String) async -> [Novel] {
        do {
            var htmlPage = ""
            
            let safeSearchQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            
            guard let requestUrl = URL(string: baseUrl + "/page/\(pageNumber)" + "?s=" + safeSearchQuery) else {
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
            let mangas: Elements = try document.getElementsByClass("col-md-3 col-sm-6 col-xs-6 home-truyendecu")
            
            /// Announce changes
            DispatchQueue.main.sync {
                NovelVM.shared.objectWillChange.send()
            }
            
            /// Reset mangas
            resetNovels()
            var finalResult: [Novel] = []
            
            for manga in mangas.array() {
                var result = Novel(title: try manga.child(0).child(1).child(0).text())
                result.detailsUrl = try URL(string: manga.child(0).attr("href"))
                result.imageUrl = try URL(string: manga.child(0).child(0).attr("src"))
                
                super.novelData.append(result)
                finalResult.append(result)
            }
            
            return finalResult
        } catch {
            Log.shared.error(error)
            return []
        }
    }
    
    func getNovelDetails(novel: Novel) async -> Novel? {
        var htmlPage = ""
        var result: Novel? = novel
        
        do {
            guard let requestUrl = novel.detailsUrl else {
                Log.shared.msg("Details url missing!")
                return nil
            }
            
            let (data, _) = try await URLSession.shared.data(from: requestUrl)
            
            if let stringData = String(data: data, encoding: .utf8) {
                if stringData.isEmpty {
                    Log.shared.msg("An error occured while fetching manga details.")
                }
                
                htmlPage = stringData
            }
        
            let document: Document = try SwiftSoup.parse(htmlPage)
            let infoElement: Element = try document.getElementsByClass("col-info-desc")[0]
            
            result?.title = try infoElement
                .child(2)
                .child(0)
                .text()

            if let descriptionText = try document.select("div.col-xs-12.col-sm-8.col-md-8.desc > div.desc-text > hr").first()?.untilNext("hr").getSeparatedText() {
                result?.description = descriptionText
            } else {
                result?.description = try document.select("div.col-xs-12.col-sm-8.col-md-8.desc > div.desc-text").first()?.getSeparatedText()
            }
            
            result?.authors = try infoElement
                .child(1)
                .child(1)
                .child(0)
                .text()
                .replacingOccurrences(of: "Author:", with: "")
                .components(separatedBy: ", ")
            
            result?.tags = try infoElement
                .child(1)
                .child(1)
                .child(1)
                .children()
                .select("a")
                .map {
                    try MediaTag(name: $0.text(), url: URL(string: $0.attr("href")))
                }
                        
            var chapters: [NovelChapter] = []

            guard let pageCount = try document.select("#pagination > ul > li").compactMap({ element in
                try element.select("a").first()?.attr("data-page")
            }).compactMap({ Int($0) }).max() else {
                Log.shared.msg("Page count not found!")
                return nil
            }
            
            guard let novelId = Int(try document.select("#id_post").val()) else {
                Log.shared.msg("Novel id not found!")
                return nil
            }
            
            for i in 1...pageCount {
                chapters.append(contentsOf: await fetchChapters(novelId: novelId, chapterPage: i, referer: requestUrl.absoluteString))
            }
            
            result?.segments = chapters
        } catch {
            Log.shared.error(error)
        }
        
        return result
    }
    
    func fetchChapters(novelId: Int, chapterPage: Int, referer: String) async -> [NovelChapter] {
        var chapters = [NovelChapter]()
        
        do {
            let requestUrl = URL(string: baseUrl + "/wp-admin/admin-ajax.php")!
            var request = URLRequest(url: requestUrl)
            request.httpMethod = "POST"
            
            let parameters = "action=tw_ajax&type=pagination&id=\(novelId)&page=\(chapterPage)"
            
            let encodedParameters = parameters.data(using: .utf8)
            
            request.httpBody = encodedParameters
            
            request.addValue(referer, forHTTPHeaderField: "referer")
            request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "content-type")
            request.addValue(baseUrl, forHTTPHeaderField: "origin")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            let decoded = try decoder.decode(ChapterJSON.self, from: data)
            
            let document = try SwiftSoup.parse(decoded.listChap)

            for chapterElement in try document.select("ul.list-chapter > li") {
                let chapterTitle = try chapterElement.child(1).child(0).text()
                let chapterUrl = try URL(string: chapterElement.child(1).attr("href"))
                
                if let chapterUrl = chapterUrl {
                    chapters.append(NovelChapter(title: chapterTitle, segmentUrl: chapterUrl))
                }
            }
            
        } catch {
            print(error)
            Log.shared.error(error)
        }
        
        return chapters
    }
    
    func getNovelContent(novel: Novel, chapter: NovelChapter) async -> String? {
        var result = ""

        do {
            let (data, _) = try await URLSession.shared.data(from: chapter.segmentUrl)

            guard let stringData = String(data: data, encoding: .utf8) else {
                Log.shared.msg("An error occured while fetching manga pages.")
                return nil
            }
            
            let document: Document = try SwiftSoup.parse(stringData)

            let content = try document.getElementsByClass("chapter-content")[0]
            
            result = try content.getSeparatedText()
        } catch {
            Log.shared.error(error)
            return nil
        }
        
        return result
    }
    
    struct ChapterJSON: Codable {
        var pagination: String
        var listChap: String
    }
}
