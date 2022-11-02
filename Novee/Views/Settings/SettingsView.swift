//
//  SettingsView.swift
//  Novee
//
//  Created by Nick on 2022-10-16.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsVM: SettingsVM
    
    var body: some View {
        TabView {
            MangaSettingsView()
                .tabItem {
                    Label("Manga", systemImage: "book.closed")
                }
        }
        .padding(20)
        .frame(width: 375, height: 150)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
