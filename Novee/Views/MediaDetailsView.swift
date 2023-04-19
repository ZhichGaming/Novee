//
//  MediaDetailsView.swift
//  Novee
//
//  Created by Nick on 2023-04-16.
//

import SwiftUI
import SystemNotification
import CachedAsyncImage

struct MediaDetailsView<T: Media>: View {
    @EnvironmentObject var mediaVM: MediaVM<T>
    @EnvironmentObject var mediaListVM: MediaListVM<T.MediaListElementType>
    @EnvironmentObject var settingsVM: SettingsVM
    @EnvironmentObject var notification: SystemNotificationContext
    
    @Environment(\.openURL) var openUrl
    
    @State var selectedMedia: T

    @State private var descriptionSize: CGSize = .zero
    @State private var descriptionCollapsed = false
    @State private var isHoveringOverDescription = false
    @State private var isShowingAddToListSheet = false
    
    @State private var detailsLoadingState: LoadingState = .loading
    
    let fetchDetails: () async -> T?
    let updateMediaInList: (T) -> Void
    
    var resetDownloadProgress: () -> Void
    var downloadSegment: (T.MediaSegmentType) -> Void
    var isDownloading: Bool
    var downloadProgress: Double?
    var downloadTotal: Double?
    
    var isInList: Bool {
        mediaListVM.findInList(media: selectedMedia) != nil
    }
    
