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
                .environmentObject(MangaVM.shared)
                .environmentObject(MangaListVM.shared)
                .environmentObject(notification)
                .presentedWindowToolbarStyle(.unified)
        }
        .windowStyle(.titleBar)
        
        SwiftUI.Settings {
            SettingsView()
                .environmentObject(SettingsVM.shared)
        }
    }
}
