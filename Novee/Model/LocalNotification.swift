//
//  LocalNotification.swift
//  Novee
//
//  Created by Nick on 2023-08-04.
//

import Foundation

struct LocalNotification: Identifiable, Hashable {
    let id: UUID = UUID()
    
    var title: String
    var body: String
    
    var date: Date
}
