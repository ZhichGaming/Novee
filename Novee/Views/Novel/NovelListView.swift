//
//  NovelListView.swift
//  Novee
//
//  Created by Nick on 2023-03-05.
//

import SwiftUI
import CachedAsyncImage

struct NovelListView: View {
    @EnvironmentObject var novelListVM: NovelListVM
    
    @State private var listQuery = ""
    @State private var showingSearchDetailsSheet = false
    @State private var showingAddNewNovelSheet = false
    @State private var selectedSortingStyle = "Recently updated"
    @State private var novelDetailsSheet: NovelListElement?
    
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
    
    var filteredList: [NovelListElement] {
        var result = novelListVM.list
        
        if !showingWaiting { result.removeAll { $0.status == .waiting } }
        if !showingReading { result.removeAll { $0.status == .viewing } }
        if !showingDropped { result.removeAll { $0.status == .dropped } }
        if !showingCompleted { result.removeAll { $0.status == .completed } }
        if !showingToRead { result.removeAll { $0.status == .toView } }
        
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
            result.removeAll { novel in
                let novelInstances = novel.content.map { [$0.value.title] + ($0.value.altTitles ?? []) }
                
                for titles in novelInstances {
                    for title in titles {
                        if title?.uppercased().contains(listQuery.uppercased()) ?? false {
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
            NavigationStack {
                VStack(spacing: 0) {
                    HStack {
                        TextField("Search for novel", text: $listQuery)
                            .textFieldStyle(.roundedBorder)
                        
                        Button {
                            showingSearchDetailsSheet = true
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        
                        Button {
                            showingAddNewNovelSheet = true
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
                    
                    VStack {
                        List(filteredList) { novelListElement in
                            NavigationLink(value: novelListElement) {
                                NovelListRowView(novel: novelListElement, geo: geo)
                            }
                            .buttonStyle(.plain)
                        }
                        .navigationDestination(for: NovelListElement.self) { novelListElement in
                            NovelListDetailsSheetView(passedNovel: novelListElement)
                        }
                        .navigationDestination(for: Novel.self) { novel in
                            NovelDetailsView(selectedNovel: novel)
                        }
                    }
                    .sheet(isPresented: $showingAddNewNovelSheet) {
                        NovelListAddNewToListView()
                            .frame(width: 500, height: 300)
                    }
                }
                .frame(width: geo.size.width)
            }
        }
    }
}

struct NovelListRowView: View {
    var novel: NovelListElement
    let geo: GeometryProxy
    
    var body: some View {
        HStack {
            Text(novel.content.first?.value.title ?? "No title")
                .frame(width: geo.size.width * 0.3, alignment: .leading)
                .lineLimit(2)
            Text(novel.lastSegment ?? "No last chapter")
                .frame(width: geo.size.width * 0.2, alignment: .leading)
                .lineLimit(2)
            Text(novel.status.rawValue)
                .foregroundColor(.white)
                .padding(3)
                .padding(.horizontal, 3)
                .background {
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundColor(novel.status.getStatusColor())
                }
                .frame(width: geo.size.width * 0.2, alignment: .leading)
            Text(novel.rating.rawValue)
                .frame(width: geo.size.width * 0.2, alignment: .leading)
                .foregroundColor(novel.rating == .best ? .purple : .primary)
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

struct NovelListDetailsSheetView: View {
    @EnvironmentObject var novelVM: NovelVM
    @EnvironmentObject var novelListVM: NovelListVM
    
    @State var passedNovel: NovelListElement

    @Environment(\.dismiss) var dismiss
    
    @State private var novelKeysArray: [String] = []
    
    @State private var showingDeleteSourceAlert = false
    @State private var deleteSourceAlertSource: String? = nil

    var body: some View {
        VStack {
            Text(passedNovel.content.first?.value.title ?? "None")
                .font(.title2.bold())
            
            TabView {
                ScrollView {
                    ForEach(novelKeysArray, id: \.self) { key in
                        if let novel = passedNovel.content[key] {
                            Text(novelVM.sources[key]?.label ?? key)
                                .font(.title2.bold())
                                .padding(.top)
                            
                            HStack {
                                VStack {
                                    if let url = novel.imageUrl {
                                        CachedAsyncImage(url: url) { image in
                                            image
                                                .resizable()
                                                .scaledToFit()
                                        } placeholder: {
                                            ProgressView()
                                        }
                                    }
                                    
                                    Text(novel.title ?? "No title")
                                        .font(.headline)
                                }
                                .frame(width: 200)
                                .padding(.trailing)
                                
                                List {
                                    if let description = novel.description {
                                        Text("Description")
                                            .font(.headline)
                                        Text(description)
                                        Spacer()
                                    }
                                    
                                    if let tags = novel.tags {
                                        Text("Tags")
                                            .font(.headline)
                                        Text(tags.map { $0.name }.joined(separator: ", "))
                                        Spacer()
                                    }
                                    
                                    if let altTitles = novel.altTitles?.joined(separator: ", ") {
                                        Text("Alternative titles")
                                            .font(.headline)
                                        Text(altTitles)
                                        Spacer()
                                    }
                                    
                                    if let authors = novel.authors?.joined(separator: ", ") {
                                        Text("Authors")
                                            .font(.headline)
                                        Text(authors)
                                        Spacer()
                                    }
                                    
                                    if let detailsUrl = novel.detailsUrl {
                                        Link("URL source", destination: detailsUrl)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 200)
                            .padding()
                            
                            Spacer()
                            HStack {
                                Spacer()
                                
                                NavigationLink("Open", value: novel)
                                
                                Button {
                                    if let currentIndex = novelKeysArray.firstIndex(of: key) {
                                        withAnimation {
                                            novelKeysArray.rearrange(fromIndex: currentIndex, toIndex: currentIndex - 1)
                                        }
                                    }
                                } label: {
                                    Image(systemName: "arrow.up")
                                }
                                .disabled((novelKeysArray.firstIndex(of: key) ?? 0) - 1 < 0)
                                
                                Button {
                                    if let currentIndex = novelKeysArray.firstIndex(of: key) {
                                        withAnimation {
                                            novelKeysArray.rearrange(fromIndex: currentIndex, toIndex: currentIndex + 1)
                                        }
                                    }
                                } label: {
                                    Image(systemName: "arrow.down")
                                }
                                .disabled(novelKeysArray.firstIndex(of: key) ?? novelKeysArray.count >= novelKeysArray.count - 1)

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
                                            novelListVM.removeSourceFromList(id: passedNovel.id, source: source)
                                            passedNovel.content.removeValue(forKey: source)
                                            
                                            if !novelListVM.list.contains(where: { $0.id == passedNovel.id }) {
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
                        novelKeysArray = Array(passedNovel.content.keys)
                                                
                        Task { @MainActor in
                            passedNovel.content = await novelVM.getAllUpdatedNovelDetails(for: passedNovel.content)
                        }
                    }
                }
                .tabItem {
                    Text("Novel details")
                }
                
                NovelListListDetailsView(passedNovel: passedNovel, dismissOnDelete: true)
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

struct NovelListListDetailsView: View {
    @EnvironmentObject var novelVM: NovelVM
    @EnvironmentObject var novelListVM: NovelListVM
    
    @Environment(\.dismiss) var dismiss
    
    let passedNovel: NovelListElement
    
    let dismissOnDelete: Bool
    
    @State private var selectedSource: String = ""
    @State private var selectedLastChapter: String = ""
    @State private var selectedNovelRating: String = ""
    @State private var selectedNovelStatus: String = ""
    
    @State private var showingDeleteAlert = false
    
    @State private var showingLastChapterSelection = false
    @State private var selectedLastReadDate: Date = Date.now

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text("Novel status/rating")
                    .font(.headline)
                
                Picker("Novel status", selection: $selectedNovelStatus) {
                    ForEach(Status.allCases, id: \.rawValue) { status in
                        Text(status.rawValue)
                            .tag(status.rawValue)
                    }
                }
                .onChange(of: selectedNovelStatus) { newStatus in
                    novelListVM.updateStatus(
                        id: passedNovel.id,
                        to: Status(rawValue: newStatus) ?? passedNovel.status
                    )
                }
                
                Picker("Novel rating", selection: $selectedNovelRating) {
                    ForEach(Rating.allCases, id: \.rawValue) { rating in
                        Text(rating.rawValue)
                            .tag(rating.rawValue)
                    }
                }
                .onChange(of: selectedNovelRating) { newRating in
                    novelListVM.updateRating(
                        id: passedNovel.id,
                        to: Rating(rawValue: newRating) ?? passedNovel.rating
                    )
                }
            }
            
            VStack(alignment: .leading) {
                Text("Last read chapter")
                    .font(.headline)
                
                Picker("Chapter source", selection: $selectedSource) {
                    ForEach(Array(passedNovel.content.keys), id: \.self) { key in
                        Text(novelVM.sources[key]?.label ?? key)
                            .tag(key)
                    }
                }
                
                Picker("Last chapter", selection: $selectedLastChapter) {
                    ForEach(passedNovel.content[selectedSource]?.segments ?? [], id: \.id) { chapter in
                        Text(chapter.title)
                            .tag(chapter.title)
                    }
                }
                .disabled(!passedNovel.content.keys.contains(selectedSource))
                .onChange(of: selectedLastChapter) { newChapter in
                    novelListVM.updateLastSegment(
                        id: passedNovel.id,
                        to: newChapter
                    )
                }
                
                HStack {
                    Text("Current last chapter:")
                    Text(passedNovel.lastSegment ?? "None")
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
                            novelListVM.updateLastViewedDate(id: passedNovel.id, to: newDate)
                        }
                    }
                    
                    Button(showingLastChapterSelection ? "Remove last read date" : "Add last read date") {
                        showingLastChapterSelection.toggle()
                    }
                    .onAppear {
                        showingLastChapterSelection = passedNovel.lastViewedDate != nil
                        selectedLastReadDate = passedNovel.lastViewedDate ?? selectedLastReadDate
                    }
                    .onChange(of: showingLastChapterSelection) { showingLastChapter in
                        if !showingLastChapter {
                            novelListVM.updateLastViewedDate(id: passedNovel.id, to: nil)
                        }
                    }
                }
                .padding(.vertical, 3)

                HStack {
                    Text("Creation date:")
                    Text(passedNovel.creationDate.formatted(date: .abbreviated, time: .omitted))
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
                            if let listElementIndex = novelListVM.list.firstIndex(where: { $0.id == passedNovel.id }) {
                                novelListVM.list.remove(at: listElementIndex)
                                
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
            
            Spacer()
        }
        .onAppear {
            selectedNovelRating = passedNovel.rating.rawValue
            selectedNovelStatus = passedNovel.status.rawValue
        }
    }
}

struct NovelListAddNewToListView: View {
    @EnvironmentObject var novelVM: NovelVM
    @EnvironmentObject var novelListVM: NovelListVM
    
    @Environment(\.dismiss) var dismiss
    
    @State var storyTitle: String = ""
    @State var lastSegmentTitle: String = ""
    @State var selectedNovelStatus: Status = .viewing
    @State var selectedNovelRating: Rating = .none
    
    @State var novelListNewImageUrl = ""
    @State var novelListNewAuthor = ""
        
    @State var novelElements: [NovelWithSource] = []
    @State var selectedNovelIndex: Set<Int> = Set()
    @State var searchState: LoadingState? = nil
    
    @State var selectedTab = 0
    
    @State var showingAddToListAlert = false
    
    var body: some View {
        VStack {
            Text("Add new novel")
                .font(.title3.bold())
            
            TabView(selection: $selectedTab) {
                VStack {
                    Text("The Title field is used for autofill in the next step. It can be left blank if you do not want to use autofill.")
                        .fixedSize(horizontal: false, vertical: true)

                    TextField("Title", text: $storyTitle)
                    TextField("Last chapter title", text: $lastSegmentTitle)
                    
                    Group {
                        Picker("Status", selection: $selectedNovelStatus) {
                            ForEach(Status.allCases, id: \.rawValue) {
                                Text($0.rawValue)
                                    .tag($0)
                            }
                        }
                        
                        Picker("Rating", selection: $selectedNovelRating) {
                            ForEach(Rating.allCases, id: \.rawValue) {
                                Text($0.rawValue)
                                    .tag($0)
                            }
                        }
                    }
                }
                .padding()
                .tabItem {
                    Text("Novel list info")
                }
                .tag(0)
                .transition(.slide)
                
                VStack(alignment: .leading) {
                    NavigationView {
                        List(0..<novelElements.count, id: \.self, selection: $selectedNovelIndex) { index in
                            let hasDuplicate = Array<String>(Set<String>(novelElements.map { $0.source })).sorted() == novelElements.map { $0.source }.sorted()
                            
                            NavigationLink {
                                if index >= 0 && novelElements.count > index {
                                    NovelListNovelDetailsEditorView(
                                        novelElement: $novelElements[index],
                                        storyTitle: $storyTitle,
                                        lastSegmentTitle: $lastSegmentTitle,
                                        selectedNovelStatus: $selectedNovelStatus,
                                        selectedNovelRating: $selectedNovelRating,
                                        novelListNewImageUrl: $novelListNewImageUrl,
                                        novelListNewAuthor: $novelListNewAuthor)
                                }
                            } label: {
                                Text(novelElements[index].source)
                                    .foregroundColor(hasDuplicate ? .primary : .red)
                            }
                            .help(hasDuplicate ? "" : "There is another novel with the same source key.")
                        }
                        .listStyle(.bordered)
                    }
                    
                    HStack {
                        ControlGroup {
                            Button {
                                novelElements.remove(at: selectedNovelIndex.first!)
                            } label: {
                                Image(systemName: "minus")
                            }
                            
                            Menu {
                                Button("Create manually") {
                                    novelElements.append(NovelWithSource(source: "manual", novel: Novel(title: storyTitle, authors: [])))
                                }
                                
                                Menu("Search in source") {
                                    ForEach(novelVM.sourcesArray, id: \.sourceId) { source in
                                        Button(source.label) {
                                            searchAndGetNovel(source: source)
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
                    Text("Novel info")
                }
                .tag(1)
                .transition(.slide)
            }
            .onChange(of: selectedTab) { _ in
                if selectedTab == 1 && novelElements.isEmpty && !storyTitle.isEmpty {
                    novelElements.append(NovelWithSource(source: "manual", novel: Novel(title: storyTitle)))
                }
            }
            
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                
                Button(selectedTab == 1 ? "Add to list" : "Next") {
                    if selectedTab == 1 {
                        let novels: [String: Novel] = novelElements.reduce(into: [String: Novel]()) {
                            $0[$1.source] = $1.novel
                        }
                        
                        novelListVM.addToList(
                            novels: novels,
                            lastSegment: lastSegmentTitle,
                            status: selectedNovelStatus,
                            rating: selectedNovelRating,
                            lastViewedDate: Date.now
                        )
                        
                        dismiss()
                    } else {
                        withAnimation {
                            selectedTab = 1
                        }
                    }
                }
                .disabled(selectedTab == 1 ? storyTitle.isEmpty && novelElements.isEmpty : false)
            }
        }
        .padding()
    }
    
    private func searchAndGetNovel(source: NovelSource) {
        Task { @MainActor in
            searchState = .loading
                        
            if let initialNovel = await source.getSearchNovel(pageNumber: 1, searchQuery: storyTitle).first {
                await novelVM.getNovelDetails(for: initialNovel, source: source.sourceId) { result in
                    if let result = result {
                        novelElements.append(NovelWithSource(source: source.sourceId, novel: result))
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

struct NovelListNovelDetailsEditorView: View {
    @Binding var novelElement: NovelWithSource
    
    @Binding var storyTitle: String
    @Binding var lastSegmentTitle: String
    @Binding var selectedNovelStatus: Status
    @Binding var selectedNovelRating: Rating
    
    @Binding var novelListNewImageUrl: String
    @Binding var novelListNewAuthor: String
        
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                TextField("Source", text: $novelElement.source)
                    .padding(.bottom, 20)
                
                Text("Novel details")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .font(.headline)
                
                TextField("Title", text: $novelElement.novel.title ?? "No title")
                TextField("Description", text: $novelElement.novel.description ?? "")
                TextField("Image URL", text: $novelListNewImageUrl)
                    .onChange(of: novelListNewImageUrl) { _ in
                        if let url = URL(string: novelListNewImageUrl) {
                            novelElement.novel.imageUrl = url
                        }
                    }
                
                Text("Authors")
                ScrollView {
                    ForEach((novelElement.novel.authors ?? []).indices, id: \.self) { authorIndex in
                        let authorsBinding: Binding<[String]> = Binding(get: { novelElement.novel.authors ?? [] }, set: { novelElement.novel.authors = $0 })
                        
                        TextField("Author", text: authorsBinding[authorIndex])
                    }
                    
                    TextField("Add new author", text: $novelListNewAuthor)
                        .onSubmit {
                            novelElement.novel.authors?.append(novelListNewAuthor)
                            novelListNewAuthor = ""
                        }
                }
            }
            .padding()
        }
    }
}

struct NovelListView_Previews: PreviewProvider {
    static var previews: some View {
        NovelListView()
    }
}
