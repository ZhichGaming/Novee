//
//  AnimeWatcherView.swift
//  Novee
//
//  Created by Nick on 2023-02-16.
//

import SwiftUI
import AVKit

struct AnimeWatcherView: View {
    @EnvironmentObject var animeVM: AnimeVM

    let selectedAnime: Anime
    @State var selectedEpisode: Episode
    
    @State var pickerSelectedEpisodeId = UUID()
    @State var streamingUrl: URL? = nil
    
    @State var player: AVPlayer? = nil

    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }
            } else {
                ProgressView()
                    .onAppear {
                        Task {
                            await animeVM.getStreamingUrl(for: selectedEpisode, anime: selectedAnime) { newEpisode in
                                if let newEpisode = newEpisode {
                                    selectedEpisode = newEpisode
                                    
                                    if let url = newEpisode.streamingUrls?.first?.url {
                                        player = AVPlayer(url: url)
                                        streamingUrl = url
                                    }
                                }
                            }
                        }
                    }
            }
        }
        .toolbar {
            // A toolbar item to change video resolution using a picker
            ToolbarItem(placement: .secondaryAction) {
                Picker("Select resolution", selection: $streamingUrl) {
                    ForEach(selectedEpisode.streamingUrls ?? []) { streamingUrl in
                        Text(streamingUrl.quality ?? "Unknown")
                            .tag(streamingUrl.url)
                    }
                }
                .onChange(of: streamingUrl) { _ in
                    guard let player = player else { return }
                    
                    if let streamingUrl = streamingUrl {
                        player.pause()
                        self.player = AVPlayer(url: streamingUrl)
                    }
                }
            }
            
            // Some toolbar items to change chapter
            ToolbarItemGroup(placement: .primaryAction) {
                Spacer()
                
                Button(action: {
                    selectedEpisode = animeVM.changeEpisode(episode: selectedEpisode, anime: selectedAnime, offset: -1) ?? selectedEpisode
                    pickerSelectedEpisodeId = selectedEpisode.id
                }, label: {
                    Image(systemName: "chevron.left")
                })
                
                Button(action: {
                    selectedEpisode = animeVM.changeEpisode(episode: selectedEpisode, anime: selectedAnime, offset: 1) ?? selectedEpisode
                    pickerSelectedEpisodeId = selectedEpisode.id
                }, label: {
                    Image(systemName: "chevron.right")
                })
                
                Picker("Select episode", selection: $pickerSelectedEpisodeId) {
                    ForEach(selectedAnime.episodes ?? []) { episode in
                        Text(episode.title)
                            .tag(episode.id)
                    }
                }
                .onAppear {
                    pickerSelectedEpisodeId = selectedEpisode.id
                }
                .onChange(of: pickerSelectedEpisodeId) { _ in
                    selectedEpisode = selectedAnime.episodes?.first { $0.id == pickerSelectedEpisodeId } ?? selectedEpisode
                }
            }
        }
        .navigationTitle(selectedEpisode.title)
    }
}
