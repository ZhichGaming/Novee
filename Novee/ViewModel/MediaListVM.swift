//
//  MediaListVM.swift
//  Novee
//
//  Created by Nick on 2023-03-30.
//

import Foundation

class MediaListVM<T: MediaListElement>: ObservableObject {
    let savePath: String
    
    init(savePath: String) {
        self.savePath = savePath
        
        list = []
        decode()
    }
    
    @Published var list: [T] {
        didSet {
            encode()
        }
    }
    
    func encode() {
        do {
            let encoded = try JSONEncoder().encode(list)

            FileManager().createFile(atPath: savePath, contents: encoded)
        } catch {
            Log.shared.error(error)
        }
    }

    func decode() {
        do {
            if !FileManager().fileExists(atPath: savePath) {
                FileManager().createFile(atPath: savePath, contents: Data([]))
                return
            }

            if let data = FileManager().contents(atPath: savePath) {
                let decoded = try JSONDecoder().decode([T].self, from: data)
                list = decoded
            } else {
                Log.shared.msg("An error occured while loading media list data.")
            }
        } catch {
            Log.shared.error(error)
        }
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
            list[index].content.removeValue(forKey: source)

            if list[index].content.isEmpty {
                removeFromList(id: id)
            }
        } else {
            Log.shared.msg("Could not remove source from list.")
        }
    }

    func updateMediaInListElement(id: UUID, source: String, media: T.AssociatedMediaType) {
        if let index = list.firstIndex(where: { $0.id == id }) {
            list[index].content[source] = media
        } else {
            Log.shared.msg("A list entry with this UUID could not be found.")
        }
    }

    func updateListEntry(id: UUID, newValue: T) {
        if let index = list.firstIndex(where: { $0.id == id }) {
            list[index] = newValue
        } else {
            Log.shared.msg("A list entry with this UUID could not be found.")
        }
    }

    func updateStatus(id: UUID, to status: Status) {
        if let index = list.firstIndex(where: { $0.id == id }) {
            list[index].status = status
        } else {
            Log.shared.msg("A list entry with this UUID could not be found.")
        }
    }

    func updateRating(id: UUID, to rating: Rating) {
        if let index = list.firstIndex(where: { $0.id == id }) {
            list[index].rating = rating
        } else {
            Log.shared.msg("A list entry with this UUID could not be found.")
        }
    }
//    "lemme read my god damn mangas"
//        - sunny, 31 march 2023

    func updateLastSegment(id: UUID, to chapter: String) {
        if let index = list.firstIndex(where: { $0.id == id }) {
            list[index].lastSegment = chapter
        } else {
            Log.shared.msg("A list entry with this UUID could not be found.")
        }
    }

    func updateLastViewedDate(id: UUID, to date: Date?) {
        if let index = list.firstIndex(where: { $0.id == id }) {
            list[index].lastViewedDate = date
        } else {
            Log.shared.msg("A list entry with this UUID could not be found.")
        }
    }

    func findInList(media: some Media) -> T? {
        let inputTitles = [media.title] + (media.altTitles ?? [])

        for media in list {
            for source in media.content {
                for listTitle in [source.value.title] + (source.value.altTitles ?? []) {
                    for inputTitle in inputTitles {
                        if listTitle == inputTitle {
                            return media
                        }
                    }
                }
            }
        }

        return nil
    }

    func changeStaleViewingStatus(id: UUID) {
        if let index = list.firstIndex(where: { $0.id == id }) {
            let fiveDaysAgo = Calendar.current.date(byAdding: .day, value: -5, to: Date())!

            if list[index].lastViewedDate ?? Date.now < fiveDaysAgo {
                let containsLastChapter = Array(list[index].content.values).map { media in
                    let chapterTitles = (media.segments ?? []).map { $0.title }

                    if let lastTitle = chapterTitles.last, lastTitle == list[index].lastSegment ?? "" {
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
            print("Error at changeStaleViewingStatus: Cannot find an element in the list with the id \(id)")
        }
    }

    func getLatestMedia(_ length: Int = 10) -> [T] {
        let sorted = list.sorted(by: { $0.creationDate < $1.creationDate })

        return sorted.suffix(length)
    }
}
