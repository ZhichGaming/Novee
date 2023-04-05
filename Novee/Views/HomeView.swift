//
//  HomeView.swift
//  Novee
//
//  Created by Nick on 2022-10-16.
//

import SwiftUI
import AppKit
import CachedAsyncImage

struct HomeView: View {
    @EnvironmentObject var homeVM: HomeVM
    @EnvironmentObject var animeVM: AnimeVM
    @EnvironmentObject var mangaVM: MangaVM
    @EnvironmentObject var novelVM: NovelVM
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var tab: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    Text("Home")
                        .font(.largeTitle.bold())
                    
                    Divider()
                    
                    recentView
                    
                    Group {
                        Divider()
                        HomeNewMediaView(media: $homeVM.newAnime, tab: $tab)
                            .padding(.vertical, 25)
                        Divider()
                        HomeNewMediaView(media: $homeVM.newManga, tab: $tab)
                            .padding(.vertical, 25)
                        Divider()
                        HomeNewMediaView(media: $homeVM.newNovels, tab: $tab)
                            .padding(.vertical, 25)
                    }
                }
                .padding()
                .onAppear {
                    Task {
                        await homeVM.fetchLatestMedia()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationDestination(for: Anime.self) { anime in
                AnimeDetailsView(selectedAnime: anime)
            }
            .navigationDestination(for: Manga.self) { manga in
                MangaDetailsView(selectedManga: manga)
            }
            .navigationDestination(for: Novel.self) { novel in
                NovelDetailsView(selectedNovel: novel)
            }
        }
    }
    
    var recentView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading) {
                Text("Recent")
                    .font(.title3.bold())
                
                HStack(spacing: 15) {
                    ForEach(homeVM.getLatestActivities(), id: \.id) { activity in
                        if let firstContent: any Media = activity.content.first?.value {
                            NavigationLink {
                                if let anime = firstContent as? Anime {
                                    AnimeDetailsView(selectedAnime: anime)
                                } else if let manga = firstContent as? Manga {
                                    MangaDetailsView(selectedManga: manga)
                                } else if let novel = firstContent as? Novel {
                                    NovelDetailsView(selectedNovel: novel)
                                }
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(.secondary)
                                        .opacity(0.3)
                                        .shadow(color: .black, radius: 5, x: 2, y: 2)
                                    
                                    HStack {
                                        StyledImage(imageUrl: firstContent.imageUrl)
                                            .frame(width: 100, height: 150)
                                        
                                        VStack(alignment: .leading, spacing: 10) {
                                            Text(firstContent.title ?? "No title")
                                                .font(.headline)
                                                .lineLimit(2)
                                            
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 5)
                                                    .fill(activity.type.getColor())
                                                
                                                Text(activity.type.rawValue)
                                                    .foregroundColor(.white)
                                                    .padding(3)
                                                    .padding(.horizontal, 3)
                                            }
                                            .frame(width: 60, height: 20, alignment: .leading)
                                            
                                            Text(firstContent.description ?? "")
                                                .lineLimit(6)
                                        }
                                    }
                                    .padding(10)
                                }
                                .frame(width: 350)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.vertical)
            .padding(.horizontal, 20)
        }
        .frame(height: 200)
        .padding(.horizontal, -20)
    }
}

struct HomeNewMediaView<T: Media>: View {
    @EnvironmentObject var homeVM: HomeVM
    
    var mediaType: MediaType {
        type(of: media) == [Anime].self ? .anime : type(of: media) == [Manga].self ? .manga : .novel
    }
    
    @Binding var media: [T]
    @Binding var tab: String?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading) {
                Text("New \(mediaType.rawValue)")
                    .font(.title3.bold())
                
                HStack(spacing: 15) {
                    ForEach(media, id: \.id) { activity in
                        NavigationLink(value: activity) {
                            VStack(alignment: .leading) {
                                Spacer() // y dis no work???
                                
                                StyledImage(imageUrl: activity.imageUrl)
                                    .frame(maxHeight: 250)
                                
                                
                                Text(activity.title ?? "No title")
                                    .lineLimit(1)
                                    .font(.headline)
                            }
                            .frame(width: 150)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Button("More") {
                        tab = mediaType.rawValue.lowercased()
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, -20)
    }
}
