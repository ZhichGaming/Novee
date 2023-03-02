//
//  AnimeListView.swift
//  Novee
//
//  Created by Nick on 2023-02-18.
//

import SwiftUI
import CachedAsyncImage

struct AnimeListView: View {
    @EnvironmentObject var animeListVM: AnimeListVM
    @EnvironmentObject var animeVM: AnimeVM
    
    @State private var listQuery = ""
    @State private var showingSearchDetailsSheet = false
    @State private var showingAddNewAnimeSheet = false
    @State private var selectedSortingStyle = "Recently updated"
    @State private var animeDetailsSheet: AnimeListElement?
    
    @State private var showingWaiting = true
    @State private var showingWatching = true
    @State private var showingDropped = true
    @State private var showingCompleted = true
    @State private var showingToWatch = true
    
    @State private var showingRatingNone = true
    @State private var showingRatingHorrible = true
    @State private var showingRatingBad = true
    @State private var showingRatingGood = true
    @State private var showingRatingBest = true
    
    @State private var navigationPath = NavigationPath()
    
    var filteredList: [AnimeListElement] {
        var result = animeListVM.list
        
        if !showingWaiting { result.removeAll { $0.status == .waiting } }
        if !showingWatching { result.removeAll { $0.status == .watching } }
        if !showingDropped { result.removeAll { $0.status == .dropped } }
        if !showingCompleted { result.removeAll { $0.status == .completed } }
        if !showingToWatch { result.removeAll { $0.status == .toWatch } }
        
        if !showingRatingNone { result.removeAll { $0.rating == .none } }
        if !showingRatingHorrible { result.removeAll { $0.rating == .horrible } }
        if !showingRatingBad { result.removeAll { $0.rating == .bad } }
        if !showingRatingGood { result.removeAll { $0.rating == .good } }
        if !showingRatingBest { result.removeAll { $0.rating == .best } }
        
        if selectedSortingStyle == "Recently updated" {
            result.sort {
                return $0.lastWatchDate ?? Date.distantPast > $1.lastWatchDate ?? Date.distantPast
            }
        } else if selectedSortingStyle == "Recently added" {
            result.sort { $0.creationDate.compare($1.creationDate) == .orderedDescending }
        } else {
            result.sort {
                return $0.anime.first?.value.title ?? "" < $1.anime.first?.value.title ?? ""
            }
        }
        
        if !listQuery.isEmpty {
            result.removeAll { anime in
                let animeInstances = anime.anime.map { [$0.value.title ?? ""] + ($0.value.altTitles ?? []) }
                
                for titles in animeInstances {
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
                VStack(spacing: 0) {
                    HStack {
                        TextField("Search for anime", text: $listQuery)
                            .textFieldStyle(.roundedBorder)
                        
                        Button {
                            showingSearchDetailsSheet = true
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        
                        Button {
                            showingAddNewAnimeSheet = true
                        } label: {
                            Image(systemName: "plus.circle")
                        }
                    }
                    .padding()
                    .sheet(isPresented: $showingSearchDetailsSheet) {
                        VStack {
                            Text("Filter options")
                                .font(.title2.bold())
                                .padding(.top)
                            
                            TabView {
                                VStack {
                                    HStack {
                                        Picker("Sorting style", selection: $selectedSortingStyle) {
                                            ForEach(["Recently updated", "Recently added", "By title"], id: \.self) {
                                                Text($0)
                                            }
                                        }
                                        .pickerStyle(.radioGroup)
                                    }
                                    .padding(.horizontal)
                                    
                                }
                                .tabItem {
                                    Text("Grouping and sorting")
                                }
                                
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Showing status")
                                            .font(.headline)
                                        
                                        Toggle("Waiting", isOn: $showingWaiting)
                                        Toggle("Watching", isOn: $showingWatching)
                                        Toggle("Dropped", isOn: $showingDropped)
                                        Toggle("Completed", isOn: $showingCompleted)
                                        Toggle("To watch", isOn: $showingToWatch)
                                    }
                                    .padding(.trailing)
                                    
                                    VStack(alignment: .leading) {
                                        Text("Showing rating")
                                            .font(.headline)
                                        
                                        Toggle("None", isOn: $showingRatingNone)
                                        Toggle("Horrible", isOn: $showingRatingHorrible)
                                        Toggle("Bad", isOn: $showingRatingBad)
                                        Toggle("Good", isOn: $showingRatingGood)
                                        Toggle("Best", isOn: $showingRatingBest)
                                    }
                                    .padding(.leading)
                                }
                                .padding()
                                .tabItem {
                                    Text("Filters")
                                }
                            }
                            .padding()
                            
                            HStack {
                                Spacer()
                                Button("Done") {
                                    showingSearchDetailsSheet = false
                                }
                            }
                            .padding([.bottom, .horizontal])
                        }
                        .frame(width: 500, height: 350)
                    }
                    
                    HStack {
                        Text("Title")
                            .frame(width: geo.size.width * 0.3, alignment: .leading)
                        Text("Last episode")
                            .frame(width: geo.size.width * 0.2, alignment: .leading)
                        Text("Status")
                            .frame(width: geo.size.width * 0.2, alignment: .leading)
                        Text("Rating")
                            .frame(width: geo.size.width * 0.2, alignment: .leading)
                    }
                    .font(.headline)
                    .padding()
                    .padding(.horizontal)
                    
                    Divider()
                    ScrollView {
                        LazyVStack {
                            ForEach(filteredList) { animeListElement in
                                NavigationLink(value: animeListElement) {
                                    AnimeListRowView(anime: animeListElement, geo: geo)
                                }
                                .buttonStyle(.plain)
                            }
                            .navigationDestination(for: AnimeListElement.self) { animeListElement in
                                AnimeListDetailsSheetView(passedAnime: animeListElement)
                            }
                            .navigationDestination(for: Anime.self) { anime in
                                AnimeDetailsView(selectedAnime: anime)
                            }
                        }
                        .padding()
                    }
                    .sheet(isPresented: $showingAddNewAnimeSheet) {
                        AnimeListAddNewToListView()
                            .frame(width: 500, height: 300)
                    }
                }
                .frame(width: geo.size.width)
            }
        }
    }
}

