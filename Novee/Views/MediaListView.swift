//
//  MediaListView.swift
//  Novee
//
//  Created by Nick on 2023-04-16.
//

import SwiftUI
import CachedAsyncImage
import SystemNotification

struct MediaListView<T: MediaListElement>: View {
    @EnvironmentObject var mediaListVM: MediaListVM<T>
    @EnvironmentObject var mediaVM: MediaVM<T.AssociatedMediaType>
    
    @State private var listQuery = ""
    @State private var showingFilterPopover = false
    @State private var showingAddNewMediaSheet = false
    @State private var selectedSortingStyle = "Recently updated"
    @State private var mediaDetailsSheet: T?
    
    @State private var showingWaiting = true
    @State private var showingViewing = true
    @State private var showingDropped = true
    @State private var showingCompleted = true
    @State private var showingToView = true
    
    @State private var showingRatingNone = true
    @State private var showingRatingHorrible = true
    @State private var showingRatingBad = true
    @State private var showingRatingGood = true
    @State private var showingRatingBest = true
    
    @State private var navigationPath = NavigationPath()
    
    @Binding var sources: [String: any MediaSource]
    
    var filteredList: [T] {
        var result = mediaListVM.list
        
        if !showingWaiting { result.removeAll { $0.status == .waiting } }
        if !showingViewing { result.removeAll { $0.status == .viewing } }
        if !showingDropped { result.removeAll { $0.status == .dropped } }
        if !showingCompleted { result.removeAll { $0.status == .completed } }
        if !showingToView { result.removeAll { $0.status == .toView } }
        
        if !showingRatingNone { result.removeAll { $0.rating == .none } }
        if !showingRatingHorrible { result.removeAll { $0.rating == .horrible } }
        if !showingRatingBad { result.removeAll { $0.rating == .bad } }
        if !showingRatingGood { result.removeAll { $0.rating == .good } }
        if !showingRatingBest { result.removeAll { $0.rating == .best } }
        
        if selectedSortingStyle == "Recently updated" {
            result.sort {
                return $0.lastViewedDate ?? Date.distantPast > $1.lastViewedDate ?? Date.distantPast
            }
        } else if selectedSortingStyle == "Recently added" {
            result.sort { $0.creationDate.compare($1.creationDate) == .orderedDescending }
        } else {
            result.sort {
                return $0.content.first?.value.title ?? "" < $1.content.first?.value.title ?? ""
            }
        }
        
        if !listQuery.isEmpty {
            result.removeAll { media in
                let mediaInstances = media.content.map { [$0.value.title ?? ""] + ($0.value.altTitles ?? []) }
                
                for titles in mediaInstances {
                    for title in titles {
                        if title.uppercased().contains(listQuery.uppercased()) {
                            return false
                        }
                    }
                }
                
                return true
            }
        }
        
        return result
    }

    var body: some View {
        GeometryReader { geo in
            NavigationStack(path: $navigationPath) {
                VStack(alignment: .leading, spacing: 0) {
//                    Text(String(describing: type(of: T.AssociatedMediaType.self)).replacingOccurrences(of: ".Type", with: "") + " list")
//                        .font(.title.bold())
//                        .padding()
//                    Divider()
//                        .padding(.horizontal)
                    
                    HStack {
                        Picker("Sorted by", selection: $selectedSortingStyle) {
                            ForEach(["Recently updated", "Recently added", "By title"], id: \.self) {
                                Text($0)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 500)
                        
                        Spacer()
                        
                        Button {
                            showingFilterPopover.toggle()
                        } label: {
                            HStack {
                                Text("Advanced filters")
                                    .font(.headline)
                                
                                Image(systemName: "chevron.down")
                            }
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showingFilterPopover) {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Filter options")
                                    .font(.title2.bold())
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Grouping and sorting")
                                        .font(.headline)
                                    
                                    Picker("Sorted by", selection: $selectedSortingStyle) {
                                        ForEach(["Recently updated", "Recently added", "By title"], id: \.self) {
                                            Text($0)
                                        }
                                    }
                                    .pickerStyle(.radioGroup)
                                }
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Filters")
                                        .font(.headline)
                                    
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("Status")
                                            
                                            Toggle("Waiting", isOn: $showingWaiting)
                                            Toggle("Viewing", isOn: $showingViewing)
                                            Toggle("Dropped", isOn: $showingDropped)
                                            Toggle("Completed", isOn: $showingCompleted)
                                            Toggle("To view", isOn: $showingToView)
                                        }
                                        
                                        VStack(alignment: .leading) {
                                            Text("Rating")
                                            
                                            Toggle("None", isOn: $showingRatingNone)
                                            Toggle("Horrible", isOn: $showingRatingHorrible)
                                            Toggle("Bad", isOn: $showingRatingBad)
                                            Toggle("Good", isOn: $showingRatingGood)
                                            Toggle("Best", isOn: $showingRatingBest)
                                        }
                                    }
                                }
                            }
                            .padding(40)
                        }
                    }
                    .padding()
                    
