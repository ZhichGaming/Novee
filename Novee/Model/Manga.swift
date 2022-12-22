//
//  Manga.swift
//  Novee
//
//  Created by Nick on 2022-12-13.
//

import Foundation
import SwiftUI

struct Manga: Hashable {
    var title: String
    var altTitles: [String]?
    var description: String?
    var authors: [String]?
    var tags: [String]?
    
    var detailsUrl: URL?
    var imageUrl: URL?
    var chapters: [Chapter]?
}

struct Chapter: Hashable {
    var title: String
    var chapterUrl: URL
    var imageUrls: [URL]
}
