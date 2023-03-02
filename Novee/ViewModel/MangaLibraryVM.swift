//
//  MangaLibraryVM.swift
//  Novee
//
//  Created by Nick on 2023-03-01.
//

import Foundation
import AppKit

class MangaLibraryVM: ObservableObject {
    static let shared = MangaLibraryVM()
    
    @Published var mangaData: [LocalManga] = []
    
    init() {
        load()
    }
    
    func load() {
        do {
            mangaData = []
            
            for directory in try FileManager().contentsOfDirectory(atPath: URL.mangaStorageUrl.path).filteredDS_Store() {
                var localManga = LocalManga()
                
                if let imageData = FileManager().contents(atPath: "\(URL.mangaStorageUrl.path)/\(directory)/thumbnail.png") {
                    localManga.image = NSImage(data: imageData)
                }
                
                localManga.title = directory
                
                for chapterName in try FileManager().contentsOfDirectory(atPath: "\(URL.mangaStorageUrl.path)/\(directory)").filter({
                    var isDirectory: ObjCBool = true
                    let exists = FileManager.default.fileExists(atPath:"\(URL.mangaStorageUrl.path)/\(directory)/\($0)", isDirectory: &isDirectory)
                    return exists && isDirectory.boolValue
                }) {
                    var chapter = LocalChapter()
                    
                    chapter.title = chapterName
                    
                    for pageName in try FileManager()
                        .contentsOfDirectory(
                            atPath: "\(URL.mangaStorageUrl.path)/\(directory)/\(chapterName)"
                        ).filteredDS_Store() {
                        if let imageData = FileManager()
                            .contents(
                                atPath: "\(URL.mangaStorageUrl.path)/\(directory)/\(chapterName)/\(pageName)"),
                            let image = NSImage(data: imageData) {
                            
                            if let integerPageNumber = Int((pageName as NSString).deletingPathExtension) {
                                chapter.images[integerPageNumber] = image
                            }
                        }
                    }
                    
                    localManga.chapters.append(chapter)
                }
                
                mangaData.append(localManga)
            }
        } catch {
            Log.shared.error(error)
        }
    }
}

struct LocalManga: Hashable, Identifiable {
    let id = UUID()
    
    var title: String?
    var image: NSImage?
    var chapters: [LocalChapter] = []
}

struct LocalChapter: Hashable, Identifiable {
    let id = UUID()
    
    var title: String?
    var images: [Int:NSImage] = [:]
}
