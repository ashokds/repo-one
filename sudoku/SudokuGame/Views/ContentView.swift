import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                // Title with difficulty and settings
                HStack {
                    Spacer()
                        .frame(width: 44)

                    Spacer()

                    VStack(spacing: 4) {
                        Text("Sudoku")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text(viewModel.currentDifficulty.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button(action: {
                        viewModel.showSettings = true
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 22))
                            .foregroundColor(.primary)
                    }
                    .frame(width: 44)
                }

                Spacer()

                // Game board
                BoardView(viewModel: viewModel)
                    .padding(.horizontal)

                Spacer()

                // Toolbar
                ToolbarView(viewModel: viewModel)
                    .padding(.horizontal)

                // Number pad
                NumberPadView(viewModel: viewModel)
                    .padding(.horizontal)

                Spacer()
            }
            .padding()

            // Win overlay
            if viewModel.gameState.isGameWon {
                winOverlay
            }
        }
        .confirmationDialog(
            "Select Difficulty",
            isPresented: $viewModel.showDifficultyPicker,
            titleVisibility: .visible
        ) {
            ForEach(Difficulty.allCases, id: \.self) { difficulty in
                Button(difficulty.rawValue) {
                    viewModel.startNewGame(difficulty: difficulty)
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .alert("Auto-Fill Available", isPresented: $viewModel.showAutoFillPrompt) {
            Button("Yes, Auto-Fill") {
                withAnimation {
                    viewModel.autoFillRemaining()
                }
            }
            Button("No, Thanks", role: .cancel) { }
        } message: {
            let numbers = viewModel.numbersReadyForAutoFill
            let numberList = numbers.map { String($0) }.joined(separator: ", ")
            Text("The number\(numbers.count > 1 ? "s" : "") \(numberList) \(numbers.count > 1 ? "have" : "has") only one spot remaining. Would you like to auto-fill?")
        }
        .sheet(isPresented: $viewModel.showGameHistory) {
            GameHistoryView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showSettings) {
            SettingsView(settings: viewModel.settings)
        }
    }

    private var winOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Congratulations!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("You solved the puzzle!")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.9))

                Button(action: {
                    viewModel.showDifficultyPicker = true
                }) {
                    Text("New Game")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue)
                        )
                }
                .padding(.top, 16)
            }
        }
        .transition(.opacity)
    }
}

#Preview {
    ContentView(viewModel: GameViewModel())
}
