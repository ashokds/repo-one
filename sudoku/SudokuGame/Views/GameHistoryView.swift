import SwiftUI

struct GameHistoryView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab picker
                Picker("Filter", selection: $selectedTab) {
                    Text("All").tag(0)
                    Text("In Progress").tag(1)
                    Text("Completed").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                // Game list
                if filteredRecords.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text(emptyMessage)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filteredRecords) { record in
                            GameHistoryRow(record: record)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.loadGameFromHistory(record)
                                }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let record = filteredRecords[index]
                                viewModel.deleteGameFromHistory(record)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Game History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        viewModel.showGameHistory = false
                    }
                }
            }
        }
    }

    private var filteredRecords: [GameRecord] {
        switch selectedTab {
        case 1:
            return viewModel.historyManager.incompleteGames
        case 2:
            return viewModel.historyManager.completedGames
        default:
            return viewModel.historyManager.records
        }
    }

    private var emptyMessage: String {
        switch selectedTab {
        case 1:
            return "No games in progress"
        case 2:
            return "No completed games"
        default:
            return "No game history yet"
        }
    }
}

struct GameHistoryRow: View {
    let record: GameRecord

    var body: some View {
        HStack(spacing: 16) {
            // Mini board preview
            MiniBoard(record: record)
                .frame(width: 60, height: 60)

            // Game info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(record.difficulty.rawValue)
                        .font(.headline)

                    if record.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.subheadline)
                    }
                }

                Text(record.formattedDate)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(record.statusText)
                    .font(.caption)
                    .foregroundColor(record.isCompleted ? .green : .blue)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding(.vertical, 8)
    }
}

struct MiniBoard: View {
    let record: GameRecord

    var body: some View {
        GeometryReader { geometry in
            let cellSize = geometry.size.width / 9

            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: Color(UIColor.label).opacity(0.15), radius: 1)

                // Cells
                VStack(spacing: 0) {
                    ForEach(0..<9, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<9, id: \.self) { col in
                                let cell = record.board[row, col]
                                Rectangle()
                                    .fill(cellColor(cell: cell))
                                    .frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }

                // Grid lines
                Path { path in
                    for i in 0...3 {
                        let pos = CGFloat(i * 3) * cellSize
                        path.move(to: CGPoint(x: pos, y: 0))
                        path.addLine(to: CGPoint(x: pos, y: geometry.size.height))
                        path.move(to: CGPoint(x: 0, y: pos))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: pos))
                    }
                }
                .stroke(Color(UIColor.separator), lineWidth: 0.5)
            }
        }
    }

    private func cellColor(cell: Cell) -> Color {
        if cell.value != nil {
            return cell.isFixed ? Color(UIColor.systemGray3) : Color.blue.opacity(0.4)
        }
        return Color.clear
    }
}

#Preview {
    GameHistoryView(viewModel: GameViewModel())
}
