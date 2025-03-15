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
    var puzzleSolution: Sudoku = .empty
    var immutableCells: [Sudoku.SudokuGrid.Cell] = []
    var invalidCells: [Sudoku.SudokuGrid.Cell] = []
    var selectedGridIdetifier: Int = 100
    var selectedCell: Sudoku.SudokuGrid.Cell? = nil

    func updateSelectedCell(gridID: Int, cell: Sudoku.SudokuGrid.Cell) {
        selectedGridIdetifier = gridID
        selectedCell = cell
    }

    func generatePuzzle() async {
        do {
            let puzzle = try await SudokuGenerator.generate(difficulty: .easy)
            sudoku = puzzle.puzzle
            puzzleSolution = puzzle.solved
            immutableCells = sudoku.allCells.filter { $0.value != 0}
        } catch {
            fatalError("generatePuzzle failed: \(error)")
        }
    }

    func updateSelectedCell(with number: Int) {
        guard let selectedCell else { return }
        guard !immutableCells.contains(where: { $0.id == selectedCell.id }) else {
            return
        }
        let gridIndex = selectedGridIdetifier - 1
        let cellIndex = sudoku.grid[gridIndex].cells.firstIndex(where: { $0.id == selectedCell.id })
        guard let cellIndex else {
            return
        }
        sudoku.grid[gridIndex].cells[cellIndex].value = number
        self.selectedCell = sudoku.grid[gridIndex].cells[cellIndex]
        invalidCells = sudoku.invalidCells()
        // haptic feedback on error
    }
}
