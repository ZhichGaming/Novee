//
//  Base.swift
//  Novee
//
//  Created by Nick on 2022-12-13.
//

import Foundation

class MangaFetcher {
    func getPage(requestUrl: URL) async -> String? {
        do {
            let (data, _) = try await URLSession.shared.data(from: requestUrl)
            return String(data: data, encoding: .utf8)
        } catch {
            Log.shared.error(error)
        }
        
        return nil
    }
}

protocol MangaSource {
    var label: String { get }
    var baseUrl: String { get }
    var sourceId: String { get }
    
    var mangaData: [Manga] { get set }
    
    func getManga() async
    func getMangaDetails(manga: Manga) async
    func getMangaDetails(manga: Manga, mangaIndex: Int) async
}
