//
//  AnimeWatcherView.swift
//  Novee
//
//  Created by Nick on 2023-02-16.
//

import SwiftUI
import AVKit
import SystemNotification
import CachedAsyncImage

struct AnimeWatcherView: View {
    @EnvironmentObject var animeVM: AnimeVM
    @EnvironmentObject var animeListVM: AnimeListVM
    @StateObject var notification = SystemNotificationContext()

    let selectedAnime: Anime
    @State var selectedEpisode: Episode
    
    @State var pickerSelectedEpisodeId = UUID()
    @State var streamingUrl: URL? = nil
    
    @State var player: AVPlayer? = nil
    
    @State var showingNextEpisode = false
    @State var timeObserverToken: Any?
    @State var statusTimeObserverToken: Any?
    @State var remainingTime = 5
    
    @State var showingCustomizedAddToListSheet = false
    @State var oldEpisodeTitle = ""

    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .onAppear {
                        selectedEpisode.resumeTime = animeListVM.findChapterInList(anime: selectedAnime, episode: selectedEpisode)?.resumeTime
                        
                        if selectedAnime.episodes?.last?.id != selectedEpisode.id {
                            addPeriodicTimeObserver()
                        }
                        
                        self.player?.play()
                        showSeekToResumeTimePopup()
                    }
                    .onDisappear {
                        self.player?.pause()
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
                                    player.removeTimeObserver(timeObserverToken as Any)
                                    
                                    withAnimation {
                                        showingNextEpisode = false
                                    }
                                    
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
                                        
                                        player.removeTimeObserver(timeObserverToken as Any)

                                        withAnimation {
                                            showingNextEpisode = false
                                        }
                                        
                                        nextEpisode()
                                    }
                                }
                            }
                        }
                    }
                
                Group {
                    Button("") {
                        navigateSeconds(5)
                    }
                    .keyboardShortcut(.rightArrow, modifiers: [])
                    
                    Button("") {
                        navigateSeconds(-5)
                    }
                    .keyboardShortcut(.leftArrow, modifiers: [])
                }
                .opacity(0)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            // A toolbar item to change video resolution using a picker
            ToolbarItem(placement: .secondaryAction) {
                Picker("Select resolution", selection: $streamingUrl) {
                    ForEach(selectedEpisode.streamingUrls ?? []) { streamingUrl in
                        Text(streamingUrl.quality ?? "Unknown")
                            .tag(streamingUrl.url)
                    }
                }
                .onChange(of: streamingUrl) { [streamingUrl] newUrl in
                    if player == nil { return }
                    
                    if let newUrl = newUrl {
                        self.player?.pause()
                                                
                        selectedEpisode.resumeTime = animeListVM.getResumeTime(anime: selectedAnime, episode: selectedEpisode)
                        self.player = AVPlayer(url: newUrl)
                        
                        if streamingUrl != nil {
                            seekToResumeTime()
                            player?.play()
                        }
                        
                        if let newSelectedQuality = selectedEpisode.streamingUrls?.first(where: { $0.url == newUrl })?.quality {
                            animeVM.lastSelectedResolution = newSelectedQuality
                        }
                    }
                }
            }
            
            // Some toolbar items to change episode
            ToolbarItemGroup(placement: .primaryAction) {
                Spacer()
                
                Button(action: {
                    previousEpisode()
                }, label: {
                    Image(systemName: "chevron.left")
                })
                .disabled(selectedAnime.episodes?.first?.id == selectedEpisode.id)
                
                Button(action: {
                    nextEpisode()
                }, label: {
                    Image(systemName: "chevron.right")
                })
                .disabled(selectedAnime.episodes?.last?.id == selectedEpisode.id)
                
                Picker("Select episode", selection: $pickerSelectedEpisodeId) {
                    ForEach(selectedAnime.episodes ?? []) { episode in
                        Text(episode.title)
                            .tag(episode.id)
                    }
                }
                .onAppear {
                    pickerSelectedEpisodeId = selectedEpisode.id
                    
                    if animeListVM.findInList(anime: selectedAnime) == nil {
                        showAddAnimeNotification()
                    } else {
                        showUpdateEpisodeNotification(newEpisode: selectedEpisode)
                    }
                }
                .onChange(of: pickerSelectedEpisodeId) { [pickerSelectedEpisodeId] newId in
                    selectAndLoadEpisode()
                    streamingUrl = nil
                    
                    if pickerSelectedEpisodeId != newId {
                        showUpdateEpisodeNotification(newEpisode: selectedEpisode)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCustomizedAddToListSheet) {
            AnimeWatcherAddToListView(anime: selectedAnime, episode: selectedEpisode)
        }
        .navigationTitle(selectedEpisode.title)
        .systemNotification(notification)
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
                
                // Update the time the user left off
                animeListVM.updateResumeTime(anime: selectedAnime, episode: selectedEpisode, newTime: time.seconds)
            }
        }
    }
    
    func navigateSeconds(_ time: Double) {
        if let currentTime = player?.currentItem?.currentTime() {
            print(currentTime)
            let newTime = CMTime(seconds: currentTime.seconds + time, preferredTimescale: currentTime.timescale)
            
            player?.seek(to: newTime)
        } else {
            print("error")
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
    
    /**
     Unloads previous episode and loads the next
     */
    func selectAndLoadEpisode() {
        player?.pause()

        selectedEpisode = selectedAnime.episodes?.first { $0.id == pickerSelectedEpisodeId } ?? selectedEpisode
        player = nil
    }
    
    func getStreamingUrl() -> StreamingUrl? {
        return selectedEpisode.streamingUrls?.first { $0.quality == animeVM.lastSelectedResolution } ?? selectedEpisode.streamingUrls?.first
    }
    
    private func showAddAnimeNotification() {
        notification.present(configuration: .init(duration: 15)) {
            VStack {
                VStack(alignment: .leading) {
                    Text("Add this anime to your list?")
                        .font(.footnote.bold())
                        .foregroundColor(.primary.opacity(0.6))
                    Text("Swipe to dismiss")
                        .font(.footnote.bold())
                        .foregroundColor(.primary.opacity(0.4))
                }
                .frame(width: 225, alignment: .leading)

                HStack {
                    Button {
                        showingCustomizedAddToListSheet = true
                        notification.dismiss()
                    } label: {
                        Text("Add with options")
                    }
                    
                    Button {
                        animeListVM.addToList(
                            source: animeVM.selectedSource,
                            anime: selectedAnime,
                            lastEpisode: selectedEpisode.title,
                            status: .watching,
                            rating: .none,
                            lastWatchDate: Date.now
                        )
                        
                        notification.dismiss()
                    } label: {
                        Text("Add")
                    }
                    .keyboardShortcut(.defaultAction)
                }
                .frame(width: 225, alignment: .trailing)
            }
            .frame(width: 300, height: 75)
        }
    }
    
    private func showUpdateEpisodeNotification(newEpisode: Episode) {
        if let index = animeListVM.list.firstIndex(where: { $0.id == animeListVM.findInList(anime: selectedAnime)?.id }) {
            oldEpisodeTitle = animeListVM.list[index].lastEpisode ?? ""
            animeListVM.list[index].lastEpisode = newEpisode.title
            
            notification.present {
                VStack {
                    VStack(alignment: .leading) {
                        Text("Last read episode updated!")
                            .font(.footnote.bold())
                            .foregroundColor(.primary.opacity(0.6))
                        Text("Swipe to dismiss")
                            .font(.footnote.bold())
                            .foregroundColor(.primary.opacity(0.4))
                    }
                    .frame(width: 225, alignment: .leading)

                    HStack {
                        Button {
                            animeListVM.list[index].lastEpisode = oldEpisodeTitle
                            notification.dismiss()
                        } label: {
                            Text("Undo")
                        }
                        .keyboardShortcut(.defaultAction)
                    }
                    .frame(width: 225, alignment: .trailing)
                }
                .frame(width: 300, height: 75)
            }
        } else {
            print("An error occured in the `showUpdateEpisodeNotification` function.")
        }
    }
    
    private func showSeekToResumeTimePopup() {
        if selectedEpisode.resumeTime != nil {
            notification.present(configuration: .init(duration: 10)) {
                VStack {
                    VStack(alignment: .leading) {
                        Text("Resume playback from where you left off?")
                            .font(.footnote.bold())
                            .foregroundColor(.primary.opacity(0.6))
                        Text("Swipe to dismiss")
                            .font(.footnote.bold())
                            .foregroundColor(.primary.opacity(0.4))
                    }
                    .frame(width: 225, alignment: .leading)
                    
                    HStack {
                        Button {
                            seekToResumeTime()
                            notification.dismiss()
                        } label: {
                            Text("Resume")
                        }
                        .keyboardShortcut(.defaultAction)
                    }
                    .frame(width: 225, alignment: .trailing)
                }
                .frame(width: 300, height: 75)
            }
        }
    }
    
    private func seekToResumeTime() {
        if let resumeTime = selectedEpisode.resumeTime {
            self.player?.seek(to: CMTime(seconds: resumeTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
        }
    }
}

struct AnimeWatcherAddToListView: View {
    @EnvironmentObject var animeVM: AnimeVM
    @EnvironmentObject var animeListVM: AnimeListVM

    @Environment(\.dismiss) var dismiss

    let anime: Anime
    var episode: Episode? = nil
    
    @State private var selectedAnimeStatus: AnimeStatus = .watching
    @State private var selectedAnimeRating: AnimeRating = .none
    @State private var selectedLastEpisode: UUID = UUID()
    
    @State private var selectedAnimeListElement: AnimeListElement?
    
    @State private var createNewEntry = false
    
    @State private var selectedListItem = UUID()
    @State private var showingFindManuallyPopup = false
    
    var body: some View {
        HStack {
            VStack {
                Button("Add new entry") {
                    selectedAnimeListElement = AnimeListElement(anime: [:], status: .watching, rating: .none, creationDate: Date.now)
                    createNewEntry = true
                }
                                        
                Button("Find manually") {
                    showingFindManuallyPopup = true
                }
                .popover(isPresented: $showingFindManuallyPopup) {
                    VStack {
                        List(animeListVM.list.sorted { $0.anime.first?.value.title ?? "" < $1.anime.first?.value.title ?? "" }, id: \.id, selection: $selectedListItem) { item in
                            Text(item.anime.first?.value.title ?? "No title")
                                .tag(item.id)
                        }
                        .listStyle(.bordered(alternatesRowBackgrounds: true))
                        
                        Text("Type in the list to search.")
                        
                        HStack {
                            Spacer()
                            
                            Button("Cancel") { showingFindManuallyPopup = false }
                            Button("Select") {
                                selectedAnimeListElement = animeListVM.list.first(where: { $0.id == selectedListItem })
                                showingFindManuallyPopup = false
                            }
                            .disabled(!animeListVM.list.contains { $0.id == selectedListItem })
                        }
                    }
                    .frame(width: 400, height: 300)
                    .padding()
                }
                
                Spacer()
                Text(animeListVM.findInList(anime: anime)?.anime.first?.value.title ?? "Anime not found")
                
                if let url = animeListVM.findInList(anime: anime)?.anime.first?.value.imageUrl {
                    CachedAsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                }
                
                Spacer()
            }
            
            Divider()
                .padding(.horizontal)
            
            VStack {
                Text("Anime options")

                Group {
                    Picker("Status", selection: $selectedAnimeStatus) {
                        ForEach(AnimeStatus.allCases, id: \.rawValue) {
                            Text($0.rawValue)
                                .tag($0)
                        }
                    }
                    
                    Picker("Rating", selection: $selectedAnimeRating) {
                        ForEach(AnimeRating.allCases, id: \.rawValue) {
                            Text($0.rawValue)
                                .tag($0)
                        }
                    }
                    
                    Picker("Last episode", selection: $selectedLastEpisode) {
                        ForEach(anime.episodes ?? []) {
                            Text($0.title)
                                .tag($0.id)
                        }
                    }
                }
                .disabled(selectedAnimeListElement == nil)
                
                HStack {
                    Spacer()
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                    
                    Button(createNewEntry ? "Add to list" : "Save") {
                        if createNewEntry {
                            animeListVM.addToList(
                                source: animeVM.selectedSource,
                                anime: anime,
                                lastEpisode: anime.episodes?.first { $0.id == selectedLastEpisode }?.title ?? episode?.title,
                                status: selectedAnimeStatus,
                                rating: selectedAnimeRating,
                                lastWatchDate: Date.now
                            )
                        } else {
                            animeListVM.updateListEntry(
                                id: selectedAnimeListElement!.id,
                                newValue: AnimeListElement(
                                    anime: [animeVM.selectedSource: anime],
                                    lastEpisode: anime.episodes?.first { $0.id == selectedLastEpisode }?.title ?? episode?.title,
                                    status: selectedAnimeStatus,
                                    rating: selectedAnimeRating,
                                    lastWatchDate: Date.now,
                                    creationDate: Date.now
                                )
                            )
                        }
                        
                        dismiss()
                    }
                    .disabled(selectedAnimeListElement == nil)
                }
            }
        }
        .padding()
        .onAppear {
            selectedAnimeListElement = animeListVM.findInList(anime: anime)
        }
        .onChange(of: selectedAnimeListElement) { _ in
            if let selectedAnimeListElement = selectedAnimeListElement {
                selectedAnimeStatus = selectedAnimeListElement.status
                selectedAnimeRating = selectedAnimeListElement.rating
                
                selectedLastEpisode = anime.episodes?.first { $0.title == selectedAnimeListElement.lastEpisode }?.id ?? UUID()
            }
        }
    }
}
