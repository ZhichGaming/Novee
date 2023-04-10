//
//  NovelListVM.swift
//  Novee
//
//  Created by Nick on 2023-03-05.
//

import Foundation

class NovelListVM: MediaListVM<NovelListElement> {
    static let shared = NovelListVM()
    
    init() {
        super.init(savePath: URL.novelListStorageUrl.path)
    }
}
