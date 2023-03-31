//
//  NovelList.swift
//  Novee
//
//  Created by Nick on 2023-03-05.
//

import Foundation

struct NovelListElement: MediaListElement, Hashable, Identifiable, Codable {
    let id = UUID()
    
    var content: [String: Novel] /// Novel from different sources
    var lastSegment: String? {
        didSet {
            if lastSegment != nil {
                lastViewedDate = Date.now
            }
        }
    }
    var status: Status
    var rating: Rating
    var lastViewedDate: Date?
    var creationDate: Date
    
    enum CodingKeys: CodingKey {
        case content
        case lastSegment
        case status
        case rating
        case lastViewedDate
        case creationDate
    }
}

struct NovelWithSource: Hashable, Identifiable, Codable {
    var id = UUID()
    
    var source: String
    var novel: Novel
}
