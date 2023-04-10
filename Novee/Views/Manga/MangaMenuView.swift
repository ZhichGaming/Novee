//
//  MangaMenuView.swift
//  Novee
//
//  Created by Nick on 2022-10-16.
//

import SwiftUI
import CachedAsyncImage

struct MangaMenuView: View {
    @EnvironmentObject var settingsVM: SettingsVM
    @EnvironmentObject var mangaVM: MangaVM
    
    @State private var searchQuery = ""
    
    @State private var textfieldPageNumber = 1
    @State private var textfieldSearchQuery = ""

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Divider()
                NavigationView {
                    VStack(spacing: 0) {
                        MangaColumnView(selectedSource: $mangaVM.selectedSource)
                        
                        Divider()
                        HStack {
                            Button {
                                mangaVM.pageNumber -= 1
                            } label: {
                                Image(systemName: "chevron.backward")
                            }
                            .disabled(mangaVM.pageNumber <= 1)
                            
                            TextField("", value: $textfieldPageNumber, format: .number)
                                .frame(width: 50)
                                .multilineTextAlignment(.center)
                                .onSubmit {
                                    mangaVM.pageNumber = textfieldPageNumber
                                }
                            
                            Button {
                                mangaVM.pageNumber += 1
                            } label: {
                                Image(systemName: "chevron.forward")
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: 30)
                        .onChange(of: mangaVM.pageNumber) { _ in
                            Task {
                                textfieldPageNumber = mangaVM.pageNumber
                                if searchQuery.isEmpty {
                                    await mangaVM.sources[mangaVM.selectedSource]!.getManga(pageNumber: mangaVM.pageNumber)
                                } else {
                                    await mangaVM.sources[mangaVM.selectedSource]!.getSearchManga(pageNumber: mangaVM.pageNumber, searchQuery: searchQuery)
                                }
                            }
                        }
                        .onChange(of: searchQuery) { _ in
                            Task {
                                /// Reset page number each time the user searches something else
                                if searchQuery.isEmpty {
                                    await mangaVM.sources[mangaVM.selectedSource]!.getManga(pageNumber: 1)
                                } else {
                                    await mangaVM.sources[mangaVM.selectedSource]!.getSearchManga(pageNumber: 1, searchQuery: searchQuery)
                                }
                            }
                        }
                        .onChange(of: mangaVM.selectedSource) { _ in mangaVM.pageNumber = 1; searchQuery = ""; }
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
                        await mangaVM.sources[mangaVM.selectedSource]?.getManga(pageNumber: mangaVM.pageNumber)
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Picker("Source", selection: $mangaVM.selectedSource) {
                    ForEach(mangaVM.sourcesArray, id: \.sourceId) { source in
                        Text(source.label)
                    }
                }
            }
        }
        .onAppear {
            Task {
                textfieldPageNumber = mangaVM.pageNumber
                await mangaVM.sources[mangaVM.selectedSource]!.getManga(pageNumber: mangaVM.pageNumber)
            }
        }
        .onChange(of: mangaVM.selectedSource) { _ in
            Task {
                await mangaVM.sources[mangaVM.selectedSource]!.getManga(pageNumber: mangaVM.pageNumber)
            }
        }
        .onDisappear {
            mangaVM.sources[mangaVM.selectedSource]!.mangaData = []
        }
    }
}

struct MangaColumnView: View {
    @EnvironmentObject var mangaVM: MangaVM
    
    @Binding var selectedSource: String

    var body: some View {
        VStack {
            List(mangaVM.sources[selectedSource]!.mangaData) { manga in
                NavigationLink {
                    MangaDetailsView(manga: manga)
                } label: {
                    MediaColumnElementView(
                        imageUrl: manga.imageUrl,
                        title: manga.title,
                        segmentTitles: manga.segments?.map { $0.title })
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

struct MangaDetailsView: View {
    @EnvironmentObject var mangaVM: MangaVM
    @EnvironmentObject var mangaListVM: MangaListVM
    
    var manga: Manga
    
    
    var isDownloading: Bool {
        mangaVM.chapterDownloadProgress != nil
    }
    
    var downloadProgress: Double? {
        Double(mangaVM.chapterDownloadProgress?.progress ?? 0)
    }
    
    var downloadTotal: Double? {
        Double(mangaVM.chapterDownloadProgress?.total ?? 0)
    }
    
    var body: some View {
        MediaDetailsView(selectedMedia: manga, fetchDetails: {
            return await mangaVM.getMangaDetails(for: manga)
        }, updateMediaInList: { newMedia in
            if let mangaListElement = mangaListVM.findInList(media: newMedia) {
                mangaListVM.updateMediaInListElement(
                    id: mangaListElement.id,
                    source: mangaVM.selectedSource,
                    media: newMedia
                )
            }
        }, resetDownloadProgress: {
            
        }, downloadSegment: { chapter in
            Task {
                await mangaVM.downloadChapter(manga: manga, chapter: chapter)
            }
        }, isDownloading: isDownloading, downloadProgress: downloadProgress, downloadTotal: downloadTotal)
        .environmentObject(mangaVM as MediaVM<Manga>)
        .environmentObject(mangaListVM as MediaListVM<MangaListElement>)
    }
}

struct MangaMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MangaMenuView()
    }
}
