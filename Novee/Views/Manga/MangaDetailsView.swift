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
        
    var body: some View {
        GeometryReader { geo in
            VStack {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        // TODO: Details
//                        Text(MangaVM.getLocalisedString(manga.attributes.title))
//                            .font(.largeTitle)
//                        Text(LocalizedStringKey("**Alternative titles:** \(getAltTitles())"))
//                            .lineLimit(5)
//                        Text(LocalizedStringKey("**Last updated:** \(manga.attributes.updatedAt.formatted(date: .abbreviated, time: .shortened))"))
//                        Text(LocalizedStringKey("**Last chapter:** \(lastChapter)"))
//
//                        /// Manga author
//                        HStack(spacing: 0) {
//                            /// Checks if author's website and twitter is null
//                            if manga.relationships.first { $0?.type == "author" }??.attributes?.website == nil && manga.relationships.first { $0?.type == "author" }??.attributes?.twitter == nil {
//                                /// If it is null, display the author name as standard text
//                                Text(LocalizedStringKey("**Author:** \(manga.relationships.first { $0?.type == "author" }??.attributes?.name ?? "Unknown")"))
//                            } else {
//                                /// If it is not null, display the author name as link
//                                Text(LocalizedStringKey("**Author:** "))
//                                Link(
//                                    manga.relationships.first { $0?.type == "author" }??.attributes?.name ?? "Unknown",
//                                    destination: URL(string: (manga.relationships.first { $0?.type == "author" }??.attributes?.website ?? manga.relationships.first { $0?.type == "author" }??.attributes?.twitter)!)!)
//                            }
//                        }
//
//                        Text(LocalizedStringKey("**Tags:** \(tags)"))
                    }
                    Spacer()
//                    CachedAsyncImage(url: URL(string: "https://uploads.mangadex.org/covers/\(manga.id.uuidString.lowercased())/\(manga.relationships.first { $0?.type == "cover_art" }??.attributes?.fileName ?? "").256.jpg")) { image in
//                        image
//                            .resizable()
//                            .scaledToFit()
//                    } placeholder: {
//                        ProgressView()
//                    }
//                    .frame(maxWidth: geo.size.width * 0.4, maxHeight: geo.size.height * 0.4)
//                    .clipped()
                }
                Divider()
                ScrollView {
//                    Text(LocalizedStringKey(MangaVM.getLocalisedString(manga.attributes.description)))
//                        .background {
//                            GeometryReader { textSize -> Color in
//                                DispatchQueue.main.async {
//                                    descriptionSize = textSize.size
//                                }
//                                return Color.clear
//                            }
//                        }
                }
                .frame(maxWidth: .infinity, maxHeight: descriptionSize.height > 200 ? 200 : descriptionSize.height, alignment: .leading)
                
                Divider()
            
                VStack(alignment: .leading) {
                    Text("Chapters")
                        .font(.headline)
                    // TODO: Add fetching manga chapters
//                    if manga.chapters != nil {
//                        ChapterList(manga: manga)
//                    } else {
//                        ProgressView()
//                            .frame(maxWidth: .infinity, maxHeight: .infinity)
//                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding()
        }
    }
}

struct ChapterList: View {
    @EnvironmentObject var mangaVM: MangaVM
    @State var selected: UUID?

    var body: some View {
        EmptyView()
        // TODO: Manga details
//        List(getSortedChapters()) { chapter in
//            VStack(alignment: .leading) {
//                HStack {
//                    Text("Chapter \(chapter.attributes.chapter ?? "") (\(Language.getValue(chapter.attributes.translatedLanguage.uppercased()) ?? "\(chapter.attributes.translatedLanguage)"))")
//                        .font(selected == Optional(chapter.id) ? .headline : nil)
//                    Spacer()
//                }
//
//                if selected == Optional(chapter.id) {
//                    VStack(alignment: .leading) {
//                        HStack {
//                            Text("Translation group(s)")
//                                .font(.callout)
//                            Spacer()
//                            if !chapter.relationships.filter { $0.type == "scanlation_group" }.isEmpty {
//                                ForEach(chapter.relationships.filter { $0.type == "scanlation_group" }) { group in
//                                    if let url = URL(string: group.attributes?.website ?? "") {
//                                        Link(group.attributes?.name ?? "Unknown", destination: url)
//                                    } else {
//                                        Text(group.attributes?.name ?? "None")
//                                    }
//                                }
//                            } else {
//                                Text("None")
//                            }
//                        }
//
//                        HStack {
//                            Text("Upload date")
//                                .font(.callout)
//                            Spacer()
//                            Text(chapter.attributes.publishAt.formatted(date: .abbreviated, time: .shortened))
//                        }
//
//                        Button("Read") {
//                            // TODO: Implement opening manga
//                            mangaVM.openedMangaId = manga.id
//                            mangaVM.openedChapterId = chapter.id
//                            if let url = URL(string: "novee://mangaReader") {
//                                NSWorkspace.shared.open(url)
//                            }
//                        }
//                    }
//                }
//            }
//            .frame(maxWidth: .infinity)
//            .contentShape(Rectangle())
//            .onTapGesture {
//                selected = chapter.id
//            }
//        }
//        .listStyle(.bordered(alternatesRowBackgrounds: true))
    }
}


struct MangaDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        MangaDetailsView(mangaId: UUID(uuidString: "1cb98005-7bf9-488b-9d44-784a961ae42d")!)
            .frame(width: 500, height: 625)
    }
}
