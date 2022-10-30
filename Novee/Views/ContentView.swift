//
//  ContentView.swift
//  Novee
//
//  Created by Nick on 2022-10-15.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @State private var selectedView: Int? = -1

    var body: some View {
        NavigationView {
            List {
                NavigationLink(tag: 1, selection: self.$selectedView, destination: { HomeView() }, label: {
                        HStack {
                            Image(systemName: "house")
                                .frame(width: 15)
                            Text("Home")
                        }
                    }
                )
                NavigationLink(tag: 2, selection: self.$selectedView, destination: { AnimeMenuView() }, label: {
                        HStack {
                            Image(systemName: "tv")
                                .frame(width: 15)
                            Text("Anime")
                        }
                    }
                )
                NavigationLink(tag: 3, selection: self.$selectedView, destination: { MangaMenuView() }, label: {
                        HStack {
                            Image(systemName: "book.closed")
                                .frame(width: 15)
                            Text("Manga")
                        }
                    }
                )
                NavigationLink(tag: 4, selection: self.$selectedView, destination: { NovelMenuView() }, label: {
                        HStack {
                            Image(systemName: "book")
                                .frame(width: 15)
                            Text("Novels")
                        }
                    }
                )
                NavigationLink(tag: 5, selection: self.$selectedView, destination: { SettingsView() }, label: {
                        HStack {
                            Image(systemName: "gear")
                                .frame(width: 15)
                            Text("Settings")
                        }
                    }
                )
            }
            .listStyle(.sidebar)
            .onAppear {
                self.selectedView = 1
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button(action: toggleSidebar, label: {
                        Image(systemName: "sidebar.leading")
                    })
                }
            }
        }
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}

struct ContentView_Previews: PreviewProvider {
    static let mangaVM = [MangadexMangaData(id: UUID(uuidString: "1cb98005-7bf9-488b-9d44-784a961ae42d")!, type: "Manga", attributes: MangadexMangaAttributes(title: ["en": "Test manga"], isLocked: false, originalLanguage: "jp", status: "Ongoing", createdAt: Date.distantPast, updatedAt: Date.now), relationships: [MangadexRelationship(id: UUID(), type: "cover_art", attributes: MangadexRelationshipAttributes(fileName: "9ab7ae43-9448-4f85-86d8-c661c6d23bbf.jpg"))], chapters: [MangadexChapter(id: UUID(uuidString: "29bfff23-c550-4a29-b65e-6f0a7b6c8574")!, type: "chapter", attributes: MangadexChapterAttributes(volume: "1", chapter: "1", title: nil, translatedLanguage: "en", externalUrl: nil, publishAt: Date.distantPast), relationships: [])])]
    
    static var previews: some View {
        ContentView()
    }
}
