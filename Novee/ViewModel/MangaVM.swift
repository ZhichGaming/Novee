//
//  MangaVM.swift
//  Novee
//
//  Created by Nick on 2022-10-17.
//

import Foundation
import SwiftUI

class MangaVM: ObservableObject {
    init() {
        fetchManga()
    }
    
    @Published var mangadexManga: [MangadexMangaData] = []
    @Published var openedMangaId: UUID?
    @Published var openedChapterId: UUID?
    
    var openedManga: MangadexMangaData? {
        mangadexManga.first { $0.id == openedMangaId }
    }
    var openedChapter: MangadexChapter? {
        openedManga?.chapters?.first { $0.id == openedChapterId }
    }
    
    func fetchManga(offset: Int? = nil, title: String? = nil) {
        DispatchQueue.global(qos: .userInteractive).async {
            var result: MangadexResponse? = nil

            var arguments: String {
                var result = ""
                
                result.append("limit=\(SettingsVM.shared.settings.mangaPerPage)")
                result.append("&")
                result.append(offset == nil ? "" : "offset=\(offset!)")
                result.append((offset != nil && title != nil) ? "&" : "")
                result.append(title == nil ? "" : "title=\(title!)")
                result.append((offset != nil || title != nil) ? "&" : "")

                return result
            }
            
            guard let url = URL(string: "https://api.mangadex.org/manga?\(arguments)includes[]=author&includes[]=cover_art") else {
                print("Invalid URL")
                return
            }
//            #if DEBUG
//            print(url)
//            #endif
            
            let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
                guard let data = data else { return }
                
                // TODO: REMOVE THIS BEFORE COMMITING ANY CHANGES, TEMPORARY FIX FOR EMPTY DICTIONARIES TRANSFORMED TO ARRAYS
                let safeData = String(data: data, encoding: .utf8)!
                    .replacingOccurrences(of: ",\"altTitles\":[]", with: "")
                    .replacingOccurrences(of: ",\"description\":[]", with: "")
                    .replacingOccurrences(of: ",\"links\":[]", with: "")
//                #if DEBUG
//                print(String(data: data, encoding: .utf8)!)
//                #endif
                
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    
                    result = try decoder.decode(MangadexResponse.self, from: safeData.data(using: .utf8)!)
                    DispatchQueue.main.sync {
                        self.mangadexManga = result!.data
                    }
                } catch {
                    print(error)
                    Log.shared.error(error)
                }
            }
            
            task.resume()
        }
    }
    
    func getChapters(manga: UUID) {
        DispatchQueue.global(qos: .userInteractive).async {
            var result: MangadexChapterResponse? = nil

            guard let url = URL(string: "https://api.mangadex.org/manga/\(manga.uuidString.lowercased())/feed?includes[]=scanlation_group") else {
                print("Invalid URL")
                return
            }
            
            let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
                guard let data = data else { return }
                
//                #if DEBUG
//                print(String(data: data, encoding: .utf8)! as Any)
//                #endif

                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601

                    result = try decoder.decode(MangadexChapterResponse.self, from: data)
                    DispatchQueue.main.sync {
                        self.mangadexManga[self.mangadexManga.firstIndex { $0.id == manga }!].chapters = result!.data
                    }
                } catch {
                    print(error)
                    Log.shared.error(error)
                }
            }
            
            task.resume()
        }
    }
    
    func getPages(for chapter: UUID) {
        self.mangadexManga[self.mangadexManga.firstIndex { $0.id == self.openedMangaId }!].chapters?[(self.openedManga?.chapters?.firstIndex { $0.id == chapter })!].pages = nil

        DispatchQueue.global(qos: .userInteractive).async {
            var result: MangadexPageResponse? = nil

            guard let url = URL(string: "https://api.mangadex.org/at-home/server/\(chapter.uuidString.lowercased())") else {
                print("Invalid URL")
                return
            }
            
            let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
                guard let data = data else { return }
                
//                #if DEBUG
//                print(String(data: data, encoding: .utf8)! as Any)
//                #endif

                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601

                    result = try decoder.decode(MangadexPageResponse.self, from: data)
                    DispatchQueue.main.sync {
                        self.mangadexManga[self.mangadexManga.firstIndex { $0.id == self.openedMangaId }!].chapters?[(self.openedManga?.chapters?.firstIndex { $0.id == chapter })!].pages = result!
                    }
                } catch {
                    print(error)
                    Log.shared.error(error)
                }
            }
            
            task.resume()
        }
    }
    
    static func getLocalisedString(_ strings: [String: String]?) -> String {
        guard let unwrappedStrings = strings else {
            return "None"
        }
        if unwrappedStrings.isEmpty { return "None" }
        let primaryLanguageString = unwrappedStrings.first { $0.key.uppercased() == "\(SettingsVM.shared.settings.preferedLanguage)" }?.value
        
        if primaryLanguageString != nil {
            return primaryLanguageString!
        } 
        
        return unwrappedStrings.first?.value ?? "None"
    }
}
