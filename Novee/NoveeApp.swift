//
//  NoveeApp.swift
//  Novee
//
//  Created by Nick on 2022-10-15.
//

import SwiftUI

@main
struct NoveeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1000, maxWidth: .infinity, minHeight: 625, maxHeight: .infinity)
                .environmentObject(SettingsVM.shared)
                .environmentObject(MangaVM.shared)
                .presentedWindowToolbarStyle(.unified)
        }
        .windowStyle(.titleBar)
        
        WindowGroup("Manga Reader") {
            MangaReaderView()
                .handlesExternalEvents(preferring: Set(arrayLiteral: "mangaReader"), allowing: Set(arrayLiteral: "*")) // activate existing window if exists
                .frame(minWidth: 1000, maxWidth: .infinity, minHeight: 625, maxHeight: .infinity)
                .environmentObject(SettingsVM.shared)
                .environmentObject(MangaVM.shared)
                .presentedWindowToolbarStyle(.unified)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                
            }
        }
        .handlesExternalEvents(matching: Set(arrayLiteral: "mangaReader")) // create new window if one doesn't exist
        
        SwiftUI.Settings {
            SettingsView()
                .environmentObject(SettingsVM.shared)
        }
    }
}
