//
//  MangaLocalLibraryView.swift
//  Novee
//
//  Created by Nick on 2023-03-01.
//

import SwiftUI
import CachedAsyncImage

struct MangaLocalLibraryView: View {
    @EnvironmentObject var mangaLibraryVM: MangaLibraryVM
        
    @State private var searchQuery = ""
    @State private var gridLayout = [GridItem(.adaptive(minimum: 200, maximum: .infinity))]
    
    @State var window: NSWindow = NSWindow()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: gridLayout, alignment: .center) {
                    ForEach(mangaLibraryVM.mangaData) { manga in
                        NavigationLink(value: manga) {
                            VStack(alignment: .center) {
                                Group {
                                    if let image = manga.image {
                                        Image(nsImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .cornerRadius(5)
                                            .clipped()
                                            .shadow(radius: 2, x: 2, y: 2)
                                    } else {
                                        ProgressView()
                                    }
                                }
                                .frame(width: 150, height: 200)
                                .onAppear {
                                    
                                }

                                Text(manga.title ?? "No title")
                                    .font(.headline)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                }
                .padding()
            }
            .buttonStyle(.plain)
            .navigationDestination(for: LocalManga.self) { manga in
                List(manga.chapters) { chapter in
                    Text(chapter.title ?? "No title")
                        .onTapGesture(count: 2) {
                            openWindow(manga: manga, chapter: chapter)
                        }
                }
                .padding()
            }
        }
        .searchable(text: $searchQuery)
        .onAppear {
            mangaLibraryVM.load()
        }
    }
    
    private func openWindow(manga: LocalManga, chapter: LocalChapter) {
        window = NSWindow(
            contentRect: NSRect(x: 20, y: 20, width: 1000, height: 625),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false)
        window.center()
        window.isReleasedWhenClosed = false
        window.title = ((manga.title ?? "No title") + " - " + (chapter.title ?? "No title"))
        window.makeKeyAndOrderFront(nil)
        window.contentView = NSHostingView(
            rootView: MangaLocalLibraryReaderView(selectedManga: manga, selectedChapter: chapter, window: $window)
                .environmentObject(mangaLibraryVM)
        )
    }
}

struct MangaLocalLibraryReaderView: View {
    @EnvironmentObject var mangaLibraryVM: MangaLibraryVM
    
    let selectedManga: LocalManga
    @State var selectedChapter: LocalChapter
    
    @Binding var window: NSWindow
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical) {
                changeChapterView
                
                VStack(spacing: 0) {
                    ForEach(Array(selectedChapter.images.keys).sorted(by: <), id: \.self) { key in
                        if let image = selectedChapter.images[key] {
                            Image(nsImage: image)
                                .resizable()
                                .aspectRatio(contentMode: image.size.width > geometry.size.width ? .fit : .fill)
                                .frame(maxWidth: image.size.width < geometry.size.width ? image.size.width : geometry.size.width)
                        }
                    }
                    .onAppear {
                        print(Array(selectedChapter.images.keys).sorted(by: <))
                    }
                }
                .frame(maxWidth: .infinity)
                
                changeChapterView
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onChange(of: selectedChapter) { [selectedChapter] newChapter in
            if selectedChapter.id != newChapter.id {
                window.title = ((selectedManga.title ?? "No title") + " - " + (newChapter.title ?? "No title"))
            }
        }
    }
    
    var changeChapterView: some View {
        HStack {
            Button {
                if let index = selectedManga.chapters.firstIndex(of: selectedChapter) {
                    selectedChapter = selectedManga.chapters[index - 1]
                }
            } label: {
                HStack {
                    Text("Previous chapter")
                    Image(systemName: "arrow.left")
                }
            }
            .disabled(selectedManga.chapters.first == selectedChapter)
            
            Button {
                if let index = selectedManga.chapters.firstIndex(of: selectedChapter) {
                    selectedChapter = selectedManga.chapters[index + 1]
                }
            } label: {
                HStack {
                    Text("Next chapter")
                    Image(systemName: "arrow.right")
                }
            }
            .disabled(selectedManga.chapters.last == selectedChapter)
        }
        .padding()
    }
}

struct MangaLocalLibraryView_Previews: PreviewProvider {
    static var previews: some View {
        MangaLocalLibraryView()
    }
}
