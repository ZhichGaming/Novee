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
    
    @Binding var window: NSWindow
    
    var body: some View {
        ZStack {
            if let streamingSource = selectedEpisode.streamingUrls?.first, let url = streamingSource.url {
                VideoPlayer(player: AVPlayer(url: url))
            } else {
                ProgressView()
                    .onAppear {
                        Task {
                            await animeVM.getStreamingUrl(for: selectedEpisode, anime: selectedAnime) { newEpisode in
                                if let newEpisode = newEpisode {
                                    selectedEpisode = newEpisode
                                }
                            }
                        }
                    }
            }
        }
    }
}
