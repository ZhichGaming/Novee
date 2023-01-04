//
//  MangaListView.swift
//  Novee
//
//  Created by Nick on 2023-01-03.
//

import SwiftUI

struct MangaListView: View {
    @EnvironmentObject var mangaListVM: MangaListVM
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
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
            Text(manga.manga.first?.title ?? "No title")
                .frame(width: geo.size.width * 0.3, alignment: .leading)
            Text(manga.lastChapter ?? "No last chapter")
                .frame(width: geo.size.width * 0.2, alignment: .leading)
            Text(manga.status.rawValue)
                .foregroundColor(.white)
                .padding(3)
                .padding(.horizontal, 3)
                .background {
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundColor(getStatusColor(for: manga))
                }
                .frame(width: geo.size.width * 0.2, alignment: .leading)
            Text(manga.rating?.rawValue ?? "No rating")
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
    
    private func getStatusColor(for: MangaListElement) -> Color {
        switch manga.status {
        case .completed:
            return Color.green
        case .dropped:
            return Color.red
        case .reading:
            return Color.orange
        case .waiting:
            return Color.yellow
        case .toRead:
            return Color.purple
        }
    }
}

struct MangaListView_Previews: PreviewProvider {
    static var previews: some View {
        MangaListView()
    }
}
