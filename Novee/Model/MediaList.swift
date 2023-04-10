//
//  MediaList.swift
//  Novee
//
//  Created by Nick on 2023-03-30.
//

import Foundation

enum Status: String, Hashable, CaseIterable, Codable {
    case dropped = "Dropped"
    case completed = "Completed"
    case viewing = "Viewing"
    case waiting = "Waiting"
    case toView = "To view"
}

enum Rating: String, Hashable, CaseIterable, Codable {
    case horrible = "Horrible"
    case bad = "Bad"
    case good = "Good"
    case best = "Best"
    case none = "None"
}

enum MediaType: String, Hashable, CaseIterable, Codable {
    case anime = "Anime"
    case manga = "Manga"
    case novel = "Novel"
}

protocol MediaListElement: Hashable, Codable, Identifiable {
    associatedtype AssociatedMediaType: Media
    
    var type: MediaType { get }
    
    var id: UUID { get }
    
    var content: [String: AssociatedMediaType]  { get set }
    var lastSegment: String? { get set }
    var status: Status { get set }
    var rating: Rating { get set }
    var lastViewedDate: Date? { get set }
    var creationDate: Date { get set }
    
    init(content: [String: AssociatedMediaType], lastSegment: String?, status: Status, rating: Rating, lastViewedDate: Date?, creationDate: Date)
}
