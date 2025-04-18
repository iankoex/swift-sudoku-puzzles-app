//
//  BoardHeader.swift
//  Sudoku Puzzles
//
//  Created by ian on 07/04/2025.
//

import SwiftUI

struct BoardHeader: View {
    @Environment(GameService.self) private var gameService: GameService
    var namespace: Namespace

    var body: some View {
        HStack {
            Spacer()

            VStack {
                Text("Time")
                    .font(.caption2)
                TimerView(namespace: namespace)
                    .font(.caption)
            }

            Button("pause game", systemImage: "pause.circle") {
                gameService.toggleGameState()
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .font(.title)
        }
    }
}

struct TimerView: View {
    @Environment(GameService.self) private var gameService: GameService
    var namespace: Namespace

    var minutes: Int {
        return gameService.timeElapsed / 60
    }

    var seconds: Int {
        return gameService.timeElapsed % 60
    }

    var body: some View {
        VStack {
            Text(String(format: "%02d:%02d", minutes, seconds))
                .contentTransition(.numericText())
                .transaction { t in
                    t.animation = .default
                }
                .monospaced()
        }
        .matchedGeometryEffect(id: "timer.view", in: namespace.wrappedValue)
    }
}
