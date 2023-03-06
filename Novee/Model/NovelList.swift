//
//  NovelList.swift
//  Novee
//
//  Created by Nick on 2023-03-05.
//

import Foundation

struct NovelListElement: Hashable, Identifiable, Codable {
    let id = UUID()
    
    var novel: [String: Novel] /// Novel from different sources
    var lastChapter: String? {
        didSet {
            if lastChapter != nil {
                lastReadDate = Date.now
            }
        }
    }
    var status: BookStatus
    var rating: BookRating
    var lastReadDate: Date?
    var creationDate: Date
    
    enum CodingKeys: CodingKey {
        case novel
        case lastChapter
        case status
        case rating
        case lastReadDate
        case creationDate
    }
}

struct NovelWithSource: Hashable, Identifiable, Codable {
    var id = UUID()
    
    var source: String
    var novel: Novel
}
