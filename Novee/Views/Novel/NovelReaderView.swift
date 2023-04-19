//
//  NovelReaderView.swift
//  Novee
//
//  Created by Nick on 2023-03-05.
//

import SwiftUI
import SystemNotification
import CachedAsyncImage

struct NovelReaderView: View {
    @EnvironmentObject var novelVM: NovelVM
    @EnvironmentObject var novelListVM: NovelListVM
    @EnvironmentObject var settingsVM: SettingsVM
    @StateObject var notification = SystemNotificationContext()
    
    @State private var zoom = 1.0
    @State private var showingDetailsSheet = false
    @State private var showingCustomizedAddToListSheet = false
    
    @State private var oldChapterTitle = ""
    
    @State private var selectedNovelStatus: Status = .viewing
    @State private var selectedNovelRating: Rating = .none
    @State private var selectedLastChapter: UUID = UUID()
    @State private var pickerSelectedChapterId: UUID = UUID()

    let novel: Novel
    @State var chapter: NovelChapter
    
    var selectedColorScheme: ColorScheme? {
        settingsVM.settings.novelSettings.colorScheme == .light ? .light : settingsVM.settings.novelSettings.colorScheme == .dark ? .dark : nil
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical) {                
                if let chapterContent = chapter.content {
                    Text(chapterContent)
                        .font(settingsVM.settings.novelSettings.selectedTheme?.font)
                        .lineSpacing(5)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .scaleEffect(CGSize(width: zoom, height: zoom))
                        .gesture(MagnificationGesture()
                                    .onChanged { value in
                                        zoom = value.magnitude
                                    }
                                    .onEnded { _ in
                                        zoom = 1.0
                                    }
                        )
                } else {
                    ProgressView()
                }
                
                changeChaptersView
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: chapter) { [chapter] newChapter in
                if chapter.id != newChapter.id {                    
                    Task {
                        await fetchContent()
                    }
                    
                    showUpdateChapterNotification(newChapter: newChapter)
                }
            }
        }
        .systemNotification(notification)
        .onAppear {
            if novelListVM.findInList(media: novel) == nil {
                showAddNovelNotification()
            } else {
                showUpdateChapterNotification(newChapter: chapter)
            }
            
            Task {
                await fetchContent()
            }
        }
        .sheet(isPresented: $showingDetailsSheet) {
            VStack {
                HStack {
                    CachedAsyncImage(url: novel.imageUrl) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipped()
                    } placeholder: {
                        ProgressView()
                    }
                    
                    VStack(alignment: .leading) {
                        Text(novel.title ?? "No title")
                            .font(.title2.bold())
                        Text(chapter.title)
                            .font(.headline)
                    }
                    
                    Spacer()
                }
                
                TabView {
                    NovelReaderSettingsView(novel: novel, chapter: chapter)
                        .tabItem {
                            Text("Reading options")
                        }

                    AddToListView(media: novel, segment: chapter)
                        .environmentObject(novelVM as MediaVM<Novel>)
                        .environmentObject(novelListVM as MediaListVM<NovelListElement>)
                        .tabItem {
                            Text("Novel list")
                        }
                }
            }
            .frame(width: 500, height: 300)
            .padding()
        }
        .sheet(isPresented: $showingCustomizedAddToListSheet) {
            AddToListView(media: novel, segment: chapter)
                .environmentObject(novelVM as MediaVM<Novel>)
                .environmentObject(novelListVM as MediaListVM<NovelListElement>)
        }
        .toolbar {
            // Some toolbar items to change chapter
            ToolbarItemGroup(placement: .primaryAction) {
                Spacer()
                
                Button(action: {
                    if let newChapter = novelVM.changeChapter(chapter: chapter, novel: novel, offset: -1) {
                        chapter = newChapter
                    }
                }, label: {
                    Image(systemName: "chevron.left")
                })
                .disabled(novel.segments?.first?.id == chapter.id)
                
                Button(action: {
                    if let newChapter = novelVM.changeChapter(chapter: chapter, novel: novel, offset: 1) {
                        chapter = newChapter
                    }
                }, label: {
                    Image(systemName: "chevron.right")
                })
                .disabled(novel.segments?.last?.id == chapter.id)
                
                Picker("Select chapter", selection: $pickerSelectedChapterId) {
                    ForEach(novel.segments ?? []) { chapter in
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
                    if let newChapter = novel.segments?.first(where: { $0.id == newChapterId }) {
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
        .background(settingsVM.settings.novelSettings.selectedTheme?.getBackgroundColor(settingsVM.settings.novelSettings.colorScheme))
        .navigationTitle(chapter.title)
    }
    
    var changeChaptersView: some View {
        HStack {
            Button {
                if let newChapter = novelVM.changeChapter(chapter: chapter, novel: novel, offset: -1) {
                    chapter = newChapter
                }
            } label: {
                HStack {
                    Text("Previous chapter")
                    Image(systemName: "arrow.left")
                }
            }
            .disabled(chapter.id == novel.segments?.first?.id)
            
            Button {
                if let newChapter = novelVM.changeChapter(chapter: chapter, novel: novel, offset: 1) {
                    chapter = newChapter
                }
            } label: {
                HStack {
                    Text("Next chapter")
                    Image(systemName: "arrow.right")
                }
            }
            .disabled(chapter.id == novel.segments?.last?.id)
        }
        .padding()
    }
    
    private func showAddNovelNotification() {
        notification.present(configuration: .init(duration: 15)) {
            VStack {
                VStack(alignment: .leading) {
                    Text("Add this novel to your list?")
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
                        novelListVM.addToList(
                            source: novelVM.selectedSource,
                            media: novel,
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
    
    private func showUpdateChapterNotification(newChapter: NovelChapter) {
        if let index = novelListVM.list.firstIndex(where: { $0.id == novelListVM.findInList(media: novel)?.id }) {
            oldChapterTitle = novelListVM.list[index].lastSegment ?? ""
            novelListVM.list[index].lastSegment = newChapter.title

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
                            novelListVM.list[index].lastSegment = oldChapterTitle
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
            print("Index in NovelReaderView onChange of chapter is nil!")
        }
    }
    
    private func fetchContent() async {
        chapter.content = nil
        
        chapter.content = await novelVM.sources[novelVM.selectedSource]!.getNovelContent(novel: novel, chapter: chapter)
    }
}

struct NovelReaderSettingsView: View {
    @EnvironmentObject var novelVM: NovelVM
    @EnvironmentObject var novelListVM: NovelListVM
    @EnvironmentObject var settingsVM: SettingsVM
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
        
    let novel: Novel
    let chapter: NovelChapter
    
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
                    
                    Picker("", selection: $settingsVM.settings.novelSettings.colorScheme) {
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
                                    settingsVM.settings.novelSettings.selectedThemeName = theme.name
                                } label: {
                                    ZStack {
                                        let backgroundColor: Color = theme.getBackgroundColor(settingsVM.settings.novelSettings.colorScheme) == .clear ? (colorScheme == .light ? Color.white : Color.black) : theme.getBackgroundColor(settingsVM.settings.novelSettings.colorScheme)
                                        let isSelected: Bool = settingsVM.settings.novelSettings.selectedTheme?.name == theme.name
                                        
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(backgroundColor)
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 4)
                                            }

                                        Text(theme.name)
                                            .font(theme.font)
                                            .foregroundColor(theme.getTextColor(settingsVM.settings.novelSettings.colorScheme))
                                    }
                                    .frame(height: 50)
                                }
                                .buttonStyle(.plain)
                            }
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
