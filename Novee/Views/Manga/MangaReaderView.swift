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
        ScrollView([.horizontal, .vertical]) {
            Text(manga.title + " " + chapter.title)
                .font(.title)
            // TODO: Load the images
            ForEach(chapter.images ?? [], id: \.self) { nsImage in
                Image(nsImage: nsImage)
                    .scaledToFit()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            Task {
                chapter.images = await mangaVM
                    .sources[mangaVM.selectedSource]!
                    .getMangaPages(manga: manga, chapter: chapter)
            }
        }
    }
}
