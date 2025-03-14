//
//  SudokuBoard.swift
//  Sudoku Puzzles
//
//  Created by ian on 12/03/2025.
//

import SwiftUI
import SudukoEngine

struct SudokuBoardView: View {
    let gridItems: [GridItem] = Array(repeating: .init(.flexible(), spacing: 0), count: 3)
    @State private var gameService: GameService = GameService()

    var body: some View {
        VStack {
            Text(
                "grid: \(gameService.selectedGridIdetifier), cell: \(gameService.selectedCell?.id ?? "")"
            )

            LazyVGrid(columns: gridItems, alignment: .center, spacing: 0) {
                ForEach(gameService.sudoku.grid) { grid in
                    SudokuGridView(grid: grid)
                }
            }
            .border(Color.gray, width: 4)
            .aspectRatio(1, contentMode: .fit)
            .padding()
            .task {
                await gameService.generatePuzzle()
            }
        }
        .fontDesign(.monospaced)
        .environment(gameService)
    }
}

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
        .background(gridBackgroundColor)
    }

    var gridBackgroundColor: some ShapeStyle {
        if gameService.selectedGridIdetifier == grid.id {
            appService.constansts.selectedCellBackgroundColor.tertiary
        } else {
            appService.constansts.boardBackgroundColor.tertiary
        }
    }

    func fillColor(for cell: Sudoku.SudokuGrid.Cell) -> any ShapeStyle {
        guard gameService.selectedCell?.id != cell.id else {
            return appService.constansts.selectedCellBackgroundColor.tertiary
        }
        guard gameService.selectedGridIdetifier != grid.id else {
            return appService.constansts.boardBackgroundColor.tertiary
        }
        return if gameService.selectedCell?.column == cell.column {
            appService.constansts.selectedCellBackgroundColor.tertiary
        } else if gameService.selectedCell?.row == cell.row {
            appService.constansts.selectedCellBackgroundColor.tertiary
        } else if gameService.selectedCell?.value == cell.value {
            appService.constansts.selectedCellBackgroundColor.tertiary
        } else {
            appService.constansts.boardBackgroundColor.tertiary
        }
    }

    func onCellTapped(_ cell: Sudoku.SudokuGrid.Cell) {
        withAnimation(.interactiveSpring) {
            gameService.updateSelectedCell(gridID: grid.id, cell: cell)
        }
    }
}
#Preview {
    SudokuBoardView()
}
