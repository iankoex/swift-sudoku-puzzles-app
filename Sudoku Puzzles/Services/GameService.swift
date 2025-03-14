//
//  GameService.swift
//  Sudoku Puzzles
//
//  Created by ian on 14/03/2025.
//

import Foundation
import Observation
import SudukoEngine

@MainActor
@Observable class GameService {
    var sudoku: Sudoku = .empty
    var selectedGridIdetifier: Int = 100
    var selectedCell: Sudoku.SudokuGrid.Cell? = nil

    func updateSelectedCell(
        gridID: Int,
        cell: Sudoku.SudokuGrid.Cell
    ) {
        selectedGridIdetifier = gridID
        selectedCell = cell
    }

    func generatePuzzle() async {
        do {
            let puzzle = try await SudokuGenerator.generate(difficulty: .easy)
            sudoku = puzzle.puzzle
        } catch {
            fatalError("generatePuzzle failed: \(error)")
        }
    }
}
