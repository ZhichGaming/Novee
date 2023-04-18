//
//  MediaBase.swift
//  Novee
//
//  Created by Nick on 2023-04-16.
//

import Foundation

protocol MediaSource {
    associatedtype AssociatedMediaType: Media
    
    var label: String { get }
    var baseUrl: String { get }
    var sourceId: String { get }
    
    var mediaData: [AssociatedMediaType] { get set }
        
    @discardableResult
    func getMedia(pageNumber: Int) async -> [AssociatedMediaType]
    
    @discardableResult
    func getSearchMedia(pageNumber: Int, searchQuery: String) async -> [AssociatedMediaType]
    
    @discardableResult
    func getMediaDetails(media: AssociatedMediaType) async -> AssociatedMediaType?
}
