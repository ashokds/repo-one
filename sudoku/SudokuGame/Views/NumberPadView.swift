import SwiftUI
import UniformTypeIdentifiers

struct DragPreviewView: View {
    let number: Int

    var body: some View {
        Text("\(number)")
            .font(.system(size: 32, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .frame(width: 56, height: 56)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .blue.opacity(0.5), radius: 8, x: 0, y: 4)
            )
    }
}

struct NumberPadView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { number in
                    numberButton(number)
                }
            }

            HStack(spacing: 8) {
                ForEach(6...9, id: \.self) { number in
                    numberButton(number)
                }
                clearButton
            }
        }
    }

    private func numberButton(_ number: Int) -> some View {
        let isComplete = viewModel.isNumberComplete(number)
        let isInvalid = viewModel.settings.highlightInvalidNumbers &&
                        viewModel.invalidNumbersForSelectedCell().contains(number)

        return Button(action: {
            viewModel.inputNumber(number)
        }) {
            Text("\(number)")
                .font(.system(size: 24, weight: .medium))
                .frame(width: 56, height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(buttonBackgroundColor(isComplete: isComplete, isInvalid: isInvalid))
                )
                .foregroundColor(buttonForegroundColor(isComplete: isComplete, isInvalid: isInvalid))
        }
        .disabled(isComplete)
        .draggable("\(number)") {
            DragPreviewView(number: number)
        }
    }

    private func buttonBackgroundColor(isComplete: Bool, isInvalid: Bool) -> Color {
        if isComplete {
            return Color.gray.opacity(0.3)
        } else if isInvalid {
            return Color.gray.opacity(0.15)
        } else {
            return Color.blue.opacity(0.1)
        }
    }

    private func buttonForegroundColor(isComplete: Bool, isInvalid: Bool) -> Color {
        if isComplete {
            return .gray
        } else if isInvalid {
            return .gray.opacity(0.5)
        } else {
            return .blue
        }
    }

    private var clearButton: some View {
        Button(action: {
            viewModel.clearCell()
        }) {
            Image(systemName: "xmark")
                .font(.system(size: 20, weight: .medium))
                .frame(width: 56, height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.1))
                )
                .foregroundColor(.red)
        }
    }
}

#Preview {
    NumberPadView(viewModel: GameViewModel())
}
