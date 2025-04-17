//
//  GameService.swift
//  Sudoku Puzzles
//
//  Created by ian on 14/03/2025.
//

import Foundation
import Observation
import SudukoEngine
import Combine

@Observable
class GameService {
    var undoManager: UndoManager = UndoManager()
    var sudoku: Sudoku = .empty
    var puzzleSolution: Sudoku = .empty
    var immutableCells: [Sudoku.SudokuGrid.Cell] = []
    var invalidCells: [Sudoku.SudokuGrid.Cell] = []
    var selectedGridIdetifier: Int = 0
    var selectedCell: Sudoku.SudokuGrid.Cell? = nil
    var inputMode: InputMode = .play
    var cellNotes: [CellNote] = []
    var availableCellsForInput: [Int] = []
    var timeElapsed: Int = 0
    var isGameRunning: Bool = false
    private var timer: AnyCancellable?

    var isGeneratingNewGame: Bool {
        return sudoku == .empty
    }

    // MARK: - Cell Selection

    func updateSelectedCell(gridID: Int, cell: Sudoku.SudokuGrid.Cell) {
        selectedGridIdetifier = gridID
        selectedCell = cell
    }

    // MARK: - Game Generation

    @MainActor
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
                immutableCells = sudoku.allCells.filter { $0.value != 0 }
                invalidCells = sudoku.invalidCells()
                // reset the board
                cellNotes = []
                availableCellsForInput = Array(1...9)
                selectedCell = nil
                selectedGridIdetifier = 0
                startTimer(from: 0)
                // Clear undo stack for a new game.
                undoManager.removeAllActions()
            } catch {
                generatePuzzle(difficulty: difficulty)
#if DEBUG
                fatalError("generatePuzzle failed: \(error)")
#endif
            }
        }
    }

    // MARK: - Update Cell Value with Undo/Redo

    @discardableResult
    func updateSelectedCell(with value: Int) -> Bool {
        guard let (selectedCell, gridIndex, cellIndex) = selectedCellIndicies() else {
            return false
        }
        if inputMode == .play {
            // Clear any existing notes on this cell.
            cellNotes.removeAll(where: { $0.cellID == selectedCell.id })
            updateCellValue(gridIndex: gridIndex, cellIndex: cellIndex, value: value)
            availableCellsForInput = SudokuGenerator.getAvailableNumbers(from: sudoku, using: puzzleSolution)
        } else if inputMode == .notes {
            updateCellNotes(selectedCell: selectedCell, value: value)
        }
        return true
    }

    /// Returns a tuple containing the selected cell along with its indices in the Sudoku model.
    private func selectedCellIndicies() -> (selectedCell: Sudoku.SudokuGrid.Cell, gridIndex: Int, cellIndex: Int)? {
        guard let selectedCell else { return nil }
        guard !immutableCells.contains(where: { $0.id == selectedCell.id }) else {
            return nil
        }
        let gridIndex = selectedGridIdetifier - 1
        guard let cellIndex = sudoku.grid[gridIndex].cells.firstIndex(where: { $0.id == selectedCell.id }) else {
            return nil
        }
        return (selectedCell, gridIndex, cellIndex)
    }

    /// Updates a cell's value with undo support. When a cell is updated,
    /// the previous value is captured and registered with the UndoManager.
    private func updateCellValue(gridIndex: Int, cellIndex: Int, value: Int) {
        // Capture the cell's old value.
        let oldValue = sudoku.grid[gridIndex].cells[cellIndex].value

        // Register the inverse change with the undo manager.
        undoManager.registerUndo(withTarget: self) { target in
            // When undoing, revert the cell to its old value.
            target.updateCellValue(gridIndex: gridIndex, cellIndex: cellIndex, value: oldValue)
            // Also update dependent properties.
            target.invalidCells = target.sudoku.invalidCells()
            target.availableCellsForInput = SudokuGenerator.getAvailableNumbers(from: target.sudoku, using: target.puzzleSolution)
        }
        undoManager.setActionName("Cell Value Update")

        // Apply the new value.
        if oldValue == value {
            // A tap on the same value resets the cell.
            sudoku.grid[gridIndex].cells[cellIndex].value = 0
        } else {
            sudoku.grid[gridIndex].cells[cellIndex].value = value
        }
        // Update selected cell to reflect the change.
        self.selectedCell = sudoku.grid[gridIndex].cells[cellIndex]
        self.invalidCells = sudoku.invalidCells()
    }

    // MARK: - Update Cell Notes with Undo/Redo

    private func updateCellNotes(selectedCell: Sudoku.SudokuGrid.Cell, value: Int) {
        // Capture the current note for the selected cell.
        let oldNotes: [Int: Int]
        if let index = cellNotes.firstIndex(where: { $0.cellID == selectedCell.id }) {
            oldNotes = cellNotes[index].values
        } else {
            oldNotes = [:]
        }

        // Closure to update cell notes (toggle value presence).
        func applyNoteChange(for cellID: String, value: Int, currentNotes: inout [Int: Int]) {
            if currentNotes[value] == value {
                currentNotes[value] = 0
            } else {
                currentNotes[value] = value
            }
        }

        // Register undo operation. The undo block will restore the old notes.
        undoManager.registerUndo(withTarget: self) { target in
            target.restoreCellNotes(cellID: selectedCell.id, previousNotes: oldNotes)
        }
        undoManager.setActionName("Cell Note Update")

        // Update the note for the selected cell.
        if let index = cellNotes.firstIndex(where: { $0.cellID == selectedCell.id }) {
            applyNoteChange(for: selectedCell.id, value: value, currentNotes: &cellNotes[index].values)
        } else {
            var newNotes: [Int: Int] = [:]
            // Set the note based on our change.
            newNotes[value] = value
            cellNotes.append(CellNote(cellID: selectedCell.id, values: newNotes))
        }
    }

    /// Helper method to restore cell notes to a previous state.
    func restoreCellNotes(cellID: String, previousNotes: [Int: Int]) {
        if let index = cellNotes.firstIndex(where: { $0.cellID == cellID }) {
            // Register the redo operation: capture the state before restoring.
            let currentNotes = cellNotes[index].values
            undoManager.registerUndo(withTarget: self) { target in
                target.restoreCellNotes(cellID: cellID, previousNotes: currentNotes)
            }
            cellNotes[index].values = previousNotes
        } else {
            // If no current notes exist, we add one.
            cellNotes.append(CellNote(cellID: cellID, values: previousNotes))

            // Also, register redo accordingly.
            undoManager.registerUndo(withTarget: self) { target in
                target.eraseNotes(for: cellID)
            }
        }
    }

    /// Helper to erase cell notes.
    func eraseNotes(for cellID: String) {
        if let index = cellNotes.firstIndex(where: { $0.cellID == cellID }) {
            let currentNotes = cellNotes[index].values
            undoManager.registerUndo(withTarget: self) { target in
                target.restoreCellNotes(cellID: cellID, previousNotes: currentNotes)
            }
            cellNotes.remove(at: index)
        }
    }

    // MARK: - Erase Cell Value with Undo/Redo

    @discardableResult
    func eraseSelectedCell() -> Bool {
        guard let (selectedCell, gridIndex, cellIndex) = selectedCellIndicies() else {
            return false
        }
        updateCellValue(gridIndex: gridIndex, cellIndex: cellIndex, value: 0)
        cellNotes.removeAll(where: { $0.cellID == selectedCell.id })
        return true
    }

    // MARK: - Public Undo/Redo Methods

    var canUndo: Bool {
        undoManager.canUndo
    }

    var canRedo: Bool {
        undoManager.canRedo
    }

    /// Performs an undo action using the internal UndoManager.
    func undo() {
        if canUndo {
            undoManager.undo()
        }
    }

    /// Performs a redo action using the internal UndoManager.
    func redo() {
        if canRedo {
            undoManager.redo()
        }
    }

    func startTimer(from seconds: Int = 0) {
        timeElapsed = seconds
        isGameRunning = true
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isGameRunning else { return }
                self.timeElapsed += 1
            }
    }

    func pauseTimer() {
        isGameRunning = false
        timer?.cancel()
    }

    func resetTimer() {
        isGameRunning = false
        timer?.cancel()
        timeElapsed = 0
    }

    func toggleGameState() {
        if isGameRunning {
            pauseTimer()
        } else {
            startTimer(from: timeElapsed)
        }
    }
}

extension GameService {
    enum InputMode: Equatable {
        case play
        case notes
    }
}
