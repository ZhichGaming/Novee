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
    var selectedManga: Manga? {
        if mangaVM.sources[mangaVM.selectedSource]!.mangaData.isEmpty == false {
            return mangaVM.sources[mangaVM.selectedSource]!.mangaData[selectedMangaIndex]
        }
        
        return nil
    }
    
    var body: some View {
        if let selectedManga = selectedManga {
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

                            ChapterList(selectedMangaIndex: selectedMangaIndex)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .padding()
                }
            case .loading:
                ProgressView()
                    .onAppear {
                        Task {
                            await mangaVM.getMangaDetails(for: selectedManga)
                        }
                    }
            case .failed:
                Text("Fetching failed")
                Button("Try again") {
                    Task {
                        await mangaVM.sources[mangaVM.selectedSource]!.getMangaDetails(manga: selectedManga)
                    }
                }
            case .notFound:
                Text("A source for the selected manga has not been found.")
            }
        }
    }
}

struct ChapterList: View {
    @EnvironmentObject var mangaVM: MangaVM
    
    @State var selectedMangaIndex: Int
    @State var selected: UUID?
    
    var selectedManga: Manga? {
        if mangaVM.sources[mangaVM.selectedSource]?.mangaData.isEmpty == false {
            return mangaVM.sources[mangaVM.selectedSource]!.mangaData[selectedMangaIndex]
        }
        
        return nil
    }

    var body: some View {
        if selectedManga != nil, let chapters = mangaVM.sources[mangaVM.selectedSource]!.mangaData[selectedMangaIndex].chapters {
            List(chapters) { chapter in
                VStack(alignment: .leading) {
                    // TODO: Chapter upload date
                    HStack {
                        Text(chapter.title)
                            .font(.headline)
                        
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
                /// Make entire area tappable
                .contentShape(Rectangle())
                /// Select chapter when tapped
                .onTapGesture {
                    selected = chapter.id
                }
            }
            .listStyle(.bordered(alternatesRowBackgrounds: true))
        } else {
            Text("No chapters have been found.")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}


struct MangaDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        MangaDetailsView(selectedMangaIndex: 0)
            .frame(width: 500, height: 625)
    }
}
