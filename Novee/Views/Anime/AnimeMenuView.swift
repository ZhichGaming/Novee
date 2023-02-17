//
//  AnimeMenuView.swift
//  Novee
//
//  Created by Nick on 2022-10-16.
//

import SwiftUI
import CachedAsyncImage

struct AnimeMenuView: View {
    @EnvironmentObject var settingsVM: SettingsVM
    @EnvironmentObject var animeVM: AnimeVM
    
    @State private var searchQuery = ""
    @State private var pageNumber = 1
    
    @State private var textfieldPageNumber = 1
    @State private var textfieldSearchQuery = ""

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Divider()
                NavigationView {
                    VStack(spacing: 0) {
                        AnimeColumnView(selectedSource: $animeVM.selectedSource)
                        
                        Divider()
                        HStack {
                            Button {
                                pageNumber -= 1
                            } label: {
                                Image(systemName: "chevron.backward")
                            }
                            .disabled(pageNumber <= 1)
                            
                            TextField("", value: $textfieldPageNumber, format: .number)
                                .frame(width: 50)
                                .multilineTextAlignment(.center)
                                .onSubmit {
                                    pageNumber = textfieldPageNumber
                                }
                            
                            Button {
                                pageNumber += 1
                            } label: {
                                Image(systemName: "chevron.forward")
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: 30)
                        .onChange(of: pageNumber) { _ in
                            Task {
                                textfieldPageNumber = pageNumber
                                if searchQuery.isEmpty {
                                    await animeVM.sources[animeVM.selectedSource]!.getAnime(pageNumber: pageNumber)
                                } else {
                                    await animeVM.sources[animeVM.selectedSource]!.getSearchAnime(pageNumber: pageNumber, searchQuery: searchQuery)
                                }
                            }
                        }
                        .onChange(of: searchQuery) { _ in
                            Task {
                                /// Reset page number each time the user searches something else
                                if searchQuery.isEmpty {
                                    await animeVM.sources[animeVM.selectedSource]!.getAnime(pageNumber: 1)
                                } else {
                                    await animeVM.sources[animeVM.selectedSource]!.getSearchAnime(pageNumber: 1, searchQuery: searchQuery)
                                }
                            }
                        }
                        .onChange(of: animeVM.selectedSource) { _ in pageNumber = 1; searchQuery = ""; }
                    }
                }
            }
        }
        .searchable(text: $textfieldSearchQuery, placement: .toolbar)
        .onSubmit(of: .search) { searchQuery = textfieldSearchQuery }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task {
                        await animeVM.sources[animeVM.selectedSource]?.getAnime(pageNumber: pageNumber)
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Picker("Source", selection: $animeVM.selectedSource) {
                    ForEach(animeVM.sourcesArray, id: \.sourceId) { source in
                        Text(source.label)
                    }
                }
            }
        }
    }
}

struct AnimeColumnView: View {
    @EnvironmentObject var animeVM: AnimeVM
    
    @Binding var selectedSource: String

    var body: some View {
        VStack {
            List(animeVM.sources[selectedSource]!.animeData) { anime in
                NavigationLink {
                    AnimeDetailsView(selectedAnimeIndex: animeVM.sources[animeVM.selectedSource]!.animeData.firstIndex(of: anime) ?? 0)
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(anime.title ?? "No title")
                                .font(.title2)
                            Text(anime.detailsUrl?.host ?? "Unknown host")
                                .font(.caption)
                            // TODO: Latest chapter
//                            Text("Latest chapter: \(manga.attributes.lastChapter ?? "Unknown")")
//                                .font(.footnote)
                        }

                        Spacer()
                        CachedAsyncImage(url: anime.imageUrl) { image in
                            image
                                .resizable()
                                .scaledToFit()
                        } placeholder: {
                            ProgressView()
                        }
                    }
                    .frame(height: 100)
                    .contentShape(Rectangle())
                }
            }
//        } else if mangaVM.mangadexResponse == nil {
//            let _ = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
//                showingReload = true
//            }
//
//            if showingReload {
//                Button("Reload") {
//                    mangaVM.fetchManga()
//                }
//            }
        }
        .frame(minWidth: 400, maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            Task {
                await animeVM.sources[selectedSource]!.getAnime(pageNumber: 1)
            }
        }
        .onChange(of: animeVM.selectedSource) { _ in
            Task {
                await animeVM.sources[selectedSource]!.getAnime(pageNumber: 1)
            }
        }
        .onDisappear {
            animeVM.sources[selectedSource]!.animeData = []
        }
    }
}

struct AnimeMenuView_Previews: PreviewProvider {
    static var previews: some View {
        AnimeMenuView()
    }
}
