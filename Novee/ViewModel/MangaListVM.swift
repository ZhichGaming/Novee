//
//  MangaListVM.swift
//  Novee
//
//  Created by Nick on 2023-01-04.
//

import Foundation

class MangaListVM: ObservableObject {
    static let shared = MangaListVM()
    
    init() {
        list = [
            MangaListElement(manga: [Manga(title: "Test 1")], status: .waiting),
            MangaListElement(manga: [Manga(title: "Test 2")], lastChapter: "Chapter 12", status: .reading, rating: .best),
            MangaListElement(manga: [Manga(title: "Test 3")], lastChapter: "Chapter 2", status: .dropped, rating: .good),
            MangaListElement(manga: [Manga(title: "Test 4")], lastChapter: "Chapter 2", status: .completed, rating: .horrible),
            MangaListElement(manga: [Manga(title: "A random enticing manga")], status: .toRead)
        ]
    }
    
    @Published var list: [MangaListElement]
}
