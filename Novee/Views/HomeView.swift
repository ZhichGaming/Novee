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
    
    @State private var showingNotificationsPopup = false
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var tab: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    Text("Recent")
                        .font(.title.bold())
                    
                    Divider()
                    
                    recentView
                        .padding(.vertical)
                    
                    Text("New Updates")
                        .font(.title.bold())
                    
                    Divider()
                    
                    VStack(spacing: 0) {
                        HomeNewMediaView(media: $homeVM.newAnime, tab: $tab)

                        HomeNewMediaView(media: $homeVM.newManga, tab: $tab)

                        HomeNewMediaView(media: $homeVM.newNovels, tab: $tab)
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
                AnimeDetailsView(anime: anime)
            }
            .navigationDestination(for: Manga.self) { manga in
                MangaDetailsView(manga: manga)
            }
            .navigationDestination(for: Novel.self) { novel in
                NovelDetailsView(novel: novel)
            }
        }
    }
    
    var recentView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(homeVM.getLatestActivities(), id: \.id) { activity in
                    if let firstContent: any Media = activity.content.first?.value {
                        NavigationLink {
                            if let anime = firstContent as? Anime {
                                AnimeDetailsView(anime: anime)
                            } else if let manga = firstContent as? Manga {
                                MangaDetailsView(manga: manga)
                            } else if let novel = firstContent as? Novel {
                                NovelDetailsView(novel: novel)
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(.black.opacity(0.05))
                                    .shadow(radius: 2, x: 0, y: 2)
                                    .frame(height: 150)
                                
                                HStack {
                                    CachedAsyncImage(url: firstContent.imageUrl) { image in
                                        if let image = image {
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(maxWidth: 120)
                                                .shadow(radius: 4, x: 0.5, y: 2)
                                        }
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .frame(maxWidth: 120, maxHeight: .infinity)
                                    .padding(.leading, -10)
                                    
                                    VStack(alignment: .leading, spacing: 6.5) {
                                        Text(firstContent.title ?? "No title")
                                            .font(.headline)
                                            .lineLimit(1)
                                        
                                        Text(firstContent.segments?.last?.title ?? "Unknown latest chapter")
                                            .font(.subheadline)
                                            .lineLimit(1)
                                        
                                        Text(firstContent.description ?? "")
                                            .lineLimit(6)
                                            .font(.caption)
                                            .opacity(0.5)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(10)
                                .frame(height: 150)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                .clipped()
                            }
                            .frame(width: 340)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
        .frame(height: 200)
        .padding(-20)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NotificationToolbarButton(isPopupShown: $showingNotificationsPopup)
                    .popover(isPresented: $showingNotificationsPopup) {
                        NotificationView()
                    }
            }
        }
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
            VStack(alignment: .leading, spacing: 0) {
                Text("\(mediaType.rawValue)")
                    .font(.title3.bold())
                
                HStack(spacing: 15) {
                    ForEach(media.indices, id: \.self) { index in
                        let activity = media[index]
                        
                        NavigationLink(value: activity) {
                            VStack(alignment: .leading) {
                                Spacer()
                                
                                CachedAsyncImage(url: activity.imageUrl) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 140, height: 180)
                                        .clipped()
                                        .cornerRadius(3)
                                        .shadow(radius: 2, x: 0, y: 2)
//                                        .shadow(radius: 2, x: 0, y: 2)
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(maxHeight: 250)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(activity.title ?? "No title")
                                        .lineLimit(1)
                                        .font(.headline)
                                    
                                    let title: String? = activity.segments?.last?.title
                                    /// If title is shorter than 25 characters or title is nil, return title as is. Else, return title's first 25 letters and an ellipsis.
                                    let trimmedTitle: String = ((title ?? "" == title?.prefix(25) ?? "") ? title : (title!.prefix(25) + "...")) ?? "Unknown"
                                    let statusString: String = activity.associatedListElement?.status.rawValue ?? "Not viewing"
                                    
                                    Text(trimmedTitle + ", " + statusString)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                }
                                .frame(height: 60)
                            }
                            .frame(width: 140)
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
