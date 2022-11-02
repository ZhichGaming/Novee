//
//  MangaSettingsView.swift
//  Novee
//
//  Created by Nick on 2022-11-02.
//

import SwiftUI

struct MangaSettingsView: View {
    @EnvironmentObject var settingsVM: SettingsVM
    
    var body: some View {
        VStack {
            Picker("Primary language", selection: Binding(get: { settingsVM.settings.preferedLanguage }, set: { settingsVM.settings.preferedLanguage = $0 })
            ) {
                ForEach(Language.allCases, id: \.self) { language in
                    Text(language.rawValue)
                        .tag(language)
                }
            }
        }
    }
}

struct MangaSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        MangaSettingsView()
    }
}
