//
//  MangaDetailsView.swift
//  Novee
//
//  Created by Nick on 2022-10-20.
//

import SwiftUI

struct MangaDetailsView: View {
    @EnvironmentObject var settingsVM: SettingsVM
    @State var manga: MangadexMangaData
    @State var collapsed = true
    
    var body: some View {
        GeometryReader { geo in
            ScrollView {
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
                    VStack(alignment: .leading) {
                        Text(LocalizedStringKey(MangaVM.getLocalisedString(manga.attributes.description, settingsVM: settingsVM))).lineLimit(collapsed ? 5 : nil)
                        Button(action: {
                            withAnimation {
                                collapsed.toggle()
                            }
                        }, label: {
                            Text(collapsed ? "More" : "Less")
                                .foregroundColor(.accentColor)
                        })
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
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
    static var previews: some View {
        MangaDetailsView(manga: MangadexMangaData(id: UUID(uuidString: "1cb98005-7bf9-488b-9d44-784a961ae42d")!, type: "Manga", attributes: MangadexMangaAttributes(title: ["en": "Test manga"], isLocked: false, originalLanguage: "jp", status: "Ongoing", createdAt: Date.distantPast, updatedAt: Date.now), relationships: [MangadexRelationship(id: UUID(), type: "cover_art", attributes: MangadexRelationshipAttributes(fileName: "9ab7ae43-9448-4f85-86d8-c661c6d23bbf.jpg"))]))
            .frame(width: 500, height: 625)
    }
}
