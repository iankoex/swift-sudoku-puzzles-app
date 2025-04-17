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
    @Environment(\.undoManager) var undoManager
    let namespace: Namespace = Namespace()

    var body: some View {
        ScrollView {
            Group {
                if gameService.isGeneratingNewGame {
                    contentUnavailableView
                } else {
                    boardView
                }
            }
            .padding(.horizontal)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    ActionsMenu()
                }
                ToolbarItem(placement: .automatic) {
                    ActionButtons()
                }
            }
        }
        .fontDesign(.monospaced)
        .scrollBounceBehavior(.basedOnSize)
        .environment(gameService)
        .task {
            if let undoManager {
                gameService.undoManager = undoManager
            }
            print("generate the game better")
            gameService.generatePuzzle(difficulty: .medium)
        }
    }

    var boardView: some View {
        VStack {
            BoardHeader(namespace: namespace)
            
            Group {
                LazyVGrid(columns: gridItems, alignment: .center, spacing: 0) {
                    ForEach(gameService.sudoku.grid) { grid in
                        SudokuGridView(grid: grid)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.gray.opacity(0.7), lineWidth: 4)
                }
                .aspectRatio(1, contentMode: .fit)
                .focusable()
                .focusEffectDisabled()
                .scaleEffect(gameService.isGameRunning ? 1 : 0.95)
                .blur(radius: gameService.isGameRunning ? 0 : 5)

                .onKeyPress(characters: .decimalDigits) { key in
                    let number: Int = Int(key.characters) ?? 0
                    if gameService.updateSelectedCell(with: number) {
                        return .handled
                    }
                    return .ignored
                }
                //            .onModifierKeysChanged(mask: .option) { old, new in
                //                if new.isEmpty {
                //                    // Option key released
                //                    gameService.inputMode = .play
                //                } else {
                //                    // Option key pressed
                //                    gameService.inputMode = .notes
                //                }
                //            }
                .onKeyPress(characters: [UnicodeScalar(127), UnicodeScalar(8)]) { _ in
                    print("Unicode Scalers need investigation, especially for delete key")
                    if gameService.eraseSelectedCell() {
                        return .handled
                    }
                    return .ignored
                }
                .disabled(!gameService.isGameRunning)
                .overlay {
                    if !gameService.isGameRunning {
                        continuePlayingButton
                    }
                }

                BoardNumberPad()
                    .padding(.vertical)
                    .disabled(!gameService.isGameRunning)
            }
        }
    }

    var continuePlayingButton: some View {
        VStack {
            TimerView(namespace: namespace)
            Button("play", systemImage: "play") {
                withAnimation(.snappy) {
                    gameService.toggleGameState()
                }
            }


        }
        .buttonStyle(.plain)
        .labelStyle(.iconOnly)
        .font(.largeTitle)
        .padding()
        .contentShape(Circle())
        .foregroundStyle(.gray)
    }

    var contentUnavailableView: some View {
        ContentUnavailableView(
            label: {
                Label(title: {
                    Text("Generating Puzzle ...")
                }, icon: {
                    ProgressView()
                        .progressViewStyle(.circular)
                })
            }, description: {
                Text("You will be able to play once the puzzle is generated.")
            }
        )
    }
}

#Preview {
    SudokuBoardView()
        .environment(AppService())
        .frame(width: 500, height: 500)
}
