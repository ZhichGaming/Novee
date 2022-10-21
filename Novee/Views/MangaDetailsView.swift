//
//  MangaDetailsView.swift
//  Novee
//
//  Created by Nick on 2022-10-20.
//

import SwiftUI

struct MangaDetailsView: View {
    @Binding var manga: MangadexMangaData
    
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack {
                    HStack(alignment: .top) {
                        Text(manga.attributes.title.first?.value ?? "No title")
                            .font(.largeTitle)
                        Spacer()
                        AsyncImage(url: URL(string: "https://uploads.mangadex.org/covers/\(manga.id.uuidString.lowercased())/\(manga.relationships.first { $0?.type == "cover_art" }!!.attributes!.fileName!).256.jpg")) { image in
                            image
                                .resizable()
                                .scaledToFit()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(maxWidth: geo.size.width * 0.4, maxHeight: geo.size.height * 0.4)
                        .clipped()
                    }
                    Divider()
                    Text(LocalizedStringKey(manga.attributes.description?.first?.value ?? "No description"))
                }
                .padding()
            }
        }
    }
}

struct MangaDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        MangaDetailsView(manga: .constant(MangadexMangaData(id: UUID(uuidString: "1cb98005-7bf9-488b-9d44-784a961ae42d")!, type: "Manga", attributes: MangadexMangaAttributes(title: ["en": "Test manga"], isLocked: false, originalLanguage: "jp", status: "Ongoing", createdAt: Date.distantPast, updatedAt: Date.now), relationships: [MangadexRelationship(id: UUID(), type: "cover_art", attributes: MangadexRelationshipAttributes(fileName: "9ab7ae43-9448-4f85-86d8-c661c6d23bbf.jpg"))])))
            .frame(width: 500, height: 625)
    }
}
