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
        ScrollView {
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
                .focusable()
                .focusEffectDisabled()
                .onKeyPress(characters: .decimalDigits) { key in
                    let number: Int = Int(key.characters) ?? 0
                    gameService.updateSelectedCell(with: number)
                    return .handled
                }

                BoardNumberPad()
                    .padding(.vertical)
            }
            .padding(.horizontal)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    ActionButtons()
                }
            }
        }
        .fontDesign(.monospaced)
        .environment(gameService)
        .task {
            await gameService.generatePuzzle()
        }
    }
}

#Preview {
    SudokuBoardView()
        .environment(AppService())
        .frame(width: 500, height: 500)
}
