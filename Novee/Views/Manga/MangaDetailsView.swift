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
    
    @State var selectedMangaIndex: Int
    @State var collapsed = true
    @State var descriptionSize: CGSize = .zero
    
    /// Manga of the index passed in
    var selectedManga: Manga {
        return mangaVM.sources[mangaVM.selectedSource]!.mangaData[selectedMangaIndex]
    }
    
    var body: some View {
        switch selectedManga.detailsLoadingState {
        case .success:
            GeometryReader { geo in
                VStack {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(selectedManga.title)
                                .font(.largeTitle)
                            Text(LocalizedStringKey(
                                "**Alternative titles:** \(selectedManga.altTitles?.joined(separator: "; ") ?? "None")"
                            ))
                            .lineLimit(5)
                            
                            Text(LocalizedStringKey("**Authors:** \(selectedManga.authors?.joined(separator: ", ") ?? "None")"))

                            Text(LocalizedStringKey("**Tags:** \(selectedManga.tags?.joined(separator: ", ") ?? "None")"))
                        }
                        Spacer()
                        CachedAsyncImage(url: selectedManga.imageUrl) { image in
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
                        Text(LocalizedStringKey(selectedManga.description ?? "None"))
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
        case .loading:
            ProgressView()
                .onAppear {
                    Task {
                        await mangaVM.sources[mangaVM.selectedSource]!.getMangaDetails(manga: selectedManga)
                    }
                }
        case .failed:
            Text("Fetching failed")
            Button("Try again") {
                Task {
                    await mangaVM.sources[mangaVM.selectedSource]!.getMangaDetails(manga: selectedManga)
                }
            }
        }
    }
}

struct ChapterList: View {
    @EnvironmentObject var mangaVM: MangaVM
    @State var selected: UUID?

    var body: some View {
        EmptyView()
        // TODO: Manga chapters
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
        MangaDetailsView(selectedMangaIndex: 0)
            .frame(width: 500, height: 625)
    }
}
