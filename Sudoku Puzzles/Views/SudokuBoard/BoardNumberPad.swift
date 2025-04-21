//
//  BoardNumberPad.swift
//  Sudoku Puzzles
//
//  Created by ian on 22/03/2025.
//

import SwiftUI
import SudukoEngine

struct BoardNumberPad: View {
    @Environment(GameService.self) private var gameService: GameService

    var body: some View {
        HStack {
            ForEach(1..<10) { number in
                boardButton(for: number)
            }
        }
    }

    func boardButton(for number: Int) -> some View {
        Button(action: {
            gameService.updateSelectedCell(with: number)
        }) {
            Text("\(number)")
        }
        .font(.title2)
        .buttonStyle(.borderless)
        .padding(.horizontal, 5)
        .padding(5)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 5))
        .disabled(boardButtonDisabled(number))
    }

    func boardButtonDisabled(_ number: Int) -> Bool {
        guard gameService.inputMode == .play else {
            return false
        }
        return !gameService.availableCellsForInput.contains(number)
    }
}
