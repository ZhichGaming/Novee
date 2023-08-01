//
//  Favourites.swift
//  Novee
//
//  Created by Nick on 2023-04-20.
//

import Foundation

struct Favourite: Identifiable {
    var id = UUID()
    
    var mediaListElement: any MediaListElement
    var loadingState: LoadingState?
    
    enum CodingKeys: CodingKey {
        case id
        case mediaListElement
        case loadingState
    }
}

extension Favourite: Codable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(mediaListElement, forKey: .mediaListElement)
        try container.encode(loadingState, forKey: .loadingState)
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try values.decode(UUID.self, forKey: .id)
        
        if let decodedMediaListElement = try? values.decode(AnimeListElement.self, forKey: .mediaListElement) {
            mediaListElement = decodedMediaListElement
        } else if let decodedMediaListElement = try? values.decode(MangaListElement.self, forKey: .mediaListElement) {
            mediaListElement = decodedMediaListElement
        } else if let decodedMediaListElement = try? values.decode(NovelListElement.self, forKey: .mediaListElement) {
            mediaListElement = decodedMediaListElement
        } else {
            throw DecodingError.dataCorruptedError(forKey: .mediaListElement, in: values, debugDescription: "Could not decode mediaListElement.")
        }
        
        loadingState = try values.decode(LoadingState.self, forKey: .loadingState)
    }
}
