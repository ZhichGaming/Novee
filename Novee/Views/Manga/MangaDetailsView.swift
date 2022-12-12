//
//  MangaDetailsView.swift
//  Novee
//
//  Created by Nick on 2022-10-20.
//

import SwiftUI
import CachedAsyncImage

struct MangaDetailsView: View {
    @EnvironmentObject var mangaVM: MangaVM
    @EnvironmentObject var settingsVM: SettingsVM
    
    @State var mangaId: UUID
    @State var collapsed = true
    @State var descriptionSize: CGSize = .zero
    
    @State var selectedChapter: MangadexChapter?

    var manga: MangadexMangaData {
        mangaVM.mangadexResponse?.data.first { $0.id == mangaId } ?? MangadexMangaData(id: UUID(), type: "", attributes: MangadexMangaAttributes(title: [:], isLocked: false, originalLanguage: "jp", status: "", createdAt: Date.distantPast, updatedAt: Date.now), relationships: [], chapters: nil)
    }
    var lastChapter: String {
        var result = ""
        let volumeIsEmpty = manga.attributes.lastVolume?.isEmpty ?? true
        let chapterIsEmpty = manga.attributes.lastChapter?.isEmpty ?? true
                
        if !volumeIsEmpty {
            result.append("Vol " + (manga.attributes.lastVolume!))
        }
        
        if volumeIsEmpty && chapterIsEmpty {
            result = ""
        } else if !volumeIsEmpty && !chapterIsEmpty {
            result.append(", ")
        }
        
        if !chapterIsEmpty {
            result.append("Chapter " + (manga.attributes.lastChapter!))
        }

        return result
    }
    var tags: String {
        var result: [String] = []
        
        if manga.attributes.tags != nil {
            for tag in manga.attributes.tags! {
                result.append(MangaVM.getLocalisedString(tag.attributes.name))
            }
        } else {
            return "No tags"
        }
        
        return result.joined(separator: " - ")
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(MangaVM.getLocalisedString(manga.attributes.title))
                            .font(.largeTitle)
                        Text(LocalizedStringKey("**Alternative titles:** \(getAltTitles())"))
                            .lineLimit(5)
                        Text(LocalizedStringKey("**Last updated:** \(manga.attributes.updatedAt.formatted(date: .abbreviated, time: .shortened))"))
                        Text(LocalizedStringKey("**Last chapter:** \(lastChapter)"))

                        /// Manga author
                        HStack(spacing: 0) {
                            /// Checks if author's website and twitter is null
                            if manga.relationships.first { $0?.type == "author" }??.attributes?.website == nil && manga.relationships.first { $0?.type == "author" }??.attributes?.twitter == nil {
                                /// If it is null, display the author name as standard text
                                Text(LocalizedStringKey("**Author:** \(manga.relationships.first { $0?.type == "author" }??.attributes?.name ?? "Unknown")"))
                            } else {
                                /// If it is not null, display the author name as link
                                Text(LocalizedStringKey("**Author:** "))
                                Link(
                                    manga.relationships.first { $0?.type == "author" }??.attributes?.name ?? "Unknown",
                                    destination: URL(string: (manga.relationships.first { $0?.type == "author" }??.attributes?.website ?? manga.relationships.first { $0?.type == "author" }??.attributes?.twitter)!)!)
                            }
                        }
                        
                        Text(LocalizedStringKey("**Tags:** \(tags)"))
                    }
                    Spacer()
                    CachedAsyncImage(url: URL(string: "https://uploads.mangadex.org/covers/\(manga.id.uuidString.lowercased())/\(manga.relationships.first { $0?.type == "cover_art" }??.attributes?.fileName ?? "").256.jpg")) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(maxWidth: geo.size.width * 0.4, maxHeight: geo.size.height * 0.4)
                    .clipped()
                }
                Divider()
                ScrollView {
                    Text(LocalizedStringKey(MangaVM.getLocalisedString(manga.attributes.description)))
                        .background {
                            GeometryReader { textSize -> Color in
                                DispatchQueue.main.async {
                                    descriptionSize = textSize.size
                                }
                                return Color.clear
                            }
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: descriptionSize.height > 200 ? 200 : descriptionSize.height, alignment: .leading)
                
                Divider()
            
                VStack(alignment: .leading) {
                    Text("Chapters")
                        .font(.headline)
                    if manga.chapters != nil {
                        ChapterList(manga: manga)
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding()
        }
        .onAppear {
            mangaVM.getChapters(manga: manga.id)
        }
    }
    
    func getAltTitles() -> String {
        var titles: [String] = []
        
        if manga.attributes.altTitles != nil {
            for altTitle in manga.attributes.altTitles! {
                for value in altTitle.values {
                    titles.append(value)
                }
            }
        } else {
            return "None"
        }
        
        return titles.joined(separator: ", ")
    }
}

