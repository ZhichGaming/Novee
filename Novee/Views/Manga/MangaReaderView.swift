//
//  MangaReaderView.swift
//  Novee
//
//  Created by Nick on 2022-10-26.
//

import SwiftUI

struct MangaReaderView: View {
    @EnvironmentObject var mangaVM: MangaVM
    
    @State private var showingMenuBar = true
    
    @Binding var openedManga: MangadexMangaData?
    @Binding var openedChapter: MangadexChapter?
    
    var body: some View {
        VStack {
            Text("Chapter \(openedChapter!.attributes.chapter ?? "") openedChapter?.attributes.title")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .top) {
            HStack {
                Text("Test")
            }
            .frame(maxWidth: .infinity, maxHeight: 75)
        }
    }
}

struct MangaReaderView_Previews: PreviewProvider {
    static let mangaVM = [MangadexMangaData(id: UUID(uuidString: "1cb98005-7bf9-488b-9d44-784a961ae42d")!, type: "Manga", attributes: MangadexMangaAttributes(title: ["en": "Test manga"], isLocked: false, originalLanguage: "jp", status: "Ongoing", createdAt: Date.distantPast, updatedAt: Date.now), relationships: [MangadexRelationship(id: UUID(), type: "cover_art", attributes: MangadexRelationshipAttributes(fileName: "9ab7ae43-9448-4f85-86d8-c661c6d23bbf.jpg"))], chapters: [MangadexChapter(id: UUID(uuidString: "29bfff23-c550-4a29-b65e-6f0a7b6c8574")!, type: "chapter", attributes: MangadexChapterAttributes(volume: "1", chapter: "1", title: nil, translatedLanguage: "en", externalUrl: nil, publishAt: Date.distantPast), relationships: [])])]
    
    static var previews: some View {
        MangaReaderView(openedManga: .constant(mangaVM[0]), openedChapter: .constant(mangaVM[0].chapters![0]))
            .frame(width: 1000, height: 625)
    }
}
