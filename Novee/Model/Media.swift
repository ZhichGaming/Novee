//
//  Media.swift
//  Novee
//
//  Created by Nick on 2023-03-29.
//

import Foundation

enum LoadingState: Codable {
    case loading, success, failed, notFound
}

protocol Media: Hashable, Codable, Identifiable {
    associatedtype MediaSegmentType: MediaSegment

    var id: UUID { get set }
    
    var title: String? { get set }
    var altTitles: [String]? { get set }
    var description: String? { get set }
    var authors: [String]? { get set }
        
    var detailsUrl: URL? { get set }
    var imageUrl: URL? { get set }
    var segments: [MediaSegmentType]? { get set }
}

protocol MediaSegment: Hashable, Codable, Identifiable {
    var id: UUID { get set }
    var title: String { get set }

    var segmentUrl: URL { get set }
}
