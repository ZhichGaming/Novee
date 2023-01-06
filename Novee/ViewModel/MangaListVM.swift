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
            MangaListElement(manga: ["mangakakalot":Manga(title: "The Last Cultivator")], status: .waiting, rating: .none),
            MangaListElement(manga: ["mangakakalot":Manga(title: "Test 2")], lastChapter: "Chapter 12", status: .reading, rating: .best),
            MangaListElement(manga: ["mangakakalot":Manga(title: "Test 3")], lastChapter: "Chapter 2", status: .dropped, rating: .good),
            MangaListElement(manga: ["mangakakalot":Manga(title: "Test 4")], lastChapter: "Chapter 2", status: .completed, rating: .horrible),
            MangaListElement(manga: ["mangakakalot":Manga(title: "A random enticing manga")], status: .toRead, rating: .none)
        ]
    }
    
    @Published var list: [MangaListElement]
    
    func addToList(source: String, manga: Manga, lastChapter: String? = nil, status: MangaStatus, rating: MangaRating = .none) {
        list.append(MangaListElement(manga: [source: manga], lastChapter: lastChapter, status: status, rating: rating))
    }
    
    func updateListEntry(id: UUID, newValue: MangaListElement) {
        if let index = list.firstIndex(where: { $0.id == id }) {
            list[index] = newValue
        } else {
            Log.shared.msg("A list entry with this UUID could not be found.")
        }
    }
    
    func findInList(manga: Manga) -> MangaListElement? {
        let inputTitles = [manga.title] + (manga.altTitles ?? [])
        
        for manga in list {
            for source in manga.manga {
                for listTitle in [source.value.title] + (source.value.altTitles ?? []) {
                    for inputTitle in inputTitles {
                        if listTitle == inputTitle {
                            return manga
                        }
                    }
                }
            }
        }
        
        return nil
    }
}
