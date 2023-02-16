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
        list = []
        decode()
    }
    
    @Published var list: [MangaListElement] {
        didSet {
            encode()
        }
    }
    
    func encode() {
        do {
            let encoded = try JSONEncoder().encode(list)
            
            FileManager().createFile(atPath: URL.mangaListStorageUrl.path, contents: encoded)
        } catch {
            Log.shared.error(error)
        }
    }
    
    func decode() {
        do {
            if !FileManager().fileExists(atPath: URL.mangaListStorageUrl.path) {
                FileManager().createFile(atPath: URL.mangaListStorageUrl.path, contents: Data([]))
                return
            }
            
            if let data = FileManager().contents(atPath: URL.mangaListStorageUrl.path) {
                let decoded = try JSONDecoder().decode([MangaListElement].self, from: data)
                list = decoded
            } else {
                Log.shared.msg("An error occured while loading manga list data.")
            }
        } catch {
            Log.shared.error(error)
        }
    }
    
    func addToList(source: String, manga: Manga, lastChapter: String? = nil, status: MangaStatus, rating: MangaRating = .none, creationDate: Date = Date.now, lastReadDate: Date? = nil) {
        list.append(MangaListElement(manga: [source: manga], lastChapter: lastChapter, status: status, rating: rating, lastReadDate: lastReadDate, creationDate: creationDate))
    }
    
    func addToList(mangas: [String: Manga], lastChapter: String? = nil, status: MangaStatus, rating: MangaRating = .none, creationDate: Date = Date.now, lastReadDate: Date? = nil) {
        list.append(MangaListElement(manga: mangas, lastChapter: lastChapter, status: status, rating: rating, lastReadDate: lastReadDate, creationDate: creationDate))
    }
    
    func updateMangaInListElement(id: UUID, source: String, manga: Manga) {
        if let index = list.firstIndex(where: { $0.id == id }) {
            list[index].manga[source] = manga
        } else {
            Log.shared.msg("A list entry with this UUID could not be found.")
        }
    }
    
    func updateListEntry(id: UUID, newValue: MangaListElement) {
        if let index = list.firstIndex(where: { $0.id == id }) {
            list[index] = newValue
        } else {
            Log.shared.msg("A list entry with this UUID could not be found.")
        }
    }
    
    func updateStatus(id: UUID, to status: MangaStatus) {
        if let index = list.firstIndex(where: { $0.id == id }) {
            list[index].status = status
        } else {
            Log.shared.msg("A list entry with this UUID could not be found.")
        }
    }
    
    func updateRating(id: UUID, to rating: MangaRating) {
        if let index = list.firstIndex(where: { $0.id == id }) {
            list[index].rating = rating
        } else {
            Log.shared.msg("A list entry with this UUID could not be found.")
        }
    }
    
    func updateLastChapter(id: UUID, to chapter: String) {
        if let index = list.firstIndex(where: { $0.id == id }) {
            list[index].lastChapter = chapter
        } else {
            Log.shared.msg("A list entry with this UUID could not be found.")
        }
    }
    
    func updateLastReadDate(id: UUID, to date: Date?) {
        if let index = list.firstIndex(where: { $0.id == id }) {
            list[index].lastReadDate = date
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
    
    func changeStaleReadingStatus(id: UUID) {
        if let index = list.firstIndex(where: { $0.id == id }) {
            let fiveDaysAgo = Calendar.current.date(byAdding: .day, value: -5, to: Date())!

            if list[index].lastReadDate ?? Date.now < fiveDaysAgo {
                let containsLastChapter = Array(list[index].manga.values).map { manga in
                    let chapterTitles = (manga.chapters ?? []).map { $0.title }
                    
                    if let lastTitle = chapterTitles.last, lastTitle == list[index].lastChapter ?? "" {
                        return true
                    }
                    
                    return false
                }.contains(true)
                
                if containsLastChapter {
                    list[index].status = .waiting
                } else {
                    list[index].status = .dropped
                }
            }
        } else {
            print("Error at changeStaleReadingStatus: Cannot find an element in the list with the id \(id)")
        }
    }
}
