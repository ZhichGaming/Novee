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
    
    func fetchManga() {
        DispatchQueue.global(qos: .userInteractive).async {
            var result: MangadexResponse? = nil

            guard let url = URL(string: "https://api.mangadex.org/manga?includes[]=author&includes[]=artist&includes[]=cover_art") else {
                print("Invalid URL")
                return
            }
            
            let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
                guard let data = data else { return }
                let safeData = String(data: data, encoding: .utf8)!
                    .replacingOccurrences(of: ",\"altTitles\":[]", with: "")
                    .replacingOccurrences(of: ",\"description\":[]", with: "")
                    .replacingOccurrences(of: ",\"links\":[]", with: "")
                
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    
                    result = try decoder.decode(MangadexResponse.self, from: safeData.data(using: .utf8)!)
                    DispatchQueue.main.sync {
                        self.mangadexManga = result!.data
                    }
                } catch {
                    print(error)
                }
            }
            
            task.resume()
        }
    }
    
    func getChapters(manga: UUID) {
        DispatchQueue.global(qos: .userInteractive).async {
            var result: MangadexChapterResponse? = nil

            guard let url = URL(string: "https://api.mangadex.org/manga/\(manga.uuidString.lowercased())/feed") else {
                print("Invalid URL")
                return
            }
            
            let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
                guard let data = data else { return }

                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601

                    result = try decoder.decode(MangadexChapterResponse.self, from: data)
                    DispatchQueue.main.sync {
                        self.mangadexManga[self.mangadexManga.firstIndex { $0.id == manga }!].chapters = result!.data
                    }
//                    if let JSONString = String(data: data, encoding: String.Encoding.utf8) {
//                        print(JSONString)
//                    }
                } catch {
                    print(error)
                }
            }
            
            task.resume()
        }

    }
    
    static func getLocalisedString(_ strings: [String: String]?, settingsVM: SettingsVM) -> String {
        guard let unwrappedStrings = strings else {
            return "None"
        }
        if unwrappedStrings.isEmpty { return "None" }
        let primaryLanguageString = unwrappedStrings.first { $0.key.uppercased() == "\(settingsVM.settings.preferedLanguage)" }?.value
        
        if primaryLanguageString != nil {
            return primaryLanguageString!
        } 
        
        return unwrappedStrings.first?.value ?? "None"
    }
}
