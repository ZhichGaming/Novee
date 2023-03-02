//
//  Extentions.swift
//  Novee
//
//  Created by Nick on 2022-12-26.
//

import Foundation
import SwiftUI

func ??<T>(lhs: Binding<Optional<T>>, rhs: T) -> Binding<T> {
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
}

extension URL {
    func getFinalURL() -> URL? {
        var request = URLRequest(url: self)
        request.httpMethod = "HEAD"
        var finalURL: URL? = nil
        let semaphore = DispatchSemaphore(value: 0)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                finalURL = httpResponse.url
            }
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: .distantFuture)
        return finalURL
    }
}

extension View {
    private func newWindowInternal(with title: String) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 20, y: 20, width: 1000, height: 625),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false)
        window.center()
        window.isReleasedWhenClosed = false
        window.title = title
        window.makeKeyAndOrderFront(nil)
        return window
    }
    
    func openNewWindow(with title: String = "new Window") {
        self.newWindowInternal(with: title).contentView = NSHostingView(rootView: self)
    }
}

extension MangaStatus {
    func getStatusColor() -> Color {
        switch self {
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

extension AnimeStatus {
    func getStatusColor() -> Color {
        switch self {
        case .completed:
            return Color.green
        case .dropped:
            return Color.red
        case .watching:
            return Color.orange
        case .waiting:
            return Color.yellow
        case .toWatch:
            return Color.purple
        }
    }
}

extension NSImage {
    func pngData() -> Data? {
        if let tiffRepresentation = self.tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) {
            return bitmapImage.representation(using: .png, properties: [:])
        }
        
        return nil
    }
}

extension String {
    func sanitized() -> String {
        let invalidCharacters = CharacterSet(charactersIn: "\\/:*?\"<>|")
            .union(.newlines)
            .union(.illegalCharacters)
            .union(.controlCharacters)
        
        return self
            .components(separatedBy: invalidCharacters)
            .joined(separator: "")
    }
    
    mutating func sanitize() -> Void {
        self = self.sanitized()
    }
}

extension String {
    var sanitizedFileName: String {
        return components(separatedBy: .init(charactersIn: "/:?%*|\"<>")).joined()
    }
}

extension [String] {
    func filteredDS_Store() -> [String] {
        return self.filter { $0 != ".DS_Store" }
    }
}

extension URL {
    static let applicationSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    static let mangaListStorageUrl = applicationSupportDirectory.appendingPathComponent("mangalist", conformingTo: .json)
    static let animeListStorageUrl = applicationSupportDirectory.appendingPathComponent("animelist", conformingTo: .json)
    static let mangaStorageUrl = applicationSupportDirectory.appendingPathComponent("manga", conformingTo: .folder)
    static let animeStorageUrl = applicationSupportDirectory.appendingPathComponent("anime", conformingTo: .folder)
}

extension Array {
    mutating func rearrange(fromIndex: Int, toIndex: Int){
        let element = self.remove(at: fromIndex)
        self.insert(element, at: toIndex)
    }
}
