import SwiftUI

struct ToolbarView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        HStack(spacing: 12) {
            // Undo button
            toolButton(
                icon: "arrow.uturn.backward",
                label: "Undo",
                isActive: false,
                isDisabled: viewModel.gameState.moveHistory.isEmpty
            ) {
                viewModel.undo()
            }

            // Redo button
            toolButton(
                icon: "arrow.uturn.forward",
                label: "Redo",
                isActive: false,
                isDisabled: viewModel.gameState.redoHistory.isEmpty
            ) {
                viewModel.redo()
            }

            // Notes mode toggle
            toolButton(
                icon: "pencil",
                label: "Notes",
                isActive: viewModel.gameState.isNotesMode,
                isDisabled: false
            ) {
                viewModel.toggleNotesMode()
            }

            // Hint button
            toolButton(
                icon: "lightbulb",
                label: "Hint",
                isActive: false,
                isDisabled: false
            ) {
                viewModel.useHint()
            }

            // History button
            toolButton(
                icon: "clock.arrow.circlepath",
                label: "History",
                isActive: false,
                isDisabled: false
            ) {
                viewModel.showGameHistory = true
            }

            // New game button
            toolButton(
                icon: "plus.square",
                label: "New",
                isActive: false,
                isDisabled: false
            ) {
                viewModel.showDifficultyPicker = true
            }
        }
    }

    private func toolButton(
        icon: String,
        label: String,
        isActive: Bool,
        isDisabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isActive ? "\(icon).circle.fill" : icon)
                    .font(.system(size: 24))
                    .foregroundColor(
                        isDisabled ? .gray.opacity(0.5) :
                        isActive ? .blue : .primary
                    )

                Text(label)
                    .font(.caption)
                    .foregroundColor(
                        isDisabled ? .gray.opacity(0.5) :
                        isActive ? .blue : .secondary
                    )
            }
            .frame(width: 52, height: 50)
        }
        .disabled(isDisabled)
    }
}

#Preview {
    ToolbarView(viewModel: GameViewModel())
}
