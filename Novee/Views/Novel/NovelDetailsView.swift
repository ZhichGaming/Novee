//
//  NovelDetailsView.swift
//  Novee
//
//  Created by Nick on 2023-03-05.
//

import SwiftUI
import CachedAsyncImage
import SystemNotification

struct NovelDetailsView: View {
    @EnvironmentObject var novelVM: NovelVM
    @EnvironmentObject var novelListVM: NovelListVM
    @EnvironmentObject var settingsVM: SettingsVM
    @EnvironmentObject var notification: SystemNotificationContext
    
    @State var selectedNovel: Novel

    @State private var descriptionSize: CGSize = .zero
    @State private var descriptionCollapsed = false
    @State private var isHoveringOverDescription = false
    @State private var isShowingAddToListSheet = false
    
    var body: some View {
        switch selectedNovel.detailsLoadingState {
        case .success:
            GeometryReader { geo in
                TabView {
                    VStack {
                        NovelInfoView(geo: geo, selectedNovel: selectedNovel)
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
                                    Text(LocalizedStringKey(selectedNovel.description ?? "None"))
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
                        
                        NovelChapterList(selectedNovel: $selectedNovel)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .padding()
                    .tabItem {
                        Text("Novel details")
                    }
                    
                    Group {
                        if let novelListElement = novelListVM.findInList(novel: selectedNovel) {
                            NovelListListDetailsView(
                                passedNovel: novelListElement,
                                dismissOnDelete: false
                            )
                        } else {
                            VStack {
                                Text("This novel was not found in your list.")
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
                if let novelListId = novelListVM.findInList(novel: selectedNovel)?.id {
                    novelListVM.updateNovelInListElement(
                        id: novelListId,
                        source: novelVM.selectedSource,
                        novel: selectedNovel
                    )
                }
            }
            .sheet(isPresented: $isShowingAddToListSheet) {
                NovelReaderAddToListView(novel: selectedNovel)
            }
        case .loading:
            ProgressView()
                .onAppear {
                    Task {
                        await novelVM.getNovelDetails(for: selectedNovel, source: novelVM.selectedSource) { newNovel in
                            if let newNovel = newNovel {
                                selectedNovel = newNovel
                                
                                if let novelListId = novelListVM.findInList(novel: selectedNovel)?.id {
                                    novelListVM.updateNovelInListElement(
                                        id: novelListId,
                                        source: novelVM.selectedSource,
                                        novel: selectedNovel
                                    )
                                }
                            } else {
                                selectedNovel.detailsLoadingState = .failed
                            }
                        }
                    }
                }
        case .failed:
            Text("Fetching failed")
            Button("Try again") {
                Task {
                    await novelVM.sources[novelVM.selectedSource]!.getNovelDetails(novel: selectedNovel)
                }
            }
        case .notFound:
            Text("A source for the selected novel has not been found.")
        }
    }
}

struct NovelInfoView: View {
    @State private var isHoveringOverTitle = false

    let geo: GeometryProxy
    var selectedNovel: Novel
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Button(selectedNovel.title ?? "No title") {
                    if let title = selectedNovel.title {
                        let pasteBoard = NSPasteboard.general
                        pasteBoard.clearContents()
                        pasteBoard.writeObjects([title as NSString])
                    }
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
                
                if let detailsUrl = selectedNovel.detailsUrl {
                    Link(destination: detailsUrl) {
                        Label("Open in browser", systemImage: "arrow.up.forward.app")
                    }
                }
                
                Text(LocalizedStringKey(
                    "**Alternative titles:** \(selectedNovel.altTitles?.joined(separator: "; ") ?? "None")"
                ))
                .lineLimit(5)
                
                Text(LocalizedStringKey("**Authors:** \(selectedNovel.authors?.joined(separator: ", ") ?? "None")"))
                
                HStack {
                    if selectedNovel.tags?.map { $0.url }.contains(nil) ?? true {
                        Text("**Tags:** \(selectedNovel.tags?.map { $0.name }.joined(separator: ", ") ?? "None")")
                    } else {
                        Text(LocalizedStringKey("**Tags:** " + (selectedNovel.tags?.map { "[\($0.name)](\($0.url!))" }.joined(separator: ", ") ?? "None")))
                    }
                    
                }
            }
            Spacer()
            CachedAsyncImage(url: selectedNovel.imageUrl) { image in
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

struct NovelChapterList: View {
    @EnvironmentObject var novelVM: NovelVM
    @EnvironmentObject var novelListVM: NovelListVM
    @EnvironmentObject var notification: SystemNotificationContext
    
    @Binding var selectedNovel: Novel
    @State var selected: UUID?
    
    @State private var ascendingOrder = true
    @State private var showingSearch = false
    @State private var chapterQuery = ""
    @State private var presentedDownloadChapterSheet: NovelChapter? = nil
    
    @State var window: NSWindow = NSWindow()
    
    var filteredChapters: [NovelChapter]? {
        var result: [NovelChapter]?
        
        if let chapters = selectedNovel.chapters {
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
                        if let chapters = selectedNovel.chapters {
                            Spacer()
                            
                            let novelListElement = novelListVM.findInList(novel: selectedNovel)
                            let currentChapterIndex = chapters.firstIndex { $0.title == novelListElement?.lastChapter }
                            let isInBounds = currentChapterIndex != nil && currentChapterIndex! + 1 < chapters.endIndex
                            
                            Button("Continue") {
                                let nextChapter = chapters[currentChapterIndex! + 1]
                                
                                openWindow(
                                    title: (selectedNovel.title ?? "No Title") + " - " + nextChapter.title,
                                    novel: selectedNovel,
                                    chapter: nextChapter
                                )
                            }
                            .disabled(!isInBounds)
                        
                            Button("Read first") {
                                openWindow(
                                    title: (selectedNovel.title ?? "No title") + " - " + chapters.first!.title,
                                    novel: selectedNovel,
                                    chapter: chapters.first!
                                )
                            }
                            .disabled(filteredChapters.isEmpty)
                            
                            Button("Read last") {
                                openWindow(
                                    title: (selectedNovel.title ?? "No title") + " - " + chapters.last!.title,
                                    novel: selectedNovel,
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
                            title: (selectedNovel.title ?? "No title") + " - " + chapter.title,
                            novel: selectedNovel,
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
                            if novelVM.chapterDownloadProgress != nil {
                                ProgressView(value: novelVM.chapterDownloadProgress! ? 1.0 : 0.0, total: 1.0) {
                                    if novelVM.chapterDownloadProgress! {
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
                                    await novelVM.downloadChapter(novel: selectedNovel, chapter: chapter)
                                }
                            }
                        }
                    }
                    .frame(width: 300)
                    .padding()
                    .onDisappear {
                        novelVM.chapterDownloadProgress = nil
                    }
                }
            }
        } else {
            Text("No chapters have been found.")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private func openWindow(title: String, novel: Novel, chapter: NovelChapter) {
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
            rootView: NovelReaderView(novel: novel, chapter: chapter, window: $window)
                .environmentObject(novelVM)
                .environmentObject(novelListVM)
                .environmentObject(notification)
        )
    }
}
