//
//  NovelListVM.swift
//  Novee
//
//  Created by Nick on 2023-03-05.
//

import Foundation

class NovelListVM: MediaListVM<NovelListElement> {
    static let shared = NovelListVM()
    
    init() {
        super.init(savePath: URL.novelListStorageUrl.path)
    }
    
    func addToList(source: String, novel: Novel, lastSegment: String? = nil, status: Status, rating: Rating = .none, creationDate: Date = Date.now, lastViewedDate: Date? = nil) {
        list.append(NovelListElement(content: [source: novel], lastSegment: lastSegment, status: status, rating: rating, lastViewedDate: lastViewedDate, creationDate: creationDate))
    }
    
    func addToList(novels: [String: Novel], lastSegment: String? = nil, status: Status, rating: Rating = .none, creationDate: Date = Date.now, lastViewedDate: Date? = nil) {
        list.append(NovelListElement(content: novels, lastSegment: lastSegment, status: status, rating: rating, lastViewedDate: lastViewedDate, creationDate: creationDate))
    }
}
