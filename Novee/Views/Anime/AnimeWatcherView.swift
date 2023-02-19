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
    
    @State var showingNextEpisode = false
    @State var timeObserverToken: Any?
    @State var remainingTime = 5

    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .onAppear {
                        // Add a periodic time observer to track the playback time every second
                        addPeriodicTimeObserver()
                    }
                    .onDisappear {
                        player.pause()
                    }
                    .overlay(alignment: .bottomTrailing) {
                        if showingNextEpisode {
                            HStack {
                                Text("Go to next episode? (\(remainingTime)s)")
                                Button("Cancel (esc)") {
                                    player.removeTimeObserver(timeObserverToken as Any)
                                    
                                    withAnimation {
                                        showingNextEpisode = false
                                    }
                                }
                                .keyboardShortcut(.cancelAction)

                                Button("Next episode (return)") {
                                    nextEpisode()
                                }
                                .keyboardShortcut(.defaultAction)
                            }
                            .padding()
                            .background {
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(.regularMaterial)
                            }
                            .padding(50)
                            .onAppear {
                                remainingTime = 5
                                
                                Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                                    if remainingTime > 0 {
                                        remainingTime -= 1
                                    } else {
                                        timer.invalidate()
                                        nextEpisode()
                                    }
                                }
                            }
                        }
                    }
            } else {
                ProgressView()
                    .onAppear {
                        Task {
                            await animeVM.getStreamingUrl(for: selectedEpisode, anime: selectedAnime) { newEpisode in
                                if let newEpisode = newEpisode {
                                    selectedEpisode = newEpisode
                                    
                                    if let url = getStreamingUrl()?.url {
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
                        
                        if let newSelectedQuality = selectedEpisode.streamingUrls?.first(where: { $0.url == streamingUrl })?.quality {
                            animeVM.lastSelectedResolution = newSelectedQuality
                        }
                    }
                }
            }
            
            // Some toolbar items to change chapter
            ToolbarItemGroup(placement: .primaryAction) {
                Spacer()
                
                Button(action: {
                    previousEpisode()
                }, label: {
                    Image(systemName: "chevron.left")
                })
                
                Button(action: {
                    nextEpisode()
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
                    selectAndLoadEpisode()
                }
            }
        }
        .navigationTitle(selectedEpisode.title)
    }
    
    func addPeriodicTimeObserver() {
        // Invoke callback every half second
        let interval = CMTime(seconds: 0.5,
                              preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        // Add time observer. Invoke closure on the main queue.
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            if let duration = player?.currentItem?.duration {
                let remainingTime = duration - time

                showingNextEpisode = remainingTime.seconds < 90
            }
        }
    }
    
    func previousEpisode() {
        selectedEpisode = animeVM.changeEpisode(episode: selectedEpisode, anime: selectedAnime, offset: -1) ?? selectedEpisode
        pickerSelectedEpisodeId = selectedEpisode.id
    }
    
    func nextEpisode() {
        selectedEpisode = animeVM.changeEpisode(episode: selectedEpisode, anime: selectedAnime, offset: 1) ?? selectedEpisode
        pickerSelectedEpisodeId = selectedEpisode.id
    }
    
    func selectAndLoadEpisode() {
        selectedEpisode = selectedAnime.episodes?.first { $0.id == pickerSelectedEpisodeId } ?? selectedEpisode
        player = nil
    }
    
    func getStreamingUrl() -> StreamingUrl? {
        return selectedEpisode.streamingUrls?.first { $0.quality == animeVM.lastSelectedResolution } ?? selectedEpisode.streamingUrls?.first
    }
}