    var body: some View {
        switch detailsLoadingState {
        case .success:
            VStack(spacing: 12) {
                HStack(alignment: .top, spacing: 15) {
                    StyledImage(imageUrl: selectedMedia.imageUrl)
                        .frame(maxWidth: 250)
                    
                    MediaInfoView(selectedMedia: selectedMedia)
                }
                
                HStack(alignment: .top, spacing: 15) {
                    VStack(spacing: 0) {
                        HStack {
                            Button("Open in browser") {
                                openUrl(selectedMedia.detailsUrl!)
                            }
                            .disabled(selectedMedia.detailsUrl == nil)
                            
                            Button(isInList ? "Edit list entry" : "Add to list") {
                                if isInList {
                                    isShowingAddToListSheet = true
                                } else {
                                    mediaListVM.list.append(T.MediaListElementType(content: [mediaVM.selectedSource: selectedMedia as! T.MediaListElementType.AssociatedMediaType], lastSegment: nil, status: .viewing, rating: .none, lastViewedDate: nil, creationDate: Date.now))
                                }
                            }
                        }
                        
                        if let listElement = mediaListVM.findInList(media: selectedMedia) {
                            Form {
                                Section {
                                    HStack {
                                        Text("Status")
                                        
                                        Spacer()
                                        
                                        Text(listElement.status.rawValue)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    HStack {
                                        Text("Rating")
                                        
                                        Spacer()
                                        
                                        Text(listElement.rating.rawValue)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Section {
                                    HStack {
                                        Text("Last segment")
                                        
                                        Spacer()
                                        
                                        Text(listElement.lastSegment ?? "None")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Section {
                                    HStack {
                                        Text("Last viewed date")
                                        
                                        Spacer()
                                        
                                        Text(listElement.lastViewedDate?.toString() ?? "None")
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    HStack {
                                        Text("Creation date")
                                        
                                        Spacer()
                                        
                                        Text(listElement.creationDate.toString())
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .font(.body)
                            .formStyle(.grouped)
                            .scrollContentBackground(.hidden)
                            .padding(.horizontal, -20)
                        }
                    }
                    .frame(maxWidth: 250)
                    
                    SegmentList(selectedMedia: $selectedMedia, resetDownloadProgress: resetDownloadProgress, downloadSegment: downloadSegment, isDownloading: isDownloading, downloadProgress: downloadProgress, downloadTotal: downloadTotal)
                }
                .frame(maxHeight: .infinity)
            }
            .padding()
            .sheet(isPresented: $isShowingAddToListSheet) {
                AddToListView(media: selectedMedia)
                    .frame(width: 400, height: 200)
            }
        case .loading:
            ProgressView()
                .onAppear {
                    Task {
                        if let newMedia = await fetchDetails() {
                            selectedMedia = newMedia
                            
                            detailsLoadingState = .success
                            
                            updateMediaInList(newMedia)
                        } else {
                            detailsLoadingState = .failed
                        }
                    }
//                    Task {
//                        await mediaVM.getMediaDetails(for: selectedMedia, source: mediaVM.selectedSource) { newMedia in
//                            if let newMedia = newMedia {
//                                selectedMedia = newMedia
//
//                                if let mediaListElement = mediaListVM.findInList(media: selectedMedia) {
//                                    mediaListVM.updateMediaInListElement(
//                                        id: mediaListElement.id,
//                                        source: mediaVM.selectedSource,
//                                        media: selectedMedia
//                                    )
//                                }
//                            } else {
//                                selectedMedia.detailsLoadingState = .failed
//                            }
//                        }
//                    }
                }
        case .failed:
            Text("Fetching failed")
            
            Button("Try again") {
                Task {
                    if let newMedia = await fetchDetails() {
                        selectedMedia = newMedia
                        
                        detailsLoadingState = .success
                        
                        updateMediaInList(newMedia)
                    } else {
                        detailsLoadingState = .failed
                    }
                }
            }
        }
    }
}

struct MediaInfoView<T: Media>: View {
    @State private var isHoveringOverTitle = false

    var selectedMedia: T
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(selectedMedia.title ?? "No title") {
                if let title = selectedMedia.title {
                    let pasteBoard = NSPasteboard.general
                    pasteBoard.clearContents()
                    pasteBoard.writeObjects([title as NSString])
                }
            }
            .background {
                Color.secondary
                    .opacity(isHoveringOverTitle ? 0.1 : 0.0)
            }
            .onHover { hoverState in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHoveringOverTitle = hoverState
                }
            }
            .buttonStyle(.plain)
            .font(.largeTitle.bold())
            .help("Click to copy title")
            
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey("**Authors:** \(selectedMedia.authors?.joined(separator: ", ") ?? "None")"))
                
                Text(LocalizedStringKey("**Alternative titles:** \(selectedMedia.altTitles?.joined(separator: ", ") ?? "None")"))
                    .lineLimit(5)
                
                HStack {
                    if selectedMedia.tags?.map { $0.url }.contains(nil) ?? true {
                        Text("**Tags:** \(selectedMedia.tags?.map { $0.name }.joined(separator: ", ") ?? "None")")
                    } else {
                        Text(LocalizedStringKey("**Tags:** " + (selectedMedia.tags?.map { "[\($0.name)](\($0.url!))" }.joined(separator: ", ") ?? "None")))
                    }
                    
                }
            }
            
            if let description = selectedMedia.description {
                Divider()
                
                Text(description)
            }
        }
    }
}

struct SegmentList<T: Media>: View {
    @EnvironmentObject var mediaVM: MediaVM<T>
    @EnvironmentObject var mediaListVM: MediaListVM<T.MediaListElementType>
    @EnvironmentObject var notification: SystemNotificationContext
    
    @Environment(\.openWindow) var openWindow
    
    @Binding var selectedMedia: T
    @State var selected: UUID?
    
    @State private var ascendingOrder = true
    @State private var showingSearch = false
    @State private var segmentQuery = ""
    @State private var showingDownloadSheet = false
    
    @State private var presentedDownloadSegmentSheet: T.MediaSegmentType? = nil
        
    var resetDownloadProgress: () -> Void
    var downloadSegment: (T.MediaSegmentType) -> Void
    var isDownloading: Bool
    var downloadProgress: Double?
    var downloadTotal: Double?
    
    var filteredSegments: [T.MediaSegmentType]? {
        var result: [T.MediaSegmentType]?
        
        if let segments = selectedMedia.segments {
            if ascendingOrder {
                result = segments
            } else {
                result = segments.reversed()
            }
            
            if !segmentQuery.isEmpty {
                result = result?.filter { $0.title.uppercased().contains(segmentQuery.uppercased()) }
            }
        }
        
        return result
    }

    var body: some View {
        if let filteredSegments = filteredSegments {
            VStack {
                HStack {
                    if showingSearch {
                        TextField("Search for a segment", text: $segmentQuery)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        if let segments = selectedMedia.segments {
                            let mediaListElement = mediaListVM.findInList(media: selectedMedia)
                            let currentSegmentIndex = segments.firstIndex { $0.title == mediaListElement?.lastSegment }
                            let isInBounds = currentSegmentIndex != nil && currentSegmentIndex! + 1 < segments.endIndex
                            
                            Button("Continue") {
                                let nextSegment = segments[currentSegmentIndex! + 1]
                                
                                openWindow(value: MediaSegmentPair(media: selectedMedia, segment: nextSegment))
                            }
                            .disabled(!isInBounds)
                            
                            Button("Open first") {
                                openWindow(value: MediaSegmentPair(media: selectedMedia, segment: segments.first!))
                            }
                            .disabled(filteredSegments.isEmpty)
                            
                            Button("Open last") {
                                openWindow(value: MediaSegmentPair(media: selectedMedia, segment: segments.last!))
                            }
                            .disabled(filteredSegments.isEmpty)

                            Spacer()
                        }
                    }
                    
                    Button {
                        showingSearch.toggle()
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .keyboardShortcut(showingSearch ? .cancelAction : nil)
                    
                    Button {
                        ascendingOrder.toggle()
                    } label: {
                        if ascendingOrder {
                            Image(systemName: "arrow.up")
                        } else {
                            Image(systemName: "arrow.down")
                        }
                    }
                    
                    Button {
                        showingDownloadSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                }
                
                List(filteredSegments.reversed()) { segment in
                    HStack {
                        Text(segment.title)
                            .font(.headline)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        openWindow(value: MediaSegmentPair(media: selectedMedia, segment: segment))
                    }
                }
                .listStyle(.bordered(alternatesRowBackgrounds: true))
                .sheet(item: $presentedDownloadSegmentSheet) { segment in
                    VStack {
                        HStack {
                            if isDownloading, let downloadProgress = downloadProgress, let downloadTotal = downloadTotal {
                                ProgressView(value: downloadProgress, total: downloadTotal) {
                                    EmptyView()
//                                    if mediaVM.segmentDownloadProgress?.progress != 1 {
//                                        Text("Downloading media...")
//                                    } else {
//                                        Text("Download finished!")
//                                    }
                                }
                                .progressViewStyle(LinearProgressViewStyle())
                            }
                            
                            Spacer()
                            
                            Button("Cancel") {
                                presentedDownloadSegmentSheet = nil
                                resetDownloadProgress()
                            }
                            
                            Button("Download") {
                                resetDownloadProgress()
                                downloadSegment(segment)
                            }
                        }
                    }
                    .padding()
                }
            }
        } else {
            Text("No segments have been found.")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct AddToListView<T: Media>: View {
    @EnvironmentObject var mediaVM: MediaVM<T>
    @EnvironmentObject var mediaListVM: MediaListVM<T.MediaListElementType>

    @Environment(\.dismiss) var dismiss

    let media: T
    var segment: T.MediaSegmentType? = nil
    
    @State private var selectedStatus: Status = .viewing
    @State private var selectedRating: Rating = .none
    @State private var selectedLastSegment: UUID = UUID()
    
    @State private var selectedMediaListElement: T.MediaListElementType?
    
    @State private var createNewEntry = false
    
    @State private var selectedListItem = UUID()
    @State private var showingFindManuallyPopup = false
    
    var body: some View {
        HStack {
            VStack {
                Button("Add new entry") {
                    selectedMediaListElement = T.MediaListElementType(content: [:], lastSegment: nil, status: .viewing, rating: .none, lastViewedDate: nil, creationDate: Date.now)
                    createNewEntry = true
                }

                Button("Find manually") {
                    showingFindManuallyPopup = true
                }
                .popover(isPresented: $showingFindManuallyPopup) {
                    VStack {
                        List(mediaListVM.list.sorted { $0.content.first?.value.title ?? "" < $1.content.first?.value.title ?? "" }, id: \.id, selection: $selectedListItem) { item in
                            Text(item.content.first?.value.title ?? "No title")
                                .tag(item.id)
                        }
                        .listStyle(.bordered(alternatesRowBackgrounds: true))

                        Text("Type in the list to search.")

                        HStack {
                            Spacer()

                            Button("Cancel") { showingFindManuallyPopup = false }
                            Button("Select") {
                                selectedMediaListElement = mediaListVM.list.first(where: { $0.id == selectedListItem })
                                showingFindManuallyPopup = false
                            }
                            .disabled(!mediaListVM.list.contains { $0.id == selectedListItem })
                        }
                    }
                    .frame(width: 400, height: 300)
                    .padding()
                }

                Spacer()
                Text(mediaListVM.findInList(media: media)?.content.first?.value.title ?? "Media not found")

                if let url = mediaListVM.findInList(media: media)?.content.first?.value.imageUrl {
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
                    Picker("Status", selection: $selectedStatus) {
                        ForEach(Status.allCases, id: \.rawValue) {
                            Text($0.rawValue)
                                .tag($0)
                        }
                    }

                    Picker("Rating", selection: $selectedRating) {
                        ForEach(Rating.allCases, id: \.rawValue) {
                            Text($0.rawValue)
                                .tag($0)
                        }
                    }

                    Picker("Last segment", selection: $selectedLastSegment) {
                        ForEach(media.segments ?? []) {
                            Text($0.title)
                                .tag($0.id)
                        }
                    }
                }
                .disabled(selectedMediaListElement == nil)

                HStack {
                    Spacer()
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }

                    Button(createNewEntry ? "Add to list" : "Save") {
                        if createNewEntry {
                            mediaListVM.addToList(
                                source: mediaVM.selectedSource,
                                media: media as! T.MediaListElementType.AssociatedMediaType,
                                lastSegment: media.segments?.first { $0.id == selectedLastSegment }?.title ?? segment?.title,
                                status: selectedStatus,
                                rating: selectedRating,
                                lastViewedDate: Date.now
                            )
                        } else {
                            mediaListVM.updateListEntry(
                                id: selectedMediaListElement!.id,
                                newValue: T.MediaListElementType(
                                    content: [mediaVM.selectedSource: media as! T.MediaListElementType.AssociatedMediaType],
                                    lastSegment: media.segments?.first { $0.id == selectedLastSegment }?.title ?? segment?.title,
                                    status: selectedStatus,
                                    rating: selectedRating,
                                    lastViewedDate: Date.now,
                                    creationDate: Date.now
                                )
                            )
                        }

                        dismiss()
                    }
                    .disabled(selectedMediaListElement == nil)
                }
            }
        }
        .padding()
        .onAppear {
            selectedMediaListElement = mediaListVM.findInList(media: media)
        }
        .onChange(of: selectedMediaListElement) { _ in
            if let selectedMediaListElement = selectedMediaListElement {
                selectedStatus = selectedMediaListElement.status
                selectedRating = selectedMediaListElement.rating
                
                selectedLastSegment = media.segments?.first { $0.title == selectedMediaListElement.lastSegment }?.id ?? UUID()
            }
        }
    }
}
