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
                HStack {
                    TextField("Search", text: $searchText)
                        .frame(width: geo.size.width * 0.5)
                        .textFieldStyle(.roundedBorder)
                        .padding()
                    
                    Spacer()
                }
                .frame(height: 30)
                .frame(maxWidth: .infinity)

                NavigationView {
                    List(mangaVM.mangadexManga) { manga in
                        NavigationLink {
                            MangaDetailsView(manga: manga)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(manga.attributes.title.first?.value ?? "No title")
                                        .font(.title2)
                                    Text("Latest chapter: \(manga.attributes.lastChapter ?? "No chapters")")
                                        .font(.footnote)
                                    HStack {
                                        ForEach(getShortenedTags(for: manga)) { tag in
                                            Text(MangaVM.getLocalisedString(tag.attributes.name, settingsVM: settingsVM))
                                                .font(.caption)
                                                .padding(3)
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
    }
    
    func getShortenedTags(for manga: MangadexMangaData) -> [MangadexTag] {
        if manga.attributes.tags!.count >= 5 {
            let shortenedTags = manga.attributes.tags![0..<5]
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
