//
//  MangaDetailsView.swift
//  Novee
//
//  Created by Nick on 2022-10-20.
//

import SwiftUI

struct MangaDetailsView: View {
    @EnvironmentObject var mangaVM: MangaVM
    @EnvironmentObject var settingsVM: SettingsVM
    
    @State var mangaId: UUID
    @State var collapsed = true
    @State var descriptionSize: CGSize = .zero
    
    @Binding var openedManga: MangadexMangaData?
    @Binding var openedChapter: MangadexChapter?

    var manga: MangadexMangaData {
        mangaVM.mangadexManga.first { $0.id == mangaId }!
    }
    
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Text(MangaVM.getLocalisedString(manga.attributes.title, settingsVM: settingsVM))
                            .font(.largeTitle)
                        Text(LocalizedStringKey("**Alternative titles:** \(getAltTitles())"))
                        TagView(tags: getTags())
                    }
                    Spacer()
                    AsyncImage(url: URL(string: "https://uploads.mangadex.org/covers/\(manga.id.uuidString.lowercased())/\(manga.relationships.first { $0?.type == "cover_art" }!!.attributes!.fileName!).256.jpg")) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(maxWidth: geo.size.width * 0.4, maxHeight: geo.size.height * 0.4)
                    .clipped()
                }
                Divider()
                ScrollView {
                    Text(LocalizedStringKey(MangaVM.getLocalisedString(manga.attributes.description, settingsVM: settingsVM)))
                        .background {
                            GeometryReader { textSize -> Color in
                                DispatchQueue.main.async {
                                    descriptionSize = textSize.size
                                }
                                return Color.clear
                            }
                        }
                }
                .frame(maxHeight: descriptionSize.height > 200 ? 200 : descriptionSize.height, alignment: .leading)
                
                Divider()
            
                VStack(alignment: .leading) {
                    Text("Chapters")
                        .font(.headline)
                    if manga.chapters != nil {
                        ChapterList(manga: manga, openedManga: $openedManga, openedChapter: $openedChapter)
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding()
        }
        .onAppear {
            mangaVM.getChapters(manga: manga.id)
        }
    }
    
    func getAltTitles() -> String {
        var titles: [String] = []
        
        if manga.attributes.altTitles != nil {
            for altTitle in manga.attributes.altTitles! {
                for value in altTitle.values {
                    titles.append(value)
                }
            }
        } else {
            return "None"
        }
        
        return titles.joined(separator: ", ")
    }
    
    func getTags() -> [String] {
        var tags: [String] = []
        
        if manga.attributes.tags != nil {
            for tag in manga.attributes.tags! {
                tags.append(MangaVM.getLocalisedString(tag.attributes.name, settingsVM: settingsVM))
            }
        } else {
            return ["No tags"]
        }
        
        return tags
    }
}

struct ChapterList: View {
    @State var selected: UUID?

    var manga: MangadexMangaData
    @Binding var openedManga: MangadexMangaData?
    @Binding var openedChapter: MangadexChapter?

