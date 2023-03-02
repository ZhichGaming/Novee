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
    @State private var selectedView: Int? = -1

    var body: some View {
        NavigationView {
            List {
                Section("Anime") {
                    NavigationLink(tag: 1, selection: self.$selectedView, destination: { AnimeMenuView() }) {
                        HStack {
                            Image(systemName: "tv")
                                .frame(width: 15)
                            Text("Anime")
                        }
                    }
                    
                    NavigationLink(tag: 2, selection: self.$selectedView, destination: { AnimeListView() }) {
                        HStack {
                            Image(systemName: "list.bullet")
                                .frame(width: 15)
                            Text("Anime list")
                        }
                    }
                }
                
                Section("Manga") {
                    NavigationLink(tag: 3, selection: self.$selectedView, destination: { MangaMenuView() }) {
                        HStack {
                            Image(systemName: "book.closed")
                                .frame(width: 15)
                            Text("Manga")
                        }
                    }
                    
                    NavigationLink(tag: 4, selection: self.$selectedView, destination: { MangaListView() }) {
                        HStack {
                            Image(systemName: "list.bullet")
                                .frame(width: 15)
                            Text("Manga list")
                        }
                    }
                    
                    NavigationLink(tag: 5, selection: self.$selectedView, destination: { MangaLocalLibraryView() }) {
                        HStack {
                            Image(systemName: "books.vertical")
                                .frame(width: 15)
                            Text("Library")
                        }
                    }
                }
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

struct MediaColumnElementView: View {        
    let imageUrl: URL?
    let title: String?
    
    var installmentTitles: [String]?
    
    var body: some View {
        HStack {
            CachedAsyncImage(url: imageUrl) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(5)
                    .frame(width: 75)
                    .clipped()
                    .shadow(radius: 2, x: 2, y: 2)
            } placeholder: {
                ProgressView()
                    .frame(width: 75)
            }
                        
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
