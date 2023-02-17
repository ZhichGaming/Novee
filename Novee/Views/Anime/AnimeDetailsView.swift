//
//  AnimeDetailsView.swift
//  Novee
//
//  Created by Nick on 2023-02-16.
//

import SwiftUI
import SystemNotification
import CachedAsyncImage

struct AnimeDetailsView: View {
    @EnvironmentObject var animeVM: AnimeVM
    @EnvironmentObject var settingsVM: SettingsVM
    @EnvironmentObject var notification: SystemNotificationContext
    
    @State var selectedAnimeIndex: Int

    @State private var descriptionSize: CGSize = .zero
    @State private var descriptionCollapsed = false
    @State private var isHoveringOverDescription = false
    
    /// Anime of the index passed in
    var selectedAnime: Anime? {
        if animeVM.sources[animeVM.selectedSource]!.animeData.count > selectedAnimeIndex {
            return animeVM.sources[animeVM.selectedSource]!.animeData[selectedAnimeIndex]
        }
        
        return nil
    }
    
    var body: some View {
        if let selectedAnime = selectedAnime {
            switch selectedAnime.detailsLoadingState {
            case .success:
                GeometryReader { geo in
                    VStack {
                        AnimeInfoView(geo: geo, selectedAnime: selectedAnime)
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
                                    Text(LocalizedStringKey(selectedAnime.description ?? "None"))
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
                        
                        EpisodeList(selectedAnimeIndex: selectedAnimeIndex)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .padding()
                }
            case .loading:
                ProgressView()
                    .onAppear {
                        Task {
                            await animeVM.getAnimeDetails(for: selectedAnime)
                        }
                    }
            case .failed:
                Text("Fetching failed")
                Button("Try again") {
                    Task {
                        await animeVM.sources[animeVM.selectedSource]!.getAnimeDetails(anime: selectedAnime)
                    }
                }
            case .notFound:
                Text("A source for the selected anime has not been found.")
            }
        }
    }
}

struct AnimeInfoView: View {
    @State private var isHoveringOverTitle = false

    let geo: GeometryProxy
    var selectedAnime: Anime
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Button(selectedAnime.title ?? "No title") {
                    if let title = selectedAnime.title {
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
                
                if let detailsUrl = selectedAnime.detailsUrl {
                    Link(destination: detailsUrl) {
                        Label("Open in browser", systemImage: "arrow.up.forward.app")
                    }
                }
                
                Text(LocalizedStringKey(
                    "**Alternative titles:** \(selectedAnime.altTitles?.joined(separator: "; ") ?? "None")"
                ))
                .lineLimit(5)
                
                Text(LocalizedStringKey("**Authors:** \(selectedAnime.authors?.joined(separator: ", ") ?? "None")"))
                
                HStack {
                    if selectedAnime.tags?.map { $0.url }.contains(nil) ?? true {
                        Text("**Tags:** \(selectedAnime.tags?.map { $0.name }.joined(separator: ", ") ?? "None")")
                    } else {
                        Text(LocalizedStringKey("**Tags:** " + (selectedAnime.tags?.map { "[\($0.name)](\($0.url!))" }.joined(separator: ", ") ?? "None")))
                    }
                    
                }
            }
            Spacer()
            CachedAsyncImage(url: selectedAnime.imageUrl) { image in
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

struct EpisodeList: View {
    @EnvironmentObject var animeVM: AnimeVM
    @EnvironmentObject var notification: SystemNotificationContext
    
    @State var selectedAnimeIndex: Int
    @State var selected: UUID?
    
    @State private var ascendingOrder = true
    @State private var showingSearch = false
    @State private var episodeQuery = ""
    
    @State var window: NSWindow = NSWindow()
    
    var selectedAnime: Anime? {
        if animeVM.sources[animeVM.selectedSource]?.animeData.count ?? 0 > selectedAnimeIndex {
            return animeVM.sources[animeVM.selectedSource]!.animeData[selectedAnimeIndex]
        }
        
        return nil
    }
    
    var filteredEpisodes: [Episode]? {
        var result: [Episode]?
        
        if let episodes = animeVM.sources[animeVM.selectedSource]!.animeData[selectedAnimeIndex].episodes {
            if ascendingOrder {
                result = episodes
            } else {
                result = episodes.reversed()
            }
            
            if !episodeQuery.isEmpty {
                result = result?.filter { $0.title.uppercased().contains(episodeQuery.uppercased()) }
            }
        }
        
        return result
    }

    var body: some View {
        if let selectedAnime = selectedAnime, let filteredEpisodes = filteredEpisodes {
            VStack {
                HStack {
                    Text("Episodes")
                        .font(.headline)
                    
                    if showingSearch {
                        TextField("Search for a episode", text: $episodeQuery)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        if let episodes = animeVM.sources[animeVM.selectedSource]!.animeData[selectedAnimeIndex].episodes {
                            Spacer()
                        
                            Button("Watch first") {
                                openWindow(title: episodes.first!.title, anime: selectedAnime, episode: episodes.first!)
                            }
                            .disabled(filteredEpisodes.isEmpty)
                            
                            Button("Watch last") {
                                openWindow(title: episodes.last!.title, anime: selectedAnime, episode: episodes.last!)
                            }
                            .disabled(filteredEpisodes.isEmpty)

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
                
                List(filteredEpisodes.reversed()) { episode in
                    VStack(alignment: .leading) {
                        // TODO: Episode upload date
                        HStack {
                            Text(episode.title)
                                .font(.headline)
                            
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    /// Make entire area tappable
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        openWindow(title: episode.title, anime: selectedAnime, episode: episode)
                    }
                }
                .listStyle(.bordered(alternatesRowBackgrounds: true))
            }
        } else {
            Text("No episodes have been found.")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private func openWindow(title: String, anime: Anime, episode: Episode) {
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
            rootView: AnimeWatcherView(selectedAnime: anime, selectedEpisode: episode, window: $window)
                .environmentObject(animeVM)
                .environmentObject(notification)
                .frame(minWidth: 400, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
        )
    }
}

struct AnimeDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        AnimeDetailsView(selectedAnimeIndex: 0)
            .frame(width: 500, height: 625)
    }
}
