//
//  Extentions.swift
//  Novee
//
//  Created by Nick on 2022-12-26.
//

import Foundation
import SwiftUI

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
