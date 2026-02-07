import SwiftUI

@main
struct SudokuGameApp: App {
    @StateObject private var viewModel = GameViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .inactive || newPhase == .background {
                viewModel.saveGame()
            }
        }
    }
}
