//
//  ActionButtons.swift
//  Sudoku Puzzles
//
//  Created by ian on 22/03/2025.
//

import SwiftUI

struct ActionButtons: View {
    @Environment(GameService.self) private var gameService: GameService

    var body: some View {
        HStack {
            Button("Undo", systemImage: "arrow.uturn.backward.circle") {

            }

            Button("Redo", systemImage: "arrow.uturn.right.circle") {

            }

            Button("Erase", systemImage: "eraser.line.dashed") {
                gameService.eraseSelectedCell()
            }

            Button("Notes", systemImage: gameService.inputMode == .play ? "pencil.line" : "pencil.slash") {
                withAnimation(.spring) {
                    switch gameService.inputMode {
                        case .play:
                            gameService.inputMode = .notes
                        case .notes:
                            gameService.inputMode = .play
                    }
                }
            }
            .tint(gameService.inputMode == .play ? .accentColor : .green)

            Button("Hint", systemImage: "lightbulb") {

            }
        }
        .disabled(gameService.isGeneratingNewGame)
    }
}
