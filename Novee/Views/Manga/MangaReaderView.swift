//
//  MangaReaderView.swift
//  Novee
//
//  Created by Nick on 2022-10-26.
//

import SwiftUI
import CachedAsyncImage
import SystemNotification

struct MangaReaderView: View {
    @EnvironmentObject var mangaVM: MangaVM
    @EnvironmentObject var mangaListVM: MangaListVM
    @EnvironmentObject var settingsVM: SettingsVM
    @StateObject var notification = SystemNotificationContext()
    
    @State private var zoom = 1.0
    @State private var showingDetailsSheet = false
    @State private var showingCustomizedAddToListSheet = false
    
    @State private var oldChapterTitle = ""
    
    @State private var selectedMangaStatus: Status = .viewing
    @State private var selectedMangaRating: Rating = .none
    @State private var selectedLastChapter: UUID = UUID()
    @State private var pickerSelectedChapterId: UUID = UUID()

    let manga: Manga
    @State var chapter: Chapter
    
    var selectedColorScheme: ColorScheme? {
        settingsVM.settings.mangaSettings.colorScheme == .light ? .light : settingsVM.settings.mangaSettings.colorScheme == .dark ? .dark : nil
    }

    var body: some View {
        GeometryReader { geometry in
            Group {
                switch settingsVM.settings.mangaSettings.navigationType {
                case .scroll:
                    MangaReaderScrollReaderView(geometry: geometry, manga: manga, chapter: $chapter)
                case .singlePage:
                    MangaReaderSinglePageReaderView(geometry: geometry, manga: manga, chapter: $chapter)
                case .doublePage:
                    MangaReaderDoublePageReaderView(geometry: geometry, manga: manga, chapter: $chapter)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: chapter) { [chapter] newChapter in
                if chapter.id != newChapter.id {
                    Task {
                        await fetchImages()
                    }
                    
                    showUpdateChapterNotification(newChapter: newChapter)
                }
            }
        }
        .systemNotification(notification)
        .onAppear {
            if mangaListVM.findInList(media: manga) == nil {
                showAddMangaNotification()
            } else {
                showUpdateChapterNotification(newChapter: chapter)
            }
            
            Task {
                await fetchImages()
            }
        }
        .sheet(isPresented: $showingDetailsSheet) {
            VStack {
                HStack {
                    CachedAsyncImage(url: manga.imageUrl) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipped()
                    } placeholder: {
                        ProgressView()
                    }
                    
                    VStack(alignment: .leading) {
                        Text(manga.title ?? "No title")
                            .font(.title2.bold())
                        Text(chapter.title)
                            .font(.headline)
                    }
                    
                    Spacer()
                }
                
                TabView {
                    MangaReaderSettingsView(manga: manga, chapter: chapter)
                        .tabItem {
                            Text("Reading options")
                        }
                    
                    AddToListView(media: manga, segment: chapter)
                        .environmentObject(mangaVM as MediaVM<Manga>)
                        .environmentObject(mangaListVM as MediaListVM<MangaListElement>)
                        .tabItem {
                            Text("Manga list")
                        }
                }
                
                HStack {
                    Spacer()
                    Button("Dismiss") {
                        showingDetailsSheet = false
                    }
                }
            }
            .frame(width: 500, height: 300)
            .padding()
        }
        .sheet(isPresented: $showingCustomizedAddToListSheet) {
            AddToListView(media: manga, segment: chapter)
                .environmentObject(mangaVM as MediaVM<Manga>)
                .environmentObject(mangaListVM as MediaListVM<MangaListElement>)
        }
        .toolbar {
            // Some toolbar items to change chapter
            ToolbarItemGroup(placement: .primaryAction) {
                Spacer()
                
                Button(action: {
                    if let newChapter = mangaVM.changeChapter(chapter: chapter, manga: manga, offset: -1) {
                        chapter = newChapter
                    }
                }, label: {
                    Image(systemName: "chevron.left")
                })
                .disabled(manga.segments?.first?.id == chapter.id)
                
                Button(action: {
                    if let newChapter = mangaVM.changeChapter(chapter: chapter, manga: manga, offset: 1) {
                        chapter = newChapter
                    }
                }, label: {
                    Image(systemName: "chevron.right")
                })
                .disabled(manga.segments?.last?.id == chapter.id)
                
                Picker("Select chapter", selection: $pickerSelectedChapterId) {
                    ForEach(manga.segments ?? []) { chapter in
                        Text(chapter.title)
                            .tag(chapter.id)
                    }
                }
                .frame(maxWidth: 300)
                .onAppear {
                    pickerSelectedChapterId = chapter.id
                }
                .onChange(of: chapter) { newChapter in
                    pickerSelectedChapterId = newChapter.id
                }
                .onChange(of: pickerSelectedChapterId) { newChapterId in
                    if let newChapter = manga.segments?.first(where: { $0.id == newChapterId }) {
                        chapter = newChapter
                    }
                }
            }
            
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    showingDetailsSheet = true
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .preferredColorScheme(selectedColorScheme)
        .background(settingsVM.settings.mangaSettings.selectedTheme?.backgroundColor)
        .navigationTitle(chapter.title)
    }
    
    private func showAddMangaNotification() {
        notification.present(configuration: .init(duration: 15)) {
            VStack {
                VStack(alignment: .leading) {
                    Text("Add this manga to your list?")
                        .font(.footnote.bold())
                        .foregroundColor(.primary.opacity(0.6))
                    Text("Swipe to dismiss")
                        .font(.footnote.bold())
                        .foregroundColor(.primary.opacity(0.4))
                }
                .frame(width: 225, alignment: .leading)

                HStack {
                    Button {
                        showingCustomizedAddToListSheet = true
                        notification.dismiss()
                    } label: {
                        Text("Add with options")
                    }
                    
                    Button {
                        mangaListVM.addToList(
                            source: mangaVM.selectedSource,
                            media: manga,
                            lastSegment: chapter.title,
                            status: .viewing,
                            rating: .none,
                            lastViewedDate: Date.now
                        )
                        
                        notification.dismiss()
                    } label: {
                        Text("Add")
                    }
                    .keyboardShortcut(.defaultAction)
                }
                .frame(width: 225, alignment: .trailing)
            }
            .frame(width: 300, height: 75)
        }
    }
    
    private func showUpdateChapterNotification(newChapter: Chapter) {
        if let index = mangaListVM.list.firstIndex(where: { $0.id == mangaListVM.findInList(media: manga)?.id }) {
            oldChapterTitle = mangaListVM.list[index].lastSegment ?? ""
            mangaListVM.list[index].lastSegment = newChapter.title
            
            notification.present {
                VStack {
                    VStack(alignment: .leading) {
                        Text("Last read chapter updated!")
                            .font(.footnote.bold())
                            .foregroundColor(.primary.opacity(0.6))
                        Text("Swipe to dismiss")
                            .font(.footnote.bold())
                            .foregroundColor(.primary.opacity(0.4))
                    }
                    .frame(width: 225, alignment: .leading)

                    HStack {
                        Button {
                            mangaListVM.list[index].lastSegment = oldChapterTitle
                            notification.dismiss()
                        } label: {
                            Text("Undo")
                        }
                        .keyboardShortcut(.defaultAction)
                    }
                    .frame(width: 225, alignment: .trailing)
                }
                .frame(width: 300, height: 75)
            }
        } else {
            print("Index in MangaReaderView onChange of chapter is nil!")
        }
    }
    
    private func fetchImages() async {
        chapter.images = [:]
        
        await mangaVM.sources[mangaVM.selectedSource]!.getMangaPages(manga: manga, chapter: self.chapter) { index, nsImage in
            Task { @MainActor in
                chapter.images?[index] = nsImage
            }
        }
    }
}

struct MangaReaderScrollReaderView: View {
    @EnvironmentObject var mangaVM: MangaVM
    @EnvironmentObject var mangaListVM: MangaListVM
    @EnvironmentObject var settingsVM: SettingsVM
    