struct ChapterList: View {
    @EnvironmentObject var mangaVM: MangaVM
    @State var selected: UUID?

    var manga: MangadexMangaData

    var body: some View {
        List(getSortedChapters()) { chapter in
            VStack(alignment: .leading) {
                HStack {
                    Text("Chapter \(chapter.attributes.chapter ?? "") (\(Language.getValue(chapter.attributes.translatedLanguage.uppercased()) ?? "\(chapter.attributes.translatedLanguage)"))")
                        .font(selected == Optional(chapter.id) ? .headline : nil)
                    Spacer()
                }
                
                if selected == Optional(chapter.id) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Translation group(s)")
                                .font(.callout)
                            Spacer()
                            if !chapter.relationships.filter { $0.type == "scanlation_group" }.isEmpty {
                                ForEach(chapter.relationships.filter { $0.type == "scanlation_group" }) { group in
                                    if let url = URL(string: group.attributes?.website ?? "") {
                                        Link(group.attributes?.name ?? "Unknown", destination: url)
                                    } else {
                                        Text(group.attributes?.name ?? "None")
                                    }
                                }
                            } else {
                                Text("None")
                            }
                        }
                        
                        HStack {
                            Text("Upload date")
                                .font(.callout)
                            Spacer()
                            Text(chapter.attributes.publishAt.formatted(date: .abbreviated, time: .shortened))
                        }

                        Button("Read") {
                            mangaVM.openedMangaId = manga.id
                            mangaVM.openedChapterId = chapter.id
                            if let url = URL(string: "novee://mangaReader") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                selected = chapter.id
            }
        }
        .listStyle(.bordered(alternatesRowBackgrounds: true))
    }
    
    func getSortedChapters() -> [MangadexChapter] {
        var sortedChapters: [MangadexChapter]
        sortedChapters = manga.chapters!.data.sorted(by: { chapter1, chapter2 in
            guard let verifiedString1 = Double(chapter1.attributes.chapter ?? "0") else {
                return chapter1.attributes.chapter ?? "" <= chapter2.attributes.chapter ?? ""
            }
            guard let verifiedString2 = Double(chapter2.attributes.chapter ?? "0") else {
                return chapter1.attributes.chapter ?? "" <= chapter2.attributes.chapter ?? ""
            }
            
            return verifiedString1 <= verifiedString2
        })
        
        return sortedChapters
    }
}


struct MangaDetailsView_Previews: PreviewProvider {
    static let chapters = MangadexChapterResponse(result: "ok", response: "", data: [MangadexChapter(id: UUID(uuidString: "29bfff23-c550-4a29-b65e-6f0a7b6c8574")!, type: "chapter", attributes: MangadexChapterAttributes(volume: "1", chapter: "1", title: nil, translatedLanguage: "en", externalUrl: nil, publishAt: Date.distantPast), relationships: [])])
    static let mangaVM = [MangadexMangaData(id: UUID(uuidString: "1cb98005-7bf9-488b-9d44-784a961ae42d")!, type: "Manga", attributes: MangadexMangaAttributes(title: ["en": "Test manga"], isLocked: false, originalLanguage: "jp", status: "Ongoing", createdAt: Date.distantPast, updatedAt: Date.now), relationships: [MangadexRelationship(id: UUID(), type: "cover_art", attributes: MangadexRelationshipAttributes(fileName: "9ab7ae43-9448-4f85-86d8-c661c6d23bbf.jpg"))], chapters: chapters)]

    static var previews: some View {
        MangaDetailsView(mangaId: UUID(uuidString: "1cb98005-7bf9-488b-9d44-784a961ae42d")!)
            .frame(width: 500, height: 625)
    }
}
