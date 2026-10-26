//
//  Item.swift
//  discover
//
//  Created by forest on 2026/10/26.
//

import Foundation
import SwiftData

@Model
final class Item_ {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
