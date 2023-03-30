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
        
        WindowGroup(for: AnimeEpisodePair.self) { $animeEpisode in
            if let animeEpisode = animeEpisode {
                AnimeWatcherView(selectedAnime: animeEpisode.anime, selectedEpisode: animeEpisode.episode)
                    .frame(minWidth: 200, maxWidth: .infinity, minHeight: 125, maxHeight: .infinity)
                    .environmentObject(AnimeVM.shared)
                    .environmentObject(AnimeListVM.shared)
                    .presentedWindowToolbarStyle(.unified)
            }
        }
        .windowStyle(.titleBar)
        
        WindowGroup(for: MangaChapterPair.self) { $mangaChapter in
            if let mangaChapter = mangaChapter {
                MangaReaderView(manga: mangaChapter.manga, chapter: mangaChapter.chapter)
                    .frame(minWidth: 200, maxWidth: .infinity, minHeight: 125, maxHeight: .infinity)
                    .environmentObject(MangaVM.shared)
                    .environmentObject(MangaListVM.shared)
                    .environmentObject(SettingsVM.shared)
                    .presentedWindowToolbarStyle(.unified)
            }
        }
        .windowStyle(.titleBar)
        
        WindowGroup(for: NovelChapterPair.self) { $novelChapter in
            if let novelChapter = novelChapter {
                NovelReaderView(novel: novelChapter.novel, chapter: novelChapter.chapter)
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
