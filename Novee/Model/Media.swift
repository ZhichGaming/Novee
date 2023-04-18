//
//  Media.swift
//  Novee
//
//  Created by Nick on 2023-03-29.
//

import Foundation

enum LoadingState: Codable {
    case loading, success, failed
}

protocol Media: Hashable, Codable, Identifiable {
    associatedtype MediaSegmentType: MediaSegment
    associatedtype MediaListElementType: MediaListElement

    var id: UUID { get set }
    
    var title: String? { get set }
    var altTitles: [String]? { get set }
    var description: String? { get set }
    var authors: [String]? { get set }
    var tags: [MediaTag]? { get set }

    var detailsUrl: URL? { get set }
    var imageUrl: URL? { get set }
    var segments: [MediaSegmentType]? { get set }
    
    var associatedListElement: (any MediaListElement)? { get }
    
    init()
    init(title: String?, altTitles: [String]?, description: String?, authors: [String]?, tags: [MediaTag]?, detailsUrl: URL?, imageUrl: URL?, segments: [MediaSegmentType]?)
}

protocol MediaSegment: Hashable, Codable, Identifiable {
    var id: UUID { get set }
    var title: String { get set }

    var segmentUrl: URL { get set }
}

extension Media {
    var associatedListElement: (any MediaListElement)? {
        if let self = self as? Anime {
            return AnimeListVM.shared.findInList(media: self)
        } else if let self = self as? Manga {
            return MangaListVM.shared.findInList(media: self)
        } else if let self = self as? Novel {
            return NovelListVM.shared.findInList(media: self)
        }
        
        return nil
    }
    
    init(title: String? = nil, altTitles: [String]? = nil, description: String? = nil, authors: [String]? = nil, tags: [MediaTag]? = nil, detailsUrl: URL? = nil, imageUrl: URL? = nil, segments: [MediaSegmentType]? = nil) {
        self.init()
        
        self.title = title
        self.altTitles = altTitles
        self.description = description
        self.authors = authors
        self.tags = tags
        self.detailsUrl = detailsUrl
        self.imageUrl = imageUrl
        self.segments = segments
    }
}

struct MediaTag: Hashable, Identifiable, Codable {
    var id = UUID()
    
    var name: String
    var url: URL?
}

struct MediaSegmentPair<T: Media>: Codable, Hashable, Equatable {
    var media: T
    var segment: T.MediaSegmentType
}
