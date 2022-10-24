//
//  SettingsVM.swift
//  Novee
//
//  Created by Nick on 2022-10-21.
//

import Foundation

class SettingsVM: ObservableObject {
    init() {
        settings = Settings(preferedLanguage: .EN)
        fetchSettings()
    }
    
    @Published var settings: Settings {
        didSet {
            save()
        }
    }
        
    func fetchSettings() {
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                let applicationSupportUrl = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                guard let data = FileManager().contents(atPath: applicationSupportUrl.appendingPathComponent("settings.json").path) else {
                    let encoded = try JSONEncoder().encode(self.settings)
                    FileManager().createFile(
                        atPath: applicationSupportUrl.appendingPathComponent("settings.json").path,
                        contents: encoded)
                    return
                }
                let decoded = try decoder.decode(Settings.self, from: data)
                
                DispatchQueue.main.sync {
                    self.settings = decoded
                }
            } catch {
                print(error)
            }
        }
    }
    
    func save() {
        do {
            let settingsUrl = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("settings.json")
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            
            let encoded = try encoder.encode(settings)
            
            try encoded.write(to: settingsUrl)
        } catch {
            print(error)
        }

    }
}

    
