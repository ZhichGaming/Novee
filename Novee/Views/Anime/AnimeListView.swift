//
//  AnimeListView.swift
//  Novee
//
//  Created by Nick on 2023-02-18.
//

import SwiftUI
import CachedAsyncImage

struct AnimeListView: View {
    @EnvironmentObject var animeVM: AnimeVM
    @EnvironmentObject var animeListVM: AnimeListVM
    
    let sources = Binding(get: {
        AnimeVM.shared.sources as [String: any MediaSource]
    }, set: {
        AnimeVM.shared.sources = $0 as? [String: any AnimeSource] ?? AnimeVM.shared.sources
    })
    
    var body: some View {
        MediaListView<AnimeListElement>(sources: sources)
            .environmentObject(animeVM as MediaVM)
            .environmentObject(animeListVM as MediaListVM)
    }
}

struct AnimeListView_Previews: PreviewProvider {
    static var previews: some View {
        AnimeListView()
    }
}
