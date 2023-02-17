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
                NavigationLink(tag: 1, selection: self.$selectedView, destination: { AnimeMenuView() }, label: {
                        HStack {
                            Image(systemName: "tv")
                                .frame(width: 15)
                            Text("Anime")
                        }
                    }
                )
                
                NavigationLink(tag: 2, selection: self.$selectedView, destination: { MangaMenuView() }, label: {
                        HStack {
                            Image(systemName: "book.closed")
                                .frame(width: 15)
                            Text("Manga")
                        }
                    }
                )
                
                NavigationLink(tag: 3, selection: self.$selectedView, destination: { MangaListView() }, label: {
                        HStack {
                            Image(systemName: "list.bullet")
                                .frame(width: 15)
                            Text("List")
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
    static var previews: some View {
        ContentView()
    }
}
