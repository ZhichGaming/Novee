//
//  MangaVM.swift
//  Novee
//
//  Created by Nick on 2022-10-17.
//

import Foundation

class MangaVM: ObservableObject {
    static let shared = MangaVM()
    
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
                
//                print(safeData)
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
}
