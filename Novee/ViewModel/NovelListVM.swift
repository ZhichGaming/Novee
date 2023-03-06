//
//  NovelListVM.swift
//  Novee
//
//  Created by Nick on 2023-03-05.
//

import Foundation

class NovelListVM: ObservableObject {
    static let shared = NovelListVM()
    
    init() {
        list = []
        decode()
    }
    
    @Published var list: [NovelListElement] {
        didSet {
            encode()
        }
    }
    
    func encode() {
        do {
            let encoded = try JSONEncoder().encode(list)
            
            FileManager().createFile(atPath: URL.novelListStorageUrl.path, contents: encoded)
        } catch {
            Log.shared.error(error)
        }
    }
    
    func decode() {
        do {
            if !FileManager().fileExists(atPath: URL.novelListStorageUrl.path) {
                FileManager().createFile(atPath: URL.novelListStorageUrl.path, contents: Data([]))
                return
            }
            
            if let data = FileManager().contents(atPath: URL.novelListStorageUrl.path) {
                let decoded = try JSONDecoder().decode([NovelListElement].self, from: data)
                list = decoded
            } else {
                Log.shared.msg("An error occured while loading novel list data.")
            }
        } catch {
            Log.shared.error(error)
        }
    }
    
    func addToList(source: String, novel: Novel, lastChapter: String? = nil, status: BookStatus, rating: BookRating = .none, creationDate: Date = Date.now, lastReadDate: Date? = nil) {
        list.append(NovelListElement(novel: [source: novel], lastChapter: lastChapter, status: status, rating: rating, lastReadDate: lastReadDate, creationDate: creationDate))
    }
    
    func addToList(novels: [String: Novel], lastChapter: String? = nil, status: BookStatus, rating: BookRating = .none, creationDate: Date = Date.now, lastReadDate: Date? = nil) {
        list.append(NovelListElement(novel: novels, lastChapter: lastChapter, status: status, rating: rating, lastReadDate: lastReadDate, creationDate: creationDate))
    }
    
    func removeFromList(id: UUID) {
        if let index = list.firstIndex(where: { $0.id == id }) {
            list.remove(at: index)
        } else {
            Log.shared.msg("Could not remove from list.")
        }
    }
    
    func removeSourceFromList(id: UUID, source: String) {
        if let index = list.firstIndex(where: { $0.id == id }) {
            list[index].novel.removeValue(forKey: source)
            
            if list[index].novel.isEmpty {
                removeFromList(id: id)
            }
        } else {
            Log.shared.msg("Could not remove source from list.")
        }
    }
    
    func updateNovelInListElement(id: UUID, source: String, novel: Novel) {
        if let index = list.firstIndex(where: { $0.id == id }) {
            list[index].novel[source] = novel
        } else {
            Log.shared.msg("A list entry with this UUID could not be found.")
        }
    }
    
    func updateListEntry(id: UUID, newValue: NovelListElement) {
        if let index = list.firstIndex(where: { $0.id == id }) {
            list[index] = newValue
        } else {
            Log.shared.msg("A list entry with this UUID could not be found.")
        }
    }
    
    func updateStatus(id: UUID, to status: BookStatus) {
        if let index = list.firstIndex(where: { $0.id == id }) {
            list[index].status = status
        } else {
            Log.shared.msg("A list entry with this UUID could not be found.")
        }
    }
    
    func updateRating(id: UUID, to rating: BookRating) {
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
    
    func findInList(novel: Novel) -> NovelListElement? {
        let inputTitles = [novel.title] + (novel.altTitles ?? [])
        
        for novel in list {
            for source in novel.novel {
                for listTitle in [source.value.title] + (source.value.altTitles ?? []) {
                    for inputTitle in inputTitles {
                        if listTitle == inputTitle {
                            return novel
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
                let containsLastChapter = Array(list[index].novel.values).map { novel in
                    let chapterTitles = (novel.chapters ?? []).map { $0.title }
                    
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
