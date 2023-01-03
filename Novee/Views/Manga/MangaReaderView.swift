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
    @Binding var window: NSWindow

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical) {
                ChangeChaptersView(manga: manga, chapter: $chapter)
                
                if let images = chapter.images {
                    VStack(spacing: 0) {
                        ForEach(images, id: \.self) { nsImage in
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: nsImage.size.width > geometry.size.width ? .fit : .fill)
                                .frame(maxWidth: nsImage.size.width < geometry.size.width ? nsImage.size.width : geometry.size.width)
                        }
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
                
                ChangeChaptersView(manga: manga, chapter: $chapter)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: chapter) { [chapter] newChapter in
                if chapter.id != newChapter.id {
                    window.title = manga.title + " - " + newChapter.title
                    
                    Task {
                        self.chapter.images = await mangaVM
                            .sources[mangaVM.selectedSource]!
                            .getMangaPages(manga: manga, chapter: self.chapter)
                    }
                }
            }
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

struct ChangeChaptersView: View {
    @EnvironmentObject var mangaVM: MangaVM

    let manga: Manga
    @Binding var chapter: Chapter
    
    var body: some View {
        HStack {
            Button {
                if let newChapter = mangaVM.changeChapter(chapter: chapter, manga: manga, offset: -1) {
                    chapter = newChapter
                }
            } label: {
                HStack {
                    Text("Previous chapter")
                    Image(systemName: "arrow.left")
                }
            }
            
            Button {
                if let newChapter = mangaVM.changeChapter(chapter: chapter, manga: manga, offset: 1) {
                    chapter = newChapter
                }
            } label: {
                HStack {
                    Text("Next chapter")
                    Image(systemName: "arrow.right")
                }
            }
        }
        .padding()
    }
}
