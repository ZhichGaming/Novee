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
        let favourites = FavouritesVM.shared.getFavourites()
        
        var amountOfUpdates = 0
        var updatedMediaTitle = ""
        var updatedSegmentTitle = ""
        
        for favourite in favourites {
            let savedLatestChapter = favourite.lastSegment
            let fetchedLatestChapter = await FavouritesVM.shared.getLastFetchedSegment(for: favourite)
            
            if let savedLatestChapter = savedLatestChapter, let fetchedLatestChapter = fetchedLatestChapter {
                if savedLatestChapter != fetchedLatestChapter {
                    if amountOfUpdates == 0 {
                        updatedMediaTitle = favourite.content.first?.value.title ?? "Unknown"
                        updatedSegmentTitle = fetchedLatestChapter
                    }

                    amountOfUpdates += 1
                }
            }
            
            try? await Task.sleep(nanoseconds: UInt64(3 * Double(NSEC_PER_SEC)))
        }
        
        if amountOfUpdates == 0 {
            return
        }
        
        do {
            let content = UNMutableNotificationContent()
            content.title = "There are " + amountOfUpdates.description + " new chapters/episodes"
            content.subtitle = "\(updatedSegmentTitle) from \(updatedMediaTitle) and \(amountOfUpdates != 1 ? amountOfUpdates.description + " others " : "")have been published."
            content.sound = UNNotificationSound.default

            // show this notification five seconds from now
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

            // choose a random identifier
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

            // add our notification request
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            Log.shared.error(error)
        }
    }
}