    let geometry: GeometryProxy
    
    let manga: Manga
    @Binding var chapter: Chapter
    
    var body: some View {
        ScrollView(.vertical) {
            if let images = chapter.images {
                VStack(spacing: 0) {
                    ForEach(0..<images.keys.count, id: \.self) { index in
                        if let currentImageElement = images[index] {
                            switch currentImageElement.loadingState {
                            case .success:
                                if let image = images.first { $0.key == index }?.value.image {
                                    MangaReaderImageView(
                                        nsImage: image,
                                        imageFit: settingsVM.settings.mangaSettings.imageFitOption,
                                        geometry: geometry)
                                }
                            case .failed:
                                Button("Failed to fetch image.") {
                                    Task { @MainActor in
                                        await mangaVM.sources[mangaVM.selectedSource]!
                                            .refetchMangaPage(chapter: chapter, pageIndex: index) { image in
                                                Task { @MainActor in
                                                    chapter.images?[index] = image
                                                }
                                            }
                                    }
                                }
                            case .loading:
                                ProgressView()
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
            
            changeChaptersView
        }
    }
    
    var changeChaptersView: some View {
        HStack {
            Button {
                if let newChapter = mangaVM.changeChapter(chapter: chapter, manga: manga, offset: -1) {
                    chapter = newChapter
                }
            } label: {
                HStack {
                    Text("Previous chapter")
                    Image(systemName: "arrow.left")
                }
            }
            .disabled(chapter.id == manga.segments?.first?.id)
            
            Button {
                if let newChapter = mangaVM.changeChapter(chapter: chapter, manga: manga, offset: 1) {
                    chapter = newChapter
                }
            } label: {
                HStack {
                    Text("Next chapter")
                    Image(systemName: "arrow.right")
                }
            }
            .disabled(chapter.id == manga.segments?.last?.id)
        }
        .padding()
    }
}

struct MangaReaderSinglePageReaderView: View {
    @EnvironmentObject var mangaVM: MangaVM
    @EnvironmentObject var mangaListVM: MangaListVM
    @EnvironmentObject var settingsVM: SettingsVM
    
    let geometry: GeometryProxy
    
    let manga: Manga
    @Binding var chapter: Chapter
    @State var currentImageIndex: Int = 0
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                if let nsImage = chapter.images?.first { $0.key == currentImageIndex }?.value.image {
                    MangaReaderImageView(nsImage: nsImage, imageFit: settingsVM.settings.mangaSettings.imageFitOption, geometry: geometry)
                        .id("top")
                        .tag("top")
                        .overlay {
                            MangaReaderImageChangerOverlay(geometry: geometry, proxy: proxy, manga: manga, chapter: $chapter, currentImageIndex: $currentImageIndex)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .onAppear {
            currentImageIndex = chapter.images?.first?.key ?? currentImageIndex
        }
    }
}

struct MangaReaderDoublePageReaderView: View {
    @EnvironmentObject var mangaVM: MangaVM
    @EnvironmentObject var mangaListVM: MangaListVM
    @EnvironmentObject var settingsVM: SettingsVM
    
    let geometry: GeometryProxy
    
    let manga: Manga
    @Binding var chapter: Chapter
    @State var currentImageIndex: Int = 0
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                HStack {
                    if settingsVM.settings.mangaSettings.readingDirection == .leftToRight {
                        if let nsImage = chapter.images?.first { $0.key == (currentImageIndex * 2) }?.value.image {
                            MangaReaderImageView(nsImage: nsImage, imageFit: settingsVM.settings.mangaSettings.imageFitOption, geometry: geometry)
                        }
                        
                        if let nsImage = chapter.images?.first { $0.key == (currentImageIndex * 2 + 1) }?.value.image {
                            MangaReaderImageView(nsImage: nsImage, imageFit: settingsVM.settings.mangaSettings.imageFitOption, geometry: geometry)
                        }
                    } else {
                        if let nsImage = chapter.images?.first { $0.key == (currentImageIndex * 2 + 1) }?.value.image {
                            MangaReaderImageView(nsImage: nsImage, imageFit: settingsVM.settings.mangaSettings.imageFitOption, geometry: geometry)
                        }
                        
                        if let nsImage = chapter.images?.first { $0.key == (currentImageIndex * 2) }?.value.image {
                            MangaReaderImageView(nsImage: nsImage, imageFit: settingsVM.settings.mangaSettings.imageFitOption, geometry: geometry)
                        }
                    }
                }
                .id("top")
                .tag("top")
                .overlay {
                    MangaReaderImageChangerOverlay(isDoublePage: true, geometry: geometry, proxy: proxy, manga: manga, chapter: $chapter, currentImageIndex: $currentImageIndex)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            currentImageIndex = chapter.images?.first?.key ?? currentImageIndex
        }
    }
}

struct MangaReaderImageChangerOverlay: View {
    @EnvironmentObject var mangaVM: MangaVM
    @EnvironmentObject var mangaListVM: MangaListVM
    @EnvironmentObject var settingsVM: SettingsVM
    
    var isDoublePage = false
    
    let geometry: GeometryProxy
    let proxy: ScrollViewProxy
    let manga: Manga
    
    @Binding var chapter: Chapter
    @Binding var currentImageIndex: Int
    
    var body: some View {
        ZStack {
            Button {
                if settingsVM.settings.mangaSettings.readingDirection == .leftToRight {
                    previousPage()
                } else {
                    nextPage()
                }
                
                proxy.scrollTo("top", anchor: .top)
            } label: {
                
            }
            .padding(0)
            .opacity(0)
            .frame(width: 0, height: 0)
            .keyboardShortcut(.leftArrow, modifiers: [])
            
            Button {
                if settingsVM.settings.mangaSettings.readingDirection == .leftToRight {
                    nextPage()
                } else {
                    previousPage()
                }
                
                proxy.scrollTo("top", anchor: .top)
            } label: {
                
            }
            .padding(0)
            .opacity(0)
            .frame(width: 0, height: 0)
            .keyboardShortcut(.rightArrow, modifiers: [])
            
            Button {
                nextPage()
                
                proxy.scrollTo("top", anchor: .top)
            } label: {
                
            }
            .padding(0)
            .opacity(0)
            .frame(width: 0, height: 0)
            .keyboardShortcut(.space, modifiers: [])
            
            HStack {
                Button {
                    if settingsVM.settings.mangaSettings.readingDirection == .leftToRight {
                        previousPage()
                    } else {
                        nextPage()
                    }
                    
                    proxy.scrollTo("top", anchor: .top)
                } label: {
                    Color.clear
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(width: geometry.size.width * 0.5)
                
                Button {
                    if settingsVM.settings.mangaSettings.readingDirection == .leftToRight {
                        nextPage()
                    } else {
                        previousPage()
                    }
                    
                    proxy.scrollTo("top", anchor: .top)
                } label: {
                    Color.clear
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(width: geometry.size.width * 0.5)
            }
        }
    }
    
    private func previousPage() {
        if currentImageIndex <= 0 {
            if let newChapter = mangaVM.changeChapter(chapter: chapter, manga: manga, offset: -1) {
                chapter = newChapter
                currentImageIndex = 0
            }
        } else {
            currentImageIndex -= 1
        }
    }
    
    private func nextPage() {
        let doubleAndSingleImageIndex = isDoublePage ? currentImageIndex * 2 + 1 : currentImageIndex
        
        if doubleAndSingleImageIndex >= (chapter.images?.count ?? (doubleAndSingleImageIndex + 1)) - 1 {
            if let newChapter = mangaVM.changeChapter(chapter: chapter, manga: manga, offset: 1) {
                chapter = newChapter
                currentImageIndex = 0
            }
        } else {
            currentImageIndex += 1
        }
    }
}

struct MangaReaderImageView: View {
    let nsImage: NSImage
    let imageFit: MangaSettings.ImageFitOption
    let geometry: GeometryProxy
    
    var image: Image {
        Image(nsImage: nsImage)
    }

    var body: some View {
        switch imageFit {
        case .fit:
            image
                .resizable()
                .scaledToFit()
                .frame(height: geometry.size.height)
        case .fill:
            image
                .resizable()
                .scaledToFill()
        case .original:
            image
                .resizable()
                .aspectRatio(contentMode: nsImage.size.width > geometry.size.width ? .fit : .fill)
                .frame(maxWidth: nsImage.size.width < geometry.size.width ? nsImage.size.width : geometry.size.width)
        }
    }
}

struct MangaReaderSettingsView: View {
    @EnvironmentObject var mangaVM: MangaVM
    @EnvironmentObject var mangaListVM: MangaListVM
    @EnvironmentObject var settingsVM: SettingsVM
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
        
    let manga: Manga
    let chapter: Chapter
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    Text("Color scheme")
                        .font(.headline)
                    
                    Picker("", selection: $settingsVM.settings.mangaSettings.colorScheme) {
                        ForEach(NoveeColorScheme.allCases, id: \.self) { scheme in
                            Text(scheme.rawValue)
                        }
                    }
                }
                .padding(.bottom)

                VStack(alignment: .leading) {
                    Text("Themes")
                        .font(.headline)
                    
                    HStack {
                        LazyVGrid(columns: columns) {
                            ForEach(Theme.themes, id: \.self) { theme in
                                Button {
                                    settingsVM.settings.mangaSettings.selectedThemeName = theme.name
                                } label: {
                                    ZStack {
                                        let backgroundColor: Color = theme.backgroundColor == .clear ? (colorScheme == .light ? Color.white : Color.black) : theme.backgroundColor
                                        let isSelected: Bool = settingsVM.settings.mangaSettings.selectedTheme?.name == theme.name
                                        
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(backgroundColor)
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 4)
                                            }

                                        Text(theme.name)
                                            .font(theme.font)
                                            .foregroundColor(theme.textColor)
                                    }
                                    .frame(height: 50)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.bottom)

                VStack(alignment: .leading) {
                    Text("Image fit option")
                        .font(.headline)
                    
                    Picker("", selection: $settingsVM.settings.mangaSettings.imageFitOption) {
                        ForEach(MangaSettings.ImageFitOption.allCases, id: \.self) { option in
                            Text(option.rawValue)
                        }
                    }
                }
                .padding(.bottom)

                VStack(alignment: .leading) {
                    Text("Navigation type")
                        .font(.headline)
                    
                    Picker("", selection: $settingsVM.settings.mangaSettings.navigationType) {
                        ForEach(MangaSettings.NavigationType.allCases, id: \.self) { type in
                            Text(type.rawValue)
                        }
                    }
                }
                .padding(.bottom)

                VStack(alignment: .leading) {
                    Text("Reading direction")
                        .font(.headline)
                    
                    Picker("", selection: $settingsVM.settings.mangaSettings.readingDirection) {
                        ForEach(MangaSettings.ReadingDirection.allCases, id: \.self) { direction in
                            Text(direction.rawValue)
                        }
                    }
                }
                .padding(.bottom)
            }
            .padding()
            .pickerStyle(.segmented)
        }
    }
}
