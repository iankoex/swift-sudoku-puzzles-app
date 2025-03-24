//
//  CellNotes.swift
//  Sudoku Puzzles
//
//  Created by ian on 24/03/2025.
//

import Foundation

struct CellNote: Sendable, Equatable {
    var cellID: String
    var values: [Int: Int] = [1:0, 2:0, 3:0, 4:0, 5:0, 6:0, 7:0, 8:0, 9:0]
}
