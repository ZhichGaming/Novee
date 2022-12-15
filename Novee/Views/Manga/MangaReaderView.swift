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
                // TODO: Load the images
                ForEach([String](), id: \.self) { url in
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
                            }
                        case .failure:
                            // TODO: Refetch failed images
//                            Button("Failed fetching image.") {
//                                mangaVM.getPages(for: mangaVM.openedChapterId ?? UUID())
//                            }
                            Text("Failure")
                        @unknown default:
                            Text("Unknown error. Please try again.")
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            // TODO: Get pages on appearing
//            selectedChapter = mangaVM.openedChapter?.id ?? UUID()
//            if mangaVM.openedChapterId != nil {
//                mangaVM.getPages(for: mangaVM.openedChapterId!)
//            }
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
//                    ForEach(mangaVM.openedManga?.chapters?.data ?? []) { chapter in
//                        Text("Chapter \(chapter.attributes.chapter ?? "") (\(Language.getValue(chapter.attributes.translatedLanguage.uppercased()) ?? "\(mangaVM.openedChapter!.attributes.translatedLanguage)"))")
//                            .tag(chapter.id)
//                    }
                }
                .frame(width: 300)
            }
        }
    }
}

struct MangaReaderView_Previews: PreviewProvider {
    static var previews: some View {
        MangaReaderView()
            .frame(width: 1000, height: 625)
    }
}
