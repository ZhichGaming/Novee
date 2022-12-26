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
    
    @State private var searchText = ""
    @State private var pageNumber = 1
    @State private var mangaPerPage = 10

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Divider()
                NavigationView {
                    VStack(spacing: 0) {
                        MangaList(selectedSource: $mangaVM.selectedSource)
                        
                        HStack {
                            Button {
                                pageNumber -= 1
                            } label: {
                                Image(systemName: "chevron.backward")
                            }
                            .disabled(pageNumber <= 1)
                            
                            TextField("", value: $pageNumber, format: .number)
                                .frame(width: 50)
                                .multilineTextAlignment(.center)
                            
                            Button {
                                pageNumber += 1
                            } label: {
                                Image(systemName: "chevron.forward")
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: 30)
                    }
                }
            }
        }
        .searchable(text: $searchText, placement: .toolbar)
        // TODO: Search manga
//        .onSubmit(of: .search) {
//            mangaVM.fetchManga(offset: (pageNumber-1) * settingsVM.settings.mangaPerPage, title: searchText)
//        }
//        .onChange(of: pageNumber) { newPage in
//            mangaVM.fetchManga(offset: (newPage-1) * settingsVM.settings.mangaPerPage, title: searchText)
//        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Picker("Source", selection: $mangaVM.selectedSource) {
                    ForEach(mangaVM.sourcesArray, id: \.sourceId) { source in
                        Text(source.label)
                    }
                }
            }
        }
    }
}

struct MangaList: View {
    @EnvironmentObject var mangaVM: MangaVM
    
    @Binding var selectedSource: String

    var body: some View {
        VStack {
            List(mangaVM.sources[selectedSource]!.mangaData) { manga in
                NavigationLink {
                    MangaDetailsView(selectedMangaIndex: mangaVM.sources[mangaVM.selectedSource]!.mangaData.firstIndex(of: manga) ?? 0)
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(manga.title)
                                .font(.title2)
                            // TODO: Latest chapter
//                            Text("Latest chapter: \(manga.attributes.lastChapter ?? "Unknown")")
//                                .font(.footnote)
                            // TODO: Tags
//                            HStack {
//                                ForEach(getShortenedTags(for: manga)) { tag in
//                                    Text(MangaVM.getLocalisedString(tag.attributes.name))
//                                        .font(.caption)
//                                        .padding(3)
//                                        .padding(.horizontal, 2)
//                                        .foregroundColor(.white)
//                                        .background {
//                                            Color.accentColor.clipShape(RoundedRectangle(cornerRadius: 5))
//                                        }
//                                }
//                            }
                        }

                        Spacer()
                        CachedAsyncImage(url: manga.imageUrl) { image in
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
                await mangaVM.sources[selectedSource]!.getManga()
            }
        }
    }
}

struct MangaMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MangaMenuView()
    }
}
