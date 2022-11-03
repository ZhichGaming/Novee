//
//  NoveeApp.swift
//  Novee
//
//  Created by Nick on 2022-10-15.
//

import SwiftUI

@main
struct NoveeApp: App {
    @StateObject var mangaVM = MangaVM()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1000, maxWidth: .infinity, minHeight: 625, maxHeight: .infinity)
                .environmentObject(mangaVM)
                .environmentObject(SettingsVM.shared)
                .presentedWindowToolbarStyle(.unified)
        }
        .windowStyle(.titleBar)
        
        WindowGroup("Manga Reader") {
            MangaReaderView()
                .handlesExternalEvents(preferring: Set(arrayLiteral: "mangaReader"), allowing: Set(arrayLiteral: "*")) // activate existing window if exists
                .frame(minWidth: 1000, maxWidth: .infinity, minHeight: 625, maxHeight: .infinity)
                .environmentObject(mangaVM)
                .environmentObject(SettingsVM.shared)
                .presentedWindowToolbarStyle(.unified)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Refresh") {
                    mangaVM.getPages(for: mangaVM.openedChapterId ?? UUID())
                }
                .keyboardShortcut("r")
                .disabled(mangaVM.openedChapterId == nil)
            }
        }
        .handlesExternalEvents(matching: Set(arrayLiteral: "mangaReader")) // create new window if one doesn't exist
        
        SwiftUI.Settings {
            SettingsView()
                .environmentObject(SettingsVM.shared)
        }
    }
}