struct AnimeListRowView: View {
    var anime: AnimeListElement
    let geo: GeometryProxy
    
    var body: some View {
        HStack {
            Text(anime.anime.first?.value.title ?? "No title")
                .frame(width: geo.size.width * 0.3, alignment: .leading)
                .lineLimit(2)
            Text(anime.lastEpisode ?? "No last episode")
                .frame(width: geo.size.width * 0.2, alignment: .leading)
                .lineLimit(2)
            Text(anime.status.rawValue)
                .foregroundColor(.white)
                .padding(3)
                .padding(.horizontal, 3)
                .background {
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundColor(anime.status.getStatusColor())
                }
                .frame(width: geo.size.width * 0.2, alignment: .leading)
            Text(anime.rating.rawValue)
                .frame(width: geo.size.width * 0.2, alignment: .leading)
                .foregroundColor(anime.rating == .best ? .purple : .primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 5)
                .foregroundColor(Color(nsColor: NSColor.textBackgroundColor))
                .shadow(radius: 2)
        }
    }
}

struct AnimeListDetailsSheetView: View {
    @EnvironmentObject var animeVM: AnimeVM
    @EnvironmentObject var animeListVM: AnimeListVM
    
    @State var passedAnime: AnimeListElement

    @Environment(\.dismiss) var dismiss
    
    @State private var animeKeysArray: [String] = []
    
    @State private var selectedSource: String = ""
    @State private var selectedLastEpisode: String = ""
    @State private var selectedAnimeRating: String = ""
    @State private var selectedAnimeStatus: String = ""
    
    @State private var showingDeleteAlert = false
    @State private var showingDeleteSourceAlert = false
    @State private var deleteSourceAlertSource: String? = nil
    @State private var showingLastEpisodeSelection = false
    @State private var selectedLastReadDate: Date = Date.now

