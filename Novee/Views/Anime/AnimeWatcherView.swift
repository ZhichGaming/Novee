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
    var customWindowDelegate = CustomWindowDelegate()

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
                        selectedEpisode.resumeTime = animeListVM.findEpisodeInList(anime: selectedAnime, episode: selectedEpisode)?.resumeTime
                        
                        if selectedAnime.segments?.last?.id != selectedEpisode.id {
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
                            if let newEpisode = await animeVM.getStreamingUrl(for: selectedEpisode, anime: selectedAnime) {
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
                .disabled(selectedAnime.segments?.first?.id == selectedEpisode.id)
                
                Button(action: {
                    nextEpisode()
                }, label: {
                    Image(systemName: "chevron.right")
                })
                .disabled(selectedAnime.segments?.last?.id == selectedEpisode.id)
                
                Picker("Select episode", selection: $pickerSelectedEpisodeId) {
                    ForEach(selectedAnime.segments ?? []) { episode in
                        Text(episode.title)
                            .tag(episode.id)
                    }
                }
                .frame(maxWidth: 300)
                .onAppear {
                    pickerSelectedEpisodeId = selectedEpisode.id
                    
                    if animeListVM.findInList(media: selectedAnime) == nil {
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
            AddToListView(media: selectedAnime, segment: selectedEpisode)
                .environmentObject(animeVM as MediaVM<Anime>)
                .environmentObject(animeListVM as MediaListVM<AnimeListElement>)
        }
        .navigationTitle(selectedEpisode.title)
        .systemNotification(notification)
        .background {
            HostingWindowFinder { window in
                guard let window else { return }
                window.delegate = self.customWindowDelegate
            }
        }
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

        selectedEpisode = selectedAnime.segments?.first { $0.id == pickerSelectedEpisodeId } ?? selectedEpisode
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
                            media: selectedAnime,
                            lastSegment: selectedEpisode.title,
                            status: .viewing,
                            rating: .none,
                            lastViewedDate: Date.now
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
        if let index = animeListVM.list.firstIndex(where: { $0.id == animeListVM.findInList(media: selectedAnime)?.id }) {
            oldEpisodeTitle = animeListVM.list[index].lastSegment ?? ""
            animeListVM.list[index].lastSegment = newEpisode.title
            
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
                            animeListVM.list[index].lastSegment = oldEpisodeTitle
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

struct HostingWindowFinder: NSViewRepresentable {
    var callback: (NSWindow?) -> ()
    
    func makeNSView(context: Self.Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { self.callback(view.window) }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { self.callback(nsView.window) }
    }
}

class CustomWindowDelegate: NSObject, NSWindowDelegate {
    override init() {
        super.init()
    }
    
    func window(_ window: NSWindow, willUseFullScreenPresentationOptions proposedOptions: NSApplication.PresentationOptions = []) -> NSApplication.PresentationOptions {
        return [.autoHideToolbar, .autoHideMenuBar, .fullScreen]
    }
}
