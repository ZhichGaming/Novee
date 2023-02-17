//
//  ChapMangaNato.swift
//  Novee
//
//  Created by Nick on 2022-12-12.
//

import Foundation
import SwiftSoup
import SwiftUI

class ChapMangaNato: MangaNato {
    init() {
        super.init(
            label: "ChapMangaNato",
            sourceId: "chapmanganato",
            baseUrl: "https://chapmanganato.com"
        )
    }
}
