//
//  MangaReaderView.swift
//  Novee
//
//  Created by Nick on 2022-10-26.
//

import SwiftUI
import CachedAsyncImage

struct MangaReaderView: View {
    @EnvironmentObject var mangaVM: MangaVM
    
    @State private var zoom = 1.0
    
    let manga: Manga
    @State var chapter: Chapter

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical) {
                VStack {
                    ForEach(chapter.images ?? [], id: \.self) { nsImage in
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: nsImage.size.width > geometry.size.width ? .fit : .fill)
                            .frame(maxWidth: nsImage.size.width < geometry.size.width ? nsImage.size.width : geometry.size.width)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            Task {
                chapter.images = await mangaVM
                    .sources[mangaVM.selectedSource]!
                    .getMangaPages(manga: manga, chapter: chapter)
            }
        }
    }
}
