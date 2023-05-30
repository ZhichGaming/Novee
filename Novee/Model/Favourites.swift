//
//  Favourites.swift
//  Novee
//
//  Created by Nick on 2023-04-20.
//

import Foundation

struct Favourite: Identifiable {
    var id = UUID()
    
    var mediaListElement: (any MediaListElement)
    var loadingState: LoadingState?
}
