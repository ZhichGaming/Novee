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
    
    @State private var selectedChapter = UUID()
    @State private var zoom = 1.0

    var body: some View {
        GeometryReader { geo in
            ScrollView([.horizontal, .vertical]) {
                ForEach(mangaVM.openedChapter?.pages?.imageUrl ?? [], id: \.self) { url in
                    CachedAsyncImage(url: URL(string: url)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            var imageSize: CGSize = .zero

                            if geo.size.width < imageSize.width {
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geo.size.width)
                            } else {
                                image
                                    .background {
                                        GeometryReader { imageGeo in
                                            Color.clear
                                                .onAppear {
                                                    imageSize = imageGeo.size
                                                }
                                        }
                                    }
                                    .onAppear() {
                                        print("\(geo.size.width) - \(imageSize.width)")
                                    }
                                    .onChange(of: imageSize.width) { _ in
                                        print("\(geo.size.width) - \(imageSize.width)")
                                    }
                            }
                        case .failure:
                            Button("Failed fetching image.") {
                                mangaVM.getPages(for: mangaVM.openedChapterId ?? UUID())
                            }
                        @unknown default:
                            Text("Unknown error. Please try again.")
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            selectedChapter = mangaVM.openedChapter?.id ?? UUID()
            if mangaVM.openedChapterId != nil {
                mangaVM.getPages(for: mangaVM.openedChapterId!)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                TextField("Zoom", value: $zoom, format: .percent)
                    .textFieldStyle(.plain)
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
                    ForEach(mangaVM.openedManga?.chapters?.data ?? []) { chapter in
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
    static let chapters = MangadexChapterResponse(result: "ok", response: "", data: [MangadexChapter(id: UUID(uuidString: "29bfff23-c550-4a29-b65e-6f0a7b6c8574")!, type: "chapter", attributes: MangadexChapterAttributes(volume: "1", chapter: "1", title: nil, translatedLanguage: "en", externalUrl: nil, publishAt: Date.distantPast), relationships: [])])
    static let mangaVM = [MangadexMangaData(id: UUID(uuidString: "1cb98005-7bf9-488b-9d44-784a961ae42d")!, type: "Manga", attributes: MangadexMangaAttributes(title: ["en": "Test manga"], isLocked: false, originalLanguage: "jp", status: "Ongoing", createdAt: Date.distantPast, updatedAt: Date.now), relationships: [MangadexRelationship(id: UUID(), type: "cover_art", attributes: MangadexRelationshipAttributes(fileName: "9ab7ae43-9448-4f85-86d8-c661c6d23bbf.jpg"))], chapters: chapters)]
    
    static var previews: some View {
        MangaReaderView()
            .frame(width: 1000, height: 625)
    }
}
