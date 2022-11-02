//
//  MangaMenuView.swift
//  Novee
//
//  Created by Nick on 2022-10-16.
//

import SwiftUI

struct MangaMenuView: View {
    @EnvironmentObject var settingsVM: SettingsVM
    @EnvironmentObject var mangaVM: MangaVM
    @State var searchText = ""
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Divider()
                NavigationView {
                    List(mangaVM.mangadexManga) { manga in
                        NavigationLink {
                            MangaDetailsView(mangaId: manga.id)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(manga.attributes.title.first?.value ?? "No title")
                                        .font(.title2)
                                    Text("Latest chapter: \(manga.attributes.lastChapter ?? "Unknown")")
                                        .font(.footnote)
                                    HStack {
                                        ForEach(getShortenedTags(for: manga)) { tag in
                                            Text(MangaVM.getLocalisedString(tag.attributes.name, settingsVM: settingsVM))
                                                .font(.caption)
                                                .padding(3)
                                                .padding(.horizontal, 2)
                                                .foregroundColor(.white)
                                                .background {
                                                    Color.accentColor.clipShape(RoundedRectangle(cornerRadius: 5))
                                                }
                                        }
                                    }
                                }
                                
                                Spacer()
                                AsyncImage(url: URL(string: "https://uploads.mangadex.org/covers/\(manga.id.uuidString.lowercased())/\(manga.relationships.first { $0?.type == "cover_art" }!!.attributes!.fileName!).256.jpg")) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                } placeholder: {
                                    ProgressView()
                                }
                            }
                            .frame(height: 100)
                            .contentShape(Rectangle())
                        }
                    }
                    .frame(minWidth: 400, maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .searchable(text: $searchText, placement: .toolbar)
        .onSubmit(of: .search) {
            mangaVM.fetchManga(title: searchText)
        }
    }
    
    func getShortenedTags(for manga: MangadexMangaData) -> [MangadexTag] {
        if manga.attributes.tags!.count >= 3 {
            let shortenedTags = manga.attributes.tags![0..<3]
            return Array(shortenedTags)
        }
        return manga.attributes.tags!
    }
}

struct MangaMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MangaMenuView()
    }
}
