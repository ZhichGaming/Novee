//
//  MangaListVM.swift
//  Novee
//
//  Created by Nick on 2023-01-04.
//

import Foundation

class MangaListVM: MediaListVM<MangaListElement> {
    static let shared = MangaListVM()
    
    init() {
        super.init(savePath: URL.mangaListStorageUrl.path)
    }
}
