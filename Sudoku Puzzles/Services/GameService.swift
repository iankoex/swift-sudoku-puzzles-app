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
import SwiftUI

/// A service class that manages the state and logic of a Sudoku game.
@Observable
class GameService {

    // MARK: - Properties

    /// An instance of `UndoManager` to manage undo and redo actions.
    var undoManager: UndoManager = UndoManager()

    /// The current Sudoku puzzle being played.
    var sudoku: Sudoku = .empty

    /// The solution to the current Sudoku puzzle.
    var puzzleSolution: Sudoku = .empty

    /// An array of immutable cells that cannot be changed by the player.
    var immutableCells: [Sudoku.SudokuGrid.Cell] = []

    /// An array of cells that are currently invalid.
    var invalidCells: [Sudoku.SudokuGrid.Cell] = []

    /// The identifier of the currently selected grid.
    var selectedGridIdetifier: Int = 0

    /// The currently selected cell in the Sudoku grid.
    var selectedCell: Sudoku.SudokuGrid.Cell? = nil

    /// The current input mode, either for playing or for notes.
    var inputMode: InputMode = .play

    /// An array of notes for the cells.
    var cellNotes: [CellNote] = []

    /// An array of available numbers for input.
    var availableCellsForInput: [Int] = []

    /// The elapsed time in seconds since the game started.
    var timeElapsed: Int = 0

    /// A boolean indicating whether the game is currently running.
    var isGameRunning: Bool = false

    /// A cancellable for the timer publisher.
    private var timer: AnyCancellable?

    /// The last known state of the game (running or not).
    private var lastGameStateIsRunnig: Bool? = nil

    /// A computed property indicating if a new game is being generated.
    var isGeneratingNewGame: Bool {
        return sudoku == .empty
    }

    // MARK: - Cell Selection

    /// Updates the currently selected cell and grid identifier.
    /// - Parameters:
    ///   - gridID: The identifier of the grid containing the cell.
    ///   - cell: The selected cell.
    func updateSelectedCell(gridID: Int, cell: Sudoku.SudokuGrid.Cell) {
        selectedGridIdetifier = gridID
        selectedCell = cell
    }

    // MARK: - Game Generation

    /// Generates a new Sudoku puzzle with the specified difficulty.
    /// - Parameter difficulty: The difficulty level of the puzzle.
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
                // Reset the board
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

    /// Updates the selected cell with a new value, supporting undo/redo functionality.
    /// - Parameter value: The new value to set in the selected cell.
    /// - Returns: A boolean indicating whether the update was successful.
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
    /// - Returns: A tuple containing the selected cell, its grid index, and cell index, or nil if not applicable.
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
    /// - Parameters:
    ///   - gridIndex: The index of the grid containing the cell.
    ///   - cellIndex: The index of the cell within the grid.
    ///   - value: The new value to set for the cell.
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

    /// Updates the notes for the selected cell, supporting undo functionality.
    /// - Parameters:
    ///   - selectedCell: The cell for which notes are being updated.
    ///   - value: The note value to toggle.
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
    /// - Parameters:
    ///   - cellID: The ID of the cell whose notes are being restored.
    ///   - previousNotes: The notes to restore.
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
    /// - Parameter cellID: The ID of the cell whose notes are to be erased.
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

    /// Erases the value of the currently selected cell, supporting undo functionality.
    /// - Returns: A boolean indicating whether the erase operation was successful.
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

    /// A boolean indicating whether an undo operation can be performed.
    var canUndo: Bool {
        undoManager.canUndo
    }

    /// A boolean indicating whether a redo operation can be performed.
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

    // MARK: - Timer Management

    /// Starts the game timer from a specified number of seconds.
    /// - Parameter seconds: The number of seconds to start the timer from (default is 0).
    func startTimer(from seconds: Int = 0) {
        timeElapsed = seconds
        isGameRunning = true
        lastGameStateIsRunnig = nil
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isGameRunning else { return }
                self.timeElapsed += 1
            }
    }

    /// Pauses the game timer.
    func pauseTimer() {
        isGameRunning = false
        timer?.cancel()
        timer = nil
    }

    /// Resets the game timer to zero.
    func resetTimer() {
        pauseTimer()
        timeElapsed = 0
    }

    /// Toggles the game state between running and paused.
    func toggleGameState() {
        withAnimation(.snappy) {
            if isGameRunning {
                pauseTimer()
            } else {
                startTimer(from: timeElapsed)
            }
        }
    }

    /// Changes the game state based on the current scene phase.
    /// - Parameter state: The current scene phase (active or inactive).
    func changeGameStateUsingPhase(_ state: ScenePhase) {
        if lastGameStateIsRunnig == nil {
            lastGameStateIsRunnig = isGameRunning
        }
        withAnimation(.snappy) {
            if state == .active {
                if let lastGameStateIsRunnig, lastGameStateIsRunnig {
                    startTimer(from: timeElapsed)
                    self.lastGameStateIsRunnig = nil
                }
            } else {
                pauseTimer()
            }
        }
    }
}

// MARK: - Input Mode Enum

extension GameService {
    /// An enumeration representing the input modes for the game.
    enum InputMode: Equatable {
        case play
        case notes
    }
}
