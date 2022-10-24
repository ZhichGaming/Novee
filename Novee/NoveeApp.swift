//
//  NoveeApp.swift
//  Novee
//
//  Created by Nick on 2022-10-15.
//

import SwiftUI

@main
struct NoveeApp: App {
    @StateObject var settingsVM = SettingsVM()
    @StateObject var mangaVM = MangaVM()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1000, maxWidth: .infinity, minHeight: 625, maxHeight: .infinity)
                .environmentObject(mangaVM)
                .environmentObject(settingsVM)
                .presentedWindowToolbarStyle(.unified)
        }
    }
}
