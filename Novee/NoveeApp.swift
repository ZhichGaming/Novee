//
//  NoveeApp.swift
//  Novee
//
//  Created by Nick on 2022-10-15.
//

import SwiftUI
import SystemNotification
import UserNotifications

@main
struct NoveeApp: App {
    @StateObject var notification = SystemNotificationContext()
    
    init() {
        loadSegmentFetcher()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1000, maxWidth: .infinity, minHeight: 625, maxHeight: .infinity)
                .environmentObject(SettingsVM.shared)
                .environmentObject(HomeVM.shared)
                .environmentObject(FavouritesVM.shared)
                .environmentObject(AnimeVM.shared)
                .environmentObject(AnimeListVM.shared)
                .environmentObject(MangaVM.shared)
                .environmentObject(MangaListVM.shared)
                .environmentObject(MangaLibraryVM.shared)
                .environmentObject(NovelVM.shared)
                .environmentObject(NovelListVM.shared)
                .environmentObject(NotificationsVM.shared)
                .environmentObject(notification)
                .presentedWindowToolbarStyle(.unified)
        }
        .windowStyle(.titleBar)
        .commands {
            SidebarCommands()
            ToolbarCommands()
            
            CommandGroup(after: .sidebar) {
                Button("Toggle Full Screen") {
                    toggleFullScreen()
                }
                .keyboardShortcut("f", modifiers: [.control, .command])
            }
        }
        
        WindowGroup(for: MediaSegmentPair<Anime>.self) { $animeEpisode in
            if let animeEpisode = animeEpisode {
                AnimeWatcherView(selectedAnime: animeEpisode.media, selectedEpisode: animeEpisode.segment)
                    .frame(minWidth: 200, maxWidth: .infinity, minHeight: 125, maxHeight: .infinity)
                    .environmentObject(AnimeVM.shared)
                    .environmentObject(AnimeListVM.shared)
                    .presentedWindowToolbarStyle(.unified)
            }
        }
        .windowStyle(.titleBar)
        
        WindowGroup(for: MediaSegmentPair<Manga>.self) { $mangaChapter in
            if let mangaChapter = mangaChapter {
                MangaReaderView(manga: mangaChapter.media, chapter: mangaChapter.segment)
                    .frame(minWidth: 200, maxWidth: .infinity, minHeight: 125, maxHeight: .infinity)
                    .environmentObject(MangaVM.shared)
                    .environmentObject(MangaListVM.shared)
                    .environmentObject(SettingsVM.shared)
                    .presentedWindowToolbarStyle(.unified)
            }
        }
        .windowStyle(.titleBar)
        
        WindowGroup(for: MediaSegmentPair<Novel>.self) { $novelChapter in
            if let novelChapter = novelChapter {
                NovelReaderView(novel: novelChapter.media, chapter: novelChapter.segment)
                    .frame(minWidth: 200, maxWidth: .infinity, minHeight: 125, maxHeight: .infinity)
                    .environmentObject(NovelVM.shared)
                    .environmentObject(NovelListVM.shared)
                    .environmentObject(SettingsVM.shared)
                    .presentedWindowToolbarStyle(.unified)
            }
        }
        .windowStyle(.titleBar)

        SwiftUI.Settings {
            SettingsView()
                .environmentObject(SettingsVM.shared)
        }
    }
    
    private func toggleFullScreen() {
        NSApp.keyWindow?.toggleFullScreen(nil)
    }
    
    private func loadSegmentFetcher() {
        FavouritesVM.shared.getFavourites()
        
        requestNotificationAuthorization()
        
        let timer = Timer(fire: Date(), interval: 3600, repeats: true) { timer in
            Task {
                await fetchNewSegments()
            }
        }

        RunLoop.current.add(timer, forMode: .default)
    }
    
    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                print("Notification authorization granted.")
            } else if let error = error {
                print("Notification authorization denied: \(error.localizedDescription)")
            }
        }
    }
    
    private func fetchNewSegments() async {
        var favourites = FavouritesVM.shared.favourites
        
        var amountOfUpdates = 0
        var updatedMediaTitle = ""
        var updatedSegmentTitle = ""
        
        for (index, favourite) in favourites.enumerated() {
            let savedLatestChapter = favourite.mediaListElement.lastSegment
            let fetchedMedia = await FavouritesVM.shared.fetchLatestSegments(for: favourite.mediaListElement)
            
            guard let fetchedMedia = fetchedMedia else {
                Log.shared.log("Fetched media is nil.", isError: true)
                return
            }
            
            let fetchedLatestChapter = await getFetchedLatestChapter(fetchedMedia: fetchedMedia)

            if let savedLatestChapter = savedLatestChapter, let fetchedLatestChapter = fetchedLatestChapter {
                if savedLatestChapter != fetchedLatestChapter {
                    if amountOfUpdates == 0 {
                        updatedMediaTitle = favourite.mediaListElement.content.first?.value.title ?? "Unknown"
                        updatedSegmentTitle = fetchedLatestChapter
                    }

                    amountOfUpdates += 1
                }
            }
            
            // Finished checking whether there is a new chapter, update favourites so notifications don't repeat.
            favourites[index].mediaListElement = fetchedMedia
            favourites[index].mediaListElement.lastSegment = fetchedLatestChapter
            
            try? await Task.sleep(nanoseconds: UInt64(3 * Double(NSEC_PER_SEC)))
        }
        
        FavouritesVM.shared.favourites = favourites
        
        if amountOfUpdates == 0 {
            print("0 new media updates.")
            return
        }
        
        await NotificationsVM.shared.addNotification(
            title: "There are " + amountOfUpdates.description + " new chapters/episodes",
            subtitle: "\(updatedSegmentTitle) from \(updatedMediaTitle) and \(amountOfUpdates != 1 ? amountOfUpdates.description + " others " : "")have been published.")
    }
    
    private func getFetchedLatestChapter(fetchedMedia: any MediaListElement) async -> String? {
        await FavouritesVM.shared.getLastFetchedSegment(for: fetchedMedia, fetch: false)
    }
}
