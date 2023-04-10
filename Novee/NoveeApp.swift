//
//  NoveeApp.swift
//  Novee
//
//  Created by Nick on 2022-10-15.
//

import SwiftUI
import SystemNotification

@main
struct NoveeApp: App {
    @StateObject var notification = SystemNotificationContext()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1000, maxWidth: .infinity, minHeight: 625, maxHeight: .infinity)
                .environmentObject(SettingsVM.shared)
                .environmentObject(HomeVM.shared)
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
}
