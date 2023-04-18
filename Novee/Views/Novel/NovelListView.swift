//
//  NovelListView.swift
//  Novee
//
//  Created by Nick on 2023-03-05.
//

import SwiftUI
import CachedAsyncImage

struct NovelListView: View {
    @EnvironmentObject var novelVM: NovelVM
    @EnvironmentObject var novelListVM: NovelListVM
    
    let sources = Binding(get: {
        NovelVM.shared.sources as [String: any MediaSource]
    }, set: {
        NovelVM.shared.sources = $0 as? [String: any NovelSource] ?? NovelVM.shared.sources
    })
    
    var body: some View {
        MediaListView<NovelListElement>(sources: sources)
            .environmentObject(novelVM as MediaVM)
            .environmentObject(novelListVM as MediaListVM)
    }
}

struct NovelListView_Previews: PreviewProvider {
    static var previews: some View {
        NovelListView()
    }
}
