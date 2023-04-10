//
//  NovelMenuView.swift
//  Novee
//
//  Created by Nick on 2022-10-16.
//

import SwiftUI

struct NovelMenuView: View {
    @EnvironmentObject var settingsVM: SettingsVM
    @EnvironmentObject var novelVM: NovelVM
    
    @State private var searchQuery = ""
    
    @State private var textfieldPageNumber = 1
    @State private var textfieldSearchQuery = ""

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Divider()
                NavigationView {
                    VStack(spacing: 0) {
                        NovelColumnView(selectedSource: $novelVM.selectedSource)
                        
                        Divider()
                        HStack {
                            Button {
                                novelVM.pageNumber -= 1
                            } label: {
                                Image(systemName: "chevron.backward")
                            }
                            .disabled(novelVM.pageNumber <= 1)
                            
                            TextField("", value: $textfieldPageNumber, format: .number)
                                .frame(width: 50)
                                .multilineTextAlignment(.center)
                                .onSubmit {
                                    novelVM.pageNumber = textfieldPageNumber
                                }
                            
                            Button {
                                novelVM.pageNumber += 1
                            } label: {
                                Image(systemName: "chevron.forward")
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: 30)
                        .onChange(of: novelVM.pageNumber) { _ in
                            Task {
                                textfieldPageNumber = novelVM.pageNumber
                                if searchQuery.isEmpty {
                                    await novelVM.sources[novelVM.selectedSource]!.getNovel(pageNumber: novelVM.pageNumber)
                                } else {
                                    await novelVM.sources[novelVM.selectedSource]!.getSearchNovel(pageNumber: novelVM.pageNumber, searchQuery: searchQuery)
                                }
                            }
                        }
                        .onChange(of: searchQuery) { _ in
                            Task {
                                /// Reset page number each time the user searches something else
                                if searchQuery.isEmpty {
                                    await novelVM.sources[novelVM.selectedSource]!.getNovel(pageNumber: 1)
                                } else {
                                    await novelVM.sources[novelVM.selectedSource]!.getSearchNovel(pageNumber: 1, searchQuery: searchQuery)
                                }
                            }
                        }
                        .onChange(of: novelVM.selectedSource) { _ in novelVM.pageNumber = 1; searchQuery = ""; }
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
                        await novelVM.sources[novelVM.selectedSource]?.getNovel(pageNumber: novelVM.pageNumber)
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Picker("Source", selection: $novelVM.selectedSource) {
                    ForEach(novelVM.sourcesArray, id: \.sourceId) { source in
                        Text(source.label)
                    }
                }
            }
        }
        .onAppear {
            Task {
                textfieldPageNumber = novelVM.pageNumber
                await novelVM.sources[novelVM.selectedSource]!.getNovel(pageNumber: novelVM.pageNumber)
            }
        }
        .onChange(of: novelVM.selectedSource) { _ in
            Task {
                await novelVM.sources[novelVM.selectedSource]!.getNovel(pageNumber: novelVM.pageNumber)
            }
        }
        .onDisappear {
            novelVM.sources[novelVM.selectedSource]!.novelData = []
        }
    }
}

struct NovelColumnView: View {
    @EnvironmentObject var novelVM: NovelVM
    
    @Binding var selectedSource: String

    var body: some View {
        VStack {
            List(novelVM.sources[selectedSource]!.novelData) { novel in
                NavigationLink {
                    NovelDetailsView(novel: novel)
                } label: {
                    MediaColumnElementView(
                        imageUrl: novel.imageUrl,
                        title: novel.title,
                        segmentTitles: novel.segments?.map { $0.title })
                }
            }
            .listStyle(.plain)
//        } else if novelVM.noveldexResponse == nil {
//            let _ = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
//                showingReload = true
//            }
//
//            if showingReload {
//                Button("Reload") {
//                    novelVM.fetchNovel()
//                }
//            }
        }
        .frame(minWidth: 400, maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct NovelDetailsView: View {
    @EnvironmentObject var novelVM: NovelVM
    @EnvironmentObject var novelListVM: NovelListVM
    
    var novel: Novel
    
    var isDownloading: Bool {
        novelVM.chapterDownloadProgress != nil
    }
    
    var downloadProgress: Double? {
        Double(novelVM.chapterDownloadProgress ?? false ? 1 : 0)
    }
    
    var downloadTotal: Double? {
        1.0
    }
    
    var body: some View {
        MediaDetailsView(selectedMedia: novel, fetchDetails: {
            return await novelVM.getNovelDetails(for: novel, source: novelVM.selectedSource)
        }, updateMediaInList: { newMedia in
            if let mangaListElement = novelListVM.findInList(media: newMedia) {
                novelListVM.updateMediaInListElement(
                    id: mangaListElement.id,
                    source: novelVM.selectedSource,
                    media: newMedia
                )
            }
        }, resetDownloadProgress: {
            
        }, downloadSegment: { chapter in
            Task {
                await novelVM.downloadChapter(novel: novel, chapter: chapter)
            }
        }, isDownloading: isDownloading, downloadProgress: downloadProgress, downloadTotal: downloadTotal)
        .environmentObject(novelVM as MediaVM<Novel>)
        .environmentObject(novelListVM as MediaListVM<NovelListElement>)
    }
}

struct NovelMenuView_Previews: PreviewProvider {
    static var previews: some View {
        NovelMenuView()
    }
}
