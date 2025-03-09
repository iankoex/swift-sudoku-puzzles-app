//
//  Item.swift
//  Sudoku Puzzles
//
//  Created by ian on 09/03/2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
