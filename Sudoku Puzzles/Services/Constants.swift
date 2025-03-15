//
//  Constants.swift
//  Sudoku Puzzles
//
//  Created by ian on 14/03/2025.
//

import Foundation
import SwiftUI

final class Constants: Sendable {
    let selectedCellBackgroundColor: Color
    let boardBackgroundColor: Color
    let invalidCellBackgroundColor: Color

    init(
        boardBackgroundColor: Color,
        selectedCellBackgroundColor: Color,
        invalidCellBackgroundColor: Color
    ) {
        self.boardBackgroundColor = boardBackgroundColor
        self.selectedCellBackgroundColor = selectedCellBackgroundColor
        self.invalidCellBackgroundColor = invalidCellBackgroundColor
    }
}

extension Constants {
    static let `default`: Constants = Constants(
        boardBackgroundColor: Color.clear,
        selectedCellBackgroundColor: Color.cyan,
        invalidCellBackgroundColor: Color.red
    )
}
