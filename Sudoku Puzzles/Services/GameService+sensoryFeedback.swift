//
//  GameService+sensoryFeedback.swift
//  Sudoku Puzzles
//
//  Created by ian on 21/04/2025.
//

import SwiftUI
import SudukoEngine

extension GameService {

    func feedbackForInvalidCells(
        _ oldValue: [Sudoku.SudokuGrid.Cell],
        _ newValue: [Sudoku.SudokuGrid.Cell]
    ) -> Bool {
        if newValue.isEmpty {
            return false
        }

        let oldSet = Set(oldValue)
        let newSet = Set(newValue)

        // Check for new cells not in oldValue
        let newCellsNotInOld = newSet.subtracting(oldSet)
        if !newCellsNotInOld.isEmpty {
            return true
        }

        // Check for old cells not in newValue
        let oldCellsNotInNew = oldSet.subtracting(newSet)
        return oldCellsNotInNew.isEmpty
    }

    func feedbackForCorectInput(
        _ oldValue: Sudoku,
        _ newValue: Sudoku
    ) -> Bool {
        let oldSet = Set(oldValue.allCells)
        let newSet = Set(newValue.allCells)
        let invalidCellsSet = Set(invalidCells)

        // Check if there are no new cells
        guard let newCell = newSet.subtracting(oldSet).first else {
            return false
        }

        // Check if the new cell's value is 0 or if it's in the invalid cells set
        return newCell.value != 0 && !invalidCellsSet.contains(where: { $0.id == newCell.id })
    }
}
