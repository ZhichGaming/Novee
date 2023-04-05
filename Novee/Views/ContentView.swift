//
//  ContentView.swift
//  Novee
//
//  Created by Nick on 2022-10-15.
//

import SwiftUI
import AppKit
import CachedAsyncImage

struct ContentView: View {
    @State private var selectedView: String? = "home"

    var body: some View {
        NavigationView {
            List {
                NavigationLink(tag: "home", selection: self.$selectedView, destination: { HomeView(tab: $selectedView) }) {
                    HStack {
                        Image(systemName: "house")
                            .frame(width: 15)
                        Text("Home")
                    }
                }
                
                Section("Anime") {
                    NavigationLink(tag: "anime", selection: self.$selectedView, destination: { AnimeMenuView() }) {
                        HStack {
                            Image(systemName: "tv")
                                .frame(width: 15)
                            Text("Anime")
                        }
                    }
                    
                    NavigationLink(tag: "animelist", selection: self.$selectedView, destination: { AnimeListView() }) {
                        HStack {
                            Image(systemName: "list.bullet")
                                .frame(width: 15)
                            Text("Anime list")
                        }
                    }
                }
                
                Section("Manga") {
                    NavigationLink(tag: "manga", selection: self.$selectedView, destination: { MangaMenuView() }) {
                        HStack {
                            Image(systemName: "book.closed")
                                .frame(width: 15)
                            Text("Manga")
                        }
                    }
                    
                    NavigationLink(tag: "mangalist", selection: self.$selectedView, destination: { MangaListView() }) {
                        HStack {
                            Image(systemName: "list.bullet")
                                .frame(width: 15)
                            Text("Manga list")
                        }
                    }
                    
                    NavigationLink(tag: "mangalibrary", selection: self.$selectedView, destination: { MangaLocalLibraryView() }) {
                        HStack {
                            Image(systemName: "books.vertical")
                                .frame(width: 15)
                            Text("Library")
                        }
                    }
                }
                
                Section("Novel") {
                    NavigationLink(tag: "novel", selection: self.$selectedView, destination: { NovelMenuView() }) {
                        HStack {
                            Image(systemName: "book")
                                .frame(width: 15)
                            Text("Novel")
                        }
                    }
                    
                    NavigationLink(tag: "novellist", selection: self.$selectedView, destination: { NovelListView() }) {
                        HStack {
                            Image(systemName: "list.bullet")
                                .frame(width: 15)
                            Text("Novel list")
                        }
                    }
                }
            }
            .listStyle(.sidebar)
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

struct MediaColumnElementView: View {        
    let imageUrl: URL?
    let title: String?
    
    var installmentTitles: [String]?
    
    var body: some View {
        HStack {
            StyledImage(imageUrl: imageUrl)
                .frame(width: 75)

            VStack(alignment: .leading) {
                Text(title ?? "No title")
                    .font(.title3)
                    .lineLimit(2)
                    .padding(.vertical, 2)
                
                if let lastInstallments = installmentTitles?.suffix(3) {
                    ForEach(lastInstallments, id: \.self) { installment in
                        Text(installment)
                            .font(.footnote)
                            .lineLimit(1)
                    }
                }
            }
        }
        .frame(height: 100)
        .contentShape(Rectangle())
        .padding(.vertical, 2)
    }
}

struct StyledImage: View {
    var imageUrl: URL?
    
    var body: some View {
        CachedAsyncImage(url: imageUrl) { image in
            image
                .resizable()
                .scaledToFit()
                .cornerRadius(5)
                .clipped()
                .shadow(radius: 2, x: 2, y: 2)
        } placeholder: {
            ProgressView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
