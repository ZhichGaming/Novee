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
    @StateObject var notification = SystemNotificationContext()
    
    @State private var zoom = 1.0
    @State private var showingDetailsSheet = false
    @State private var showingCustomizedAddToListSheet = false
    
    @State private var oldChapterTitle = ""
    
    @State private var selectedNovelStatus: BookStatus = .reading
    @State private var selectedNovelRating: BookRating = .none
    @State private var selectedLastChapter: UUID = UUID()
    @State private var pickerSelectedChapterId: UUID = UUID()

    let novel: Novel
    @State var chapter: NovelChapter

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical) {                
                if let chapterContent = chapter.content {
                    Text(chapterContent)
                        .font(.system(size: 16))
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
            if novelListVM.findInList(novel: novel) == nil {
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
                    NovelReaderDetailsView(novel: novel, chapter: chapter)
                        .tabItem {
                            Text("Reading options")
                        }

                    NovelReaderAddToListView(novel: novel, chapter: chapter)
                        .tabItem {
                            Text("Novel list")
                        }
                }
            }
            .frame(width: 500, height: 300)
            .padding()
        }
        .sheet(isPresented: $showingCustomizedAddToListSheet) {
            VStack {
                Text(novel.title ?? "No title")
                    .font(.headline)

                Group {
                    Picker("Status", selection: $selectedNovelStatus) {
                        ForEach(BookStatus.allCases, id: \.rawValue) {
                            Text($0.rawValue)
                                .tag($0)
                        }
                    }

                    Picker("Rating", selection: $selectedNovelRating) {
                        ForEach(BookRating.allCases, id: \.rawValue) {
                            Text($0.rawValue)
                                .tag($0)
                        }
                    }

                    Picker("Last chapter", selection: $selectedLastChapter) {
                        ForEach(novel.chapters ?? []) {
                            Text($0.title)
                                .tag($0.id)
                        }
                    }
                }

                HStack {
                    Spacer()
                    Button("Cancel", role: .cancel) {
                        showingCustomizedAddToListSheet = false
                    }

                    Button("Add to list") {
                        novelListVM.addToList(
                            source: novelVM.selectedSource,
                            novel: novel,
                            lastChapter: novel.chapters?.first { $0.id == selectedLastChapter }?.title ?? chapter.title,
                            status: selectedNovelStatus,
                            rating: selectedNovelRating,
                            lastReadDate: Date.now
                        )

                        showingCustomizedAddToListSheet = false
                    }
                }
            }
            .padding()
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
                .disabled(novel.chapters?.first?.id == chapter.id)
                
                Button(action: {
                    if let newChapter = novelVM.changeChapter(chapter: chapter, novel: novel, offset: 1) {
                        chapter = newChapter
                    }
                }, label: {
                    Image(systemName: "chevron.right")
                })
                .disabled(novel.chapters?.last?.id == chapter.id)
                
                Picker("Select chapter", selection: $pickerSelectedChapterId) {
                    ForEach(novel.chapters ?? []) { chapter in
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
                    if let newChapter = novel.chapters?.first(where: { $0.id == newChapterId }) {
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
            .disabled(chapter.id == novel.chapters?.first?.id)
            
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
            .disabled(chapter.id == novel.chapters?.last?.id)
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
                            novel: novel,
                            lastChapter: chapter.title,
                            status: .reading,
                            rating: .none,
                            lastReadDate: Date.now
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
        if let index = novelListVM.list.firstIndex(where: { $0.id == novelListVM.findInList(novel: novel)?.id }) {
            oldChapterTitle = novelListVM.list[index].lastChapter ?? ""
            novelListVM.list[index].lastChapter = newChapter.title

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
                            novelListVM.list[index].lastChapter = oldChapterTitle
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

struct NovelReaderDetailsView: View {
    @EnvironmentObject var novelVM: NovelVM
    @EnvironmentObject var novelListVM: NovelListVM
    
    @Environment(\.dismiss) var dismiss
    
    let novel: Novel
    let chapter: NovelChapter

    var body: some View {
        VStack {
            
        }
        .padding()
    }
}

struct NovelReaderAddToListView: View {
    @EnvironmentObject var novelVM: NovelVM
    @EnvironmentObject var novelListVM: NovelListVM

    @Environment(\.dismiss) var dismiss

    let novel: Novel
    var chapter: NovelChapter? = nil
    
    @State private var selectedNovelStatus: BookStatus = .reading
    @State private var selectedNovelRating: BookRating = .none
    @State private var selectedLastChapter: UUID = UUID()
    
    @State private var selectedNovelListElement: NovelListElement?
    
    @State private var createNewEntry = false
    
    @State private var selectedListItem = UUID()
    @State private var showingFindManuallyPopup = false
    
    var body: some View {
        HStack {
            VStack {
                Button("Add new entry") {
                    selectedNovelListElement = NovelListElement(novel: [:], status: .reading, rating: .none, creationDate: Date.now)
                    createNewEntry = true
                }
                                        
                Button("Find manually") {
                    showingFindManuallyPopup = true
                }
                .popover(isPresented: $showingFindManuallyPopup) {
                    VStack {
                        List(novelListVM.list.sorted { $0.novel.first?.value.title ?? "" < $1.novel.first?.value.title ?? "" }, id: \.id, selection: $selectedListItem) { item in
                            Text(item.novel.first?.value.title ?? "No title")
                                .tag(item.id)
                        }
                        .listStyle(.bordered(alternatesRowBackgrounds: true))
                        
                        Text("Type in the list to search.")
                        
                        HStack {
                            Spacer()
                            
                            Button("Cancel") { showingFindManuallyPopup = false }
                            Button("Select") {
                                selectedNovelListElement = novelListVM.list.first(where: { $0.id == selectedListItem })
                                showingFindManuallyPopup = false
                            }
                            .disabled(!novelListVM.list.contains { $0.id == selectedListItem })
                        }
                    }
                    .frame(width: 400, height: 300)
                    .padding()
                }
                
                Spacer()
                Text(novelListVM.findInList(novel: novel)?.novel.first?.value.title ?? "Novel not found")
                
                if let url = novelListVM.findInList(novel: novel)?.novel.first?.value.imageUrl {
                    CachedAsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                }
                
                Spacer()
            }
            
            Divider()
                .padding(.horizontal)
            
            VStack {
                Text("Novel options")

                Group {
                    Picker("Status", selection: $selectedNovelStatus) {
                        ForEach(BookStatus.allCases, id: \.rawValue) {
                            Text($0.rawValue)
                                .tag($0)
                        }
                    }
                    
                    Picker("Rating", selection: $selectedNovelRating) {
                        ForEach(BookRating.allCases, id: \.rawValue) {
                            Text($0.rawValue)
                                .tag($0)
                        }
                    }
                    
                    Picker("Last chapter", selection: $selectedLastChapter) {
                        ForEach(novel.chapters ?? []) {
                            Text($0.title)
                                .tag($0.id)
                        }
                    }
                }
                .disabled(selectedNovelListElement == nil)
                
                HStack {
                    Spacer()
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                    
                    Button(createNewEntry ? "Add to list" : "Save") {
                        if createNewEntry {
                            novelListVM.addToList(
                                source: novelVM.selectedSource,
                                novel: novel,
                                lastChapter: novel.chapters?.first { $0.id == selectedLastChapter }?.title ?? chapter?.title,
                                status: selectedNovelStatus,
                                rating: selectedNovelRating,
                                lastReadDate: Date.now
                            )
                        } else {
                            novelListVM.updateListEntry(
                                id: selectedNovelListElement!.id,
                                newValue: NovelListElement(
                                    novel: [novelVM.selectedSource: novel],
                                    lastChapter: novel.chapters?.first { $0.id == selectedLastChapter }?.title ?? chapter?.title,
                                    status: selectedNovelStatus,
                                    rating: selectedNovelRating,
                                    lastReadDate: Date.now,
                                    creationDate: Date.now
                                )
                            )
                        }
                        
                        dismiss()
                    }
                    .disabled(selectedNovelListElement == nil)
                }
            }
        }
        .padding()
        .onAppear {
            selectedNovelListElement = novelListVM.findInList(novel: novel)
        }
        .onChange(of: selectedNovelListElement) { _ in
            if let selectedNovelListElement = selectedNovelListElement {
                selectedNovelStatus = selectedNovelListElement.status
                selectedNovelRating = selectedNovelListElement.rating
                
                selectedLastChapter = novel.chapters?.first { $0.title == selectedNovelListElement.lastChapter }?.id ?? UUID()
            }
        }
    }
}
