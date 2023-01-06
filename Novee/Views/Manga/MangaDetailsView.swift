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

    @State private var descriptionSize: CGSize = .zero
    @State private var descriptionCollapsed = false
    @State private var isHoveringOverDescription = false
    
    /// Manga of the index passed in
    var selectedManga: Manga? {
        if mangaVM.sources[mangaVM.selectedSource]!.mangaData.count > selectedMangaIndex {
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
                        
                        VStack {
                            HStack {
                                Text("Description")
                                    .font(.headline)

                                Button {
                                    withAnimation {
                                        descriptionCollapsed.toggle()
                                    }
                                } label: {
                                    Image(systemName: "chevron.right")
                                        .rotationEffect(Angle(degrees: descriptionCollapsed ? 0 : 90))
                                }
                                .buttonStyle(.plain)
                                
                                Spacer()
                            }
                            
                            if !descriptionCollapsed {
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
                                .transition(.opacity)
                            }
                        }
                        
                        Divider()
                        
                        ChapterList(selectedMangaIndex: selectedMangaIndex)
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
    @EnvironmentObject var mangaListVM: MangaListVM
    
    @State var selectedMangaIndex: Int
    @State var selected: UUID?
    
    @State private var ascendingOrder = true
    @State private var showingSearch = false
    @State private var chapterQuery = ""
    
    @State var window: NSWindow = NSWindow()
    
    var selectedManga: Manga? {
        if mangaVM.sources[mangaVM.selectedSource]?.mangaData.count ?? 0 > selectedMangaIndex {
            return mangaVM.sources[mangaVM.selectedSource]!.mangaData[selectedMangaIndex]
        }
        
        return nil
    }
    
    var filteredChapters: [Chapter]? {
        var result: [Chapter]?
        
        if let chapters = mangaVM.sources[mangaVM.selectedSource]!.mangaData[selectedMangaIndex].chapters {
            if ascendingOrder {
                result = chapters
            } else {
                result = chapters.reversed()
            }
            
            if !chapterQuery.isEmpty {
                result = result?.filter { $0.title.uppercased().contains(chapterQuery.uppercased()) }
            }
        }
        
        return result
    }

    var body: some View {
        if selectedManga != nil, let filteredChapters = filteredChapters {
            VStack {
                HStack {
                    Text("Chapters")
                        .font(.headline)
                    
                    if showingSearch {
                        TextField("Search for a chapter", text: $chapterQuery)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        if let chapters = mangaVM.sources[mangaVM.selectedSource]!.mangaData[selectedMangaIndex].chapters {
                            Spacer()
                        
                            Button("Read first") {
                                openWindow(
                                    title: selectedManga!.title + " - " + chapters.first!.title,
                                    view: MangaReaderView(manga: selectedManga!, chapter: chapters.first!, window: $window).environmentObject(mangaVM))
                            }
                            .disabled(filteredChapters.isEmpty)
                            
                            Button("Read last") {
                                openWindow(
                                    title: selectedManga!.title + " - " + chapters.last!.title,
                                    view: MangaReaderView(manga: selectedManga!, chapter: chapters.last!, window: $window).environmentObject(mangaVM))
                            }
                            .disabled(filteredChapters.isEmpty)

                            Spacer()
                        }
                    }
                    
                    Button {
                        showingSearch.toggle()
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .keyboardShortcut(showingSearch ? .cancelAction : nil)
                    
                    Button {
                        ascendingOrder.toggle()
                    } label: {
                        if ascendingOrder {
                            Image(systemName: "arrow.up")
                        } else {
                            Image(systemName: "arrow.down")
                        }
                    }
                }
                
                List(filteredChapters.reversed()) { chapter in
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
                    .onTapGesture(count: 2) {
                        if let selectedManga = selectedManga {
                            openWindow(
                                title: selectedManga.title + " - " + chapter.title,
                                view: MangaReaderView(manga: selectedManga, chapter: chapter, window: $window).environmentObject(mangaVM).environmentObject(mangaListVM))
                        }
                    }
                }
                .listStyle(.bordered(alternatesRowBackgrounds: true))
            }
        } else {
            Text("No chapters have been found.")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private func openWindow(title: String, view: some View) {
        window = NSWindow(
            contentRect: NSRect(x: 20, y: 20, width: 1000, height: 625),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false)
        window.center()
        window.isReleasedWhenClosed = false
        window.title = title
        window.makeKeyAndOrderFront(nil)
        window.contentView = NSHostingView(rootView: view)
    }
}


struct MangaDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        MangaDetailsView(selectedMangaIndex: 0)
            .frame(width: 500, height: 625)
    }
}