    var body: some View {
        List(getSortedChapters()) { chapter in
            VStack(alignment: .leading) {
                HStack {
                    Text("Chapter \(chapter.attributes.chapter ?? "") (\(Language.getValue(chapter.attributes.translatedLanguage.uppercased()) ?? "\(chapter.attributes.translatedLanguage)"))")
                        .font(selected == Optional(chapter.id) ? .headline : nil)
                    Spacer()
                }
                
                if selected == Optional(chapter.id) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Translation group(s)")
                                .font(.callout)
                            Spacer()
                            if !chapter.relationships.filter { $0.type == "scanlation_group" }.isEmpty {
                                ForEach(chapter.relationships.filter { $0.type == "scanlation_group" }) { group in
                                    if let url = URL(string: group.attributes?.website ?? "") {
                                        Link(group.attributes?.name ?? "Unknown", destination: url)
                                    } else {
                                        Text(group.attributes?.name ?? "None")
                                    }
                                }
                            } else {
                                Text("None")
                            }
                        }
                        HStack {
                            Text("Upload date")
                                .font(.callout)
                            Spacer()
                            Text(chapter.attributes.publishAt.formatted(date: .abbreviated, time: .shortened))
                        }

                        Button("Read") {
                            openedManga = manga
                            openedChapter = chapter
                            if let url = URL(string: "novee://mangaReader") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .onTapGesture {
                selected = chapter.id
            }
        }
        .listStyle(.bordered(alternatesRowBackgrounds: true))
    }
    
    func getSortedChapters() -> [MangadexChapter] {
        var sortedChapters: [MangadexChapter]
        sortedChapters = manga.chapters!.sorted(by: { chapter1, chapter2 in
            guard let verifiedString1 = Double(chapter1.attributes.chapter ?? "0") else {
                return chapter1.attributes.chapter ?? "" <= chapter2.attributes.chapter ?? ""
            }
            guard let verifiedString2 = Double(chapter2.attributes.chapter ?? "0") else {
                return chapter1.attributes.chapter ?? "" <= chapter2.attributes.chapter ?? ""
            }
            
            return verifiedString1 <= verifiedString2
        })
        
        return sortedChapters
    }
}

struct TagView: View {
    var tags: [String]

    @State private var totalHeight
          = CGFloat.zero       // << variant for ScrollView/List
    //    = CGFloat.infinity   // << variant for VStack

    var body: some View {
        VStack {
            GeometryReader { geometry in
                self.generateContent(in: geometry)
            }
        }
        .frame(height: totalHeight)// << variant for ScrollView/List
        //.frame(maxHeight: totalHeight) // << variant for VStack
    }

    private func generateContent(in g: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            ForEach(self.tags, id: \.self) { tag in
                self.item(for: tag)
                    .padding([.horizontal, .vertical], 4)
                    .alignmentGuide(.leading, computeValue: { d in
                        if (abs(width - d.width) > g.size.width)
                        {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if tag == self.tags.last! {
                            width = 0 //last item
                        } else {
                            width -= d.width
                        }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: {d in
                        let result = height
                        if tag == self.tags.last! {
                            height = 0 // last item
                        }
                        return result
                    })
            }
        }.background(viewHeightReader($totalHeight))
    }

    private func item(for text: String) -> some View {
        Text(text)
            .padding(.all, 5)
            .font(.body)
            .background(Color.blue)
            .foregroundColor(Color.white)
            .cornerRadius(5)
    }

    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        return GeometryReader { geometry -> Color in
            let rect = geometry.frame(in: .local)
            DispatchQueue.main.async {
                binding.wrappedValue = rect.size.height
            }
            return .clear
        }
    }
}

struct MangaDetailsView_Previews: PreviewProvider {
    static let mangaVM = [MangadexMangaData(id: UUID(uuidString: "1cb98005-7bf9-488b-9d44-784a961ae42d")!, type: "Manga", attributes: MangadexMangaAttributes(title: ["en": "Test manga"], isLocked: false, originalLanguage: "jp", status: "Ongoing", createdAt: Date.distantPast, updatedAt: Date.now), relationships: [MangadexRelationship(id: UUID(), type: "cover_art", attributes: MangadexRelationshipAttributes(fileName: "9ab7ae43-9448-4f85-86d8-c661c6d23bbf.jpg"))], chapters: [MangadexChapter(id: UUID(uuidString: "29bfff23-c550-4a29-b65e-6f0a7b6c8574")!, type: "chapter", attributes: MangadexChapterAttributes(volume: "1", chapter: "1", title: nil, translatedLanguage: "en", externalUrl: nil, publishAt: Date.distantPast), relationships: [])])]

    static var previews: some View {
        MangaDetailsView(mangaId: UUID(uuidString: "1cb98005-7bf9-488b-9d44-784a961ae42d")!, openedManga: .constant(mangaVM[0]), openedChapter: .constant(mangaVM[0].chapters![0]))
            .frame(width: 500, height: 625)
    }
}
