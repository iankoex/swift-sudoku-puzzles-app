//
//  SudokuGridView.swift
//  Sudoku Puzzles
//
//  Created by ian on 22/03/2025.
//

import SwiftUI
import SudukoEngine

struct SudokuGridView: View {
    @Environment(AppService.self) private var appService: AppService
    @Environment(GameService.self) private var gameService: GameService

    let grid: Sudoku.SudokuGrid
    let gridItems: [GridItem] = Array(repeating: .init(.flexible(), spacing: 0), count: 3)

    var body: some View {
        LazyVGrid(columns: gridItems, alignment: .center, spacing: 0) {
            ForEach(grid.cells) { cell in
                Rectangle()
                    .fill(AnyShapeStyle(fillColor(for: cell)))
                    .border(Color.gray.secondary, width: 1)
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(alignment: .center) {
                        if cell.value != 0 {
                            Text("\(cell.value)")
                                .font(.title)
                                .foregroundStyle(foregroundColor(for: cell))
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onCellTapped(cell)
                    }
            }
        }
        .border(Color.gray, width: 2)
        .aspectRatio(1, contentMode: .fit)
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
