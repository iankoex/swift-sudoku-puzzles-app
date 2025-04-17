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
                SudokuCellView(grid: grid, cell: cell)
            }
        }
        .border(Color.gray.opacity(0.5), width: 2)
        .aspectRatio(1, contentMode: .fit)
    }
}
