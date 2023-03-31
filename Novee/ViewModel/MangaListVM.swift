//
//  MangaListVM.swift
//  Novee
//
//  Created by Nick on 2023-01-04.
//

import Foundation

class MangaListVM: MediaListVM<MangaListElement> {
    static let shared = MangaListVM()
    
    init() {
        super.init(savePath: URL.mangaListStorageUrl.path)
    }
    
    func addToList(source: String, manga: Manga, lastSegment: String? = nil, status: Status, rating: Rating = .none, creationDate: Date = Date.now, lastViewedDate: Date? = nil) {
        list.append(MangaListElement(content: [source: manga], lastSegment: lastSegment, status: status, rating: rating, lastViewedDate: lastViewedDate, creationDate: creationDate))
    }
    
    func addToList(mangas: [String: Manga], lastSegment: String? = nil, status: Status, rating: Rating = .none, creationDate: Date = Date.now, lastViewedDate: Date? = nil) {
        list.append(MangaListElement(content: mangas, lastSegment: lastSegment, status: status, rating: rating, lastViewedDate: lastViewedDate, creationDate: creationDate))
    }
}
