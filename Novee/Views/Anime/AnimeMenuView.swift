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
                                animeVM.pageNumber -= 1
                            } label: {
                                Image(systemName: "chevron.backward")
                            }
                            .disabled(animeVM.pageNumber <= 1)
                            
                            TextField("", value: $textfieldPageNumber, format: .number)
                                .frame(width: 50)
                                .multilineTextAlignment(.center)
                                .onSubmit {
                                    animeVM.pageNumber = textfieldPageNumber
                                }
                            
                            Button {
                                animeVM.pageNumber += 1
                            } label: {
                                Image(systemName: "chevron.forward")
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: 30)
                        .onChange(of: animeVM.pageNumber) { _ in
                            Task {
                                textfieldPageNumber = animeVM.pageNumber
                                if searchQuery.isEmpty {
                                    await animeVM.sources[animeVM.selectedSource]!.getMedia(pageNumber: animeVM.pageNumber)
                                } else {
                                    await animeVM.sources[animeVM.selectedSource]!.getSearchMedia(pageNumber: animeVM.pageNumber, searchQuery: searchQuery)
                                }
                            }
                        }
                        .onChange(of: searchQuery) { _ in
                            Task {
                                /// Reset page number each time the user searches something else
                                if searchQuery.isEmpty {
                                    await animeVM.sources[animeVM.selectedSource]!.getMedia(pageNumber: 1)
                                } else {
                                    await animeVM.sources[animeVM.selectedSource]!.getSearchMedia(pageNumber: 1, searchQuery: searchQuery)
                                }
                            }
                        }
                        .onChange(of: animeVM.selectedSource) { _ in animeVM.pageNumber = 1; searchQuery = ""; }
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
                        await animeVM.sources[animeVM.selectedSource]?.getMedia(pageNumber: animeVM.pageNumber)
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
        .onAppear {
            Task {
                textfieldPageNumber = animeVM.pageNumber
                await animeVM.sources[animeVM.selectedSource]!.getMedia(pageNumber: animeVM.pageNumber)
            }
        }
        .onChange(of: animeVM.selectedSource) { _ in
            Task {
                await animeVM.sources[animeVM.selectedSource]!.getMedia(pageNumber: animeVM.pageNumber)
            }
        }
        .onDisappear {
            animeVM.sources[animeVM.selectedSource]!.mediaData = []
        }
    }
}

struct AnimeColumnView: View {
    @EnvironmentObject var animeVM: AnimeVM
    
    @Binding var selectedSource: String
    
    var body: some View {
        VStack {
            List(animeVM.sources[selectedSource]!.mediaData) { anime in
                NavigationLink {
                    AnimeDetailsView(anime: anime)
                } label: {
                    MediaColumnElementView(
                        imageUrl: anime.imageUrl,
                        title: anime.title,
                        segmentTitles: anime.segments?.map { $0.title })
                }
            }
            .listStyle(.plain)
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
    }
}

struct AnimeDetailsView: View {
    @EnvironmentObject var animeVM: AnimeVM
    @EnvironmentObject var animeListVM: AnimeListVM
    
    var anime: Anime
    
    var isDownloading: Bool {
        animeVM.episodeDownloadProgress != nil
    }
    
    var downloadProgress: Double? {
        animeVM.episodeDownloadProgress?.progress
    }
    
    var downloadTotal: Double? {
        animeVM.episodeDownloadProgress?.total
    }
    
    var body: some View {
        MediaDetailsView(selectedMedia: anime, fetchDetails: { () -> Anime? in
            return await animeVM.getAnimeDetails(for: anime)
        }, updateMediaInList: { newMedia in
            if let animeListElement = animeListVM.findInList(media: newMedia) {
                animeListVM.updateMediaInListElement(
                    id: animeListElement.id,
                    source: animeVM.selectedSource,
                    media: newMedia
                )
            }
        }, resetDownloadProgress: {
            animeVM.resetEpisodeDownloadProgress()
        }, downloadSegment: { segment in
            Task {
                var streamingUrl: StreamingUrl?
                
                let newEpisode = await animeVM.getStreamingUrl(for: segment, anime: anime)
                streamingUrl = newEpisode?.streamingUrls?.last
                
                if let streamingUrl = streamingUrl {
                    await animeVM.downloadEpisode(for: streamingUrl, anime: anime)
                }
            }
        }, isDownloading: isDownloading, downloadProgress: downloadProgress, downloadTotal: downloadTotal)
        .environmentObject(animeVM as MediaVM<Anime>)
        .environmentObject(animeListVM as MediaListVM<AnimeListElement>)
    }
}

struct AnimeMenuView_Previews: PreviewProvider {
    static var previews: some View {
        AnimeMenuView()
    }
}
