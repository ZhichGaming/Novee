//
//  FavouritesView.swift
//  Novee
//
//  Created by Nick on 2023-04-19.
//

import SwiftUI

struct FavouritesView: View {
    @EnvironmentObject var favouritesVM: FavouritesVM
    
    @State private var searchQuery = ""
    @State private var selectedSortingStyle = "Recently updated"
    
    @State private var showingFilterPopover = false

    @State private var showingWaiting = true
    @State private var showingViewing = true
    @State private var showingDropped = true
    @State private var showingCompleted = true
    @State private var showingToView = true
    
    @State private var fetchedLatestChapters: [Int: String] = [:]
    
    var filteredList: [Favourite] {
        var result = favouritesVM.favourites
        
        if !showingWaiting { result.removeAll { $0.mediaListElement.status == .waiting } }
        if !showingViewing { result.removeAll { $0.mediaListElement.status == .viewing } }
        if !showingDropped { result.removeAll { $0.mediaListElement.status == .dropped } }
        if !showingCompleted { result.removeAll { $0.mediaListElement.status == .completed } }
        if !showingToView { result.removeAll { $0.mediaListElement.status == .toView } }
        
        if selectedSortingStyle == "Recently updated" {
            result.sort {
                return $0.mediaListElement.lastViewedDate ?? Date.distantPast > $1.mediaListElement.lastViewedDate ?? Date.distantPast
            }
        } else if selectedSortingStyle == "Recently added" {
            result.sort { $0.mediaListElement.creationDate.compare($1.mediaListElement.creationDate) == .orderedDescending }
        } else {
            result.sort {
                return $0.mediaListElement.content.first?.value.title ?? "" < $1.mediaListElement.content.first?.value.title ?? ""
            }
        }
        
        if !searchQuery.isEmpty {
            result.removeAll { media in
                let mediaInstances = media.mediaListElement.content.map { [$0.value.title ?? ""] + ($0.value.altTitles ?? []) }
                
                for titles in mediaInstances {
                    for title in titles {
                        if title.uppercased().contains(searchQuery.uppercased()) {
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
                                
                                VStack(alignment: .leading) {
                                    Text("Status")
                                    
                                    Toggle("Waiting", isOn: $showingWaiting)
                                    Toggle("Viewing", isOn: $showingViewing)
                                    Toggle("Dropped", isOn: $showingDropped)
                                    Toggle("Completed", isOn: $showingCompleted)
                                    Toggle("To view", isOn: $showingToView)
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
                    Text("Last local segment")
                        .frame(width: geo.size.width * 0.2, alignment: .leading)
                    Text("Last fetched segment")
                        .frame(width: geo.size.width * 0.2, alignment: .leading)
                    Text("Type")
                        .frame(width: 150, alignment: .leading)
                }
                .font(.headline)
                .padding()
                .padding(.horizontal)
                
                Divider()
                
                List(0..<filteredList.count, id: \.self) { index in
                    let favourite = filteredList[index]
                    
                    getListRow(favourite: favourite, index: index, geo: geo)
                }
                .onAppear {
                    favouritesVM.getFavourites()
                }
                .searchable(text: $searchQuery)
            }
        }
    }
    
    func getLastFetchedSegment(for mediaListElement: any MediaListElement) async -> String {
        guard let allLatestSegments = await favouritesVM.fetchLatestSegments(for: mediaListElement)?.content else {
            return "Error."
        }
        
        var currentLatestSegment = ""
        
        for source in allLatestSegments.values {
//            source.segments?.firstIndex(where: { mediaListElement.lastSegment == $0.title })
            
            /// This if statement checks if the current looped over source has chapters later than previous sources. Checks if:
            /// - The current latest segment exists in this source.
            /// - The last segment exists in this source (whether the source is empty).
            /// - The current latest segment is not the source last segment.
            if let currentLast = source.segments?.first(where: { $0.title == currentLatestSegment }),
               let sourceLast = source.segments?.last?.title,
               currentLast.title != sourceLast {
                currentLatestSegment = sourceLast
            } else if let sourceLast = source.segments?.last?.title, currentLatestSegment.isEmpty {
                currentLatestSegment = sourceLast
            }            
        }
        
        return currentLatestSegment
    }
    
    func getListRow(favourite: Favourite, index: Int, geo: GeometryProxy) -> some View {
        HStack {
            Text(favourite.mediaListElement.content.first?.value.title ?? "No title")
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)
            Text(favourite.mediaListElement.lastSegment ?? "No last segment")
                .frame(width: geo.size.width * 0.2, alignment: .leading)
                .lineLimit(2)
            Text((fetchedLatestChapters[index]) ?? "Loading")
                .frame(width: geo.size.width * 0.2, alignment: .leading)
                .lineLimit(2)
                .onAppear {
                    Task { @MainActor in
                        fetchedLatestChapters[index] = await getLastFetchedSegment(for: favourite.mediaListElement)
                    }
                }

            let color: Color = favourite.mediaListElement.type.getColor()

            Text(favourite.mediaListElement.type.rawValue)
                .foregroundColor(.white)
                .padding(3)
                .padding(.horizontal, 3)
                .background {
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundColor(color)
                }
                .frame(width: 100, alignment: .leading)

            Button {
                favouritesVM.unfavourite(favourite.mediaListElement)
            } label: {
                Image(systemName: "star.slash")
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .padding(.horizontal, 10)
        .background {
            RoundedRectangle(cornerRadius: 5)
                .foregroundColor(Color(nsColor: NSColor.textBackgroundColor))
                .shadow(radius: 2)
                .overlay(alignment: .leading) {
                    HStack {
                        let color: Color = favourite.loadingState?.getColor() ?? Color.blue

                        Rectangle()
                            .fill(color)
                            .frame(width: 5)

                        Spacer()
                    }
                    .frame(width: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .clipped()
                }
                .padding(.horizontal, 5)
        }
    }
}

struct FavouritesView_Previews: PreviewProvider {
    static var previews: some View {
        FavouritesView()
    }
}
