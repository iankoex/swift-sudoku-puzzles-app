//
//  CellView.swift
//  Sudoku Puzzles
//
//  Created by ian on 24/03/2025.
//

import SwiftUI
import SudukoEngine

struct SudokuCellView: View {
    @Environment(AppService.self) private var appService: AppService
    @Environment(GameService.self) private var gameService: GameService

    let grid: Sudoku.SudokuGrid
    let cell: Sudoku.SudokuGrid.Cell

    var body: some View {
        Rectangle()
            .fill(AnyShapeStyle(fillColor(for: cell)))
            .border(Color.gray.quinary, width: 1)
            .aspectRatio(1, contentMode: .fit)
            .overlay(alignment: .center) {
                if cell.value != 0 {
                    Text("\(cell.value)")
                        .font(.title)
                        .foregroundStyle(foregroundColor(for: cell))
                } else {
                    CellNoteView(cell: cell)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onCellTapped(cell)
            }
    }

    func fillColor(for cell: Sudoku.SudokuGrid.Cell) -> any ShapeStyle {
        if cell.value != 0 && gameService.selectedCell?.value == cell.value &&
            gameService.invalidCells.contains(where: { $0.id == cell.id }) {
            return appService.constansts.invalidCellBackgroundColor.tertiary
        }
        if gameService.selectedCell?.id == cell.id {
            return appService.constansts.selectedCellBackgroundColor.secondary
        }
        if gameService.selectedGridIdetifier == grid.id {
            return appService.constansts.selectedCellBackgroundColor.tertiary
        }
        return if gameService.selectedCell?.column == cell.column {
            appService.constansts.selectedCellBackgroundColor.tertiary
        } else if gameService.selectedCell?.row == cell.row {
            appService.constansts.selectedCellBackgroundColor.tertiary
        } else if gameService.selectedCell?.value == cell.value && cell.value != 0 {
            appService.constansts.selectedCellBackgroundColor.tertiary
        } else {
            appService.constansts.boardBackgroundColor.tertiary
        }
    }

    func foregroundColor(for cell: Sudoku.SudokuGrid.Cell) -> any ShapeStyle {
        if gameService.immutableCells.contains(where: { $0.id == cell.id }) {
            return Color.primary
        }
        return Color.primary.secondary
    }

    func onCellTapped(_ cell: Sudoku.SudokuGrid.Cell) {
        withAnimation(.interactiveSpring) {
            gameService.updateSelectedCell(gridID: grid.id, cell: cell)
        }
    }
}

fileprivate struct CellNoteView: View {
    @Environment(GameService.self) private var gameService: GameService

    let cell: Sudoku.SudokuGrid.Cell
    let gridItems: [GridItem] = Array(repeating: .init(.flexible(), spacing: 0), count: 3)

    var body: some View {
        Group {
            if let cellNote = gameService.cellNotes.first(where: { $0.cellID == cell.id }) {
                LazyVGrid(columns: gridItems, alignment: .center, spacing: 0) {
                    ForEach(1..<10) { index in
                        if let cellNoteValue = cellNote.values[index] {
                            Text("\(cellNoteValue)")
                                .opacity(cellNoteValue == 0 ? 0 : 1)
                                .font(.caption2)
                        }
                    }
                }
            }
        }
    }
}
