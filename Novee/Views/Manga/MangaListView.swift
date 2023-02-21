//
//  MangaListView.swift
//  Novee
//
//  Created by Nick on 2023-01-03.
//

import SwiftUI
import CachedAsyncImage

struct MangaListView: View {
    @EnvironmentObject var mangaListVM: MangaListVM
    
    @State private var listQuery = ""
    @State private var showingSearchDetailsSheet = false
    @State private var showingAddNewMangaSheet = false
    @State private var selectedSortingStyle = "Recently updated"
    @State private var mangaDetailsSheet: MangaListElement?
    
    @State private var showingWaiting = true
    @State private var showingReading = true
    @State private var showingDropped = true
    @State private var showingCompleted = true
    @State private var showingToRead = true
    
    @State private var showingRatingNone = true
    @State private var showingRatingHorrible = true
    @State private var showingRatingBad = true
    @State private var showingRatingGood = true
    @State private var showingRatingBest = true
    
    var filteredList: [MangaListElement] {
        var result = mangaListVM.list
        
        if !showingWaiting { result.removeAll { $0.status == .waiting } }
        if !showingReading { result.removeAll { $0.status == .reading } }
        if !showingDropped { result.removeAll { $0.status == .dropped } }
        if !showingCompleted { result.removeAll { $0.status == .completed } }
        if !showingToRead { result.removeAll { $0.status == .toRead } }
        
        if !showingRatingNone { result.removeAll { $0.rating == .none } }
        if !showingRatingHorrible { result.removeAll { $0.rating == .horrible } }
        if !showingRatingBad { result.removeAll { $0.rating == .bad } }
        if !showingRatingGood { result.removeAll { $0.rating == .good } }
        if !showingRatingBest { result.removeAll { $0.rating == .best } }
        
        if selectedSortingStyle == "Recently updated" {
            result.sort {
                return $0.lastReadDate ?? Date.distantPast > $1.lastReadDate ?? Date.distantPast
            }
        } else if selectedSortingStyle == "Recently added" {
            result.sort { $0.creationDate.compare($1.creationDate) == .orderedDescending }
        } else {
            result.sort {
                return $0.manga.first?.value.title ?? "" < $1.manga.first?.value.title ?? ""
            }
        }
        
        if !listQuery.isEmpty {
            result.removeAll { manga in
                let mangaInstances = manga.manga.map { [$0.value.title] + ($0.value.altTitles ?? []) }
                
                for titles in mangaInstances {
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
            VStack(spacing: 0) {
                HStack {
                    TextField("Search for manga", text: $listQuery)
                        .textFieldStyle(.roundedBorder)
                    
                    Button {
                        showingSearchDetailsSheet = true
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    
                    Button {
                        showingAddNewMangaSheet = true
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
                                    Toggle("Reading", isOn: $showingReading)
                                    Toggle("Dropped", isOn: $showingDropped)
                                    Toggle("Completed", isOn: $showingCompleted)
                                    Toggle("To read", isOn: $showingToRead)
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
                    Text("Last chapter")
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
                        ForEach(filteredList) { mangaListElement in
                            Button {
                                mangaDetailsSheet = mangaListElement
                            } label: {
                                MangaListRowView(manga: mangaListElement, geo: geo)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
                .sheet(item: $mangaDetailsSheet) { mangaListElement in
                    MangaListDetailsSheetView(passedManga: mangaListElement)
                        .frame(width: 700, height: 550)
                }
                .sheet(isPresented: $showingAddNewMangaSheet) {
                    MangaListAddNewToListView()
                        .frame(width: 500, height: 300)
                }
            }
            .frame(width: geo.size.width)
        }
    }
}

struct MangaListRowView: View {
    var manga: MangaListElement
    let geo: GeometryProxy
    
    var body: some View {
        HStack {
            Text(manga.manga.first?.value.title ?? "No title")
                .frame(width: geo.size.width * 0.3, alignment: .leading)
            Text(manga.lastChapter ?? "No last chapter")
                .frame(width: geo.size.width * 0.2, alignment: .leading)
            Text(manga.status.rawValue)
                .foregroundColor(.white)
                .padding(3)
                .padding(.horizontal, 3)
                .background {
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundColor(manga.status.getStatusColor())
                }
                .frame(width: geo.size.width * 0.2, alignment: .leading)
            Text(manga.rating.rawValue)
                .frame(width: geo.size.width * 0.2, alignment: .leading)
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

struct MangaListDetailsSheetView: View {
    @EnvironmentObject var mangaVM: MangaVM
    @EnvironmentObject var mangaListVM: MangaListVM
    
    let passedManga: MangaListElement

    @Environment(\.dismiss) var dismiss
    
    @State private var mangaKeysArray: [String] = []
    
    @State private var selectedSource: String = ""
    @State private var selectedLastChapter: String = ""
    @State private var selectedMangaRating: String = ""
    @State private var selectedMangaStatus: String = ""
    
    @State private var showingDeleteAlert = false
    @State private var showingLastChapterSelection = false
    @State private var selectedLastReadDate: Date = Date.now

    var body: some View {
        VStack {
            Text(passedManga.manga.first?.value.title ?? "None")
                .font(.title2.bold())
            
            TabView {
                ScrollView {
                    ForEach(mangaKeysArray, id: \.self) { key in
                        if let manga = passedManga.manga[key] {
                            Text(mangaVM.sources[key]?.label ?? key)
                                .font(.title2.bold())
                                .padding(.top)
                            
                            HStack {
                                VStack {
                                    if let url = manga.imageUrl {
                                        CachedAsyncImage(url: url) { image in
                                            image
                                                .resizable()
                                                .scaledToFit()
                                        } placeholder: {
                                            ProgressView()
                                        }
                                    }
                                    
                                    Text(manga.title)
                                        .font(.headline)
                                }
                                .frame(width: 200)
                                .padding(.trailing)
                                
                                List {
                                    if let description = manga.description {
                                        Text("Description")
                                            .font(.headline)
                                        Text(description)
                                        Spacer()
                                    }
                                    
                                    if let tags = manga.tags {
                                        Text("Tags")
                                            .font(.headline)
                                        Text(tags.map { $0.name }.joined(separator: ", "))
                                        Spacer()
                                    }
                                    
                                    if let altTitles = manga.altTitles?.joined(separator: ", ") {
                                        Text("Alternative titles")
                                            .font(.headline)
                                        Text(altTitles)
                                        Spacer()
                                    }
                                    
                                    if let authors = manga.authors?.joined(separator: ", ") {
                                        Text("Authors")
                                            .font(.headline)
                                        Text(authors)
                                        Spacer()
                                    }
                                    
                                    if let detailsUrl = manga.detailsUrl {
                                        Link("URL source", destination: detailsUrl)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 200)
                            .padding()
                            
                            Spacer()
                            HStack {
                                Spacer()
                                Button {
                                    if let currentIndex = mangaKeysArray.firstIndex(of: key) {
                                        withAnimation {
                                            mangaKeysArray.rearrange(fromIndex: currentIndex, toIndex: currentIndex - 1)
                                        }
                                    }
                                } label: {
                                    Image(systemName: "arrow.up")
                                }
                                .disabled((mangaKeysArray.firstIndex(of: key) ?? 0) - 1 < 0)
                                
                                Button {
                                    if let currentIndex = mangaKeysArray.firstIndex(of: key) {
                                        withAnimation {
                                            mangaKeysArray.rearrange(fromIndex: currentIndex, toIndex: currentIndex + 1)
                                        }
                                    }
                                } label: {
                                    Image(systemName: "arrow.down")
                                }
                                .disabled(mangaKeysArray.firstIndex(of: key) ?? mangaKeysArray.count >= mangaKeysArray.count - 1)

                                Button {
                                    if let currentIndex = mangaKeysArray.firstIndex(of: key) {
                                        withAnimation {
                                            mangaKeysArray.remove(at: currentIndex)
                                            return () // This is to remove the warning of withAnimation being unused.
                                        }
                                        
                                        if let listElementIndex = mangaListVM.list.firstIndex(where: { $0.id == passedManga.id }) {
                                            mangaListVM.list[listElementIndex].manga.removeValue(forKey: key)
                                        }
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                            
                            Divider()
                                .padding(.horizontal)
                        }
                    }
                    .onAppear {
                        mangaKeysArray = Array(passedManga.manga.keys)
                    }
                }
                .tabItem {
                    Text("Manga details")
                }
                
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        Text("Manga status/rating")
                            .font(.headline)
                        
                        Picker("Manga status", selection: $selectedMangaStatus) {
                            ForEach(MangaStatus.allCases, id: \.rawValue) { status in
                                Text(status.rawValue)
                                    .tag(status.rawValue)
                            }
                        }
                        .onChange(of: selectedMangaStatus) { newStatus in
                            mangaListVM.updateStatus(
                                id: passedManga.id,
                                to: MangaStatus(rawValue: newStatus) ?? passedManga.status
                            )
                        }
                        
                        Picker("Manga rating", selection: $selectedMangaRating) {
                            ForEach(MangaRating.allCases, id: \.rawValue) { rating in
                                Text(rating.rawValue)
                                    .tag(rating.rawValue)
                            }
                        }
                        .onChange(of: selectedMangaRating) { newRating in
                            mangaListVM.updateRating(
                                id: passedManga.id,
                                to: MangaRating(rawValue: newRating) ?? passedManga.rating
                            )
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Last read chapter")
                            .font(.headline)
                        
                        Picker("Chapter source", selection: $selectedSource) {
                            ForEach(Array(passedManga.manga.keys), id: \.self) { key in
                                Text(mangaVM.sources[key]?.label ?? key)
                                    .tag(key)
                            }
                        }
                        
                        Picker("Last chapter", selection: $selectedLastChapter) {
                            ForEach(passedManga.manga[selectedSource]?.chapters ?? [], id: \.id) { chapter in
                                Text(chapter.title)
                                    .tag(chapter.title)
                            }
                        }
                        .disabled(!passedManga.manga.keys.contains(selectedSource))
                        .onChange(of: selectedLastChapter) { newChapter in
                            mangaListVM.updateLastChapter(
                                id: passedManga.id,
                                to: newChapter
                            )
                        }
                        
                        HStack {
                            Text("Current last chapter:")
                            Text(passedManga.lastChapter ?? "None")
                        }
                    }
                    .padding(.vertical)

                    VStack(alignment: .leading) {
                        Text("Dates")
                            .font(.headline)
                        
                        HStack {
                            if showingLastChapterSelection {
                                DatePicker(
                                    "Last read date:",
                                    selection: $selectedLastReadDate,
                                    displayedComponents: .date
                                )
                                .onChange(of: selectedLastReadDate) { newDate in
                                    mangaListVM.updateLastReadDate(id: passedManga.id, to: newDate)
                                }
                            }
                            
                            Button(showingLastChapterSelection ? "Remove last read date" : "Add last read date") {
                                showingLastChapterSelection.toggle()
                            }
                            .onAppear {
                                showingLastChapterSelection = passedManga.lastReadDate != nil
                                selectedLastReadDate = passedManga.lastReadDate ?? selectedLastReadDate
                            }
                            .onChange(of: showingLastChapterSelection) { showingLastChapter in
                                if !showingLastChapter {
                                    mangaListVM.updateLastReadDate(id: passedManga.id, to: nil)
                                }
                            }
                        }
                        .padding(.vertical, 3)

                        HStack {
                            Text("Creation date:")
                            Text(passedManga.creationDate.formatted(date: .abbreviated, time: .omitted))
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
                                    if let listElementIndex = mangaListVM.list.firstIndex(where: { $0.id == passedManga.id }) {
                                        mangaListVM.list.remove(at: listElementIndex)
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
                    selectedMangaRating = passedManga.rating.rawValue
                    selectedMangaStatus = passedManga.status.rawValue
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

struct MangaListAddNewToListView: View {
    @EnvironmentObject var mangaVM: MangaVM
    @EnvironmentObject var mangaListVM: MangaListVM
    
    @Environment(\.dismiss) var dismiss
    
    @State var storyTitle: String = ""
    @State var lastChapterTitle: String = ""
    @State var selectedMangaStatus: MangaStatus = .reading
    @State var selectedMangaRating: MangaRating = .none
    
    @State var mangaListNewImageUrl = ""
    @State var mangaListNewAuthor = ""
        
    @State var mangaElements: [MangaWithSource] = []
    @State var selectedMangaIndex: Set<Int> = Set()
    @State var searchState: LoadingState? = nil
    
    @State var selectedTab = 0
    
    @State var showingAddToListAlert = false
    
    var body: some View {
        VStack {
            Text("Add new manga")
                .font(.title3.bold())
            
            TabView(selection: $selectedTab) {
                VStack {
                    Text("The Title field is used for autofill in the next step. It can be left blank if you do not want to use autofill.")
                        .fixedSize(horizontal: false, vertical: true)

                    TextField("Title", text: $storyTitle)
                    TextField("Last chapter title", text: $lastChapterTitle)
                    
                    Group {
                        Picker("Status", selection: $selectedMangaStatus) {
                            ForEach(MangaStatus.allCases, id: \.rawValue) {
                                Text($0.rawValue)
                                    .tag($0)
                            }
                        }
                        
                        Picker("Rating", selection: $selectedMangaRating) {
                            ForEach(MangaRating.allCases, id: \.rawValue) {
                                Text($0.rawValue)
                                    .tag($0)
                            }
                        }
                    }
                }
                .padding()
                .tabItem {
                    Text("Manga list info")
                }
                .tag(0)
                .transition(.slide)
                
                VStack(alignment: .leading) {
                    NavigationView {
                        List(0..<mangaElements.count, id: \.self, selection: $selectedMangaIndex) { index in
                            let hasDuplicate = Array<String>(Set<String>(mangaElements.map { $0.source })).sorted() == mangaElements.map { $0.source }.sorted()
                            
                            NavigationLink {
                                if index >= 0 && mangaElements.count > index {
                                    MangaListMangaDetailsEditorView(
                                        mangaElement: $mangaElements[index],
                                        storyTitle: $storyTitle,
                                        lastChapterTitle: $lastChapterTitle,
                                        selectedMangaStatus: $selectedMangaStatus,
                                        selectedMangaRating: $selectedMangaRating,
                                        mangaListNewImageUrl: $mangaListNewImageUrl,
                                        mangaListNewAuthor: $mangaListNewAuthor)
                                }
                            } label: {
                                Text(mangaElements[index].source)
                                    .foregroundColor(hasDuplicate ? .primary : .red)
                            }
                            .help(hasDuplicate ? "" : "There is another manga with the same source key.")
                        }
                        .listStyle(.bordered)
                    }
                    
                    HStack {
                        ControlGroup {
                            Button {
                                mangaElements.remove(at: selectedMangaIndex.first!)
                            } label: {
                                Image(systemName: "minus")
                            }
                            
                            Menu {
                                Button("Create manually") {
                                    mangaElements.append(MangaWithSource(source: "manual", manga: Manga(title: storyTitle, authors: [])))
                                }
                                
                                Menu("Search in source") {
                                    ForEach(mangaVM.sourcesArray, id: \.sourceId) { source in
                                        Button(source.label) {
                                            searchAndGetManga(source: source)
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
                    Text("Manga info")
                }
                .tag(1)
                .transition(.slide)
            }
            .onChange(of: selectedTab) { _ in
                if selectedTab == 1 && mangaElements.isEmpty && !storyTitle.isEmpty {
                    mangaElements.append(MangaWithSource(source: "manual", manga: Manga(title: storyTitle)))
                }
            }
            
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                
                Button(selectedTab == 1 ? "Add to list" : "Next") {
                    if selectedTab == 1 {
                        let mangas: [String: Manga] = mangaElements.reduce(into: [String: Manga]()) {
                            $0[$1.source] = $1.manga
                        }
                        
                        mangaListVM.addToList(
                            mangas: mangas,
                            lastChapter: lastChapterTitle,
                            status: selectedMangaStatus,
                            rating: selectedMangaRating,
                            lastReadDate: Date.now
                        )
                        
                        dismiss()
                    } else {
                        withAnimation {
                            selectedTab = 1
                        }
                    }
                }
                .disabled(selectedTab == 1 ? storyTitle.isEmpty && mangaElements.isEmpty : false)
            }
        }
        .padding()
    }
    
    private func searchAndGetManga(source: MangaSource) {
        Task { @MainActor in
            searchState = .loading
                        
            if let initialManga = await source.getSearchManga(pageNumber: 1, searchQuery: storyTitle).first {
                await mangaVM.getMangaDetails(for: initialManga, source: source.sourceId) { result in
                    if let result = result {
                        mangaElements.append(MangaWithSource(source: source.sourceId, manga: result))
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

struct MangaListMangaDetailsEditorView: View {
    @Binding var mangaElement: MangaWithSource
    
    @Binding var storyTitle: String
    @Binding var lastChapterTitle: String
    @Binding var selectedMangaStatus: MangaStatus
    @Binding var selectedMangaRating: MangaRating
    
    @Binding var mangaListNewImageUrl: String
    @Binding var mangaListNewAuthor: String
        
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                TextField("Source", text: $mangaElement.source)
                    .padding(.bottom, 20)
                
                Text("Manga details")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .font(.headline)
                
                TextField("Title", text: $mangaElement.manga.title)
                TextField("Description", text: $mangaElement.manga.description ?? "")
                TextField("Image URL", text: $mangaListNewImageUrl)
                    .onChange(of: mangaListNewImageUrl) { _ in
                        if let url = URL(string: mangaListNewImageUrl) {
                            mangaElement.manga.imageUrl = url
                        }
                    }
                
                Text("Authors")
                ScrollView {
                    ForEach((mangaElement.manga.authors ?? []).indices, id: \.self) { authorIndex in
                        let authorsBinding: Binding<[String]> = Binding(get: { mangaElement.manga.authors ?? [] }, set: { mangaElement.manga.authors = $0 })
                        
                        TextField("Author", text: authorsBinding[authorIndex])
                    }
                    
                    TextField("Add new author", text: $mangaListNewAuthor)
                        .onSubmit {
                            mangaElement.manga.authors?.append(mangaListNewAuthor)
                            mangaListNewAuthor = ""
                        }
                }
            }
            .padding()
        }
    }
}

struct MangaListView_Previews: PreviewProvider {
    static var previews: some View {
        MangaListView()
    }
}
