//
//  SudokuPuzzlesApp.swift
//  Sudoku Puzzles
//
//  Created by ian on 09/03/2025.
//

import SwiftUI
import SwiftData

@main
struct SudokuPuzzlesApp: App {
    @State private var appService: AppService = AppService()
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
//            ContentView()
            SudokuBoardView()
                .environment(appService)
        }
        .modelContainer(sharedModelContainer)
    }
}
