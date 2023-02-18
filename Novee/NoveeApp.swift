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
                .environmentObject(MangaVM.shared)
                .environmentObject(MangaListVM.shared)
                .environmentObject(notification)
                .presentedWindowToolbarStyle(.unified)
        }
        .windowStyle(.titleBar)
        
        WindowGroup(for: AnimeEpisodePair.self) { $animeEpisode in
            if let animeEpisode = animeEpisode {
                AnimeWatcherView(selectedAnime: animeEpisode.anime, selectedEpisode: animeEpisode.episode)
                    .frame(minWidth: 200, maxWidth: .infinity, minHeight: 125, maxHeight: .infinity)
                    .environmentObject(AnimeVM.shared)
                    .presentedWindowToolbarStyle(.unified)
            }
        }
        .windowStyle(.titleBar)

        SwiftUI.Settings {
            SettingsView()
                .environmentObject(SettingsVM.shared)
        }
    }
}
