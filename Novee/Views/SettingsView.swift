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
        ScrollView {
            VStack (alignment: .leading) {
                Text("Settings")
                    .font(.largeTitle)
                Divider()
                Group {
                    Text("General")
                        .font(.title)
                }
                Divider()
                Group {
                    Text("Anime")
                        .font(.title)
                }
                Divider()
                Group {
                    Text("Manga")
                        .font(.title)
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
                Divider()
                Group {
                    Text("Novel")
                        .font(.title)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
