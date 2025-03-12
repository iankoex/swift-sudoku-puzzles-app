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
    let sudoku: Sudoku = Sudoku.empty

    var body: some View {
        LazyVGrid(columns: gridItems, alignment: .center, spacing: 0) {
            ForEach(sudoku.grid) { grid in
                SudokuGridView(grid: grid)
            }
        }
        .border(Color.gray, width: 4)
        .aspectRatio(1, contentMode: .fit)
        .padding()
    }
}

struct SudokuGridView: View {
    let grid: Sudoku.SudokuGrid
    let gridItems: [GridItem] = Array(repeating: .init(.flexible(), spacing: 0), count: 3)

    var body: some View {
        LazyVGrid(columns: gridItems, alignment: .center, spacing: 0) {
            ForEach(grid.cells) { cell in
                Color.clear
                    .border(Color.gray.opacity(0.5), width: 1)
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(alignment: .center) {
                        Text("\(cell.value)")
                    }
            }
        }
        .border(Color.gray, width: 2)
        .aspectRatio(1, contentMode: .fit)
    }
}
#Preview {
    SudokuBoardView()
}
