//
//  MangaDetailsView.swift
//  Novee
//
//  Created by Nick on 2022-10-20.
//

import SwiftUI
import CachedAsyncImage
import SystemNotification

struct MangaDetailsView: View {
    @EnvironmentObject var mangaVM: MangaVM
    @EnvironmentObject var mangaListVM: MangaListVM
    @EnvironmentObject var settingsVM: SettingsVM
    @EnvironmentObject var notification: SystemNotificationContext
    
    @State var selectedManga: Manga

    @State private var descriptionSize: CGSize = .zero
    @State private var descriptionCollapsed = false
    @State private var isHoveringOverDescription = false
    @State private var isShowingAddToListSheet = false
    
    var body: some View {
        switch selectedManga.detailsLoadingState {
        case .success:
            GeometryReader { geo in
                TabView {
                    VStack {
                        MangaInfoView(geo: geo, selectedManga: selectedManga)
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
                        
                        ChapterList(selectedManga: $selectedManga)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .padding()
                    .tabItem {
                        Text("Manga details")
                    }
                    
                    Group {
                        if let mangaListElement = mangaListVM.findInList(manga: selectedManga) {
                            MangaListListDetailsView(
                                passedManga: mangaListElement,
                                dismissOnDelete: false
                            )
                        } else {
                            VStack {
                                Text("This manga was not found in your list.")
                                Button("Add") {
                                    isShowingAddToListSheet = true
                                }
                            }
                        }
                    }
                    .padding()
                    .tabItem {
                        Text("List details")
                    }
                }
            }
            .onAppear {
                if let mangaListId = mangaListVM.findInList(manga: selectedManga)?.id {
                    mangaListVM.updateMangaInListElement(
                        id: mangaListId,
                        source: mangaVM.selectedSource,
                        manga: selectedManga
                    )
                }
            }
            .sheet(isPresented: $isShowingAddToListSheet) {
                MangaReaderAddToListView(manga: selectedManga)
            }
        case .loading:
            ProgressView()
                .onAppear {
                    Task {
                        await mangaVM.getMangaDetails(for: selectedManga, source: mangaVM.selectedSource) { newManga in
                            if let newManga = newManga {
                                selectedManga = newManga
                                
                                if let mangaListId = mangaListVM.findInList(manga: selectedManga)?.id {
                                    mangaListVM.updateMangaInListElement(
                                        id: mangaListId,
                                        source: mangaVM.selectedSource,
                                        manga: selectedManga
                                    )
                                }
                            } else {
                                selectedManga.detailsLoadingState = .failed
                            }
                        }
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

struct MangaInfoView: View {
    @State private var isHoveringOverTitle = false

    let geo: GeometryProxy
    var selectedManga: Manga
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Button(selectedManga.title) {
                    let pasteBoard = NSPasteboard.general
                    pasteBoard.clearContents()
                    pasteBoard.writeObjects([selectedManga.title as NSString])
                }
                .background {
                    Color.secondary
                        .opacity(isHoveringOverTitle ? 0.1 : 0.0)
                }
                .onHover { hoverState in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHoveringOverTitle = hoverState
                    }
                }
                .buttonStyle(.plain)
                .font(.largeTitle)
                .help("Click to copy title")
                
                if let detailsUrl = selectedManga.detailsUrl {
                    Link(destination: detailsUrl) {
                        Label("Open in browser", systemImage: "arrow.up.forward.app")
                    }
                }
                
                Text(LocalizedStringKey(
                    "**Alternative titles:** \(selectedManga.altTitles?.joined(separator: "; ") ?? "None")"
                ))
                .lineLimit(5)
                
                Text(LocalizedStringKey("**Authors:** \(selectedManga.authors?.joined(separator: ", ") ?? "None")"))
                
                HStack {
                    if selectedManga.tags?.map { $0.url }.contains(nil) ?? true {
                        Text("**Tags:** \(selectedManga.tags?.map { $0.name }.joined(separator: ", ") ?? "None")")
                    } else {
                        Text(LocalizedStringKey("**Tags:** " + (selectedManga.tags?.map { "[\($0.name)](\($0.url!))" }.joined(separator: ", ") ?? "None")))
                    }
                    
                }
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
    }
}

struct ChapterList: View {
    @EnvironmentObject var mangaVM: MangaVM
    @EnvironmentObject var mangaListVM: MangaListVM
    @EnvironmentObject var notification: SystemNotificationContext
    
    @Binding var selectedManga: Manga
    @State var selected: UUID?
    
    @State private var ascendingOrder = true
    @State private var showingSearch = false
    @State private var chapterQuery = ""
    @State private var presentedDownloadChapterSheet: Chapter? = nil
    
    @State var window: NSWindow = NSWindow()
    
    var filteredChapters: [Chapter]? {
        var result: [Chapter]?
        
        if let chapters = selectedManga.chapters {
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
        if let filteredChapters = filteredChapters {
            VStack {
                HStack {
                    Text("Chapters")
                        .font(.headline)
                    
                    if showingSearch {
                        TextField("Search for a chapter", text: $chapterQuery)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        if let chapters = selectedManga.chapters {
                            Spacer()
                        
                            Button("Read first") {
                                openWindow(
                                    title: selectedManga.title + " - " + chapters.first!.title,
                                    manga: selectedManga,
                                    chapter: chapters.first!
                                )
                            }
                            .disabled(filteredChapters.isEmpty)
                            
                            Button("Read last") {
                                openWindow(
                                    title: selectedManga.title + " - " + chapters.last!.title,
                                    manga: selectedManga,
                                    chapter: chapters.last!
                                )
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
                            
                            Button {
                                presentedDownloadChapterSheet = chapter
                            } label: {
                                Image(systemName: "arrow.down.square")
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    /// Make entire area tappable
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        openWindow(
                            title: selectedManga.title + " - " + chapter.title,
                            manga: selectedManga,
                            chapter: chapter
                        )
                    }
                }
                .listStyle(.bordered(alternatesRowBackgrounds: true))
                .sheet(item: $presentedDownloadChapterSheet) { chapter in
                    VStack {
                        Text("Download: \(chapter.title)")
                            .font(.title3.bold())
                        
                        HStack {
                            if mangaVM.chapterDownloadProgress != nil {
                                ProgressView(value: Double(mangaVM.chapterDownloadProgress!.progress), total: Double(mangaVM.chapterDownloadProgress!.total)) {
                                    if mangaVM.chapterDownloadProgress!.total == 0 {
                                        Text("Fetching chapter count")
                                    } else if mangaVM.chapterDownloadProgress!.total == mangaVM.chapterDownloadProgress!.progress {
                                        Text("Chapter downloaded!")
                                    } else {
                                        Text("Downloading chapter")
                                    }
                                }
                                .progressViewStyle(LinearProgressViewStyle())
                            }
                            
                            Spacer()
                            
                            Button("Dismiss") {
                                presentedDownloadChapterSheet = nil
                            }
                            
                            Button("Download") {
                                Task {
                                    await mangaVM.downloadChapter(manga: selectedManga, chapter: chapter)
                                }
                            }
                        }
                    }
                    .frame(width: 300)
                    .padding()
                    .onDisappear {
                        mangaVM.chapterDownloadProgress = nil
                    }
                }
            }
        } else {
            Text("No chapters have been found.")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private func openWindow(title: String, manga: Manga, chapter: Chapter) {
        window = NSWindow(
            contentRect: NSRect(x: 20, y: 20, width: 1000, height: 625),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false)
        window.center()
        window.isReleasedWhenClosed = false
        window.title = title
        window.makeKeyAndOrderFront(nil)
        window.contentView = NSHostingView(
            rootView: MangaReaderView(manga: manga, chapter: chapter, window: $window)
                .environmentObject(mangaVM)
                .environmentObject(mangaListVM)
                .environmentObject(notification)
        )
    }
}


struct MangaDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        let exampleManga = Manga(
            title: "Example Manga",
            altTitles: ["Alt title 1", "Alt title 2"],
            authors: ["Author 1", "Author 2"],
            tags: [
                MangaTag(name: "Tag 1", url: URL(string: "https://example.com/tag1")),
                MangaTag(name: "Tag 2", url: URL(string: "https://example.com/tag2"))
            ], detailsUrl: URL(string: "https://example.com"),
            imageUrl: URL(string: "https://example.com/image.jpg"),
            chapters: [
                Chapter(title: "Chapter 1", chapterUrl: URL(string: "https://example.com/chapter1")!),
                Chapter(title: "Chapter 2", chapterUrl: URL(string: "https://example.com/chapter2")!)
            ]
        )
        
        MangaDetailsView(selectedManga: exampleManga)
            .frame(width: 500, height: 625)
    }
}
