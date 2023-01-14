//
//  MangaReaderView.swift
//  Novee
//
//  Created by Nick on 2022-10-26.
//

import SwiftUI
import CachedAsyncImage

struct MangaReaderView: View {
    @EnvironmentObject var mangaVM: MangaVM
    
    @State private var zoom = 1.0
    @State private var showingDetailsSheet = false
    
    let manga: Manga
    @State var chapter: Chapter
    @Binding var window: NSWindow

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical) {
                ChangeChaptersView(manga: manga, chapter: $chapter)
                
                if let images = chapter.images {
                    VStack(spacing: 0) {
                        ForEach(images, id: \.self) { nsImage in
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: nsImage.size.width > geometry.size.width ? .fit : .fill)
                                .frame(maxWidth: nsImage.size.width < geometry.size.width ? nsImage.size.width : geometry.size.width)
                        }
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
                
                ChangeChaptersView(manga: manga, chapter: $chapter)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: chapter) { [chapter] newChapter in
                if chapter.id != newChapter.id {
                    window.title = manga.title + " - " + newChapter.title
                    
                    Task {
                        self.chapter.images = await mangaVM
                            .sources[mangaVM.selectedSource]!
                            .getMangaPages(manga: manga, chapter: self.chapter)
                    }
                }
            }
        }
        .onAppear {
            Task {
                chapter.images = await mangaVM
                    .sources[mangaVM.selectedSource]!
                    .getMangaPages(manga: manga, chapter: chapter)
            }
        }
        .sheet(isPresented: $showingDetailsSheet) {
            VStack {
                HStack {
                    CachedAsyncImage(url: manga.imageUrl) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipped()
                    } placeholder: {
                        ProgressView()
                    }
                    
                    VStack(alignment: .leading) {
                        Text(manga.title)
                            .font(.title2.bold())
                        Text(chapter.title)
                            .font(.headline)
                    }
                    
                    Spacer()
                }
                
                TabView {
                    MangaReaderDetailsView(manga: manga, chapter: chapter)
                        .tabItem {
                            Text("Reading options")
                        }
                    
                    MangaReaderAddToListView(manga: manga, chapter: chapter)
                        .tabItem {
                            Text("Manga list")
                        }
                }
            }
            .frame(width: 500, height: 300)
            .padding()
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                showingDetailsSheet = true
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .padding()
        }
    }
}

struct ChangeChaptersView: View {
    @EnvironmentObject var mangaVM: MangaVM

    let manga: Manga
    @Binding var chapter: Chapter
    
    var body: some View {
        HStack {
            Button {
                if let newChapter = mangaVM.changeChapter(chapter: chapter, manga: manga, offset: -1) {
                    chapter = newChapter
                }
            } label: {
                HStack {
                    Text("Previous chapter")
                    Image(systemName: "arrow.left")
                }
            }
            
            Button {
                if let newChapter = mangaVM.changeChapter(chapter: chapter, manga: manga, offset: 1) {
                    chapter = newChapter
                }
            } label: {
                HStack {
                    Text("Next chapter")
                    Image(systemName: "arrow.right")
                }
            }
        }
        .padding()
    }
}

struct MangaReaderDetailsView: View {
    @EnvironmentObject var mangaVM: MangaVM
    @EnvironmentObject var mangaListVM: MangaListVM
    
    @Environment(\.dismiss) var dismiss
    
    let manga: Manga
    let chapter: Chapter

    var body: some View {
        VStack {
            
        }
        .padding()
    }
}

struct MangaReaderAddToListView: View {
    @EnvironmentObject var mangaVM: MangaVM
    @EnvironmentObject var mangaListVM: MangaListVM

    @Environment(\.dismiss) var dismiss

    let manga: Manga
    let chapter: Chapter
    
    @State private var selectedMangaStatus: MangaStatus = .reading
    @State private var selectedMangaRating: MangaRating = .none
    @State private var selectedLastChapter: UUID = UUID()
    
    @State private var selectedMangaListElement: MangaListElement?
    
    @State private var createNewEntry = false
    
    var body: some View {
        HStack {
            VStack {
                Button("Add new entry") {
                    selectedMangaListElement = MangaListElement(manga: [:], status: .reading, rating: .none, creationDate: Date.now)
                    createNewEntry = true
                }
                                        
                Button("Find manually") {
                    
                }
                
                Spacer()
                Text(mangaListVM.findInList(manga: manga)?.manga.first?.value.title ?? "Manga not found")
                
                if let url = mangaListVM.findInList(manga: manga)?.manga.first?.value.imageUrl {
                    CachedAsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                }
                
                Spacer()
            }
            
            Divider()
                .padding(.horizontal)
            
            VStack {
                Text("Manga options")

                Group {
                    Picker("Status", selection: $selectedMangaStatus) {
                        ForEach(MangaStatus.allCases, id: \.rawValue) {
                            Text($0.rawValue)
                                .tag($0)
                        }
                    }
                    
                    Picker("Rating", selection: $selectedMangaRating) {
                        ForEach(MangaRating.allCases, id: \.rawValue) {
                            Text($0.rawValue)
                                .tag($0)
                        }
                    }
                    
                    Picker("Last chapter", selection: $selectedLastChapter) {
                        ForEach(manga.chapters ?? []) {
                            Text($0.title)
                                .tag($0.id)
                        }
                    }
                }
                .disabled(selectedMangaListElement == nil)
                
                HStack {
                    Spacer()
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                    
                    Button(createNewEntry ? "Add to list" : "Save") {
                        if createNewEntry {
                            mangaListVM.addToList(
                                source: mangaVM.selectedSource,
                                manga: manga,
                                lastChapter: manga.chapters?.first { $0.id == selectedLastChapter }?.title ?? chapter.title,
                                status: selectedMangaStatus,
                                rating: selectedMangaRating,
                                lastReadDate: Date.now
                            )
                        } else {
                            mangaListVM.updateListEntry(
                                id: selectedMangaListElement!.id,
                                newValue: MangaListElement(
                                    manga: [mangaVM.selectedSource: manga],
                                    lastChapter: manga.chapters?.first { $0.id == selectedLastChapter }?.title ?? chapter.title,
                                    status: selectedMangaStatus,
                                    rating: selectedMangaRating,
                                    lastReadDate: Date.now,
                                    creationDate: Date.now
                                )
                            )
                        }
                        
                        dismiss()
                    }
                    .disabled(selectedMangaListElement == nil)
                }
            }
        }
        .padding()
        .onAppear {
            selectedMangaListElement = mangaListVM.findInList(manga: manga)
        }
        .onChange(of: selectedMangaListElement) { _ in
            if let selectedMangaListElement = selectedMangaListElement {
                selectedMangaStatus = selectedMangaListElement.status
                selectedMangaRating = selectedMangaListElement.rating
                
                selectedLastChapter = manga.chapters?.first { $0.title == selectedMangaListElement.lastChapter }?.id ?? UUID()
            }
        }
    }
}
