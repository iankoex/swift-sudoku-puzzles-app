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

            }

            Button("Notes", systemImage: "pencil.line") {

            }

            Button("Hint", systemImage: "lightbulb") {

            }
        }
        .disabled(gameService.isGeneratingNewGame)
    }
}