    var body: some View {
        VStack {
            Text(passedAnime.anime.first?.value.title ?? "None")
                .font(.title2.bold())
            
            TabView {
                ScrollView {
                    ForEach(animeKeysArray, id: \.self) { key in
                        if let anime = passedAnime.anime[key] {
                            Text(animeVM.sources[key]?.label ?? key)
                                .font(.title2.bold())
                                .padding(.top)
                            
                            HStack {
                                VStack {
                                    if let url = anime.imageUrl {
                                        CachedAsyncImage(url: url) { image in
                                            image
                                                .resizable()
                                                .scaledToFit()
                                        } placeholder: {
                                            ProgressView()
                                        }
                                    }
                                    
                                    Text(anime.title ?? "No title")
                                        .font(.headline)
                                }
                                .frame(width: 200)
                                .padding(.trailing)
                                
                                List {
                                    if let description = anime.description {
                                        Text("Description")
                                            .font(.headline)
                                        Text(description)
                                        Spacer()
                                    }
                                    
                                    if let tags = anime.tags {
                                        Text("Tags")
                                            .font(.headline)
                                        Text(tags.map { $0.name }.joined(separator: ", "))
                                        Spacer()
                                    }
                                    
                                    if let altTitles = anime.altTitles?.joined(separator: ", ") {
                                        Text("Alternative titles")
                                            .font(.headline)
                                        Text(altTitles)
                                        Spacer()
                                    }
                                    
                                    if let authors = anime.authors?.joined(separator: ", ") {
                                        Text("Authors")
                                            .font(.headline)
                                        Text(authors)
                                        Spacer()
                                    }
                                    
                                    if let detailsUrl = anime.detailsUrl {
                                        Link("URL source", destination: detailsUrl)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 200)
                            .padding()
                            
                            Spacer()
                            HStack {
                                Spacer()
                                
                                NavigationLink("Open", value: anime)
                                
                                Button {
                                    if let currentIndex = animeKeysArray.firstIndex(of: key) {
                                        withAnimation {
                                            animeKeysArray.rearrange(fromIndex: currentIndex, toIndex: currentIndex - 1)
                                        }
                                    }
                                } label: {
                                    Image(systemName: "arrow.up")
                                }
                                .disabled((animeKeysArray.firstIndex(of: key) ?? 0) - 1 < 0)
                                
                                Button {
                                    if let currentIndex = animeKeysArray.firstIndex(of: key) {
                                        withAnimation {
                                            animeKeysArray.rearrange(fromIndex: currentIndex, toIndex: currentIndex + 1)
                                        }
                                    }
                                } label: {
                                    Image(systemName: "arrow.down")
                                }
                                .disabled(animeKeysArray.firstIndex(of: key) ?? animeKeysArray.count >= animeKeysArray.count - 1)

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
                                            animeListVM.removeSourceFromList(id: passedAnime.id, source: source)
                                            passedAnime.anime.removeValue(forKey: source)
                                            
                                            if !animeListVM.list.contains(where: { $0.id == passedAnime.id }) {
                                                dismiss()
                                            }
                                        }
                                    }
                                } message: { _ in
                                    Text("Are you sure you want to delete this element from your list? This action is irreversible.")
                                }
                            }
                            .padding(.horizontal)
                            
                            Divider()
                                .padding(.horizontal)
                        }
                    }
                    .onAppear {
                        animeKeysArray = Array(passedAnime.anime.keys)
                    }
                }
                .tabItem {
                    Text("Anime details")
                }
                
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        Text("Anime status/rating")
                            .font(.headline)
                        
                        Picker("Anime status", selection: $selectedAnimeStatus) {
                            ForEach(AnimeStatus.allCases, id: \.rawValue) { status in
                                Text(status.rawValue)
                                    .tag(status.rawValue)
                            }
                        }
                        .onChange(of: selectedAnimeStatus) { newStatus in
                            animeListVM.updateStatus(
                                id: passedAnime.id,
                                to: AnimeStatus(rawValue: newStatus) ?? passedAnime.status
                            )
                        }
                        
                        Picker("Anime rating", selection: $selectedAnimeRating) {
                            ForEach(AnimeRating.allCases, id: \.rawValue) { rating in
                                Text(rating.rawValue)
                                    .tag(rating.rawValue)
                            }
                        }
                        .onChange(of: selectedAnimeRating) { newRating in
                            animeListVM.updateRating(
                                id: passedAnime.id,
                                to: AnimeRating(rawValue: newRating) ?? passedAnime.rating
                            )
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Last watched episode")
                            .font(.headline)
                        
                        Picker("Episode source", selection: $selectedSource) {
                            ForEach(Array(passedAnime.anime.keys), id: \.self) { key in
                                Text(animeVM.sources[key]?.label ?? key)
                                    .tag(key)
                            }
                        }
                        
                        Picker("Last episode", selection: $selectedLastEpisode) {
                            ForEach(passedAnime.anime[selectedSource]?.episodes ?? [], id: \.id) { episode in
                                Text(episode.title)
                                    .tag(episode.title)
                            }
                        }
                        .disabled(!passedAnime.anime.keys.contains(selectedSource))
                        .onChange(of: selectedLastEpisode) { newEpisode in
                            animeListVM.updateLastEpisode(
                                id: passedAnime.id,
                                to: newEpisode
                            )
                        }
                        
                        HStack {
                            Text("Current last episode:")
                            Text(passedAnime.lastEpisode ?? "None")
                        }
                    }
                    .padding(.vertical)

                    VStack(alignment: .leading) {
                        Text("Dates")
                            .font(.headline)
                        
                        HStack {
                            if showingLastEpisodeSelection {
                                DatePicker(
                                    "Last watched date:",
                                    selection: $selectedLastReadDate,
                                    displayedComponents: .date
                                )
                                .onChange(of: selectedLastReadDate) { newDate in
                                    animeListVM.updateLastReadDate(id: passedAnime.id, to: newDate)
                                }
                            }
                            
                            Button(showingLastEpisodeSelection ? "Remove last watched date" : "Add last watched date") {
                                showingLastEpisodeSelection.toggle()
                            }
                            .onAppear {
                                showingLastEpisodeSelection = passedAnime.lastWatchDate != nil
                                selectedLastReadDate = passedAnime.lastWatchDate ?? selectedLastReadDate
                            }
                            .onChange(of: showingLastEpisodeSelection) { showingLastEpisode in
                                if !showingLastEpisode {
                                    animeListVM.updateLastReadDate(id: passedAnime.id, to: nil)
                                }
                            }
                        }
                        .padding(.vertical, 3)

                        HStack {
                            Text("Creation date:")
                            Text(passedAnime.creationDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.body)
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Destructive")
                            .font(.headline)
                            .padding(.top)
                        
                        HStack {
                            Button("Remove from list", role: .destructive) {
                                showingDeleteAlert = true
                            }
                            .foregroundColor(.red)
                            .alert("Warning", isPresented: $showingDeleteAlert) {
                                Button("Cancel", role: .cancel) { }
                                Button("Delete", role: .destructive) {
                                    if let listElementIndex = animeListVM.list.firstIndex(where: { $0.id == passedAnime.id }) {
                                        animeListVM.list.remove(at: listElementIndex)
                                        dismiss()
                                    }
                                }
                            } message: {
                                Text("Are you sure you want to delete this element from your list? This action is irreversible.")
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .tabItem {
                    Text("List details")
                }
                .onAppear {
                    selectedAnimeRating = passedAnime.rating.rawValue
                    selectedAnimeStatus = passedAnime.status.rawValue
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

struct AnimeListAddNewToListView: View {
    @EnvironmentObject var animeVM: AnimeVM
    @EnvironmentObject var animeListVM: AnimeListVM
    
    @Environment(\.dismiss) var dismiss
    
    @State var storyTitle: String = ""
    @State var lastEpisodeTitle: String = ""
    @State var selectedAnimeStatus: AnimeStatus = .watching
    @State var selectedAnimeRating: AnimeRating = .none
    
    @State var animeListNewImageUrl = ""
    @State var animeListNewAuthor = ""
        
    @State var animeElements: [AnimeWithSource] = []
    @State var selectedAnimeIndex: Set<Int> = Set()
    @State var searchState: LoadingState? = nil
    
    @State var selectedTab = 0
    
    @State var showingAddToListAlert = false
    
    var body: some View {
        VStack {
            Text("Add new anime")
                .font(.title3.bold())
            
            TabView(selection: $selectedTab) {
                VStack {
                    Text("The Title field is used for autofill in the next step. It can be left blank if you do not want to use autofill.")
                        .fixedSize(horizontal: false, vertical: true)

                    TextField("Title", text: $storyTitle)
                    TextField("Last episode title", text: $lastEpisodeTitle)
                    
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
                    }
                }
                .padding()
                .tabItem {
                    Text("Anime list info")
                }
                .tag(0)
                .transition(.slide)
                
                VStack(alignment: .leading) {
                    NavigationView {
                        List(0..<animeElements.count, id: \.self, selection: $selectedAnimeIndex) { index in
                            let hasDuplicate = Array<String>(Set<String>(animeElements.map { $0.source })).sorted() == animeElements.map { $0.source }.sorted()
                            
                            NavigationLink {
                                if index >= 0 && animeElements.count > index {
                                    AnimeListAnimeDetailsEditorView(
                                        animeElement: $animeElements[index],
                                        storyTitle: $storyTitle,
                                        lastEpisodeTitle: $lastEpisodeTitle,
                                        selectedAnimeStatus: $selectedAnimeStatus,
                                        selectedAnimeRating: $selectedAnimeRating,
                                        animeListNewImageUrl: $animeListNewImageUrl,
                                        animeListNewAuthor: $animeListNewAuthor)
                                }
                            } label: {
                                Text(animeElements[index].source)
                                    .foregroundColor(hasDuplicate ? .primary : .red)
                            }
                            .help(hasDuplicate ? "" : "There is another anime with the same source key.")
                        }
                        .listStyle(.bordered)
                    }
                    
                    HStack {
                        ControlGroup {
                            Button {
                                animeElements.remove(at: selectedAnimeIndex.first!)
                            } label: {
                                Image(systemName: "minus")
                            }
                            
                            Menu {
                                Button("Create manually") {
                                    animeElements.append(AnimeWithSource(source: "manual", anime: Anime(title: storyTitle, authors: [])))
                                }
                                
                                Menu("Search in source") {
                                    ForEach(animeVM.sourcesArray, id: \.sourceId) { source in
                                        Button(source.label) {
                                            searchAndGetAnime(source: source)
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
                            case .notFound:
                                EmptyView()
                            }
                        }
                    }
                }
                .padding()
                .tabItem {
                    Text("Anime info")
                }
                .tag(1)
                .transition(.slide)
            }
            .onChange(of: selectedTab) { _ in
                if selectedTab == 1 && animeElements.isEmpty && !storyTitle.isEmpty {
                    animeElements.append(AnimeWithSource(source: "manual", anime: Anime(title: storyTitle)))
                }
            }
            
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                
                Button(selectedTab == 1 ? "Add to list" : "Next") {
                    if selectedTab == 1 {
                        let animes: [String: Anime] = animeElements.reduce(into: [String: Anime]()) {
                            $0[$1.source] = $1.anime
                        }
                        
                        animeListVM.addToList(
                            animes: animes,
                            lastEpisode: lastEpisodeTitle,
                            status: selectedAnimeStatus,
                            rating: selectedAnimeRating,
                            lastWatchDate: Date.now
                        )
                        
                        dismiss()
                    } else {
                        withAnimation {
                            selectedTab = 1
                        }
                    }
                }
                .disabled(selectedTab == 1 ? storyTitle.isEmpty && animeElements.isEmpty : false)
            }
        }
        .padding()
    }
    
    private func searchAndGetAnime(source: AnimeSource) {
        Task { @MainActor in
            searchState = .loading
            
            if let initialAnime = await source.getSearchAnime(pageNumber: 1, searchQuery: storyTitle).first {
                await animeVM.getAnimeDetails(for: initialAnime, source: source.sourceId) { result in
                    if let result = result {
                        animeElements.append(AnimeWithSource(source: source.sourceId, anime: result))
                        searchState = .success
                        
                        return
                    } else {
                        searchState = .failed
                    }
                }
            } else {
                searchState = .failed
            }
        }
    }
}

struct AnimeListAnimeDetailsEditorView: View {
    @Binding var animeElement: AnimeWithSource
    
    @Binding var storyTitle: String
    @Binding var lastEpisodeTitle: String
    @Binding var selectedAnimeStatus: AnimeStatus
    @Binding var selectedAnimeRating: AnimeRating
    
    @Binding var animeListNewImageUrl: String
    @Binding var animeListNewAuthor: String
        
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                TextField("Source", text: $animeElement.source)
                    .padding(.bottom, 20)
                
                Text("Anime details")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .font(.headline)
                
                TextField("Title", text: $animeElement.anime.title ?? "No title")
                TextField("Description", text: $animeElement.anime.description ?? "")
                TextField("Image URL", text: $animeListNewImageUrl)
                    .onChange(of: animeListNewImageUrl) { _ in
                        if let url = URL(string: animeListNewImageUrl) {
                            animeElement.anime.imageUrl = url
                        }
                    }
                
                Text("Authors")
                ScrollView {
                    ForEach((animeElement.anime.authors ?? []).indices, id: \.self) { authorIndex in
                        let authorsBinding: Binding<[String]> = Binding(get: { animeElement.anime.authors ?? [] }, set: { animeElement.anime.authors = $0 })
                        
                        TextField("Author", text: authorsBinding[authorIndex])
                    }
                    
                    TextField("Add new author", text: $animeListNewAuthor)
                        .onSubmit {
                            animeElement.anime.authors?.append(animeListNewAuthor)
                            animeListNewAuthor = ""
                        }
                }
            }
            .padding()
        }
    }
}

struct AnimeListView_Previews: PreviewProvider {
    static var previews: some View {
        AnimeListView()
    }
}
