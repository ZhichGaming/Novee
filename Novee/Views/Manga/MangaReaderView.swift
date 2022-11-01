//
//  MangaReaderView.swift
//  Novee
//
//  Created by Nick on 2022-10-26.
//

import SwiftUI

struct MangaReaderView: View {
    @EnvironmentObject var mangaVM: MangaVM
    
    @State var selectedChapter = UUID()

    var body: some View {
        VStack {
            Text("Chapter \(mangaVM.openedChapter?.attributes.chapter ?? "")")
            ScrollView {
                ForEach(mangaVM.openedChapter?.pages?.imageUrl ?? [], id: \.self) { url in
                    AsyncImage(url: URL(string: url)) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                }
            }
        }
        .onAppear {
            selectedChapter = mangaVM.openedChapter?.id ?? UUID()
            if mangaVM.openedChapterId != nil {
                mangaVM.getPages(for: mangaVM.openedChapterId!)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    
                } label: {
                    HStack {
                        Text("Previous chapter")
                        Image(systemName: "arrow.left")
                    }
                }
                
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    
                } label: {
                    HStack {
                        Text("Next chapter")
                        Image(systemName: "arrow.right")
                    }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Picker("Select a chapter", selection: $selectedChapter) {
                    ForEach(mangaVM.openedManga?.chapters ?? []) { chapter in
                        Text("Chapter \(chapter.attributes.chapter ?? "") (\(Language.getValue(chapter.attributes.translatedLanguage.uppercased()) ?? "\(mangaVM.openedChapter!.attributes.translatedLanguage)"))")
                            .tag(chapter.id)
                    }
                }
                .frame(width: 300)
            }
        }
    }
}

struct MangaReaderView_Previews: PreviewProvider {
    static let mangaVM = [MangadexMangaData(id: UUID(uuidString: "1cb98005-7bf9-488b-9d44-784a961ae42d")!, type: "Manga", attributes: MangadexMangaAttributes(title: ["en": "Test manga"], isLocked: false, originalLanguage: "jp", status: "Ongoing", createdAt: Date.distantPast, updatedAt: Date.now), relationships: [MangadexRelationship(id: UUID(), type: "cover_art", attributes: MangadexRelationshipAttributes(fileName: "9ab7ae43-9448-4f85-86d8-c661c6d23bbf.jpg"))], chapters: [MangadexChapter(id: UUID(uuidString: "29bfff23-c550-4a29-b65e-6f0a7b6c8574")!, type: "chapter", attributes: MangadexChapterAttributes(volume: "1", chapter: "1", title: nil, translatedLanguage: "en", externalUrl: nil, publishAt: Date.distantPast), relationships: [])])]
    
    static var previews: some View {
        MangaReaderView()
            .frame(width: 1000, height: 625)
    }
}
