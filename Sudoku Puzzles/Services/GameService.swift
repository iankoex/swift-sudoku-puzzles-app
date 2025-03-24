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
    var inputMode: InputMode = .play
    var cellNotes: [CellNote] = []

    var isGeneratingNewGame: Bool {
        return sudoku == .empty
    }

    func updateSelectedCell(gridID: Int, cell: Sudoku.SudokuGrid.Cell) {
        selectedGridIdetifier = gridID
        selectedCell = cell
    }

    func generatePuzzle(difficulty: Sudoku.Difficulty) {
        Task {
            sudoku = .empty
            do {
                let puzzle = try await SudokuGenerator.generate(difficulty: difficulty)
                let sudoku = puzzle.puzzle
                defer {
                    self.sudoku = sudoku
                }
                puzzleSolution = puzzle.solved
                immutableCells = sudoku.allCells.filter { $0.value != 0}
                invalidCells = sudoku.invalidCells()
                cellNotes = []
            } catch {
                generatePuzzle(difficulty: difficulty)
                #if DEBUG
                fatalError("generatePuzzle failed: \(error)")
                #endif
            }
        }
    }

    func updateSelectedCell(with value: Int) {
        guard let selectedCell else { return }
        guard !immutableCells.contains(where: { $0.id == selectedCell.id }) else {
            return
        }
        let gridIndex = selectedGridIdetifier - 1
        let cellIndex = sudoku.grid[gridIndex].cells.firstIndex(where: { $0.id == selectedCell.id })
        guard let cellIndex else {
            return
        }
        if inputMode == .play {
            cellNotes.removeAll(where: { $0.cellID == selectedCell.id })
            updateCellValue(gridIndex: gridIndex, cellIndex: cellIndex, value: value)
        } else if inputMode == .notes {
            updateCellNotes(selectedCell: selectedCell, value: value)
        }
    }

    private func updateCellValue(gridIndex: Int, cellIndex: Int, value: Int) {
        if sudoku.grid[gridIndex].cells[cellIndex].value == value {
            sudoku.grid[gridIndex].cells[cellIndex].value = 0
        } else {
            sudoku.grid[gridIndex].cells[cellIndex].value = value
        }
        self.selectedCell = sudoku.grid[gridIndex].cells[cellIndex]
        self.invalidCells = sudoku.invalidCells()
        // haptic feedback on error
    }

    private func updateCellNotes(selectedCell: Sudoku.SudokuGrid.Cell, value: Int) {
        if let index = cellNotes.firstIndex(where: { $0.cellID == selectedCell.id }) {
            if cellNotes[index].values[value] == value {
                cellNotes[index].values[value] = 0
            } else {
                cellNotes[index].values.updateValue(value, forKey: value)
            }
        } else {
            cellNotes.append(CellNote(cellID: selectedCell.id))
            updateCellNotes(selectedCell: selectedCell, value: value)
        }
    }
}

extension GameService {
    enum InputMode: Equatable {
        case play
        case notes
    }
}
