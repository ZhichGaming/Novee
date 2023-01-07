//
//  MangaListView.swift
//  Novee
//
//  Created by Nick on 2023-01-03.
//

import SwiftUI

struct MangaListView: View {
    @EnvironmentObject var mangaListVM: MangaListVM
    
    @State private var listQuery = ""
    @State private var showingSearchDetailsSheet = false
    @State private var selectedSortingStyle = "Recently updated"
    
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
                    ForEach(mangaListVM.list) { manga in
                        MangaListRowView(manga: manga, geo: geo)
                    }
                    .padding()
                }
            }
            .frame(width: geo.size.width)
        }
    }
}

struct MangaListRowView: View {
    @State var manga: MangaListElement
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

struct MangaListView_Previews: PreviewProvider {
    static var previews: some View {
        MangaListView()
    }
}
