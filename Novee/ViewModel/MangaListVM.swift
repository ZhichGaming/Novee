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
        let manga1 = MangaListElement(
            manga: ["manga1": Manga(
                title: "Eiyuu Kyoushitsu",
                altTitles: ["英雄教室", "Class Room✿For Heroes", "Escola de Heróis"],
                description: "Long ago, a powerful demon lord ruled over the people until an equally powerful hero rose up to defeat him. To counter future threats, Rosewood Academy, a school for heroes-in-training, was created. Today, Rosewood Academy enrolls only the best of the best, and Arnest Flaming is the best of them all. The top student in the school, a dutiful girl nicknamed “Empress of Flame”, she has an irritating encounter with a light-hearted boy in the school hallway one day who seems to equal her powers, though she’s never seen him before. He introduces himself only as Blade, and Arnest soon finds out not only is he transferring into the school as a new student, but she is personally requested by the King to help him settle in to daily life in Rosewood Academy.",
                authors: ["Araki Shin"],
                tags: ["Action", "Ecchi", "Fantasy", "Romance", "School life", "Seinen", "Supernatural"],
                detailsUrl: URL(string: "https://mangakakalot.com/read-rz8bz158504863231"),
                imageUrl: URL(string: "https://avt.mkklcdnv6temp.com/39/d/2-1583467209.jpg")
            )],
            lastChapter: "Chapter 10",
            status: .reading,
            rating: .good,
            lastReadDate: Date(timeIntervalSinceNow: -3600),
            creationDate: Date(timeIntervalSinceNow: -86400)
        )

        let manga2 = MangaListElement(
            manga: ["manga2": Manga(
                title: "Please Throw Me Away",
                altTitles: ["Please Leave Me Behind", "나를 버려주세요"],
                description: "Adele was adopted in replacement of a lady who died from a rare disease. She worked her entire life so she would be loved, but as soon as her younger sister was born, she was abandoned. Then on Adele’s way to an arranged marriage, she was assassinated by mysterious enemies. “…Is this a dream?” But when she opened her eyes, she returned to 3 years in the past! Since she is destined to be abandoned when her younger sister is born, this time around, she tries to live the way she wants, but things keep going wrong. “Weren’t you interested in me?” And a mysterious knight in black keeps pursuing her…",
                authors: ["자은향"],
                tags: ["Drama", "Fantasy", "Romance", "Webtoons"],
                detailsUrl: URL(string: "https://chapmanganato.com/manga-ih985742"),
                imageUrl: URL(string: "https://avt.mkklcdnv6temp.com/29/a/21-1592300211.jpg")
            )],
            lastChapter: "Chapter 5",
            status: .waiting,
            rating: .best,
            lastReadDate: nil,
            creationDate: Date(timeIntervalSinceNow: 86400)
        )

        let manga3 = MangaListElement(
            manga: ["manga3": Manga(title: "Manga 3")],
            lastChapter: nil,
            status: .completed,
            rating: .horrible,
            lastReadDate: Date(timeIntervalSinceNow: 3600),
            creationDate: Date(timeIntervalSinceNow: -604800)
        )

        let manga4 = MangaListElement(
            manga: ["manga4": Manga(title: "Manga 4")],
            lastChapter: "Chapter 3",
            status: .dropped,
            rating: .none,
            lastReadDate: nil,
            creationDate: Date(timeIntervalSinceNow: 604800)
        )
        
        list = [
            manga1,
            manga2,
            manga3,
            manga4
        ]
    }
    
    @Published var list: [MangaListElement]
    
    func addToList(source: String, manga: Manga, lastChapter: String? = nil, status: MangaStatus, rating: MangaRating = .none, creationDate: Date = Date.now, lastReadDate: Date? = nil) {
        list.append(MangaListElement(manga: [source: manga], lastChapter: lastChapter, status: status, rating: rating, lastReadDate: lastReadDate, creationDate: creationDate))
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
