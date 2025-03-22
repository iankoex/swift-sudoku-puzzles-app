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
                Button(action: {
                    gameService.updateSelectedCell(with: number)
                }) {
                    Text("\(number)")
                }
                .font(.title)
                .buttonStyle(.borderless)
                .padding(.horizontal, 5)
                .padding(5)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 5))
//                .hoverEffect(.lift)
            }
        }
    }
}
