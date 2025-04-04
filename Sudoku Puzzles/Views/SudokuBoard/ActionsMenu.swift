//
//  ActionsMenu.swift
//  Sudoku Puzzles
//
//  Created by ian on 22/03/2025.
//

import SwiftUI
import SudukoEngine

struct ActionsMenu: View {
    @Environment(GameService.self) private var gameService: GameService
    
    var body: some View {
        Menu("Actions", systemImage: "ellipsis.circle") {
            Section("New Game") {
                ForEach(Sudoku.Difficulty.allCases) { difficulty in
                    Button(difficulty.description) {
                        gameService.generatePuzzle(difficulty: difficulty)
                    }
                }
            }
            .disabled(gameService.isGeneratingNewGame)

            Button("Settings", systemImage: "gear") {

            }
        }
    }
}
