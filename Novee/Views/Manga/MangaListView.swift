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
                    ForEach(filteredList) { mangaListElement in
                        Button {
                            mangaDetailsSheet = mangaListElement
                        } label: {
                            MangaListRowView(manga: mangaListElement, geo: geo)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                }
                .sheet(item: $mangaDetailsSheet) { mangaListElement in
                    MangaListDetailsSheetView(passedManga: mangaListElement)
                        .frame(width: 700, height: 500)
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
    
    @State private var selectedSource: String = ""
    @State private var selectedLastChapter: String = ""
    @State private var selectedMangaRating: String = ""
    @State private var selectedMangaStatus: String = ""
    
    var body: some View {
        VStack {
            Text(passedManga.manga.first?.value.title ?? "None")
                .font(.title2.bold())
            
            TabView {
                ScrollView {
                    ForEach(Array(passedManga.manga.values), id: \.id) { manga in
                        HStack {
                            VStack {
                                CachedAsyncImage(url: manga.imageUrl) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                } placeholder: {
                                    ProgressView()
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
                                    Text(tags.joined(separator: ", "))
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
                        .frame(maxWidth: .infinity)
                        .padding()

                        Divider()
                            .padding(.horizontal)
                    }
                }
                .tabItem {
                    Text("Manga details")
                }
                
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        Text("Manga status/rating")
                            .font(.title2.bold())
                        
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
                            .font(.title2.bold())
                        
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
                            .font(.title2.bold())
                        
                        HStack {
                            Text("Last read date:")
                            Text(passedManga.lastReadDate?.formatted(date: .abbreviated, time: .standard) ?? "None")
                                .font(.body)
                        }
                        .padding(.vertical, 3)

                        HStack {
                            Text("Creation date:")
                            Text(passedManga.creationDate.formatted(date: .abbreviated, time: .standard))
                                .font(.body)
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

struct MangaListView_Previews: PreviewProvider {
    static var previews: some View {
        MangaListView()
    }
}
