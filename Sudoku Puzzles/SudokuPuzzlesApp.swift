//
//  SudokuPuzzlesApp.swift
//  Sudoku Puzzles
//
//  Created by ian on 09/03/2025.
//

import SwiftUI

@main
struct SudokuPuzzlesApp: App {
    @State private var appService: AppService = AppService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appService)
        }
    }
}