                    HStack {
                        Text("Title")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Last segment")
                            .frame(width: geo.size.width * 0.25, alignment: .leading)
                        Text("Status")
                            .frame(width: 150, alignment: .leading)
                        Text("Rating")
                            .frame(width: 70, alignment: .leading)
                    }
                    .font(.headline)
                    .padding()
                    .padding(.horizontal)
                    
                    Divider()
                    
                    VStack {
                        List(filteredList) { mediaListElement in
                            NavigationLink(value: mediaListElement) {
                                MediaListRowView(media: mediaListElement, geo: geo)
                            }
                            .buttonStyle(.plain)
                        }
                        .navigationDestination(for: T.self) { mediaListElement in
                            MediaListDetailsView(passedMedia: mediaListElement, sources: $sources)
                        }
                        .navigationDestination(for: T.AssociatedMediaType.self) { media in
                            if let anime = media as? Anime {
                                AnimeDetailsView(anime: anime)
                            } else if let manga = media as? Manga {
                                MangaDetailsView(manga: manga)
                            } else if let novel = media as? Novel {
                                NovelDetailsView(novel: novel)
                            }
                        }
                        .searchable(text: $listQuery)
                    }
                    .sheet(isPresented: $showingAddNewMediaSheet) {
                        MediaListAddNewToListView<T>(sources: $sources)
                            .frame(width: 500, height: 300)
                    }
                }
                .frame(width: geo.size.width)
            }
        }
        .toolbar {
            ToolbarItem {
                Button {
                    showingAddNewMediaSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

struct MediaListRowView<T: MediaListElement>: View {
    var media: T
    let geo: GeometryProxy
    
    var body: some View {
        HStack {
            Text(media.content.first?.value.title ?? "No title")
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)
            Text(media.lastSegment ?? "No last segment")
                .frame(width: geo.size.width * 0.25, alignment: .leading)
                .lineLimit(2)
            Text(media.status.rawValue)
                .foregroundColor(.white)
                .padding(3)
                .padding(.horizontal, 3)
                .background {
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundColor(media.status.getStatusColor())
                }
                .frame(width: 150, alignment: .leading)
            Text(media.rating.rawValue)
                .frame(width: 70, alignment: .leading)
                .foregroundColor(media.rating == .best ? .purple : .primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 5)
                .foregroundColor(Color(nsColor: NSColor.textBackgroundColor))
                .shadow(radius: 2)
                .padding(.horizontal, 5)
        }
    }
}

struct MediaListDetailsView<T: MediaListElement>: View {
    @EnvironmentObject var mediaVM: MediaVM<T.AssociatedMediaType>
    @EnvironmentObject var mediaListVM: MediaListVM<T>
    
    @State var passedMedia: T

    @Environment(\.dismiss) var dismiss

    @Binding var sources: [String: any MediaSource]

    var body: some View {
        VStack {
            Text(passedMedia.content.first?.value.title ?? "None")
                .font(.title2.bold())
            
            TabView {
                MediaListDetailsMediaDetailsView(passedMedia: passedMedia, sources: $sources)
                    .tabItem {
                        Text("Media details")
                    }
                
                MediaListDetailsListDetailsView(passedMedia: passedMedia, dismissOnDelete: true, sources: $sources)
                    .padding()
                    .tabItem {
                        Text("List details")
                    }
            }
            
            HStack {
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
            }
        }
        .padding()
    }
}

struct MediaListDetailsMediaDetailsView<T: MediaListElement>: View {
    @EnvironmentObject var mediaVM: MediaVM<T.AssociatedMediaType>
    @EnvironmentObject var mediaListVM: MediaListVM<T>
    
    @State var passedMedia: T
    
    @Environment(\.dismiss) var dismiss

    @State private var mediaKeysArray: [String] = []
    
    @State private var showingDeleteSourceAlert = false
    @State private var deleteSourceAlertSource: String? = nil
    
    @Binding var sources: [String: any MediaSource]

    var body: some View {
        ScrollView {
            ForEach(mediaKeysArray, id: \.self) { key in
                if let media = passedMedia.content[key] {
                    VStack(alignment: .leading) {
                        Text(sources[key]?.label ?? key)
                            .font(.title3.bold())
                        
                        HStack(spacing: 5) {
                            StyledImage(imageUrl: media.imageUrl)
                                .frame(width: 250)
                            
                            Spacer()
                            Form {
                                if let title = media.title {
                                    HStack(alignment: .top) {
                                        Text("Title")
                                        
                                        Spacer()
                                        Text(title)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.trailing)
                                    }
                                }
                                
                                if let tags = media.tags {
                                    HStack(alignment: .top) {
                                        Text("Tags")
                                        
                                        Spacer()
                                        Text(tags.map { $0.name }.joined(separator: ", "))
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.trailing)
                                    }
                                }
                                
                                if let altTitles = media.altTitles?.joined(separator: ", ") {
                                    HStack(alignment: .top) {
                                        Text("Alternative titles")
                                        
                                        Spacer()
                                        Text(altTitles)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.trailing)
                                    }
                                }
                                
                                if let authors = media.authors?.joined(separator: ", ") {
                                    HStack(alignment: .top) {
                                        Text("Authors")
                                        
                                        Spacer()
                                        Text(authors)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.trailing)
                                    }
                                }
                                
                                if let detailsUrl = media.detailsUrl {
                                    HStack(alignment: .top) {
                                        Text("Source")
                                        
                                        Spacer()
                                        Link(destination: detailsUrl) {
                                            Text(detailsUrl.absoluteString)
                                                .multilineTextAlignment(.trailing)
                                        }
                                    }
                                }
                                
                                if let description = media.description {
                                    Text(description)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .scrollContentBackground(.hidden)
                            .formStyle(.grouped)
                            .padding(-20)
                        }
                        .frame(maxWidth: .infinity)
                        
                        HStack {
                            Spacer()
                            
                            NavigationLink("Open", value: media)
                            
                            Button {
                                if let currentIndex = mediaKeysArray.firstIndex(of: key) {
                                    withAnimation {
                                        mediaKeysArray.rearrange(fromIndex: currentIndex, toIndex: currentIndex - 1)
                                    }
                                }
                            } label: {
                                Image(systemName: "arrow.up")
                            }
                            .disabled((mediaKeysArray.firstIndex(of: key) ?? 0) - 1 < 0)
                            
                            Button {
                                if let currentIndex = mediaKeysArray.firstIndex(of: key) {
                                    withAnimation {
                                        mediaKeysArray.rearrange(fromIndex: currentIndex, toIndex: currentIndex + 1)
                                    }
                                }
                            } label: {
                                Image(systemName: "arrow.down")
                            }
                            .disabled(mediaKeysArray.firstIndex(of: key) ?? mediaKeysArray.count >= mediaKeysArray.count - 1)
                            
                            Button {
                                showingDeleteSourceAlert = true
                                deleteSourceAlertSource = key
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .alert(
                                "Warning",
                                isPresented: $showingDeleteSourceAlert,
                                presenting: deleteSourceAlertSource
                            ) { source in
                                Button("Cancel", role: .cancel) { }
                                Button("Delete", role: .destructive) {
                                    withAnimation {
                                        mediaListVM.removeSourceFromList(id: passedMedia.id, source: source)
                                        passedMedia.content.removeValue(forKey: source)
                                        
                                        if !mediaListVM.list.contains(where: { $0.id == passedMedia.id }) {
                                            dismiss()
                                        }
                                    }
                                }
                            } message: { _ in
                                Text("Are you sure you want to delete this element from your list? This action is irreversible.")
                            }
                        }
                        
                        Divider()
                    }
                    .padding()
                }
            }
            .onAppear {
                mediaKeysArray = Array(passedMedia.content.keys)
                
                Task { @MainActor in
                    passedMedia.content = await mediaVM.getAllUpdatedMediaDetails(for: passedMedia.content)
                }
                
            }
        }
    }
}

struct MediaListDetailsListDetailsView<T: MediaListElement>: View {
    @EnvironmentObject var mediaVM: MediaVM<T.AssociatedMediaType>
    @EnvironmentObject var mediaListVM: MediaListVM<T>
    
    @Environment(\.dismiss) var dismiss
    
    let passedMedia: T
    
    let dismissOnDelete: Bool
    
    @State private var selectedSource: String = ""
    @State private var selectedLastEpisode: String = ""
    @State private var selectedRating: String = ""
    @State private var selectedStatus: String = ""
    
    @State private var showingDeleteAlert = false
    
    @State private var showingLastEpisodeSelection = false
    @State private var selectedLastReadDate: Date = Date.now
    
    @Binding var sources: [String: any MediaSource]

    var body: some View {
        Form {
            Section {
                Picker("Media status", selection: $selectedStatus) {
                    ForEach(Status.allCases, id: \.rawValue) { status in
                        Text(status.rawValue)
                            .tag(status.rawValue)
                    }
                }
                .onChange(of: selectedStatus) { newStatus in
                    mediaListVM.updateStatus(
                        id: passedMedia.id,
                        to: Status(rawValue: newStatus) ?? passedMedia.status
                    )
                }
                
                Picker("Media rating", selection: $selectedRating) {
                    ForEach(Rating.allCases, id: \.rawValue) { rating in
                        Text(rating.rawValue)
                            .tag(rating.rawValue)
                    }
                }
                .onChange(of: selectedRating) { newRating in
                    mediaListVM.updateRating(
                        id: passedMedia.id,
                        to: Rating(rawValue: newRating) ?? passedMedia.rating
                    )
                }
            }
            
            Section {
                Picker(selection: $selectedSource) {
                    ForEach(Array(passedMedia.content.keys), id: \.self) { key in
                        Text(sources[key]?.label ?? key)
                            .tag(key)
                    }
                } label: {
                    Text("Last segment source")
                    Text("Source of the segment you want to choose in the next picker.")
                        .foregroundColor(.secondary)
                }
                
                Picker("New last segment", selection: $selectedLastEpisode) {
                    ForEach(passedMedia.content[selectedSource]?.segments ?? [], id: \.id) { episode in
                        Text(episode.title)
                            .tag(episode.title)
                    }
                }
                .disabled(!passedMedia.content.keys.contains(selectedSource))
                .onChange(of: selectedLastEpisode) { newEpisode in
                    mediaListVM.updateLastSegment(
                        id: passedMedia.id,
                        to: newEpisode
                    )
                }
                
                HStack {
                    Text("Current last segment")
                    
                    Spacer()
                    Text(passedMedia.lastSegment ?? "None")
                }
            }
            
            Section {
                if showingLastEpisodeSelection {
                    DatePicker("Last watched date", selection: $selectedLastReadDate, displayedComponents: .date)
                        .onChange(of: selectedLastReadDate) { newDate in
                            mediaListVM.updateLastViewedDate(id: passedMedia.id, to: newDate)
                        }
                }
                
                HStack {
                    Text(showingLastEpisodeSelection ? "Reset last viewed date" : "Add last viewed date")
                    
                    Spacer()
                    Button(showingLastEpisodeSelection ? "Remove" : "Add") {
                        showingLastEpisodeSelection.toggle()
                    }
                    .onAppear {
                        showingLastEpisodeSelection = passedMedia.lastViewedDate != nil
                        selectedLastReadDate = passedMedia.lastViewedDate ?? selectedLastReadDate
                    }
                    .onChange(of: showingLastEpisodeSelection) { showingLastEpisode in
                        if !showingLastEpisode {
                            mediaListVM.updateLastViewedDate(id: passedMedia.id, to: nil)
                        }
                    }
                    .foregroundColor(.red)
                }
                
                HStack {
                    Text("Creation date")
                    
                    Spacer()
                    Text(passedMedia.creationDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.body)
                }
            }
            
            Section {
                HStack {
                    Text("Remove from list")
                    
                    Spacer()
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Text("Delete")
                            .foregroundColor(.red)
                    }
                    .alert("Warning", isPresented: $showingDeleteAlert) {
                        Button("Cancel", role: .cancel) { }
                        Button("Delete", role: .destructive) {
                            if let listElementIndex = mediaListVM.list.firstIndex(where: { $0.id == passedMedia.id }) {
                                mediaListVM.list.remove(at: listElementIndex)
                                
                                if dismissOnDelete {
                                    dismiss()
                                }
                            }
                        }
                    } message: {
                        Text("Are you sure you want to delete this element from your list? This action is irreversible.")
                    }
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .padding(-20)
        .onAppear {
            selectedRating = passedMedia.rating.rawValue
            selectedStatus = passedMedia.status.rawValue
        }
    }
}

struct MediaListAddNewToListView<T: MediaListElement>: View {
    @EnvironmentObject var mediaVM: MediaVM<T.AssociatedMediaType>
    @EnvironmentObject var mediaListVM: MediaListVM<T>
    
    @Environment(\.dismiss) var dismiss
    
    @State var storyTitle: String = ""
    @State var lastSegmentTitle: String = ""
    @State var selectedStatus: Status = .viewing
    @State var selectedRating: Rating = .none
    
    @State var mediaListNewImageUrl = ""
    @State var mediaListNewAuthor = ""
        
    @State var mediaElements: [(source: String, media: T.AssociatedMediaType)] = []
    @State var selectedMediaIndex: Set<Int> = Set()
    @State var searchState: LoadingState? = nil
    
    @State var selectedTab = 0
    
    @State var showingAddToListAlert = false
    
    @Binding var sources: [String: any MediaSource]

    var body: some View {
        VStack {
            Text("Add new media")
                .font(.title3.bold())
            
            TabView(selection: $selectedTab) {
                VStack {
                    Text("The Title field is used for autofill in the next step. It can be left blank if you do not want to use autofill.")
                        .fixedSize(horizontal: false, vertical: true)

                    TextField("Title", text: $storyTitle)
                    TextField("Last episode title", text: $lastSegmentTitle)
                    
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
                    }
                }
                .padding()
                .tabItem {
                    Text("Media list info")
                }
                .tag(0)
                .transition(.slide)
                
                VStack(alignment: .leading) {
                    NavigationView {
                        List(0..<mediaElements.count, id: \.self, selection: $selectedMediaIndex) { index in
                            let hasDuplicate = Array<String>(Set<String>(mediaElements.map { $0.source })).sorted() == mediaElements.map { $0.source }.sorted()
                            
                            NavigationLink {
                                if index >= 0 && mediaElements.count > index {
                                    MediaListMediaDetailsEditorView<T>(
                                        mediaElement: $mediaElements[index],
                                        storyTitle: $storyTitle,
                                        lastSegmentTitle: $lastSegmentTitle,
                                        selectedStatus: $selectedStatus,
                                        selectedRating: $selectedRating,
                                        mediaListNewImageUrl: $mediaListNewImageUrl,
                                        mediaListNewAuthor: $mediaListNewAuthor)
                                }
                            } label: {
                                Text(mediaElements[index].source)
                                    .foregroundColor(hasDuplicate ? .primary : .red)
                            }
                            .help(hasDuplicate ? "" : "There is another media with the same source key.")
                        }
                        .listStyle(.bordered)
                    }
                    
                    HStack {
                        ControlGroup {
                            Button {
                                mediaElements.remove(at: selectedMediaIndex.first!)
                            } label: {
                                Image(systemName: "minus")
                            }

                            Menu {
                                Button("Create manually") {
                                    mediaElements.append((source: "manual", media: T.AssociatedMediaType(title: storyTitle, authors: [])))
                                }

                                Menu("Search in source") {
                                    ForEach(Array(sources.values), id: \.sourceId) { source in
                                        Button(source.label) {
                                            searchAndGetMedia(source: source)
                                        }
                                    }
                                }
                                .disabled(storyTitle.isEmpty)
                            } label: {
                                Image(systemName: "plus")
                            }
                        }
                        .frame(width: 50)
                        
                        if let searchState = searchState {
                            switch searchState {
                            case .loading:
                                ProgressView()
                            case .success:
                                Circle()
                                    .fill(.green)
                                    .frame(width: 5, height: 5)
                                Text("Successfully fetched and added!")
                            case .failed:
                                Circle()
                                    .fill(.red)
                                    .frame(width: 5, height: 5)
                                Text("Fetching failed!")
                            }
                        }
                    }
                }
                .padding()
                .tabItem {
                    Text("Media info")
                }
                .tag(1)
                .transition(.slide)
            }
            .onChange(of: selectedTab) { _ in
                if selectedTab == 1 && mediaElements.isEmpty && !storyTitle.isEmpty {
                    mediaElements.append((source: "manual", media: T.AssociatedMediaType(title: storyTitle)))
                }
            }
            
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                
                Button(selectedTab == 1 ? "Add to list" : "Next") {
                    if selectedTab == 1 {
                        let medias: [String: T.AssociatedMediaType] = mediaElements.reduce(into: [String: T.AssociatedMediaType]()) {
                            $0[$1.source] = $1.media
                        }
                        
                        mediaListVM.addToList(
                            medias: medias,
                            lastSegment: lastSegmentTitle,
                            status: selectedStatus,
                            rating: selectedRating,
                            lastViewedDate: Date.now
                        )
                        
                        dismiss()
                    } else {
                        withAnimation {
                            selectedTab = 1
                        }
                    }
                }
                .disabled(selectedTab == 1 ? storyTitle.isEmpty && mediaElements.isEmpty : false)
            }
        }
        .padding()
    }
    
    private func searchAndGetMedia(source: any MediaSource) {
        Task { @MainActor in
            searchState = .loading
            
            if let initialMedia = await source.getSearchMedia(pageNumber: 1, searchQuery: storyTitle).first {
                if let result = await mediaVM.getMediaDetails(for: initialMedia as! T.AssociatedMediaType, source: source.sourceId) {
                    mediaElements.append((source: source.sourceId, media: result))
                    searchState = .success
                } else {
                    searchState = .failed
                }
            } else {
                searchState = .failed
            }
        }
    }
}

struct MediaListMediaDetailsEditorView<T: MediaListElement>: View {
    @Binding var mediaElement: (source: String, media: T.AssociatedMediaType)
    
    @Binding var storyTitle: String
    @Binding var lastSegmentTitle: String
    @Binding var selectedStatus: Status
    @Binding var selectedRating: Rating
    
    @Binding var mediaListNewImageUrl: String
    @Binding var mediaListNewAuthor: String
        
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                TextField("Source", text: $mediaElement.source)
                    .padding(.bottom, 20)
                
                Text("Media details")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .font(.headline)
                
                TextField("Title", text: $mediaElement.media.title ?? "No title")
                TextField("Description", text: $mediaElement.media.description ?? "")
                TextField("Image URL", text: $mediaListNewImageUrl)
                    .onChange(of: mediaListNewImageUrl) { _ in
                        if let url = URL(string: mediaListNewImageUrl) {
                            mediaElement.media.imageUrl = url
                        }
                    }
                
                Text("Authors")
                ScrollView {
                    ForEach((mediaElement.media.authors ?? []).indices, id: \.self) { authorIndex in
                        let authorsBinding: Binding<[String]> = Binding(get: { mediaElement.media.authors ?? [] }, set: { mediaElement.media.authors = $0 })
                        
                        TextField("Author", text: authorsBinding[authorIndex])
                    }
                    
                    TextField("Add new author", text: $mediaListNewAuthor)
                        .onSubmit {
                            mediaElement.media.authors?.append(mediaListNewAuthor)
                            mediaListNewAuthor = ""
                        }
                }
            }
            .padding()
        }
    }
}
