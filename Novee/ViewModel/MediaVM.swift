//
//  MediaVM.swift
//  Novee
//
//  Created by Nick on 2023-03-30.
//

import Foundation

class MediaVM<T: Media>: ObservableObject {
    init(selectedSource: String) {
        self.selectedSource = selectedSource
    }
    
    @Published var selectedSource: String
    @Published var pageNumber = 1
}
