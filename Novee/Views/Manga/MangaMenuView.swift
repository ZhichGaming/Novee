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
    @EnvironmentObject var mangaSourcesVM: MangaSourcesVM
    
    @State private var searchText = ""
    @State private var pageNumber = 1
    @State private var mangaPerPage = 10
    @State private var selectedSource = "mangakakalot"

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Divider()
                NavigationView {
                    VStack(spacing: 0) {
                        MangaList()
                        
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
        .onSubmit(of: .search) {
            mangaVM.fetchManga(offset: (pageNumber-1) * settingsVM.settings.mangaPerPage, title: searchText)
        }
        .onChange(of: pageNumber) { newPage in
            mangaVM.fetchManga(offset: (newPage-1) * settingsVM.settings.mangaPerPage, title: searchText)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Picker("Source", selection: $selectedSource) {
                    ForEach(mangaSourcesVM.sourcesArray, id: \.sourceId) { source in
                        Text(source.label)
                    }
                }
            }
        }
    }
}

struct MangaList: View {
    @EnvironmentObject var mangaVM: MangaVM
    @State private var showingReload = false

    var body: some View {
        VStack {
            if mangaVM.mangadexResponse?.result == "ok" {
                List(mangaVM.mangadexResponse!.data) { manga in
                    NavigationLink {
                        MangaDetailsView(mangaId: manga.id)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(manga.attributes.title.first?.value ?? "No title")
                                    .font(.title2)
                                Text("Latest chapter: \(manga.attributes.lastChapter ?? "Unknown")")
                                    .font(.footnote)
                                HStack {
                                    ForEach(getShortenedTags(for: manga)) { tag in
                                        Text(MangaVM.getLocalisedString(tag.attributes.name))
                                            .font(.caption)
                                            .padding(3)
                                            .padding(.horizontal, 2)
                                            .foregroundColor(.white)
                                            .background {
                                                Color.accentColor.clipShape(RoundedRectangle(cornerRadius: 5))
                                            }
                                    }
                                }
                            }
                            
                            Spacer()
                            CachedAsyncImage(url: URL(string: "https://uploads.mangadex.org/covers/\(manga.id.uuidString.lowercased())/\(manga.relationships.first { $0?.type == "cover_art" }!!.attributes!.fileName!).256.jpg")) { image in
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
            } else if mangaVM.mangadexResponse == nil {
                let _ = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                    showingReload = true
                }
                
                ProgressView()
                    .padding()
                if showingReload {
                    Button("Reload") {
                        mangaVM.fetchManga()
                    }
                }
            }
        }
        .frame(minWidth: 400, maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            mangaVM.fetchManga()
        }
    }
    
    func getShortenedTags(for manga: MangadexMangaData) -> [MangadexTag] {
        if manga.attributes.tags!.count >= 3 {
            let shortenedTags = manga.attributes.tags![0..<3]
            return Array(shortenedTags)
        }
        return manga.attributes.tags!
    }
}

struct MangaMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MangaMenuView()
    }
}
