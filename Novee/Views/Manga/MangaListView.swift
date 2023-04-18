//
//  MangaListView.swift
//  Novee
//
//  Created by Nick on 2023-01-03.
//

import SwiftUI
import CachedAsyncImage

struct MangaListView: View {
    @EnvironmentObject var mangaVM: MangaVM
    @EnvironmentObject var mangaListVM: MangaListVM
    
    let sources = Binding(get: {
        MangaVM.shared.sources as [String: any MediaSource]
    }, set: {
        MangaVM.shared.sources = $0 as? [String: any MangaSource] ?? MangaVM.shared.sources
    })
    
    var body: some View {
        MediaListView<MangaListElement>(sources: sources)
            .environmentObject(mangaVM as MediaVM)
            .environmentObject(mangaListVM as MediaListVM)
    }
}

struct MangaListView_Previews: PreviewProvider {
    static var previews: some View {
        MangaListView()
    }
}
